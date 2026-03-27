"""
Tests for the entropy module.

Validates the mathematical correctness of Shannon entropy computations
and the conditional entropy estimation algorithm.
"""

import sys
import os
import numpy as np

# Add project root to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.simulation.entropy import (
    binary_entropy,
    entropy_map,
    total_field_entropy,
    information_gain,
    resolvability_capacity,
    mrf_conditional_entropy,
)


def test_binary_entropy_bounds():
    """H(p) must be in [0, 1] for all p in [0, 1]."""
    p_values = np.linspace(0, 1, 1000)
    h = binary_entropy(p_values)
    assert np.all(h >= -1e-10), "Entropy must be non-negative"
    assert np.all(h <= 1.0 + 1e-10), "Binary entropy must be <= 1 bit"
    print("  [PASS] binary_entropy bounds")


def test_binary_entropy_maximum():
    """H(0.5) = 1.0 (maximum uncertainty)."""
    h = binary_entropy(0.5)
    assert abs(h - 1.0) < 1e-10, f"H(0.5) should be 1.0, got {h}"
    print("  [PASS] binary_entropy maximum at p=0.5")


def test_binary_entropy_zeros():
    """H(0) = 0 and H(1) = 0 (certainty)."""
    h0 = binary_entropy(0.0)
    h1 = binary_entropy(1.0)
    assert h0 < 1e-10, f"H(0) should be ~0, got {h0}"
    assert h1 < 1e-10, f"H(1) should be ~0, got {h1}"
    print("  [PASS] binary_entropy at certainty (p=0, p=1)")


def test_binary_entropy_symmetry():
    """H(p) = H(1-p) (symmetry around p=0.5)."""
    p_values = np.linspace(0.01, 0.49, 100)
    h_p = binary_entropy(p_values)
    h_1mp = binary_entropy(1.0 - p_values)
    assert np.allclose(h_p, h_1mp, atol=1e-12), "H(p) must equal H(1-p)"
    print("  [PASS] binary_entropy symmetry")


def test_binary_entropy_array():
    """binary_entropy works on arrays."""
    p = np.array([0.0, 0.25, 0.5, 0.75, 1.0])
    h = binary_entropy(p)
    assert h.shape == (5,), f"Expected shape (5,), got {h.shape}"
    assert h[2] > h[1] > h[0], "Entropy should increase toward p=0.5"
    print("  [PASS] binary_entropy array input")


def test_entropy_map_shape():
    """entropy_map preserves input shape."""
    field = np.random.rand(16, 16)
    ent = entropy_map(field)
    assert ent.shape == (16, 16), f"Expected (16,16), got {ent.shape}"
    print("  [PASS] entropy_map shape")


def test_entropy_map_uniform():
    """Uniform probability field has maximum entropy everywhere."""
    field = np.full((10, 10), 0.5)
    ent = entropy_map(field)
    assert np.allclose(ent, 1.0, atol=1e-10), "Uniform p=0.5 should give H=1.0"
    print("  [PASS] entropy_map uniform field")


def test_total_field_entropy():
    """Total entropy is sum of pixelwise entropies."""
    field = np.full((10, 10), 0.5)
    total = total_field_entropy(field)
    assert abs(total - 100.0) < 1e-8, f"Expected 100.0, got {total}"
    print("  [PASS] total_field_entropy")


def test_information_gain():
    """Information gain is non-negative."""
    before = np.full((10, 10), 1.0)
    after = np.full((10, 10), 0.8)
    gain = information_gain(before, after)
    assert gain > 0, f"Information gain should be positive, got {gain}"
    assert abs(gain - 20.0) < 1e-8, f"Expected 20.0, got {gain}"
    print("  [PASS] information_gain")


def test_resolvability_capacity():
    """Resolvability capacity C_k in [0, 1]."""
    c0 = resolvability_capacity(100.0, 100.0)
    assert abs(c0) < 1e-10, f"C_0 should be 0, got {c0}"

    c_half = resolvability_capacity(100.0, 50.0)
    assert abs(c_half - 0.5) < 1e-10, f"Expected 0.5, got {c_half}"

    c_full = resolvability_capacity(100.0, 0.0)
    assert abs(c_full - 1.0) < 1e-10, f"C_N should be 1, got {c_full}"
    print("  [PASS] resolvability_capacity")


def test_mrf_entropy():
    """MRF conditional entropy produces valid results."""
    np.random.seed(42)
    field = np.random.randint(0, 2, (32, 32)).astype(np.float64)
    mask = np.zeros((32, 32), dtype=bool)
    mask[16, 16] = True

    h = mrf_conditional_entropy(field, mask, clique_radius=2)
    assert h.shape == (32, 32), f"Expected (32,32), got {h.shape}"
    assert h[16, 16] == 0, "Sampled position should have zero entropy"
    assert np.all(h >= 0), "All entropy values must be non-negative"
    assert np.all(h <= 1.0 + 1e-10), "Binary entropy must be <= 1 bit"
    print("  [PASS] MRF conditional entropy")


def test_mrf_entropy_all_sampled():
    """When all positions are sampled, entropy should be zero everywhere."""
    field = np.random.randint(0, 2, (8, 8)).astype(np.float64)
    mask = np.ones((8, 8), dtype=bool)
    h = mrf_conditional_entropy(field, mask, clique_radius=1)
    assert np.allclose(h, 0.0), "All-sampled field should have zero entropy"
    print("  [PASS] MRF entropy all-sampled")


def test_mrf_entropy_no_sampled():
    """When no positions are sampled, entropy should use Laplace prior (p=0.5 -> H=1)."""
    field = np.random.randint(0, 2, (8, 8)).astype(np.float64)
    mask = np.zeros((8, 8), dtype=bool)
    h = mrf_conditional_entropy(field, mask, clique_radius=1)
    # With no sampled neighbors, p = alpha / (2*alpha) = 0.5, so H = 1.0
    assert np.allclose(h, 1.0, atol=1e-6), "No-sampled field should have max entropy"
    print("  [PASS] MRF entropy no-sampled (max uncertainty)")


if __name__ == '__main__':
    print("Running entropy tests...")
    test_binary_entropy_bounds()
    test_binary_entropy_maximum()
    test_binary_entropy_zeros()
    test_binary_entropy_symmetry()
    test_binary_entropy_array()
    test_entropy_map_shape()
    test_entropy_map_uniform()
    test_total_field_entropy()
    test_information_gain()
    test_resolvability_capacity()
    test_mrf_entropy()
    test_mrf_entropy_all_sampled()
    test_mrf_entropy_no_sampled()
    print("\nAll entropy tests passed!")

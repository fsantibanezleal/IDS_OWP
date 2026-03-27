"""
Integration tests for the OWP pipeline.

Tests the full workflow: generate -> sample -> reconstruct -> evaluate.
"""

import sys
import os
import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.simulation.field_generator import (
    generate_field,
    generate_training_image,
    generate_single_channel,
    generate_multi_channel,
    generate_branching_channels,
    generate_random_field,
)
from app.simulation.sampling import (
    random_uniform_sampling,
    stratified_sampling,
    adaptive_entropy_sampling,
    apply_sampling,
)
from app.simulation.inference import (
    nearest_neighbor_interpolation,
    indicator_kriging,
    entropy_weighted_interpolation,
    reconstruct,
)
from app.simulation.entropy import entropy_map, total_field_entropy, binary_entropy
from app.simulation.metrics import (
    snr_db,
    mse,
    classification_accuracy,
    spatial_coverage,
    pattern_preservation,
    compute_all_metrics,
)


def test_field_generators():
    """All field generators produce valid binary fields."""
    for ftype in ["single_channel", "multi_channel", "branching", "random"]:
        field = generate_field(ftype, shape=(32, 32), seed=42)
        assert field.shape == (32, 32), f"{ftype}: wrong shape"
        assert np.all((field == 0) | (field == 1)) or np.all(
            (field >= 0) & (field <= 1)
        ), f"{ftype}: values out of range"
        prop = np.mean(field)
        assert 0.05 < prop < 0.95, f"{ftype}: extreme proportion {prop}"
        print(f"  [PASS] generate_field('{ftype}') proportion={prop:.2f}")


def test_training_image():
    """Training image is larger and valid."""
    ti = generate_training_image("multi_channel", shape=(64, 64), seed=42)
    assert ti.shape == (64, 64)
    assert 0.05 < np.mean(ti) < 0.95
    print("  [PASS] generate_training_image")


def test_full_pipeline_nearest():
    """Full pipeline with random sampling + nearest neighbor."""
    field = generate_multi_channel((32, 32), num_channels=2, seed=42)
    positions = random_uniform_sampling((32, 32), 30, seed=42)
    sampled_field, sampled_mask = apply_sampling(field, positions)

    recon = nearest_neighbor_interpolation(sampled_field, sampled_mask)
    assert recon.shape == (32, 32)

    acc = classification_accuracy(field, recon)
    assert acc > 0.5, f"Accuracy should be > 50%, got {acc:.2%}"
    print(f"  [PASS] Pipeline (random + nearest): accuracy={acc:.2%}")


def test_full_pipeline_kriging():
    """Full pipeline with stratified sampling + kriging."""
    field = generate_multi_channel((32, 32), num_channels=2, seed=42)
    positions = stratified_sampling((32, 32), 25)
    sampled_field, sampled_mask = apply_sampling(field, positions)

    recon = indicator_kriging(sampled_field, sampled_mask, range_param=8.0)
    assert recon.shape == (32, 32)
    assert np.all((recon >= 0) & (recon <= 1)), "Kriging output should be in [0, 1]"

    acc = classification_accuracy(field, recon)
    assert acc > 0.4, f"Accuracy should be > 40%, got {acc:.2%}"
    print(f"  [PASS] Pipeline (stratified + kriging): accuracy={acc:.2%}")


def test_full_pipeline_entropy_weighted():
    """Full pipeline with entropy-weighted interpolation."""
    field = generate_multi_channel((32, 32), num_channels=2, seed=42)
    positions = random_uniform_sampling((32, 32), 30, seed=42)
    sampled_field, sampled_mask = apply_sampling(field, positions)

    # Compute entropy field
    p_prior = np.mean(field)
    prob = np.full((32, 32), p_prior)
    prob[sampled_mask] = sampled_field[sampled_mask]
    ent = entropy_map(prob)

    recon = entropy_weighted_interpolation(sampled_field, sampled_mask, ent)
    assert recon.shape == (32, 32)
    acc = classification_accuracy(field, recon)
    assert acc > 0.4, f"Accuracy should be > 40%, got {acc:.2%}"
    print(f"  [PASS] Pipeline (random + entropy_weighted): accuracy={acc:.2%}")


def test_metrics():
    """Metrics compute correctly."""
    field = generate_multi_channel((32, 32), num_channels=2, seed=42)

    # Perfect reconstruction
    snr_perfect = snr_db(field, field)
    assert snr_perfect == float("inf"), f"Perfect SNR should be inf, got {snr_perfect}"

    mse_perfect = mse(field, field)
    assert mse_perfect < 1e-15, f"Perfect MSE should be ~0, got {mse_perfect}"

    acc_perfect = classification_accuracy(field, field)
    assert acc_perfect == 1.0, f"Perfect accuracy should be 1.0, got {acc_perfect}"

    # Random reconstruction (should be worse)
    random_recon = np.random.RandomState(99).rand(32, 32)
    snr_random = snr_db(field, random_recon)
    assert snr_random < snr_perfect

    print("  [PASS] metrics correctness")


def test_spatial_coverage():
    """Coverage metric works correctly."""
    positions = np.array([[0, 0], [31, 31]])
    cov = spatial_coverage((32, 32), positions, max_distance=5.0)
    assert 0 < cov < 1, f"Coverage should be partial, got {cov}"

    # Full grid should give 100% coverage
    full_pos = np.array([[i, j] for i in range(32) for j in range(32)])
    cov_full = spatial_coverage((32, 32), full_pos, max_distance=1.0)
    assert cov_full == 1.0, f"Full coverage should be 1.0, got {cov_full}"
    print("  [PASS] spatial_coverage")


def test_adaptive_entropy_small():
    """Adaptive entropy sampling runs on a small field (smoke test)."""
    # Use very small field for speed
    field = generate_random_field((8, 8), proportion=0.3, correlation_length=3, seed=42)
    ti = generate_random_field((16, 16), proportion=0.3, correlation_length=3, seed=43)

    positions, entropy_history = adaptive_entropy_sampling(
        field, ti, num_samples=3, pattern_radius=2, seed=42
    )

    assert len(positions) == 3, f"Expected 3 positions, got {len(positions)}"
    assert len(entropy_history) == 3, f"Expected 3 entropy maps, got {len(entropy_history)}"

    # All positions unique
    unique = set(tuple(p) for p in positions)
    assert len(unique) == 3, "Adaptive positions must be unique"
    print("  [PASS] adaptive_entropy_sampling (small)")


def test_reconstruct_dispatch():
    """reconstruct() dispatches to correct method."""
    field = generate_multi_channel((16, 16), num_channels=1, seed=42)
    positions = random_uniform_sampling((16, 16), 10, seed=42)
    sampled_field, sampled_mask = apply_sampling(field, positions)

    for method in ["nearest", "kriging", "entropy_weighted"]:
        recon = reconstruct(sampled_field, sampled_mask, method=method)
        assert recon.shape == (16, 16), f"{method}: wrong shape"
        print(f"  [PASS] reconstruct(method='{method}')")


def test_compute_all_metrics():
    """compute_all_metrics returns expected keys."""
    field = generate_multi_channel((16, 16), num_channels=1, seed=42)
    positions = random_uniform_sampling((16, 16), 10, seed=42)
    sampled_field, sampled_mask = apply_sampling(field, positions)
    recon = reconstruct(sampled_field, sampled_mask, method="nearest")

    metrics = compute_all_metrics(field, recon, positions, 100.0, 50.0)

    expected_keys = ["snr_db", "mse", "accuracy", "coverage_5px",
                     "pattern_preservation", "resolvability"]
    for key in expected_keys:
        assert key in metrics, f"Missing metric: {key}"
    print("  [PASS] compute_all_metrics")


if __name__ == '__main__':
    print("Running integration tests...")
    test_field_generators()
    test_training_image()
    test_full_pipeline_nearest()
    test_full_pipeline_kriging()
    test_full_pipeline_entropy_weighted()
    test_metrics()
    test_spatial_coverage()
    test_adaptive_entropy_small()
    test_reconstruct_dispatch()
    test_compute_all_metrics()
    print("\nAll integration tests passed!")

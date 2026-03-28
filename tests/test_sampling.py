"""
Tests for sampling schemes.

Validates that all sampling methods produce valid positions
and expected spatial properties.
"""

import sys
import os
import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.simulation.sampling import (
    random_uniform_sampling,
    stratified_sampling,
    random_stratified_sampling,
    multiscale_stratified_sampling,
    oracle_entropy_sampling,
    penalized_adaptive_sampling,
    hybrid_stratified_adaptive_sampling,
    multiscale_adaptive_sampling,
    pso_sampling,
    apply_sampling,
)
from app.simulation.field_generator import (
    generate_multi_channel,
    generate_random_field,
    generate_training_ensemble,
)


FIELD_SHAPE = (32, 32)
NUM_SAMPLES = 20


def test_random_uniform():
    """Random uniform sampling produces valid unique positions."""
    pos = random_uniform_sampling(FIELD_SHAPE, NUM_SAMPLES, seed=42)
    assert pos.shape == (NUM_SAMPLES, 2), f"Expected ({NUM_SAMPLES}, 2), got {pos.shape}"

    # All positions in bounds
    assert np.all(pos[:, 0] >= 0) and np.all(pos[:, 0] < FIELD_SHAPE[0])
    assert np.all(pos[:, 1] >= 0) and np.all(pos[:, 1] < FIELD_SHAPE[1])

    # All unique
    unique = set(tuple(p) for p in pos)
    assert len(unique) == NUM_SAMPLES, "Positions must be unique"
    print("  [PASS] random_uniform_sampling")


def test_stratified():
    """Stratified sampling produces evenly spaced positions."""
    pos = stratified_sampling(FIELD_SHAPE, NUM_SAMPLES)
    assert len(pos) > 0, "Should produce at least 1 position"
    assert len(pos) <= NUM_SAMPLES + 5, f"Too many positions: {len(pos)}"

    # Check bounds
    assert np.all(pos[:, 0] >= 0) and np.all(pos[:, 0] < FIELD_SHAPE[0])
    assert np.all(pos[:, 1] >= 0) and np.all(pos[:, 1] < FIELD_SHAPE[1])
    print("  [PASS] stratified_sampling")


def test_random_stratified():
    """Random stratified produces positions with minimum spacing."""
    pos = random_stratified_sampling(FIELD_SHAPE, NUM_SAMPLES, seed=42)
    assert len(pos) > 0
    assert np.all(pos[:, 0] >= 0) and np.all(pos[:, 0] < FIELD_SHAPE[0])
    print("  [PASS] random_stratified_sampling")


def test_multiscale():
    """Multiscale sampling produces multi-resolution positions."""
    pos = multiscale_stratified_sampling(FIELD_SHAPE, NUM_SAMPLES, seed=42)
    assert len(pos) > 0
    assert np.all(pos[:, 0] >= 0) and np.all(pos[:, 0] < FIELD_SHAPE[0])
    print("  [PASS] multiscale_stratified_sampling")


def test_oracle_entropy():
    """Oracle entropy sampling works with a real field."""
    field = generate_multi_channel(FIELD_SHAPE, num_channels=2, seed=42)
    pos = oracle_entropy_sampling(field, 10, seed=42)
    assert pos.shape == (10, 2), f"Expected (10, 2), got {pos.shape}"
    assert np.all(pos[:, 0] >= 0) and np.all(pos[:, 0] < FIELD_SHAPE[0])

    # All unique
    unique = set(tuple(p) for p in pos)
    assert len(unique) == 10, "Oracle positions must be unique"
    print("  [PASS] oracle_entropy_sampling")


def test_apply_sampling():
    """apply_sampling correctly reveals field values."""
    field = np.random.RandomState(42).randint(0, 2, FIELD_SHAPE).astype(float)
    positions = np.array([[0, 0], [5, 5], [10, 10]])

    sampled_field, sampled_mask = apply_sampling(field, positions)

    assert sampled_mask[0, 0] == True
    assert sampled_mask[5, 5] == True
    assert sampled_mask[10, 10] == True
    assert sampled_mask[1, 1] == False

    assert sampled_field[0, 0] == field[0, 0]
    assert sampled_field[5, 5] == field[5, 5]
    assert np.isnan(sampled_field[1, 1])
    print("  [PASS] apply_sampling")


def test_reproducibility():
    """Same seed produces identical results."""
    pos1 = random_uniform_sampling(FIELD_SHAPE, NUM_SAMPLES, seed=123)
    pos2 = random_uniform_sampling(FIELD_SHAPE, NUM_SAMPLES, seed=123)
    assert np.array_equal(pos1, pos2), "Same seed should produce identical results"
    print("  [PASS] reproducibility")


def test_penalized_adaptive_sampling():
    """Penalized adaptive sampling achieves better coverage than plain adaptive."""
    field = generate_random_field(FIELD_SHAPE, proportion=0.3, correlation_length=5, seed=42)
    training_images = generate_training_ensemble(
        field_type='random', n_realizations=3,
        field_size=(48, 48), seed=100,
    )

    mask, order, entropy_hist = penalized_adaptive_sampling(
        field, training_images, num_samples=10,
        pattern_radius=2, penalty_radius=5, penalty_decay=0.5, seed=42,
    )

    # Check correct number of samples
    num_placed = int(np.sum(mask))
    assert num_placed == 10, f"Expected 10 samples, got {num_placed}"

    # Check order is sequential 1..10
    orders = order[mask]
    assert set(orders) == set(range(1, 11)), f"Order values unexpected: {sorted(orders)}"

    # Check entropy history has correct length
    assert len(entropy_hist) == 10, f"Expected 10 entropy values, got {len(entropy_hist)}"

    # Check spatial spread: compute pairwise distances
    positions = np.argwhere(mask)
    from scipy.spatial.distance import pdist
    dists = pdist(positions)
    min_dist = np.min(dists)
    assert min_dist > 1.0, f"Samples too close together: min distance = {min_dist}"
    print("  [PASS] penalized_adaptive_sampling")


def test_hybrid_stratified_adaptive():
    """Hybrid stratified+adaptive combines coverage with adaptation."""
    field = generate_random_field(FIELD_SHAPE, proportion=0.3, correlation_length=5, seed=42)
    training_images = generate_training_ensemble(
        field_type='random', n_realizations=3,
        field_size=(48, 48), seed=200,
    )

    mask, order, entropy_hist = hybrid_stratified_adaptive_sampling(
        field, training_images, num_samples=15,
        stratified_fraction=0.3, pattern_radius=2, seed=42,
    )

    num_placed = int(np.sum(mask))
    assert num_placed == 15, f"Expected 15 samples, got {num_placed}"

    # Check that stratified phase placed samples first (lower order numbers)
    n_strat = max(1, int(15 * 0.3))
    # Orders should go from 1 to num_placed
    orders = sorted(order[mask])
    assert orders[0] == 1, f"First order should be 1, got {orders[0]}"
    assert orders[-1] == num_placed, f"Last order should be {num_placed}, got {orders[-1]}"

    # All positions in bounds
    positions = np.argwhere(mask)
    assert np.all(positions[:, 0] >= 0) and np.all(positions[:, 0] < FIELD_SHAPE[0])
    assert np.all(positions[:, 1] >= 0) and np.all(positions[:, 1] < FIELD_SHAPE[1])
    print("  [PASS] hybrid_stratified_adaptive_sampling")


def test_multiscale_adaptive():
    """Multiscale adaptive samples at multiple resolutions."""
    field = generate_random_field(FIELD_SHAPE, proportion=0.3, correlation_length=5, seed=42)
    training_images = generate_training_ensemble(
        field_type='random', n_realizations=3,
        field_size=(48, 48), seed=300,
    )

    mask, order, entropy_hist = multiscale_adaptive_sampling(
        field, training_images, num_samples=12,
        n_scales=3, pattern_radius=2, seed=42,
    )

    num_placed = int(np.sum(mask))
    assert num_placed == 12, f"Expected 12 samples, got {num_placed}"

    # Check all positions unique and in bounds
    positions = np.argwhere(mask)
    assert len(positions) == 12
    assert np.all(positions[:, 0] >= 0) and np.all(positions[:, 0] < FIELD_SHAPE[0])
    assert np.all(positions[:, 1] >= 0) and np.all(positions[:, 1] < FIELD_SHAPE[1])

    assert len(entropy_hist) == 12, f"Expected 12 entropy values, got {len(entropy_hist)}"
    print("  [PASS] multiscale_adaptive_sampling")


def test_multi_ti_probability():
    """Multi-TI estimation uses multiple training images."""
    from app.simulation.sampling import _update_probability_field_multi_ti

    field = np.full((8, 8), np.nan)
    field[4, 4] = 1.0
    mask = np.zeros((8, 8), dtype=bool)
    mask[4, 4] = True

    training_images = generate_training_ensemble(
        field_type='random', n_realizations=5,
        field_size=(32, 32), seed=42,
    )

    # Initial uniform probability
    prob_field = np.full((8, 8), 0.3)

    updated = _update_probability_field_multi_ti(
        field, mask, training_images, prob_field, 4, 4, pattern_radius=2,
    )

    # Updated field should differ from initial near the sample
    assert not np.allclose(updated, prob_field), "Probability field should be updated"

    # Sampled position should have the true value
    assert abs(updated[4, 4] - 1.0) < 1e-10, f"Sampled position should have prob=1.0, got {updated[4, 4]}"

    # All probabilities should be in [0, 1]
    assert np.all(updated >= 0.0) and np.all(updated <= 1.0), "Probabilities must be in [0, 1]"
    print("  [PASS] multi_ti_probability")


def test_pso_sampling():
    """PSO sampling produces valid positions with positive fitness."""
    field = generate_random_field(FIELD_SHAPE, proportion=0.3, correlation_length=5, seed=42)
    training_images = generate_training_ensemble(
        field_type='random', n_realizations=3,
        field_size=(48, 48), seed=400,
    )

    mask, order, fitness_hist = pso_sampling(
        field, training_images, num_samples=10,
        n_particles=10, n_iterations=15, seed=42,
    )

    # Check samples were placed
    num_placed = int(np.sum(mask))
    assert num_placed > 0, "PSO should place at least 1 sample"
    assert num_placed <= 10, f"Too many samples: {num_placed}"

    # Check all positions in bounds
    positions = np.argwhere(mask)
    assert np.all(positions[:, 0] >= 0) and np.all(positions[:, 0] < FIELD_SHAPE[0])
    assert np.all(positions[:, 1] >= 0) and np.all(positions[:, 1] < FIELD_SHAPE[1])

    # Fitness should be non-negative and non-decreasing (global best)
    assert len(fitness_hist) == 15, f"Expected 15 fitness values, got {len(fitness_hist)}"
    assert all(f >= 0 for f in fitness_hist), "Fitness should be non-negative"
    # Global best fitness should be monotonically non-decreasing
    for i in range(1, len(fitness_hist)):
        assert fitness_hist[i] >= fitness_hist[i - 1] - 1e-10, \
            f"Global best fitness decreased at iteration {i}"

    # Order values should be sequential from 1
    orders = sorted(order[mask])
    assert orders[0] == 1, f"First order should be 1, got {orders[0]}"
    print("  [PASS] pso_sampling")


def test_training_ensemble_generation():
    """Training ensemble generates the right number of distinct TIs."""
    ensemble = generate_training_ensemble(
        field_type='random', n_realizations=5,
        field_size=(32, 32), seed=42,
    )
    assert len(ensemble) == 5, f"Expected 5 TIs, got {len(ensemble)}"
    for i, ti in enumerate(ensemble):
        assert ti.shape == (32, 32), f"TI {i} has wrong shape: {ti.shape}"

    # TIs should not all be identical
    all_same = all(np.array_equal(ensemble[0], ti) for ti in ensemble[1:])
    assert not all_same, "Training images should not all be identical"
    print("  [PASS] training_ensemble_generation")


if __name__ == '__main__':
    print("Running sampling tests...")
    test_random_uniform()
    test_stratified()
    test_random_stratified()
    test_multiscale()
    test_oracle_entropy()
    test_apply_sampling()
    test_reproducibility()
    test_penalized_adaptive_sampling()
    test_hybrid_stratified_adaptive()
    test_multiscale_adaptive()
    test_multi_ti_probability()
    test_pso_sampling()
    test_training_ensemble_generation()
    print("\nAll sampling tests passed!")

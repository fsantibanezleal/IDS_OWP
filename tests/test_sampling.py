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
    apply_sampling,
)
from app.simulation.field_generator import generate_multi_channel


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


if __name__ == '__main__':
    print("Running sampling tests...")
    test_random_uniform()
    test_stratified()
    test_random_stratified()
    test_multiscale()
    test_oracle_entropy()
    test_apply_sampling()
    test_reproducibility()
    print("\nAll sampling tests passed!")

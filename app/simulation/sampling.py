"""
Sampling Schemes for Optimal Well Placement.

===== SAMPLING STRATEGY OVERVIEW =====

The goal is to select K positions in an H x W grid to measure (drill wells),
maximizing the information gained about the entire field. Different sampling
strategies offer different trade-offs between:
    - Information efficiency (entropy reduction per sample)
    - Computational cost
    - Robustness to prior assumptions
    - Adaptivity (using previous measurements)

===== IMPLEMENTED SCHEMES =====

1. Random Uniform: Baseline. K positions drawn uniformly at random.
   - Complexity: O(K)
   - Expected entropy reduction: moderate
   - No spatial structure guarantees

2. Stratified (Deterministic Grid): Divides field into K strata and
   places one sample at the center of each stratum.
   - Complexity: O(K)
   - Guarantees uniform spatial coverage
   - Sub-optimal for non-stationary fields

3. Random Stratified: Divides field into K strata and places one
   sample randomly within each stratum.
   - Complexity: O(K)
   - Combines coverage with randomization
   - Better variance properties than pure random

4. Multiscale Stratified: Hierarchical sampling at multiple resolutions.
   First samples at coarse grid, then refines.
   - Complexity: O(K)
   - Captures both large and small scale features

5. Oracle Entropy: Uses the TRUE field to compute entropy and place
   samples where true uncertainty is highest. This is an upper bound
   on performance (not achievable in practice).
   - Complexity: O(K * H * W)
   - Requires ground truth (oracle)
   - Benchmark for other methods

6. Adaptive Entropy (AdSEMES): The main algorithm. Uses pattern
   matching against a training image to estimate conditional entropy,
   then greedily selects the maximum-entropy position.
   - Complexity: O(K * H * W * TI_H * TI_W)
   - Uses only training image (no ground truth)
   - Theoretically optimal (1-1/e approximation)

References:
    - Silva et al., Fondecyt 1140840
    - Nemhauser, Wolsey, Fisher (1978), submodular optimization
"""

import numpy as np
from typing import Tuple, List, Optional, Callable
from .entropy import (
    binary_entropy,
    entropy_map,
    conditional_entropy_estimate,
    total_field_entropy,
)


def random_uniform_sampling(
    field_shape: Tuple[int, int],
    num_samples: int,
    seed: Optional[int] = None,
) -> np.ndarray:
    """Random uniform sampling: select K positions uniformly at random.

    Each position in the field has equal probability of being selected.
    This is the simplest baseline strategy with no spatial structure.

    Properties:
        - Unbiased estimator of field statistics
        - No spatial coverage guarantee (may cluster)
        - O(K) complexity
        - Variance decreases as 1/K

    Args:
        field_shape: (H, W) dimensions of the field.
        num_samples: Number of positions to select (K).
        seed: Random seed for reproducibility.

    Returns:
        Array of shape (num_samples, 2) with (row, col) coordinates.
        Each row is a unique sample position.
    """
    rng = np.random.RandomState(seed)
    H, W = field_shape
    total = H * W

    if num_samples > total:
        num_samples = total

    # Sample without replacement from flattened indices
    indices = rng.choice(total, size=num_samples, replace=False)
    rows = indices // W
    cols = indices % W

    return np.column_stack([rows, cols])


def stratified_sampling(
    field_shape: Tuple[int, int],
    num_samples: int,
) -> np.ndarray:
    """Deterministic stratified (grid) sampling.

    Divides the field into approximately sqrt(K) x sqrt(K) strata
    and places one sample at the center of each stratum.

    This guarantees uniform spatial coverage. The actual number of
    samples may differ slightly from num_samples due to integer
    rounding of the grid.

    Properties:
        - Perfect spatial coverage
        - Deterministic (no randomness)
        - O(K) complexity
        - Suboptimal for anisotropic or non-stationary fields

    Args:
        field_shape: (H, W) dimensions of the field.
        num_samples: Approximate number of positions to select.

    Returns:
        Array of shape (K', 2) with (row, col) coordinates.
        K' may differ slightly from num_samples.
    """
    H, W = field_shape

    # Compute grid dimensions
    aspect = W / H
    n_rows = max(1, int(np.sqrt(num_samples / aspect)))
    n_cols = max(1, int(np.sqrt(num_samples * aspect)))

    # Adjust to get close to num_samples
    while n_rows * n_cols < num_samples and n_rows < H and n_cols < W:
        if n_rows <= n_cols:
            n_rows += 1
        else:
            n_cols += 1

    # Compute strata centers
    row_step = H / n_rows
    col_step = W / n_cols

    positions = []
    for i in range(n_rows):
        for j in range(n_cols):
            r = int(row_step * (i + 0.5))
            c = int(col_step * (j + 0.5))
            r = min(r, H - 1)
            c = min(c, W - 1)
            positions.append([r, c])

    return np.array(positions[:num_samples])


def random_stratified_sampling(
    field_shape: Tuple[int, int],
    num_samples: int,
    seed: Optional[int] = None,
) -> np.ndarray:
    """Random stratified sampling: one random sample per stratum.

    Like stratified_sampling, divides the field into strata, but places
    the sample at a random position within each stratum instead of the
    center. This combines spatial coverage with statistical randomization.

    Properties:
        - Guaranteed minimum spacing between samples
        - Randomization enables unbiased estimation
        - Lower variance than pure random sampling
        - O(K) complexity

    Args:
        field_shape: (H, W) dimensions of the field.
        num_samples: Approximate number of positions.
        seed: Random seed.

    Returns:
        Array of shape (K', 2) with (row, col) coordinates.
    """
    rng = np.random.RandomState(seed)
    H, W = field_shape

    aspect = W / H
    n_rows = max(1, int(np.sqrt(num_samples / aspect)))
    n_cols = max(1, int(np.sqrt(num_samples * aspect)))

    while n_rows * n_cols < num_samples and n_rows < H and n_cols < W:
        if n_rows <= n_cols:
            n_rows += 1
        else:
            n_cols += 1

    row_step = H / n_rows
    col_step = W / n_cols

    positions = []
    for i in range(n_rows):
        for j in range(n_cols):
            r_min = int(row_step * i)
            r_max = int(row_step * (i + 1)) - 1
            c_min = int(col_step * j)
            c_max = int(col_step * (j + 1)) - 1

            r = rng.randint(r_min, max(r_min + 1, r_max + 1))
            c = rng.randint(c_min, max(c_min + 1, c_max + 1))

            r = min(r, H - 1)
            c = min(c, W - 1)
            positions.append([r, c])

    return np.array(positions[:num_samples])


def multiscale_stratified_sampling(
    field_shape: Tuple[int, int],
    num_samples: int,
    num_levels: int = 3,
    seed: Optional[int] = None,
) -> np.ndarray:
    """Multiscale (hierarchical) stratified sampling.

    Distributes samples across multiple resolution levels:
    - Level 0 (coarsest): ~25% of samples on a coarse grid
    - Level 1: ~35% of samples on a medium grid
    - Level 2 (finest): ~40% of samples on a fine grid

    This captures both large-scale trends and local details.
    Samples at finer levels avoid positions already sampled at coarser levels.

    Properties:
        - Multi-resolution spatial coverage
        - Good for fields with features at multiple scales
        - O(K) complexity
        - Combines global and local information

    Args:
        field_shape: (H, W) dimensions of the field.
        num_samples: Total number of samples across all levels.
        num_levels: Number of resolution levels (default 3).
        seed: Random seed.

    Returns:
        Array of shape (K, 2) with (row, col) coordinates.
    """
    rng = np.random.RandomState(seed)
    H, W = field_shape

    # Allocate samples to levels (more at finer levels)
    weights = np.array([1.0 + i for i in range(num_levels)])
    weights /= weights.sum()
    counts = (weights * num_samples).astype(int)
    counts[-1] = num_samples - counts[:-1].sum()  # Fix rounding

    all_positions = set()
    positions_list: List[List[int]] = []

    for level in range(num_levels):
        k = int(counts[level])
        if k <= 0:
            continue

        # Generate stratified samples at this level
        level_positions = random_stratified_sampling(
            field_shape, k, seed=rng.randint(0, 2**31) if seed is not None else None
        )

        for pos in level_positions:
            key = (int(pos[0]), int(pos[1]))
            if key not in all_positions:
                all_positions.add(key)
                positions_list.append([key[0], key[1]])

    # If we have fewer than requested due to duplicates, add random
    if len(positions_list) < num_samples:
        remaining = num_samples - len(positions_list)
        extra = random_uniform_sampling(
            field_shape,
            remaining + 10,
            seed=rng.randint(0, 2**31) if seed is not None else None,
        )
        for pos in extra:
            if len(positions_list) >= num_samples:
                break
            key = (int(pos[0]), int(pos[1]))
            if key not in all_positions:
                all_positions.add(key)
                positions_list.append([key[0], key[1]])

    result = np.array(positions_list[:num_samples])
    return result


def oracle_entropy_sampling(
    true_field: np.ndarray,
    num_samples: int,
    seed: Optional[int] = None,
) -> np.ndarray:
    """Oracle entropy sampling using the TRUE field (upper bound benchmark).

    This method has access to the ground truth field and uses it to
    greedily select positions that maximize information gain. It serves
    as a theoretical upper bound on what any sampling strategy can achieve.

    NOT achievable in practice (requires knowing what you're trying to learn).

    Algorithm:
        1. Initialize probability field as marginal proportion.
        2. For k = 1, ..., K:
           a. Compute entropy map from current probability field.
           b. Select position with maximum entropy.
           c. Reveal true value at selected position.
           d. Update probability field in neighborhood.

    Properties:
        - Upper bound on sampling performance
        - Greedy with respect to true field entropy
        - O(K * H * W) complexity
        - Useful as a benchmark for comparing methods

    Args:
        true_field: The actual binary field (ground truth).
        num_samples: Number of positions to select.
        seed: Random seed (for tie-breaking).

    Returns:
        Array of shape (K, 2) with (row, col) coordinates in selection order.
    """
    rng = np.random.RandomState(seed)
    H, W = true_field.shape

    # Initialize: uniform probability at every position
    prob_field = np.full((H, W), np.mean(true_field))
    sampled_mask = np.zeros((H, W), dtype=bool)
    positions = []

    for _ in range(num_samples):
        # Compute entropy at each unsampled position
        ent = entropy_map(prob_field)
        ent[sampled_mask] = -1.0  # Exclude already sampled

        # Select maximum entropy position (break ties randomly)
        max_ent = np.max(ent)
        candidates = np.argwhere(np.abs(ent - max_ent) < 1e-10)
        idx = rng.randint(len(candidates))
        r, c = candidates[idx]

        positions.append([int(r), int(c)])
        sampled_mask[r, c] = True

        # Update probability field: simple neighborhood update
        # Reveal true value and update nearby probabilities
        true_val = true_field[r, c]
        prob_field[r, c] = true_val

        # Propagate information to neighbors (exponential decay)
        for di in range(-5, 6):
            for dj in range(-5, 6):
                ni, nj = r + di, c + dj
                if 0 <= ni < H and 0 <= nj < W and not sampled_mask[ni, nj]:
                    dist = np.sqrt(di**2 + dj**2)
                    weight = np.exp(-dist / 3.0)
                    # Bayesian-like update: blend prior toward observed value
                    prob_field[ni, nj] = (
                        (1 - weight) * prob_field[ni, nj] + weight * true_val
                    )

    return np.array(positions)


def adaptive_entropy_sampling(
    true_field: np.ndarray,
    training_image: np.ndarray,
    num_samples: int,
    pattern_radius: int = 3,
    callback: Optional[Callable] = None,
    seed: Optional[int] = None,
) -> Tuple[np.ndarray, List[np.ndarray]]:
    """Adaptive Sequential Empirical Maximum Entropy Sampling (AdSEMES).

    The main algorithm of the OWP framework. Uses pattern matching against
    a training image to estimate conditional entropy, then greedily selects
    the position with maximum estimated conditional entropy.

    ===== ALGORITHM (AdSEMES) =====

    Input: Training image TI, field dimensions (H,W), budget K, radius r
    Output: Ordered set of K measurement positions f* = {i*_1, ..., i*_K}

    1. Initialize:
       - field = empty (all NaN)
       - sampled_mask = all False
       - f* = {}

    2. For k = 1, 2, ..., K:
       a. Estimate conditional entropy at each unsampled position:
          H_est(i) = H_bin( P_TI(X_i=1 | known neighbors) )
          using pattern matching against TI.

       b. Select maximum-entropy position:
          i*_k = argmax_{i not in f*} H_est(i)

       c. Reveal true value:
          field[i*_k] = true_field[i*_k]
          sampled_mask[i*_k] = True
          f* = f* union {i*_k}

       d. (Optional) Record entropy map for visualization.

    3. Return f* and entropy history.

    ===== OPTIMALITY GUARANTEE =====

    Because entropy is a monotone submodular function, the greedy algorithm
    achieves at least (1 - 1/e) ≈ 63.2% of the optimal solution's
    information gain (Nemhauser, Wolsey, Fisher 1978).

    ===== COMPLEXITY =====

    O(K * U * TI_H * TI_W) where U = number of unsampled positions.
    For large fields and TIs, this can be expensive. The fast vectorized
    implementation in entropy.py mitigates the constant factor.

    Args:
        true_field: The actual binary field. Values are revealed upon
            sampling (simulating drilling a well and observing the facies).
        training_image: Binary training image for pattern statistics.
        num_samples: Number of samples (wells) to place (K).
        pattern_radius: Half-width of neighborhood pattern for matching.
            Larger = more context but slower and fewer matches.
        callback: Optional function called after each sample with
            (step, position, entropy_map) for real-time visualization.
        seed: Random seed for tie-breaking.

    Returns:
        Tuple of:
        - positions: Array of shape (K, 2) with selected positions in order.
        - entropy_history: List of K entropy maps (one per step).
    """
    rng = np.random.RandomState(seed)
    H, W = true_field.shape

    # Initialize field with NaN (unknown)
    field = np.full((H, W), np.nan)
    sampled_mask = np.zeros((H, W), dtype=bool)
    positions = []
    entropy_history = []

    for step in range(num_samples):
        # Step 2a: Estimate conditional entropy at all unsampled positions
        ent = conditional_entropy_estimate(
            field, sampled_mask, training_image, pattern_radius
        )
        entropy_history.append(ent.copy())

        # Step 2b: Select maximum-entropy unsampled position
        ent_masked = ent.copy()
        ent_masked[sampled_mask] = -1.0

        max_ent = np.max(ent_masked)
        if max_ent <= 0:
            break  # All positions resolved

        candidates = np.argwhere(np.abs(ent_masked - max_ent) < 1e-10)
        idx = rng.randint(len(candidates))
        r, c = int(candidates[idx, 0]), int(candidates[idx, 1])

        # Step 2c: Reveal true value (simulate drilling)
        positions.append([r, c])
        field[r, c] = true_field[r, c]
        sampled_mask[r, c] = True

        # Optional callback for real-time updates
        if callback is not None:
            callback(step, (r, c), ent)

    return np.array(positions), entropy_history


def apply_sampling(
    true_field: np.ndarray,
    positions: np.ndarray,
) -> Tuple[np.ndarray, np.ndarray]:
    """Apply sampling positions to a field and return observed values.

    Simulates "drilling" at the specified positions and observing
    the true field values there.

    Args:
        true_field: Binary field of shape (H, W).
        positions: Array of shape (K, 2) with (row, col) coordinates.

    Returns:
        Tuple of:
        - sampled_field: Field with observed values and NaN elsewhere.
        - sampled_mask: Boolean mask of sampled positions.
    """
    H, W = true_field.shape
    sampled_field = np.full((H, W), np.nan)
    sampled_mask = np.zeros((H, W), dtype=bool)

    for pos in positions:
        r, c = int(pos[0]), int(pos[1])
        if 0 <= r < H and 0 <= c < W:
            sampled_field[r, c] = true_field[r, c]
            sampled_mask[r, c] = True

    return sampled_field, sampled_mask

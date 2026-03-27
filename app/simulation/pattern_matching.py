"""
Training Image Pattern Statistics (TIPS) for OWP.

===== PATTERN STATISTICS FROM TRAINING IMAGES =====

In geostatistics, a Training Image (TI) is a conceptual representation
of the spatial patterns expected in the subsurface. It encodes prior
geological knowledge about facies geometry, connectivity, and proportions.

Pattern statistics are extracted by scanning the TI with a template
(sliding window) and recording:
    - The frequency of each observed pattern
    - The conditional probability of center pixel values given
      partial observations

For binary fields with template of size (2r+1) x (2r+1):
    Total possible patterns: 2^((2r+1)^2)
    Observed patterns: typically much fewer (TI is spatially structured)

The key operation is:
    P(X_center = 1 | known_neighbors) = count(matching, center=1) / count(matching)

This is used by the AdSEMES algorithm to estimate conditional entropy
at unsampled positions.

===== IMPLEMENTATION NOTES =====

For efficiency, patterns are hashed as binary strings. The known/unknown
mask determines which positions in the template must match and which are
ignored (wildcards).

References:
    - Strebelle (2002), Conditional simulation of complex geological
      structures using multiple-point statistics
    - Mariethoz & Caers (2015), Multiple-point Geostatistics
"""

import numpy as np
from typing import Dict, Tuple, Optional


def extract_all_patterns(
    training_image: np.ndarray,
    radius: int = 2,
) -> np.ndarray:
    """Extract all (2r+1)x(2r+1) patches from a training image.

    Slides a window of size (2r+1, 2r+1) over the training image
    and returns all extracted patches as a 3D array.

    Args:
        training_image: Binary 2D array, shape (TI_H, TI_W).
        radius: Half-width of the patch. Patch size = (2r+1, 2r+1).

    Returns:
        3D array of shape (N_patches, 2r+1, 2r+1) containing all
        extracted patches. N_patches = (TI_H - 2r) * (TI_W - 2r).
    """
    ti_h, ti_w = training_image.shape
    size = 2 * radius + 1

    if ti_h < size or ti_w < size:
        raise ValueError(
            f"Training image ({ti_h}x{ti_w}) too small for radius {radius}"
        )

    n_rows = ti_h - size + 1
    n_cols = ti_w - size + 1
    n_patches = n_rows * n_cols

    patches = np.zeros((n_patches, size, size), dtype=training_image.dtype)
    idx = 0
    for i in range(n_rows):
        for j in range(n_cols):
            patches[idx] = training_image[i : i + size, j : j + size]
            idx += 1

    return patches


def compute_conditional_probability(
    training_image: np.ndarray,
    pattern: np.ndarray,
    mask: np.ndarray,
    center_offset: Optional[Tuple[int, int]] = None,
) -> float:
    """Compute P(center=1 | known pattern) from a training image.

    Scans the training image for all patches where the known positions
    (indicated by mask) match the given pattern values. Returns the
    fraction of matching patches where the center pixel is 1.

    Args:
        training_image: Binary 2D array, shape (TI_H, TI_W).
        pattern: 2D array of known values at masked positions.
        mask: Boolean 2D array. True = position is known and must match.
        center_offset: (row, col) of the center pixel within the pattern.
            Defaults to the geometric center.

    Returns:
        Estimated P(center=1 | known neighbors) in [0, 1].
        Returns marginal P(X=1) if no matches found.
    """
    ph, pw = pattern.shape
    ti_h, ti_w = training_image.shape

    if center_offset is None:
        center_offset = (ph // 2, pw // 2)

    ci, cj = center_offset

    # Marginal fallback
    p_marginal = float(np.mean(training_image))

    if np.sum(mask) == 0:
        return p_marginal

    # Get known offsets and values
    known_positions = np.argwhere(mask)
    known_values = np.array([pattern[di, dj] for di, dj in known_positions])

    count_1 = 0
    count_0 = 0

    # Scan TI
    for i in range(ci, ti_h - (ph - ci - 1)):
        for j in range(cj, ti_w - (pw - cj - 1)):
            # Check all known positions
            match = True
            for k in range(len(known_positions)):
                di, dj = known_positions[k]
                ti_val = training_image[i - ci + di, j - cj + dj]
                if abs(ti_val - known_values[k]) > 0.5:
                    match = False
                    break

            if match:
                if training_image[i, j] > 0.5:
                    count_1 += 1
                else:
                    count_0 += 1

    total = count_1 + count_0
    if total > 0:
        return count_1 / total
    else:
        return p_marginal


def compute_conditional_probability_fast(
    training_image: np.ndarray,
    pattern: np.ndarray,
    mask: np.ndarray,
    center_offset: Optional[Tuple[int, int]] = None,
) -> float:
    """Fast vectorized version of conditional probability computation.

    Uses numpy broadcasting to check all TI patches simultaneously.

    Args:
        training_image: Binary 2D array.
        pattern: 2D array of known values at masked positions.
        mask: Boolean 2D array indicating known positions.
        center_offset: (row, col) of center pixel within pattern.

    Returns:
        P(center=1 | known neighbors) in [0, 1].
    """
    ph, pw = pattern.shape
    ti_h, ti_w = training_image.shape

    if center_offset is None:
        center_offset = (ph // 2, pw // 2)

    ci, cj = center_offset
    p_marginal = float(np.mean(training_image))

    if np.sum(mask) == 0:
        return p_marginal

    known_positions = np.argwhere(mask)
    known_values = np.array([pattern[di, dj] for di, dj in known_positions])

    # Valid center positions
    row_start = ci
    row_end = ti_h - (ph - ci - 1)
    col_start = cj
    col_end = ti_w - (pw - cj - 1)

    if row_end <= row_start or col_end <= col_start:
        return p_marginal

    n_rows = row_end - row_start
    n_cols = col_end - col_start

    # Start with all positions matching
    all_match = np.ones((n_rows, n_cols), dtype=bool)

    for k in range(len(known_positions)):
        di, dj = known_positions[k]
        val = known_values[k]

        r_s = row_start - ci + di
        c_s = col_start - cj + dj

        ti_slice = training_image[r_s : r_s + n_rows, c_s : c_s + n_cols]

        if val > 0.5:
            all_match &= ti_slice > 0.5
        else:
            all_match &= ti_slice <= 0.5

    # Center values
    center_vals = training_image[row_start:row_end, col_start:col_end]

    count_1 = int(np.sum(all_match & (center_vals > 0.5)))
    count_0 = int(np.sum(all_match & (center_vals <= 0.5)))

    total = count_1 + count_0
    if total > 0:
        return count_1 / total
    else:
        return p_marginal


def pattern_frequency_map(
    training_image: np.ndarray,
    radius: int = 2,
) -> Dict[str, int]:
    """Compute frequency of each unique pattern in the training image.

    Patterns are hashed as binary strings for dictionary keys.
    This provides insight into the diversity and redundancy of the TI.

    Args:
        training_image: Binary 2D array.
        radius: Half-width of patterns.

    Returns:
        Dictionary mapping pattern hash strings to occurrence counts.
    """
    patches = extract_all_patterns(training_image, radius)
    freq: Dict[str, int] = {}

    for idx in range(patches.shape[0]):
        # Hash pattern as binary string
        key = "".join(str(int(v > 0.5)) for v in patches[idx].ravel())
        freq[key] = freq.get(key, 0) + 1

    return freq

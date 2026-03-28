"""
Shannon Entropy Computation for Optimal Well Placement.

===== INFORMATION-THEORETIC FRAMEWORK =====

The OWP problem is formulated as an information-theoretic
sensing design problem. Given a 2D random field X = {X_ij}
with spatial dependence, we seek K measurement locations
that minimize posterior uncertainty.

Shannon entropy of a discrete random variable:
    H(X) = -sum P(x) * log2(P(x))

Binary entropy (special case for Bernoulli r.v.):
    H_bin(p) = -p*log2(p) - (1-p)*log2(1-p)

For a collection of binary random variables forming a random field,
the joint entropy decomposes as:
    H(X) = sum_{i=1}^{N} H(X_i | X_1, ..., X_{i-1})

Conditional entropy (posterior uncertainty after measuring X_f):
    H(X^f | X_f) = H(X) - H(X_f)

where X_f are measured variables and X^f are unmeasured.

===== OWP OPTIMIZATION =====

Optimal placement rule:
    f* = argmax_{f in F_K} H(X_f)

This is equivalent to:
    1. Minimize posterior uncertainty:    min H(X^f | X_f)
    2. Maximize information gain:         max I(X_f; X^f)
    3. Maximize a-priori entropy of measurements: max H(X_f)

The equivalence (1)-(3) holds because H(X) is a constant for a
given field, so maximizing H(X_f) is equivalent to minimizing
H(X) - H(X_f) = H(X^f | X_f).

Greedy iterative solution (AdSEMES):
    For k = 1, ..., K:
        i*_k = argmax_{i in free} H(X_i | X_{i*_1}, ..., X_{i*_{k-1}})

This greedy approach yields a (1 - 1/e) approximation to the
optimal solution because entropy is a monotone submodular function
(Nemhauser, Wolsey, Fisher 1978).

===== RESOLVABILITY CAPACITY =====

    C_k = I(f*_k) / H(X) in [0, 1]

Measures how quickly uncertainty is resolved with k measurements.
    C_k monotonically increasing: C_{k+1} >= C_k
    C_N = 1 (complete resolution with all positions measured)

References:
    - Shannon (1948), A Mathematical Theory of Communication
    - Cover & Thomas (2006), Elements of Information Theory
    - Silva et al. (IDS Group, U. Chile), Fondecyt 1140840
    - Nemhauser, Wolsey, Fisher (1978), An analysis of approximations
      for maximizing submodular set functions
"""

import numpy as np
from typing import Optional


def binary_entropy(p: np.ndarray) -> np.ndarray:
    """Compute binary Shannon entropy H(p) = -p*log2(p) - (1-p)*log2(1-p).

    The binary entropy function is the entropy of a Bernoulli random variable
    with parameter p. It reaches its maximum of 1 bit at p=0.5 (maximum
    uncertainty) and its minimum of 0 bits at p=0 or p=1 (certainty).

    Implementation uses clipping to avoid log(0) = -inf. Values of p
    very close to 0 or 1 are clipped to [1e-15, 1-1e-15], producing
    negligible numerical error (< 1e-13 bits).

    Args:
        p: Probability values in [0, 1]. Can be scalar, 1D, or 2D array.
            Values outside [0,1] will be clipped.

    Returns:
        Entropy values in [0, 1] (bits). Same shape as input.
        Maximum of 1.0 at p=0.5, minimum of 0.0 at p=0 or p=1.

    Examples:
        >>> binary_entropy(0.5)
        1.0
        >>> binary_entropy(np.array([0.0, 0.5, 1.0]))
        array([0., 1., 0.])
    """
    p = np.asarray(p, dtype=np.float64)
    # Clip to avoid log(0); this introduces negligible error
    p = np.clip(p, 1e-15, 1.0 - 1e-15)
    return -(p * np.log2(p) + (1.0 - p) * np.log2(1.0 - p))


def entropy_map(probability_field: np.ndarray) -> np.ndarray:
    """Compute pixelwise binary entropy of a probability field.

    Each pixel (i,j) in the input represents P(X_ij = 1), the marginal
    probability that the random variable at position (i,j) takes value 1.
    The output is the binary entropy H(X_ij) at each position.

    For a uniform prior (all p=0.5), the entropy map is uniformly 1.0.
    After conditioning on observations, positions near known values
    will have lower entropy (more certainty).

    Args:
        probability_field: 2D array of shape (H, W) with P(X_ij = 1) values.
            All values should be in [0, 1].

    Returns:
        2D array of shape (H, W) with H(X_ij) values in bits [0, 1].
    """
    return binary_entropy(probability_field)


def total_field_entropy(probability_field: np.ndarray) -> float:
    """Compute total entropy of a probability field (sum of pixelwise entropies).

    This is an upper bound on the true joint entropy H(X) since it assumes
    independence: H(X) <= sum H(X_ij). For spatially correlated fields,
    the true joint entropy is lower due to redundancy between neighboring
    pixels.

    Args:
        probability_field: 2D array of P(X_ij = 1) values.

    Returns:
        Total entropy in bits (sum of all pixelwise entropies).
    """
    return float(np.sum(binary_entropy(probability_field)))


def conditional_entropy_estimate(
    field: np.ndarray,
    sampled_mask: np.ndarray,
    training_image: np.ndarray,
    pattern_radius: int = 5,
) -> np.ndarray:
    """Estimate conditional entropy at each unsampled position.

    Uses pattern matching against a training image to estimate
    P(X_i = 1 | neighborhood pattern), then computes binary entropy.

    This implements the core of the AdSEMES algorithm: for each unsampled
    position, we look at the known values in its neighborhood, find all
    matching patterns in the training image, and estimate the conditional
    probability of the center pixel being 1.

    Two implementations are provided:
    - Fast vectorized version (default): uses numpy broadcasting for the
      inner pattern-matching loop. Complexity: O(H*W * TI_H*TI_W) but
      with vectorized inner operations.
    - Slow reference version: pure Python loops, used as fallback when
      the vectorized version encounters issues.

    Args:
        field: Current field state, shape (H, W). Binary values (0/1) at
            sampled positions, arbitrary values (e.g. NaN) elsewhere.
        sampled_mask: Boolean mask of shape (H, W). True where field has
            been sampled (value is known).
        training_image: Binary training image of shape (TI_H, TI_W), used
            for pattern statistics. Should represent the same geological
            facies type as the true field.
        pattern_radius: Half-width of the neighborhood pattern used for
            matching. A radius of r means a (2r+1) x (2r+1) patch.
            Larger radius = more context but fewer matches.
            Default: 5 (11x11 patches).

    Returns:
        2D array of shape (H, W) with estimated conditional entropy at
        each position. Sampled positions have entropy = 0.
    """
    try:
        return _conditional_entropy_fast(
            field, sampled_mask, training_image, pattern_radius
        )
    except Exception:
        # Fallback to slow but reliable version
        return _conditional_entropy_slow(
            field, sampled_mask, training_image, pattern_radius
        )


def _conditional_entropy_fast(
    field: np.ndarray,
    sampled_mask: np.ndarray,
    training_image: np.ndarray,
    pattern_radius: int,
) -> np.ndarray:
    """Fast vectorized conditional entropy estimation.

    For each unsampled position (i,j), this function:
    1. Extracts the local neighborhood of known values.
    2. Slides over the training image to count how many TI patches
       match the known pattern, and what fraction have center=1.
    3. Uses that fraction as P(X_ij=1 | neighbors) and computes H.

    The vectorization is done at the TI scanning level: for a given
    field position, we extract all possible TI patches at once using
    stride tricks, then check matches via broadcasting.

    Complexity: O(U * TI_H * TI_W) where U = number of unsampled positions.
    Each TI scan is vectorized so the constant factor is small.
    """
    H, W = field.shape
    ti_h, ti_w = training_image.shape
    r = pattern_radius

    entropy_field = np.zeros((H, W), dtype=np.float64)

    # Marginal probability from TI (fallback when few neighbors)
    p_marginal = float(np.mean(training_image))

    # Get unsampled positions
    unsampled = np.argwhere(~sampled_mask)

    for pos_idx in range(len(unsampled)):
        i, j = unsampled[pos_idx]

        # Define local patch bounds (clipped to field boundaries)
        i_start = max(0, i - r)
        i_end = min(H, i + r + 1)
        j_start = max(0, j - r)
        j_end = min(W, j + r + 1)

        local_mask = sampled_mask[i_start:i_end, j_start:j_end]
        local_vals = field[i_start:i_end, j_start:j_end]

        num_known = int(np.sum(local_mask))

        if num_known < 2:
            # Too few neighbors: use marginal probability from TI
            entropy_field[i, j] = float(binary_entropy(p_marginal))
            continue

        # Position of center pixel within the local patch
        pi = i - i_start
        pj = j - j_start
        ph, pw = local_mask.shape

        # Scan training image: extract all valid patches of size (ph, pw)
        # The center of each patch in TI corresponds to TI[ti_row, ti_col]
        # where ti_row ranges from pi to ti_h - (ph - pi - 1)
        # and ti_col ranges from pj to ti_w - (pw - pj - 1)
        ti_row_start = pi
        ti_row_end = ti_h - (ph - pi - 1)
        ti_col_start = pj
        ti_col_end = ti_w - (pw - pj - 1)

        if ti_row_end <= ti_row_start or ti_col_end <= ti_col_start:
            entropy_field[i, j] = float(binary_entropy(p_marginal))
            continue

        # For each known position in the local mask, check TI values
        # known_offsets: list of (di, dj) relative to patch origin
        known_offsets = np.argwhere(local_mask)  # shape (num_known, 2)
        known_values = local_vals[local_mask]  # shape (num_known,)

        # Build a match accumulator
        match_1 = 0
        match_0 = 0

        # Process in row batches to limit memory usage
        batch_size = min(64, ti_row_end - ti_row_start)
        for ti_row_batch_start in range(ti_row_start, ti_row_end, batch_size):
            ti_row_batch_end = min(ti_row_batch_start + batch_size, ti_row_end)
            n_rows = ti_row_batch_end - ti_row_batch_start
            n_cols = ti_col_end - ti_col_start

            # Check all known offsets against TI
            all_match = np.ones((n_rows, n_cols), dtype=bool)

            for k_idx in range(num_known):
                di, dj = known_offsets[k_idx]
                val = known_values[k_idx]

                # TI values at offset (di, dj) for all patch positions in batch
                row_slice_start = ti_row_batch_start - pi + di
                row_slice_end = row_slice_start + n_rows
                col_slice_start = ti_col_start - pj + dj
                col_slice_end = col_slice_start + n_cols

                ti_slice = training_image[
                    row_slice_start:row_slice_end,
                    col_slice_start:col_slice_end,
                ]

                # Check where TI matches the known value
                if val > 0.5:
                    all_match &= ti_slice > 0.5
                else:
                    all_match &= ti_slice <= 0.5

            # Center pixel values for matching patches
            center_row_start = ti_row_batch_start
            center_row_end = ti_row_batch_end
            center_col_start = ti_col_start
            center_col_end = ti_col_end

            center_vals = training_image[
                center_row_start:center_row_end,
                center_col_start:center_col_end,
            ]

            match_1 += int(np.sum(all_match & (center_vals > 0.5)))
            match_0 += int(np.sum(all_match & (center_vals <= 0.5)))

        total = match_1 + match_0
        if total > 0:
            p1 = match_1 / total
        else:
            p1 = p_marginal

        entropy_field[i, j] = float(binary_entropy(p1))

    return entropy_field


def _conditional_entropy_slow(
    field: np.ndarray,
    sampled_mask: np.ndarray,
    training_image: np.ndarray,
    pattern_radius: int,
) -> np.ndarray:
    """Slow pure-Python reference implementation of conditional entropy estimation.

    This is the straightforward O(H*W * TI_H*TI_W * patch_size) implementation
    with explicit nested loops. Used as a fallback if the fast version fails.

    The algorithm for each unsampled position (i,j):
    1. Extract the local neighborhood mask and values.
    2. For each possible center position in the training image:
       a. Extract the corresponding TI patch.
       b. Check if all known positions in the local mask match.
       c. If yes, record the TI center value (0 or 1).
    3. Compute P(center=1) = count_1 / (count_1 + count_0).
    4. Compute H = binary_entropy(P(center=1)).
    """
    H, W = field.shape
    ti_h, ti_w = training_image.shape
    r = pattern_radius

    entropy_field = np.zeros((H, W), dtype=np.float64)
    p_marginal = float(np.mean(training_image))

    for i in range(H):
        for j in range(W):
            if sampled_mask[i, j]:
                entropy_field[i, j] = 0.0  # Known position: zero entropy
                continue

            # Extract neighborhood pattern
            i_start = max(0, i - r)
            i_end = min(H, i + r + 1)
            j_start = max(0, j - r)
            j_end = min(W, j + r + 1)

            local_mask = sampled_mask[i_start:i_end, j_start:j_end]
            local_vals = field[i_start:i_end, j_start:j_end]

            num_known = int(np.sum(local_mask))

            if num_known < 2:
                # Too few neighbors: use marginal probability
                entropy_field[i, j] = float(binary_entropy(p_marginal))
                continue

            # Position of center in local patch
            pi = i - i_start
            pj = j - j_start
            ph, pw = local_mask.shape

            # Pattern matching in training image
            match_count_1 = 0
            match_count_0 = 0

            for ti_i in range(r, ti_h - r):
                for ti_j in range(r, ti_w - r):
                    # Extract TI patch aligned so center is at (ti_i, ti_j)
                    ti_patch = training_image[
                        ti_i - pi : ti_i - pi + ph,
                        ti_j - pj : ti_j - pj + pw,
                    ]
                    if ti_patch.shape != local_mask.shape:
                        continue

                    # Check if known positions match
                    matches = True
                    for di in range(ph):
                        for dj in range(pw):
                            if local_mask[di, dj]:
                                if abs(ti_patch[di, dj] - local_vals[di, dj]) > 0.5:
                                    matches = False
                                    break
                        if not matches:
                            break

                    if matches:
                        center_val = training_image[ti_i, ti_j]
                        if center_val > 0.5:
                            match_count_1 += 1
                        else:
                            match_count_0 += 1

            total = match_count_1 + match_count_0
            if total > 0:
                p1 = match_count_1 / total
            else:
                p1 = p_marginal

            entropy_field[i, j] = float(binary_entropy(p1))

    return entropy_field


def mrf_conditional_entropy(
    field: np.ndarray,
    sampled_mask: np.ndarray,
    clique_radius: int = 1,
    kernel: str = 'uniform',
    gaussian_sigma: float = 1.0,
) -> np.ndarray:
    """Estimate conditional entropy using Markov Random Field cliques.

    ===== MRF ENTROPY MODEL =====

    Instead of computing P(X_i) from marginal statistics, uses
    local neighborhood cliques to estimate P(X_i | neighbors):

        H_MRF(X_i | sampled) = -sum_x P(X_i=x|clique) * log2(P(X_i=x|clique))

    where the clique is the set of sampled neighbors within radius R
    of position i. This captures spatial correlations that marginal
    entropy misses.

    For a binary field, the clique potential is:
        P(X_i=1 | clique) = count(neighbors=1) / count(neighbors)

    With Laplace smoothing to avoid zero probabilities:
        P(X_i=1 | clique) = (count(1) + alpha) / (count + 2*alpha)

    Implementation is fully vectorized using scipy.ndimage filters
    to compute neighborhood sums via convolution, achieving O(H*W) complexity
    independent of clique radius (no Python loops over pixels).

    Args:
        field: Current field state, shape (H, W). Binary values (0/1) at
            sampled positions, arbitrary values elsewhere.
        sampled_mask: Boolean mask of shape (H, W). True where field has
            been sampled (value is known).
        clique_radius: Half-width of the neighborhood clique. A radius of r
            means a (2r+1) x (2r+1) neighborhood. Default: 1 (3x3).
        kernel: 'uniform' (equal weights) or 'gaussian' (distance-dependent).
        gaussian_sigma: Sigma for Gaussian kernel in pixels. Only used when
            kernel='gaussian'. Default: 1.0.

    Returns:
        2D array of shape (H, W) with estimated conditional entropy at
        each position. Sampled positions have entropy = 0.
    """
    from scipy.ndimage import uniform_filter, gaussian_filter

    H, W = field.shape
    size = 2 * clique_radius + 1
    alpha = 0.5  # Laplace smoothing parameter

    # Count sampled neighbors and their sum using convolution
    sampled_float = sampled_mask.astype(np.float64)
    sampled_values = (field * sampled_mask).astype(np.float64)

    if kernel == 'gaussian':
        # Gaussian kernel: distance-dependent weighting of neighbors
        n_sampled = gaussian_filter(sampled_float, sigma=gaussian_sigma, mode='constant')
        n_ones = gaussian_filter(sampled_values, sigma=gaussian_sigma, mode='constant')
    else:
        # uniform_filter computes local mean; multiply by area to get local sum
        area = size ** 2
        n_sampled = uniform_filter(sampled_float, size=size, mode='constant') * area
        n_ones = uniform_filter(sampled_values, size=size, mode='constant') * area

    # Laplace-smoothed probability estimate
    p = (n_ones + alpha) / (n_sampled + 2 * alpha)
    p = np.clip(p, 1e-10, 1 - 1e-10)

    # Binary entropy: H(p) = -p*log2(p) - (1-p)*log2(1-p)
    entropy_map_result = -p * np.log2(p) - (1 - p) * np.log2(1 - p)

    # Known positions have zero entropy (no uncertainty)
    entropy_map_result[sampled_mask] = 0.0

    return entropy_map_result


def information_gain(
    entropy_before: np.ndarray, entropy_after: np.ndarray
) -> float:
    """Compute information gain from a sampling step.

    I = H_before - H_after = sum of entropy reduction across all positions.

    This measures how much uncertainty was reduced by the new observation(s).

    Args:
        entropy_before: Entropy map before sampling step.
        entropy_after: Entropy map after sampling step.

    Returns:
        Total information gain in bits (non-negative).
    """
    gain = float(np.sum(entropy_before) - np.sum(entropy_after))
    return max(0.0, gain)  # Should be non-negative by definition


def resolvability_capacity(
    initial_entropy: float,
    current_entropy: float,
) -> float:
    """Compute resolvability capacity C_k.

    C_k = I(f*_k) / H(X) = (H_initial - H_current) / H_initial

    This normalized measure indicates what fraction of the total field
    uncertainty has been resolved by the current set of measurements.

    Properties:
        - C_k in [0, 1]
        - C_0 = 0 (no measurements)
        - C_k is monotonically non-decreasing
        - C_N = 1 (all positions measured)

    Args:
        initial_entropy: Total entropy before any measurements H(X).
        current_entropy: Total entropy after k measurements.

    Returns:
        Resolvability capacity in [0, 1].
    """
    if initial_entropy <= 0:
        return 1.0
    ck = (initial_entropy - current_entropy) / initial_entropy
    return float(np.clip(ck, 0.0, 1.0))

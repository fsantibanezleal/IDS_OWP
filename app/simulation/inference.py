"""
Reconstruction (Inference) from Sparse Samples for OWP.

===== RECONSTRUCTION PROBLEM =====

Given K observed values at positions f = {(r_1,c_1), ..., (r_K,c_K)},
reconstruct the full H x W field. This is an under-determined inverse
problem when K << H*W.

The quality of reconstruction depends on:
    1. The sampling strategy (positions selected)
    2. The reconstruction method (interpolation/estimation)
    3. The spatial structure of the true field

===== IMPLEMENTED METHODS =====

1. Nearest-Neighbor Interpolation:
   Each unsampled position takes the value of its nearest sampled neighbor.
   - Simple and fast: O(H*W*K)
   - Produces blocky, Voronoi-like reconstructions
   - No smoothness assumption

2. Indicator Kriging (Simple Kriging for binary fields):
   Estimates P(X_i = 1) using a weighted linear combination of nearby
   observations, with weights determined by a variogram model.
   - Optimal for stationary Gaussian-like fields
   - O(H*W*K^2) for K neighbors
   - Produces smooth probability fields

3. Entropy-Weighted Interpolation:
   Inverse-distance weighting where weights are modulated by the
   estimated conditional entropy. Higher-entropy positions get less
   influence (less certain).
   - Heuristic approach
   - O(H*W*K) complexity
   - Accounts for local uncertainty

References:
    - Goovaerts (1997), Geostatistics for Natural Resources Evaluation
    - Chilès & Delfiner (2012), Geostatistics: Modeling Spatial Uncertainty
"""

import numpy as np
from typing import Tuple, Optional
from scipy.spatial import cKDTree


def nearest_neighbor_interpolation(
    sampled_field: np.ndarray,
    sampled_mask: np.ndarray,
) -> np.ndarray:
    """Reconstruct field using nearest-neighbor interpolation.

    Each unsampled position is assigned the value of the closest
    sampled position (Euclidean distance). This produces a Voronoi
    tessellation of the sampled values.

    Properties:
        - No smoothing or averaging
        - Preserves original sample values exactly
        - Discontinuous boundaries between regions
        - Fast: O(H*W * log(K)) using KD-tree

    Args:
        sampled_field: Field with known values and NaN elsewhere.
        sampled_mask: Boolean mask of sampled positions.

    Returns:
        Reconstructed binary field of same shape.
    """
    H, W = sampled_field.shape

    # Get sampled positions and values
    sampled_positions = np.argwhere(sampled_mask)
    if len(sampled_positions) == 0:
        # No samples: return uniform 0.5 (maximum uncertainty)
        return np.full((H, W), 0.5)

    sampled_values = sampled_field[sampled_mask]

    # Build KD-tree for efficient nearest-neighbor queries
    tree = cKDTree(sampled_positions)

    # Query all positions
    all_positions = np.array([[i, j] for i in range(H) for j in range(W)])
    _, nearest_idx = tree.query(all_positions)

    reconstructed = sampled_values[nearest_idx].reshape(H, W)
    return reconstructed


def indicator_kriging(
    sampled_field: np.ndarray,
    sampled_mask: np.ndarray,
    range_param: float = 10.0,
    sill: float = 0.25,
    nugget: float = 0.01,
    max_neighbors: int = 12,
) -> np.ndarray:
    """Reconstruct field using simple indicator kriging.

    Indicator kriging treats binary values as indicators I(x) = {0, 1}
    and estimates P(X_i = 1) as a linear combination of nearby observations
    with weights determined by the variogram (spatial covariance model).

    The variogram model used is exponential:
        gamma(h) = nugget + sill * (1 - exp(-3*h / range))

    The covariance is:
        C(h) = (sill + nugget) - gamma(h) = sill * exp(-3*h/range)
               (for h > 0; C(0) = sill + nugget)

    Kriging weights are obtained by solving the kriging system:
        C * w = c
    where C is the covariance matrix between sampled points and
    c is the covariance vector between sampled points and target.

    Properties:
        - BLUE (Best Linear Unbiased Estimator) for the covariance model
        - Produces smooth probability fields
        - Computational cost: O(H*W * K_nn^3) for K_nn neighbors
        - May produce values outside [0,1], which are clipped

    Args:
        sampled_field: Field with observed values and NaN elsewhere.
        sampled_mask: Boolean mask of sampled positions.
        range_param: Range of the exponential variogram (correlation length).
        sill: Sill of the variogram (variance of the field).
        nugget: Nugget effect (measurement noise / micro-scale variability).
        max_neighbors: Maximum number of neighbors used for each estimate.

    Returns:
        Probability field of shape (H, W) with P(X=1) estimates in [0, 1].
    """
    H, W = sampled_field.shape

    sampled_positions = np.argwhere(sampled_mask)
    n_sampled = len(sampled_positions)

    if n_sampled == 0:
        return np.full((H, W), 0.5)

    sampled_values = sampled_field[sampled_mask]
    mean_val = np.mean(sampled_values)

    # Covariance function (exponential model)
    def covariance(h):
        """Exponential covariance: C(h) = sill * exp(-3h/range)."""
        return sill * np.exp(-3.0 * h / range_param)

    # Build KD-tree for neighbor search
    tree = cKDTree(sampled_positions)

    result = np.full((H, W), np.nan)

    # Fill in sampled positions with their known values
    result[sampled_mask] = sampled_values

    # Estimate each unsampled position
    unsampled = np.argwhere(~sampled_mask)

    for pos in unsampled:
        i, j = pos

        # Find nearest neighbors
        k_nn = min(max_neighbors, n_sampled)
        distances, indices = tree.query([i, j], k=k_nn)

        if k_nn == 1:
            distances = np.array([distances])
            indices = np.array([indices])

        # Build kriging system
        # C_matrix: covariance between neighbors
        neighbor_positions = sampled_positions[indices]
        neighbor_values = sampled_values[indices]

        C_matrix = np.zeros((k_nn, k_nn))
        for a in range(k_nn):
            for b in range(k_nn):
                h = np.linalg.norm(
                    neighbor_positions[a] - neighbor_positions[b]
                )
                C_matrix[a, b] = covariance(h)
            # Add nugget on diagonal
            C_matrix[a, a] += nugget

        # c_vector: covariance between target and neighbors
        c_vector = np.array([covariance(d) for d in distances])

        # Solve kriging system: C * w = c
        try:
            weights = np.linalg.solve(C_matrix, c_vector)
        except np.linalg.LinAlgError:
            # Singular matrix: fall back to inverse-distance weighting
            if np.all(distances > 0):
                weights = 1.0 / distances
                weights /= weights.sum()
            else:
                weights = np.zeros(k_nn)
                weights[0] = 1.0

        # Simple kriging estimate
        residuals = neighbor_values - mean_val
        estimate = mean_val + np.dot(weights, residuals)

        # Clip to [0, 1] since this is a probability
        result[i, j] = np.clip(estimate, 0.0, 1.0)

    return result


def entropy_weighted_interpolation(
    sampled_field: np.ndarray,
    sampled_mask: np.ndarray,
    entropy_field: Optional[np.ndarray] = None,
    power: float = 2.0,
) -> np.ndarray:
    """Reconstruct field using entropy-weighted inverse-distance interpolation.

    A heuristic method that combines inverse-distance weighting (IDW)
    with entropy-based modulation. Nearby samples with lower local entropy
    (higher certainty) receive more weight.

    The weight for sample j when estimating position i is:
        w_ij = (1 / d_ij^p) * (1 - H_j / H_max + epsilon)

    where d_ij is the Euclidean distance, p is the power parameter,
    and H_j is the entropy at the sample position's neighborhood.

    Properties:
        - Fast: O(H*W*K)
        - Smooth interpolation
        - Accounts for local uncertainty
        - Heuristic (no formal optimality guarantee)

    Args:
        sampled_field: Field with observed values and NaN elsewhere.
        sampled_mask: Boolean mask of sampled positions.
        entropy_field: Optional entropy map. If None, uses uniform weights
            (reduces to standard IDW).
        power: Distance weighting power (higher = more local).

    Returns:
        Reconstructed field of shape (H, W) with values in [0, 1].
    """
    H, W = sampled_field.shape

    sampled_positions = np.argwhere(sampled_mask)
    n_sampled = len(sampled_positions)

    if n_sampled == 0:
        return np.full((H, W), 0.5)

    sampled_values = sampled_field[sampled_mask]

    # Entropy weights for each sample
    if entropy_field is not None:
        H_max = np.max(entropy_field) + 1e-10
        entropy_weights = np.array([
            1.0 - entropy_field[int(p[0]), int(p[1])] / H_max + 0.1
            for p in sampled_positions
        ])
    else:
        entropy_weights = np.ones(n_sampled)

    result = np.full((H, W), np.nan)
    result[sampled_mask] = sampled_values

    unsampled = np.argwhere(~sampled_mask)

    for pos in unsampled:
        i, j = pos
        distances = np.sqrt(
            (sampled_positions[:, 0] - i) ** 2
            + (sampled_positions[:, 1] - j) ** 2
        )

        # Avoid division by zero
        distances = np.maximum(distances, 1e-10)

        # Inverse-distance weights modulated by entropy
        weights = (1.0 / distances**power) * entropy_weights
        weights /= weights.sum()

        estimate = np.dot(weights, sampled_values)
        result[i, j] = np.clip(estimate, 0.0, 1.0)

    return result


def reconstruct(
    sampled_field: np.ndarray,
    sampled_mask: np.ndarray,
    method: str = "kriging",
    entropy_field: Optional[np.ndarray] = None,
    **kwargs,
) -> np.ndarray:
    """Dispatch reconstruction method.

    Args:
        sampled_field: Field with observed values and NaN elsewhere.
        sampled_mask: Boolean mask of sampled positions.
        method: One of "nearest", "kriging", "entropy_weighted".
        entropy_field: Optional entropy map (for entropy_weighted method).
        **kwargs: Additional arguments for the specific method.

    Returns:
        Reconstructed field of shape (H, W).

    Raises:
        ValueError: If method is not recognized.
    """
    if method == "nearest":
        return nearest_neighbor_interpolation(sampled_field, sampled_mask)
    elif method == "kriging":
        return indicator_kriging(sampled_field, sampled_mask, **kwargs)
    elif method == "entropy_weighted":
        return entropy_weighted_interpolation(
            sampled_field, sampled_mask, entropy_field=entropy_field, **kwargs
        )
    else:
        raise ValueError(
            f"Unknown reconstruction method '{method}'. "
            f"Choose from: nearest, kriging, entropy_weighted"
        )

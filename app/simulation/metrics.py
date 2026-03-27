"""
Performance Metrics for OWP Sampling and Reconstruction.

===== METRICS OVERVIEW =====

These metrics evaluate how well a sampling strategy and reconstruction
method recover the true field from sparse observations.

1. SNR (Signal-to-Noise Ratio):
   Measures reconstruction fidelity in decibels.

2. Resolvability Capacity C_k:
   Information-theoretic metric measuring what fraction of total
   field uncertainty has been resolved after k measurements.

3. Coverage:
   Fraction of the field within a given distance of a sample point.

4. Pattern Preservation:
   How well the spatial structure (connectivity, channel geometry)
   is preserved in the reconstruction.

5. Classification Accuracy:
   For binary fields, accuracy of thresholded reconstruction.

References:
    - Silva et al., IDS Group, Fondecyt 1140840
"""

import numpy as np
from typing import Optional, Dict
from scipy.spatial import cKDTree


def snr_db(true_field: np.ndarray, reconstructed: np.ndarray) -> float:
    """Compute Signal-to-Noise Ratio in decibels.

    SNR = 10 * log10( ||signal||^2 / ||noise||^2 )

    where signal = true_field, noise = true_field - reconstructed.

    Higher SNR = better reconstruction. Typical values:
        - 0-5 dB: poor reconstruction
        - 5-15 dB: moderate reconstruction
        - 15-25 dB: good reconstruction
        - >25 dB: excellent reconstruction

    Args:
        true_field: Ground truth binary field.
        reconstructed: Reconstructed field (may be continuous [0,1]).

    Returns:
        SNR in decibels. Returns inf if perfect reconstruction.
    """
    signal_power = np.sum(true_field**2)
    noise = true_field - reconstructed
    noise_power = np.sum(noise**2)

    if noise_power < 1e-15:
        return float("inf")
    if signal_power < 1e-15:
        return 0.0

    return float(10.0 * np.log10(signal_power / noise_power))


def mse(true_field: np.ndarray, reconstructed: np.ndarray) -> float:
    """Mean Squared Error between true and reconstructed fields.

    MSE = (1/N) * sum (true - reconstructed)^2

    Args:
        true_field: Ground truth.
        reconstructed: Reconstructed field.

    Returns:
        MSE value (non-negative, 0 = perfect).
    """
    return float(np.mean((true_field - reconstructed) ** 2))


def classification_accuracy(
    true_field: np.ndarray,
    reconstructed: np.ndarray,
    threshold: float = 0.5,
) -> float:
    """Classification accuracy for binary field reconstruction.

    Thresholds the reconstructed field at `threshold` and compares
    with the true binary field. Returns fraction of correctly
    classified pixels.

    Args:
        true_field: Ground truth binary field.
        reconstructed: Reconstructed probability field in [0, 1].
        threshold: Decision boundary for classification.

    Returns:
        Accuracy in [0, 1]. 1.0 = perfect classification.
    """
    predicted = (reconstructed >= threshold).astype(float)
    true_binary = (true_field >= threshold).astype(float)
    return float(np.mean(predicted == true_binary))


def confusion_matrix_metrics(
    true_field: np.ndarray,
    reconstructed: np.ndarray,
    threshold: float = 0.5,
) -> Dict[str, float]:
    """Compute precision, recall, F1 for binary classification.

    Positive class = 1 (channel/sand), Negative class = 0 (background/shale).

    Args:
        true_field: Ground truth binary field.
        reconstructed: Reconstructed probability field.
        threshold: Classification threshold.

    Returns:
        Dictionary with precision, recall, f1, accuracy.
    """
    pred = (reconstructed >= threshold).astype(bool)
    true = (true_field >= threshold).astype(bool)

    tp = int(np.sum(pred & true))
    fp = int(np.sum(pred & ~true))
    fn = int(np.sum(~pred & true))
    tn = int(np.sum(~pred & ~true))

    total = tp + fp + fn + tn
    accuracy = (tp + tn) / total if total > 0 else 0.0
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0.0

    return {
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "f1": f1,
        "tp": tp,
        "fp": fp,
        "fn": fn,
        "tn": tn,
    }


def resolvability_capacity(
    initial_entropy_total: float,
    current_entropy_total: float,
) -> float:
    """Compute resolvability capacity C_k.

    C_k = (H_0 - H_k) / H_0

    where H_0 is the total initial entropy and H_k is the total
    entropy after k measurements.

    Properties:
        C_0 = 0 (no measurements)
        C_k in [0, 1]
        C_k monotonically non-decreasing
        C_N = 1 (all positions measured)

    Args:
        initial_entropy_total: Sum of pixelwise entropy before any measurements.
        current_entropy_total: Sum of pixelwise entropy after k measurements.

    Returns:
        C_k in [0, 1].
    """
    if initial_entropy_total <= 0:
        return 1.0
    ck = (initial_entropy_total - current_entropy_total) / initial_entropy_total
    return float(np.clip(ck, 0.0, 1.0))


def spatial_coverage(
    field_shape: tuple,
    positions: np.ndarray,
    max_distance: float = 5.0,
) -> float:
    """Fraction of field pixels within max_distance of a sample point.

    Measures how well the sampling positions cover the spatial domain.
    A coverage of 1.0 means every pixel has a sample within max_distance.

    Args:
        field_shape: (H, W) field dimensions.
        positions: Array of shape (K, 2) with sample positions.
        max_distance: Maximum distance threshold in pixels.

    Returns:
        Coverage fraction in [0, 1].
    """
    H, W = field_shape

    if len(positions) == 0:
        return 0.0

    tree = cKDTree(positions)

    all_positions = np.array([[i, j] for i in range(H) for j in range(W)])
    distances, _ = tree.query(all_positions)

    covered = np.sum(distances <= max_distance)
    return float(covered / (H * W))


def pattern_preservation(
    true_field: np.ndarray,
    reconstructed: np.ndarray,
    threshold: float = 0.5,
) -> float:
    """Measure preservation of spatial patterns (connectivity).

    Computes the similarity between the connected component structure
    of the true and reconstructed fields. Uses a simple metric based
    on the correlation of local pattern frequencies.

    The metric computes the 2D autocorrelation of both fields at
    short lags and compares them. High correlation means the
    reconstruction preserves the spatial structure.

    Args:
        true_field: Ground truth binary field.
        reconstructed: Reconstructed field (will be thresholded).
        threshold: Threshold for binarizing the reconstruction.

    Returns:
        Pattern preservation score in [0, 1]. 1.0 = perfect match.
    """
    true_bin = (true_field >= threshold).astype(float)
    recon_bin = (reconstructed >= threshold).astype(float)

    # Compare proportion
    prop_true = np.mean(true_bin)
    prop_recon = np.mean(recon_bin)

    # Compare short-lag autocorrelation (lags 1-3 in each direction)
    lags = [1, 2, 3]
    autocorr_similarity = 0.0
    n_comparisons = 0

    for lag in lags:
        # Horizontal
        if lag < true_bin.shape[1]:
            ac_true_h = np.mean(true_bin[:, :-lag] * true_bin[:, lag:])
            ac_recon_h = np.mean(recon_bin[:, :-lag] * recon_bin[:, lag:])
            autocorr_similarity += 1.0 - abs(ac_true_h - ac_recon_h)
            n_comparisons += 1

        # Vertical
        if lag < true_bin.shape[0]:
            ac_true_v = np.mean(true_bin[:-lag, :] * true_bin[lag:, :])
            ac_recon_v = np.mean(recon_bin[:-lag, :] * recon_bin[lag:, :])
            autocorr_similarity += 1.0 - abs(ac_true_v - ac_recon_v)
            n_comparisons += 1

    if n_comparisons > 0:
        autocorr_score = autocorr_similarity / n_comparisons
    else:
        autocorr_score = 0.0

    # Combine proportion similarity and autocorrelation similarity
    prop_score = 1.0 - abs(prop_true - prop_recon)
    score = 0.4 * prop_score + 0.6 * autocorr_score

    return float(np.clip(score, 0.0, 1.0))


def compute_all_metrics(
    true_field: np.ndarray,
    reconstructed: np.ndarray,
    positions: np.ndarray,
    initial_entropy: Optional[float] = None,
    current_entropy: Optional[float] = None,
) -> Dict[str, float]:
    """Compute all performance metrics at once.

    Args:
        true_field: Ground truth binary field.
        reconstructed: Reconstructed field.
        positions: Sample positions array of shape (K, 2).
        initial_entropy: Total initial entropy (for resolvability).
        current_entropy: Total current entropy (for resolvability).

    Returns:
        Dictionary with all metric values.
    """
    metrics = {
        "snr_db": snr_db(true_field, reconstructed),
        "mse": mse(true_field, reconstructed),
        "accuracy": classification_accuracy(true_field, reconstructed),
        "coverage_5px": spatial_coverage(true_field.shape, positions, 5.0),
        "coverage_10px": spatial_coverage(true_field.shape, positions, 10.0),
        "pattern_preservation": pattern_preservation(true_field, reconstructed),
    }

    cm = confusion_matrix_metrics(true_field, reconstructed)
    metrics.update({f"cm_{k}": v for k, v in cm.items()})

    if initial_entropy is not None and current_entropy is not None:
        metrics["resolvability"] = resolvability_capacity(
            initial_entropy, current_entropy
        )

    return metrics

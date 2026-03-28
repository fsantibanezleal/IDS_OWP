"""
Synthetic Binary Field Generator for OWP.

Generates channelized binary fields that simulate geological facies patterns,
specifically sand channels in a shale background. These synthetic fields are
used as:
    1. True fields (ground truth) for testing sampling strategies
    2. Training images (TI) that encode prior geological knowledge

===== FIELD TYPES =====

1. Single Channel: One sinuous channel crossing the field.
   - Parameters: width, sinuosity amplitude and frequency
   - Typical proportion: 15-30%

2. Multi-Channel: Multiple independent channels.
   - Parameters: number of channels, width distribution
   - Typical proportion: 20-40%

3. Branching: Channels that split and merge.
   - Parameters: branch probability, merge probability
   - Typical proportion: 25-45%

4. Random MPS-like: Uses a simple Markov random field approach
   to generate patterns with prescribed two-point statistics.

===== GENERATION APPROACH =====

Channels are generated as parametric curves y(x) = A*sin(2*pi*f*x + phi) + offset,
then rasterized onto the grid with a specified width using distance fields.
Post-processing with morphological operations smooths the boundaries.

References:
    - Strebelle (2002), Conditional simulation
    - Mariethoz & Caers (2015), Multiple-point Geostatistics
"""

import numpy as np
from typing import Tuple, Optional, List
from scipy.ndimage import binary_dilation, binary_erosion, gaussian_filter


def generate_single_channel(
    shape: Tuple[int, int] = (64, 64),
    channel_width: float = 5.0,
    sinuosity_amplitude: float = 10.0,
    sinuosity_frequency: float = 2.0,
    phase: Optional[float] = None,
    offset: Optional[float] = None,
    seed: Optional[int] = None,
) -> np.ndarray:
    """Generate a binary field with a single sinuous channel.

    The channel is modeled as a sinusoidal curve:
        y(x) = A * sin(2*pi*f * x/W + phi) + y_offset

    where A is amplitude, f is frequency, W is field width,
    phi is random phase, and y_offset is the vertical center.

    Pixels within channel_width/2 of the curve are set to 1 (sand),
    the rest to 0 (shale).

    Args:
        shape: (height, width) of the output field.
        channel_width: Width of the channel in pixels.
        sinuosity_amplitude: Amplitude of sinusoidal curve in pixels.
        sinuosity_frequency: Number of complete oscillations across the field.
        phase: Phase offset in radians. Random if None.
        offset: Vertical offset of channel center. Random if None.
        seed: Random seed for reproducibility.

    Returns:
        Binary 2D array of shape `shape`. 1 = channel (sand), 0 = background (shale).
    """
    rng = np.random.RandomState(seed)
    H, W = shape

    if phase is None:
        phase = rng.uniform(0, 2 * np.pi)
    if offset is None:
        offset = H / 2 + rng.uniform(-H * 0.15, H * 0.15)

    field = np.zeros((H, W), dtype=np.float64)

    # Create coordinate grids
    x = np.arange(W)
    y_center = sinuosity_amplitude * np.sin(
        2 * np.pi * sinuosity_frequency * x / W + phase
    ) + offset

    # Distance from each pixel to the channel centerline
    y_coords = np.arange(H)[:, np.newaxis]  # (H, 1)
    y_center_row = y_center[np.newaxis, :]  # (1, W)

    distance = np.abs(y_coords - y_center_row)
    field = (distance <= channel_width / 2).astype(np.float64)

    return field


def generate_multi_channel(
    shape: Tuple[int, int] = (64, 64),
    num_channels: int = 3,
    channel_width_range: Tuple[float, float] = (3.0, 7.0),
    sinuosity_amplitude_range: Tuple[float, float] = (5.0, 15.0),
    sinuosity_frequency_range: Tuple[float, float] = (1.0, 3.0),
    seed: Optional[int] = None,
) -> np.ndarray:
    """Generate a binary field with multiple independent sinuous channels.

    Each channel has randomly drawn parameters for width, sinuosity,
    and vertical position. Channels may overlap (union operation).

    Args:
        shape: (height, width) of the output field.
        num_channels: Number of independent channels.
        channel_width_range: (min, max) channel width in pixels.
        sinuosity_amplitude_range: (min, max) sinusoidal amplitude.
        sinuosity_frequency_range: (min, max) sinusoidal frequency.
        seed: Random seed.

    Returns:
        Binary 2D array. 1 = channel, 0 = background.
    """
    rng = np.random.RandomState(seed)
    H, W = shape
    field = np.zeros((H, W), dtype=np.float64)

    for _ in range(num_channels):
        width = rng.uniform(*channel_width_range)
        amp = rng.uniform(*sinuosity_amplitude_range)
        freq = rng.uniform(*sinuosity_frequency_range)
        phase = rng.uniform(0, 2 * np.pi)
        offset = rng.uniform(H * 0.1, H * 0.9)

        channel = generate_single_channel(
            shape=shape,
            channel_width=width,
            sinuosity_amplitude=amp,
            sinuosity_frequency=freq,
            phase=phase,
            offset=offset,
            seed=None,
        )
        field = np.maximum(field, channel)

    return field


def generate_branching_channels(
    shape: Tuple[int, int] = (64, 64),
    num_initial: int = 2,
    branch_probability: float = 0.3,
    channel_width: float = 4.0,
    seed: Optional[int] = None,
) -> np.ndarray:
    """Generate a binary field with branching channel patterns.

    Starts with `num_initial` channels and allows branching at random
    positions. Branches diverge from the parent channel with a small
    angular offset, creating realistic distributary patterns.

    The algorithm processes the field column by column (left to right),
    tracking active channel center positions. At each column, there's a
    probability of a channel splitting into two.

    Args:
        shape: (height, width) of the output field.
        num_initial: Number of channels at the left edge.
        branch_probability: Probability of branching per column per channel.
        channel_width: Width of each channel in pixels.
        seed: Random seed.

    Returns:
        Binary 2D array. 1 = channel, 0 = background.
    """
    rng = np.random.RandomState(seed)
    H, W = shape
    field = np.zeros((H, W), dtype=np.float64)

    # Initialize channel centers
    centers: List[float] = []
    for _ in range(num_initial):
        centers.append(rng.uniform(H * 0.15, H * 0.85))

    half_w = channel_width / 2.0

    for col in range(W):
        new_centers: List[float] = []

        for c in centers:
            # Random walk for center position
            c += rng.normal(0, 0.8)
            c = np.clip(c, half_w, H - half_w)

            # Mark pixels within channel width
            for row in range(H):
                if abs(row - c) <= half_w:
                    field[row, col] = 1.0

            new_centers.append(c)

            # Possible branching
            if rng.random() < branch_probability / W:
                # Create a branch with offset
                branch_offset = rng.choice([-1, 1]) * rng.uniform(3, 8)
                branch_center = np.clip(c + branch_offset, half_w, H - half_w)
                new_centers.append(branch_center)

        centers = new_centers

    # Smooth with morphological operations for realism
    struct = np.ones((3, 3))
    field = binary_dilation(field > 0.5, structure=struct).astype(np.float64)
    field = binary_erosion(field > 0.5, structure=struct).astype(np.float64)

    return field


def generate_random_field(
    shape: Tuple[int, int] = (64, 64),
    proportion: float = 0.3,
    correlation_length: float = 8.0,
    seed: Optional[int] = None,
) -> np.ndarray:
    """Generate a spatially correlated binary random field.

    Uses a Gaussian random field approach:
    1. Generate white noise
    2. Apply Gaussian smoothing (controls spatial correlation)
    3. Threshold to achieve desired proportion

    The correlation length determines the characteristic size of
    connected features. Larger values produce smoother, more
    continuous structures.

    Args:
        shape: (height, width) of the output field.
        proportion: Target fraction of 1-valued pixels (channel proportion).
        correlation_length: Sigma of Gaussian smoothing kernel in pixels.
            Controls the spatial extent of correlations.
        seed: Random seed.

    Returns:
        Binary 2D array. 1 = channel, 0 = background.
    """
    rng = np.random.RandomState(seed)

    # Step 1: White noise
    noise = rng.randn(*shape)

    # Step 2: Gaussian smoothing to introduce spatial correlation
    smoothed = gaussian_filter(noise, sigma=correlation_length)

    # Step 3: Threshold to get desired proportion
    # Find threshold that gives the target proportion of 1s
    threshold = np.percentile(smoothed, (1.0 - proportion) * 100)
    field = (smoothed >= threshold).astype(np.float64)

    return field


def simulate_darcy_flow(permeability_field, well_positions, well_types,
                         pressure_boundary=1.0, n_steps=50):
    """Simple 2D Darcy flow proxy model for reservoir simulation.

    Solves the pressure equation:
        div(k * grad(p)) = q

    using finite differences on the permeability field.
    Well types: 'producer' (q < 0) or 'injector' (q > 0).

    This is a proxy model -- not a full reservoir simulator, but
    sufficient for comparing well placement strategies by their
    cumulative production.

    Args:
        permeability_field: (H, W) binary field (1=high perm, 0=low)
        well_positions: list of (row, col) tuples
        well_types: list of 'producer' or 'injector'
        pressure_boundary: boundary pressure condition
        n_steps: number of pressure solve iterations (Jacobi)

    Returns:
        dict with:
        - 'pressure': (H, W) pressure field
        - 'flow_rate': total production rate
        - 'npv': simplified NPV estimate
    """
    H, W = permeability_field.shape
    k = permeability_field.astype(np.float64) * 0.9 + 0.1  # min perm 0.1

    # Initialize pressure
    p = np.full((H, W), pressure_boundary)

    # Source/sink terms
    q = np.zeros((H, W))
    for (r, c), wtype in zip(well_positions, well_types):
        if 0 <= r < H and 0 <= c < W:
            q[r, c] = 1.0 if wtype == 'injector' else -1.0

    # Jacobi iteration for pressure solve
    for _ in range(n_steps):
        p_new = p.copy()
        # Interior points: 5-point stencil
        p_new[1:-1, 1:-1] = (
            k[1:-1, 1:-1] * (
                p[2:, 1:-1] + p[:-2, 1:-1] +
                p[1:-1, 2:] + p[1:-1, :-2]
            ) / 4 + q[1:-1, 1:-1]
        ) / (k[1:-1, 1:-1] + 1e-10)
        p = p_new

    # Compute production rate at producers
    total_production = 0.0
    for (r, c), wtype in zip(well_positions, well_types):
        if wtype == 'producer' and 0 <= r < H and 0 <= c < W:
            total_production += abs(k[r, c] * p[r, c])

    # Simplified NPV (production - well cost)
    well_cost = len(well_positions) * 10.0
    npv = total_production * 100.0 - well_cost

    return {
        'pressure': p,
        'flow_rate': float(total_production),
        'npv': float(npv),
    }


def generate_field(
    field_type: str = "multi_channel",
    shape: Tuple[int, int] = (64, 64),
    seed: Optional[int] = None,
    **kwargs,
) -> np.ndarray:
    """Generate a synthetic binary field of the specified type.

    Dispatcher function that calls the appropriate generator.

    Args:
        field_type: One of "single_channel", "multi_channel",
            "branching", "random".
        shape: (height, width) of output field.
        seed: Random seed.
        **kwargs: Additional keyword arguments passed to the specific generator.

    Returns:
        Binary 2D array. 1 = channel (sand), 0 = background (shale).

    Raises:
        ValueError: If field_type is not recognized.
    """
    generators = {
        "single_channel": generate_single_channel,
        "multi_channel": generate_multi_channel,
        "branching": generate_branching_channels,
        "random": generate_random_field,
    }

    if field_type not in generators:
        raise ValueError(
            f"Unknown field type '{field_type}'. "
            f"Choose from: {list(generators.keys())}"
        )

    return generators[field_type](shape=shape, seed=seed, **kwargs)


def generate_training_image(
    field_type: str = "multi_channel",
    shape: Tuple[int, int] = (128, 128),
    seed: Optional[int] = None,
    **kwargs,
) -> np.ndarray:
    """Generate a training image (TI) for pattern statistics.

    The training image should be larger than the target field and
    representative of the expected geological patterns. It is used
    to estimate conditional probabilities during adaptive sampling.

    Typically the TI is 2-4x larger than the field being sampled,
    to provide sufficient pattern statistics.

    Args:
        field_type: Type of geological pattern.
        shape: (height, width) of TI. Should be larger than field.
        seed: Random seed for reproducibility.
        **kwargs: Additional parameters for the generator.

    Returns:
        Binary 2D array representing the training image.
    """
    return generate_field(field_type=field_type, shape=shape, seed=seed, **kwargs)


def generate_training_ensemble(
    field_type: str = "multi_channel",
    n_realizations: int = 10,
    field_size: Tuple[int, int] = (64, 64),
    seed: Optional[int] = None,
) -> List[np.ndarray]:
    """Generate an ensemble of training images (multiple realizations).

    Each realization has the same statistical properties but different
    specific geometries, representing equiprobable geological scenarios.

    In geostatistical workflows, using multiple TIs reduces estimation
    variance by factor 1/K and captures geological uncertainty that
    a single TI cannot represent.

    The ensemble is generated by varying the random seed for each
    realization while keeping the field type and size constant.

    Args:
        field_type: Type of geological pattern (e.g. 'multi_channel').
        n_realizations: Number of independent realizations to generate.
        field_size: (height, width) of each training image.
        seed: Base random seed. Each realization uses seed + i.

    Returns:
        List of n_realizations 2D binary arrays, each of shape field_size.
    """
    ensemble: List[np.ndarray] = []
    for i in range(n_realizations):
        ti_seed = (seed + i * 1000) if seed is not None else None
        ti = generate_field(
            field_type=field_type,
            shape=field_size,
            seed=ti_seed,
        )
        ensemble.append(ti)
    return ensemble

"""
API Routes for the OWP Application.

Provides REST endpoints for:
    - Generating synthetic fields and training images
    - Running sampling schemes
    - Reconstructing fields from samples
    - Querying application state

Also provides a WebSocket endpoint for real-time updates during
adaptive sampling.
"""

import json
import asyncio
import numpy as np
from typing import Optional, Dict, Any, List
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, Field

from ..simulation.field_generator import generate_field, generate_training_image
from ..simulation.sampling import (
    random_uniform_sampling,
    stratified_sampling,
    random_stratified_sampling,
    multiscale_stratified_sampling,
    oracle_entropy_sampling,
    adaptive_entropy_sampling,
    penalized_adaptive_sampling,
    hybrid_stratified_adaptive_sampling,
    multiscale_adaptive_sampling,
    pso_sampling,
    apply_sampling,
)
from ..simulation.field_generator import generate_training_ensemble
from ..simulation.inference import reconstruct
from ..simulation.entropy import entropy_map, total_field_entropy
from ..simulation.metrics import compute_all_metrics

router = APIRouter(prefix="/api")


# ===== Request/Response Models =====


class GenerateRequest(BaseModel):
    """Request to generate a new synthetic field and training image."""

    field_type: str = Field(
        default="multi_channel",
        description="Type of field: single_channel, multi_channel, branching, random",
    )
    field_height: int = Field(default=32, ge=8, le=128)
    field_width: int = Field(default=32, ge=8, le=128)
    ti_height: int = Field(default=64, ge=16, le=256)
    ti_width: int = Field(default=64, ge=16, le=256)
    seed: Optional[int] = None


class SampleRequest(BaseModel):
    """Request to run a sampling scheme on the current field."""

    method: str = Field(
        default="random_uniform",
        description=(
            "Sampling method: random_uniform, stratified, random_stratified, "
            "multiscale_stratified, oracle_entropy, adaptive_entropy, "
            "penalized_adaptive, hybrid_stratified_adaptive, multiscale_adaptive, "
            "pso"
        ),
    )
    num_samples: int = Field(default=20, ge=1, le=1000)
    pattern_radius: int = Field(default=3, ge=1, le=10)
    num_training_images: int = Field(default=5, ge=1, le=20)
    seed: Optional[int] = None


class InferRequest(BaseModel):
    """Request to reconstruct the field from current samples."""

    method: str = Field(
        default="kriging",
        description="Reconstruction method: nearest, kriging, entropy_weighted",
    )
    range_param: float = Field(default=10.0, ge=1.0)


class StateResponse(BaseModel):
    """Current application state."""

    has_field: bool
    field_shape: Optional[List[int]] = None
    field_type: Optional[str] = None
    num_samples: int = 0
    sampling_method: Optional[str] = None
    has_reconstruction: bool = False


# ===== Application State =====

# Module-level state (simple for single-user app)
_state: Dict[str, Any] = {
    "true_field": None,
    "training_image": None,
    "field_type": None,
    "sampled_field": None,
    "sampled_mask": None,
    "positions": None,
    "sampling_method": None,
    "reconstructed": None,
    "entropy_field": None,
    "entropy_history": None,
    "metrics": None,
}


def _array_to_list(arr: Optional[np.ndarray]) -> Optional[list]:
    """Convert numpy array to nested Python list for JSON serialization."""
    if arr is None:
        return None
    return arr.tolist()


# ===== Endpoints =====


@router.post("/generate")
async def generate_endpoint(req: GenerateRequest) -> Dict[str, Any]:
    """Generate a new synthetic field and training image.

    Creates a binary channelized field as the 'true' field (ground truth)
    and a separate, larger training image with similar statistics.

    The true field represents the unknown subsurface that we want to
    characterize through optimal well placement. The training image
    represents our prior geological knowledge.
    """
    global _state

    field_shape = (req.field_height, req.field_width)
    ti_shape = (req.ti_height, req.ti_width)

    # Generate field and TI with different seeds for independence
    seed = req.seed
    true_field = generate_field(req.field_type, field_shape, seed=seed)
    ti_seed = seed + 1000 if seed is not None else None
    training_image = generate_training_image(req.field_type, ti_shape, seed=ti_seed)

    # Compute initial entropy map (uniform prior)
    p_prior = np.mean(training_image)
    prior_prob = np.full(field_shape, p_prior)
    ent = entropy_map(prior_prob)

    # Reset state
    _state = {
        "true_field": true_field,
        "training_image": training_image,
        "field_type": req.field_type,
        "sampled_field": None,
        "sampled_mask": None,
        "positions": None,
        "sampling_method": None,
        "reconstructed": None,
        "entropy_field": ent,
        "entropy_history": None,
        "metrics": None,
    }

    return {
        "status": "ok",
        "field_shape": list(field_shape),
        "ti_shape": list(ti_shape),
        "field_proportion": float(np.mean(true_field)),
        "ti_proportion": float(np.mean(training_image)),
        "training_image": _array_to_list(training_image),
        "entropy_map": _array_to_list(ent),
        "initial_entropy": float(np.sum(ent)),
    }


@router.post("/sample")
async def sample_endpoint(req: SampleRequest) -> Dict[str, Any]:
    """Run a sampling scheme on the current field.

    Selects K positions using the specified method and reveals the
    true field values at those positions (simulating drilling wells).

    For non-adaptive methods, all positions are selected at once.
    For adaptive_entropy (AdSEMES), positions are selected sequentially,
    each conditioned on previous observations.
    """
    global _state

    if _state["true_field"] is None:
        return {"status": "error", "message": "No field generated. Call /api/generate first."}

    true_field = _state["true_field"]
    training_image = _state["training_image"]

    # Select positions based on method
    method = req.method
    entropy_history = None

    if method == "random_uniform":
        positions = random_uniform_sampling(true_field.shape, req.num_samples, seed=req.seed)
    elif method == "stratified":
        positions = stratified_sampling(true_field.shape, req.num_samples)
    elif method == "random_stratified":
        positions = random_stratified_sampling(true_field.shape, req.num_samples, seed=req.seed)
    elif method == "multiscale_stratified":
        positions = multiscale_stratified_sampling(true_field.shape, req.num_samples, seed=req.seed)
    elif method == "oracle_entropy":
        positions = oracle_entropy_sampling(true_field, req.num_samples, seed=req.seed)
    elif method == "adaptive_entropy":
        positions, entropy_history = adaptive_entropy_sampling(
            true_field, training_image, req.num_samples,
            pattern_radius=req.pattern_radius, seed=req.seed,
        )
    elif method in ("penalized_adaptive", "hybrid_stratified_adaptive", "multiscale_adaptive", "pso"):
        # Generate training ensemble for multi-TI methods
        ti_seed = (req.seed + 2000) if req.seed is not None else None
        training_ensemble = generate_training_ensemble(
            field_type=_state["field_type"] or "multi_channel",
            n_realizations=req.num_training_images,
            field_size=training_image.shape,
            seed=ti_seed,
        )
        if method == "penalized_adaptive":
            mask, order, ent_hist = penalized_adaptive_sampling(
                true_field, training_ensemble, req.num_samples,
                pattern_radius=req.pattern_radius, seed=req.seed,
            )
        elif method == "hybrid_stratified_adaptive":
            mask, order, ent_hist = hybrid_stratified_adaptive_sampling(
                true_field, training_ensemble, req.num_samples,
                pattern_radius=req.pattern_radius, seed=req.seed,
            )
        elif method == "pso":
            mask, order, ent_hist = pso_sampling(
                true_field, training_ensemble, req.num_samples,
                seed=req.seed,
            )
        else:  # multiscale_adaptive
            mask, order, ent_hist = multiscale_adaptive_sampling(
                true_field, training_ensemble, req.num_samples,
                pattern_radius=req.pattern_radius, seed=req.seed,
            )
        # Convert mask+order to positions array (sorted by order)
        sampled_positions = np.argwhere(mask)
        orders = np.array([order[r, c] for r, c in sampled_positions])
        sort_idx = np.argsort(orders)
        positions = sampled_positions[sort_idx]
        entropy_history = None  # These methods track total entropy differently
    else:
        return {"status": "error", "message": f"Unknown sampling method: {method}"}

    # Apply sampling
    sampled_field, sampled_mask = apply_sampling(true_field, positions)

    # Compute post-sampling entropy
    if entropy_history and len(entropy_history) > 0:
        ent = entropy_history[-1]
    else:
        # For non-adaptive methods, compute entropy from marginal
        p_prior = np.mean(training_image)
        prob_field = np.full(true_field.shape, p_prior)
        prob_field[sampled_mask] = sampled_field[sampled_mask]
        ent = entropy_map(prob_field)
        ent[sampled_mask] = 0.0

    _state.update({
        "sampled_field": sampled_field,
        "sampled_mask": sampled_mask,
        "positions": positions,
        "sampling_method": method,
        "entropy_field": ent,
        "entropy_history": [_array_to_list(e) for e in entropy_history] if entropy_history else None,
        "reconstructed": None,
        "metrics": None,
    })

    return {
        "status": "ok",
        "method": method,
        "num_samples": len(positions),
        "positions": _array_to_list(positions),
        "sampled_values": [float(sampled_field[int(p[0]), int(p[1])]) for p in positions],
        "entropy_map": _array_to_list(ent),
        "current_entropy": float(np.sum(ent)),
    }


@router.post("/infer")
async def infer_endpoint(req: InferRequest) -> Dict[str, Any]:
    """Reconstruct the full field from current samples.

    Uses the specified interpolation/estimation method to predict
    the field value at all unsampled positions.
    """
    global _state

    if _state["sampled_field"] is None:
        return {"status": "error", "message": "No samples taken. Call /api/sample first."}

    sampled_field = _state["sampled_field"]
    sampled_mask = _state["sampled_mask"]
    true_field = _state["true_field"]
    positions = _state["positions"]
    entropy_field = _state["entropy_field"]

    kwargs = {}
    if req.method == "kriging":
        kwargs["range_param"] = req.range_param
    elif req.method == "entropy_weighted":
        kwargs["entropy_field"] = entropy_field

    reconstructed = reconstruct(sampled_field, sampled_mask, method=req.method, **kwargs)

    # Compute metrics
    initial_ent = total_field_entropy(
        np.full(true_field.shape, np.mean(_state["training_image"]))
    )
    current_ent = float(np.sum(entropy_field)) if entropy_field is not None else 0.0

    metrics = compute_all_metrics(
        true_field, reconstructed, positions,
        initial_entropy=initial_ent,
        current_entropy=current_ent,
    )

    _state.update({
        "reconstructed": reconstructed,
        "metrics": metrics,
    })

    return {
        "status": "ok",
        "method": req.method,
        "reconstructed": _array_to_list(reconstructed),
        "true_field": _array_to_list(true_field),
        "metrics": {k: float(v) if isinstance(v, (int, float, np.floating, np.integer)) else v
                    for k, v in metrics.items()},
    }


@router.get("/state")
async def get_state() -> Dict[str, Any]:
    """Get the current application state summary."""
    has_field = _state["true_field"] is not None
    has_samples = _state["positions"] is not None
    has_recon = _state["reconstructed"] is not None

    result: Dict[str, Any] = {
        "has_field": has_field,
        "has_samples": has_samples,
        "has_reconstruction": has_recon,
    }

    if has_field:
        result["field_shape"] = list(_state["true_field"].shape)
        result["field_type"] = _state["field_type"]

    if has_samples:
        result["num_samples"] = len(_state["positions"])
        result["sampling_method"] = _state["sampling_method"]

    if has_recon and _state["metrics"]:
        result["metrics"] = {
            k: float(v) if isinstance(v, (int, float, np.floating, np.integer)) else v
            for k, v in _state["metrics"].items()
        }

    return result


class AnimatedRequest(BaseModel):
    """Request to run animated (step-by-step) sampling."""

    method: str = Field(default="random_uniform")
    num_samples: int = Field(default=20, ge=1, le=200)
    pattern_radius: int = Field(default=3, ge=1, le=10)
    num_training_images: int = Field(default=5, ge=1, le=20)
    recon_method: str = Field(default="kriging")
    seed: Optional[int] = None


class StepRequest(BaseModel):
    """Request to compute a single sampling step."""
    method: str = Field(default="random_uniform")
    step: int = Field(default=1, ge=1)
    num_samples: int = Field(default=20, ge=1, le=200)
    pattern_radius: int = Field(default=3, ge=1, le=10)
    num_training_images: int = Field(default=5, ge=1, le=20)
    recon_method: str = Field(default="kriging")
    seed: Optional[int] = None


@router.post("/process-animated")
async def process_animated(req: AnimatedRequest) -> Dict[str, Any]:
    """Return sample-by-sample evolution for any method.

    Runs the sampling method incrementally from 1 to num_samples,
    computing entropy maps, reconstructions, and metrics at each step.
    """
    global _state

    if _state["true_field"] is None:
        return {"status": "error", "message": "No field generated. Call /api/generate first."}

    true_field = _state["true_field"]
    training_image = _state["training_image"]
    method = req.method

    # Get all positions at once using the full sample count
    if method == "random_uniform":
        all_positions = random_uniform_sampling(true_field.shape, req.num_samples, seed=req.seed)
    elif method == "stratified":
        all_positions = stratified_sampling(true_field.shape, req.num_samples)
    elif method == "random_stratified":
        all_positions = random_stratified_sampling(true_field.shape, req.num_samples, seed=req.seed)
    elif method == "multiscale_stratified":
        all_positions = multiscale_stratified_sampling(true_field.shape, req.num_samples, seed=req.seed)
    elif method == "oracle_entropy":
        all_positions = oracle_entropy_sampling(true_field, req.num_samples, seed=req.seed)
    elif method == "adaptive_entropy":
        all_positions, _ = adaptive_entropy_sampling(
            true_field, training_image, req.num_samples,
            pattern_radius=req.pattern_radius, seed=req.seed,
        )
    elif method in ("penalized_adaptive", "hybrid_stratified_adaptive", "multiscale_adaptive", "pso"):
        ti_seed = (req.seed + 2000) if req.seed is not None else None
        training_ensemble = generate_training_ensemble(
            field_type=_state["field_type"] or "multi_channel",
            n_realizations=req.num_training_images,
            field_size=training_image.shape,
            seed=ti_seed,
        )
        if method == "penalized_adaptive":
            mask, order, _ = penalized_adaptive_sampling(
                true_field, training_ensemble, req.num_samples,
                pattern_radius=req.pattern_radius, seed=req.seed,
            )
        elif method == "hybrid_stratified_adaptive":
            mask, order, _ = hybrid_stratified_adaptive_sampling(
                true_field, training_ensemble, req.num_samples,
                pattern_radius=req.pattern_radius, seed=req.seed,
            )
        elif method == "pso":
            mask, order, _ = pso_sampling(
                true_field, training_ensemble, req.num_samples,
                seed=req.seed,
            )
        else:
            mask, order, _ = multiscale_adaptive_sampling(
                true_field, training_ensemble, req.num_samples,
                pattern_radius=req.pattern_radius, seed=req.seed,
            )
        sampled_positions = np.argwhere(mask)
        orders = np.array([order[r, c] for r, c in sampled_positions])
        sort_idx = np.argsort(orders)
        all_positions = sampled_positions[sort_idx]
    else:
        return {"status": "error", "message": f"Unknown method: {method}"}

    # Now build step-by-step results
    results = []
    for k in range(1, len(all_positions) + 1):
        positions_k = all_positions[:k]
        sampled_field_k, mask_k = apply_sampling(true_field, positions_k)

        # Entropy
        p_prior = np.mean(training_image)
        prob_field = np.full(true_field.shape, p_prior)
        prob_field[mask_k] = sampled_field_k[mask_k]
        ent = entropy_map(prob_field)
        ent[mask_k] = 0.0

        # Reconstruction
        recon_kwargs = {}
        if req.recon_method == "entropy_weighted":
            recon_kwargs["entropy_field"] = ent
        reconstructed = reconstruct(sampled_field_k, mask_k, method=req.recon_method, **recon_kwargs)

        # Metrics
        initial_ent = total_field_entropy(np.full(true_field.shape, p_prior))
        current_ent = float(np.sum(ent))
        metrics = compute_all_metrics(
            true_field, reconstructed, positions_k,
            initial_entropy=initial_ent,
            current_entropy=current_ent,
        )
        metrics_serial = {
            k_m: float(v) if isinstance(v, (int, float, np.floating, np.integer)) else v
            for k_m, v in metrics.items()
        }

        results.append({
            "step": k,
            "mask": mask_k.astype(int).tolist(),
            "entropy_map": ent.tolist(),
            "reconstruction": reconstructed.tolist(),
            "metrics": metrics_serial,
        })

    return {"status": "ok", "method": method, "results": results}


# ===== Per-step endpoint (non-blocking) =====

# Cache precomputed positions per method to avoid recomputing each step
_step_cache: Dict[str, Any] = {}


@router.post("/process-step")
async def process_step(req: StepRequest) -> Dict[str, Any]:
    """Compute a SINGLE sampling step and return immediately.

    The first call (step=1) precomputes all sample positions for
    the requested method and caches them.  Subsequent calls just
    index into the cache and compute entropy + reconstruction
    for that single step.

    This avoids blocking the browser while ALL steps are computed.
    The frontend calls this in a loop, rendering between calls.
    """
    global _state, _step_cache

    if _state["true_field"] is None:
        return {"status": "error", "message": "No field generated."}

    true_field = _state["true_field"]
    training_image = _state["training_image"]
    cache_key = f"{req.method}_{req.seed}_{req.num_samples}"

    # First step: precompute all positions (fast) and cache them
    if req.step == 1 or cache_key not in _step_cache:
        method = req.method
        if method == "random_uniform":
            positions = random_uniform_sampling(true_field.shape, req.num_samples, seed=req.seed)
        elif method == "stratified":
            positions = stratified_sampling(true_field.shape, req.num_samples)
        elif method == "random_stratified":
            positions = random_stratified_sampling(true_field.shape, req.num_samples, seed=req.seed)
        elif method == "multiscale_stratified":
            positions = multiscale_stratified_sampling(true_field.shape, req.num_samples, seed=req.seed)
        elif method == "oracle_entropy":
            positions = oracle_entropy_sampling(true_field, req.num_samples, seed=req.seed)
        elif method == "adaptive_entropy":
            positions, _ = adaptive_entropy_sampling(
                true_field, training_image, req.num_samples,
                pattern_radius=req.pattern_radius, seed=req.seed,
            )
        elif method in ("penalized_adaptive", "hybrid_stratified_adaptive", "multiscale_adaptive", "pso"):
            ti_seed = (req.seed + 2000) if req.seed is not None else None
            training_ensemble = generate_training_ensemble(
                field_type=_state["field_type"] or "multi_channel",
                n_realizations=req.num_training_images,
                field_size=training_image.shape, seed=ti_seed,
            )
            if method == "penalized_adaptive":
                mask, order, _ = penalized_adaptive_sampling(
                    true_field, training_ensemble, req.num_samples,
                    pattern_radius=req.pattern_radius, seed=req.seed,
                )
            elif method == "hybrid_stratified_adaptive":
                mask, order, _ = hybrid_stratified_adaptive_sampling(
                    true_field, training_ensemble, req.num_samples,
                    pattern_radius=req.pattern_radius, seed=req.seed,
                )
            elif method == "pso":
                mask, order, _ = pso_sampling(
                    true_field, training_ensemble, req.num_samples,
                    seed=req.seed,
                )
            else:
                mask, order, _ = multiscale_adaptive_sampling(
                    true_field, training_ensemble, req.num_samples,
                    pattern_radius=req.pattern_radius, seed=req.seed,
                )
            sampled_positions = np.argwhere(mask)
            orders = np.array([order[r, c] for r, c in sampled_positions])
            sort_idx = np.argsort(orders)
            positions = sampled_positions[sort_idx]
        else:
            return {"status": "error", "message": f"Unknown method: {method}"}

        _step_cache[cache_key] = positions

    positions = _step_cache[cache_key]
    k = min(req.step, len(positions))

    # Compute ONLY this step's entropy + reconstruction
    positions_k = positions[:k]
    sampled_field_k, mask_k = apply_sampling(true_field, positions_k)

    p_prior = np.mean(training_image)
    prob_field = np.full(true_field.shape, p_prior)
    prob_field[mask_k] = sampled_field_k[mask_k]
    ent = entropy_map(prob_field)
    ent[mask_k] = 0.0

    recon_kwargs = {}
    if req.recon_method == "entropy_weighted":
        recon_kwargs["entropy_field"] = ent
    reconstructed = reconstruct(sampled_field_k, mask_k, method=req.recon_method, **recon_kwargs)

    initial_ent = total_field_entropy(np.full(true_field.shape, p_prior))
    current_ent = float(np.sum(ent))
    metrics = compute_all_metrics(
        true_field, reconstructed, positions_k,
        initial_entropy=initial_ent, current_entropy=current_ent,
    )
    metrics_serial = {
        km: float(v) if isinstance(v, (int, float, np.floating, np.integer)) else v
        for km, v in metrics.items()
    }

    return {
        "status": "ok",
        "method": req.method,
        "step": k,
        "total_steps": len(positions),
        "mask": mask_k.astype(int).tolist(),
        "entropy_map": ent.tolist(),
        "reconstruction": reconstructed.tolist(),
        "metrics": metrics_serial,
    }


# ===== WebSocket for real-time adaptive sampling =====


@router.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    """WebSocket for real-time updates during adaptive sampling.

    Protocol:
    1. Client connects.
    2. Client sends JSON: {"action": "adaptive_sample", "num_samples": K, "pattern_radius": r}
    3. Server sends updates after each sample:
       {"step": k, "position": [r, c], "value": v, "entropy_map": [...], "entropy_total": H}
    4. Server sends final: {"status": "complete", "positions": [...], "num_samples": K}
    """
    await ws.accept()

    try:
        while True:
            data = await ws.receive_text()
            msg = json.loads(data)

            if msg.get("action") == "adaptive_sample":
                if _state["true_field"] is None:
                    await ws.send_json({"status": "error", "message": "No field generated."})
                    continue

                true_field = _state["true_field"]
                training_image = _state["training_image"]
                num_samples = msg.get("num_samples", 10)
                pattern_radius = msg.get("pattern_radius", 3)

                H, W = true_field.shape
                field = np.full((H, W), np.nan)
                sampled_mask = np.zeros((H, W), dtype=bool)
                positions_list = []
                entropy_history_list = []

                from ..simulation.entropy import conditional_entropy_estimate

                for step in range(num_samples):
                    ent = conditional_entropy_estimate(
                        field, sampled_mask, training_image, pattern_radius
                    )
                    entropy_history_list.append(ent.copy())

                    ent_masked = ent.copy()
                    ent_masked[sampled_mask] = -1.0
                    max_ent = np.max(ent_masked)

                    if max_ent <= 0:
                        break

                    candidates = np.argwhere(np.abs(ent_masked - max_ent) < 1e-10)
                    idx = np.random.randint(len(candidates))
                    r, c = int(candidates[idx, 0]), int(candidates[idx, 1])

                    field[r, c] = true_field[r, c]
                    sampled_mask[r, c] = True
                    positions_list.append([r, c])

                    # Send update to client
                    await ws.send_json({
                        "step": step,
                        "position": [r, c],
                        "value": float(true_field[r, c]),
                        "entropy_map": ent.tolist(),
                        "entropy_total": float(np.sum(ent)),
                    })

                    # Small delay to allow UI to update
                    await asyncio.sleep(0.05)

                # Update state
                positions_arr = np.array(positions_list) if positions_list else np.empty((0, 2))
                sampled_field, sampled_mask = apply_sampling(true_field, positions_arr)

                _state.update({
                    "sampled_field": sampled_field,
                    "sampled_mask": sampled_mask,
                    "positions": positions_arr,
                    "sampling_method": "adaptive_entropy",
                    "entropy_field": entropy_history_list[-1] if entropy_history_list else None,
                    "entropy_history": [e.tolist() for e in entropy_history_list],
                })

                await ws.send_json({
                    "status": "complete",
                    "positions": _array_to_list(positions_arr),
                    "num_samples": len(positions_list),
                })

            elif msg.get("action") == "ping":
                await ws.send_json({"status": "pong"})

    except WebSocketDisconnect:
        pass
    except Exception as e:
        try:
            await ws.send_json({"status": "error", "message": str(e)})
        except Exception:
            pass

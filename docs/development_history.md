# Development History

## v2.1.0 (2026-03-26) -- Algorithmic Improvements

Critical improvements to the AdSEMES algorithm addressing the locality problem, and addition of multi-training-image support.

### New Sampling Methods

#### 1. Penalized Adaptive Sampling

Applies a Gaussian spatial penalty after each sample to suppress entropy in the neighborhood, forcing the algorithm to explore globally rather than clustering locally:

```
H_pen(i',j') = H(i',j') · (1 - α · exp(-d²/(2R²)))
```

where:
- H(i',j') = original entropy at candidate position
- α = penalty strength (0 to 1)
- d = distance from the new sample to the candidate
- R = penalty radius

Configurable penalty radius and decay strength.

#### 2. Hybrid Stratified + Adaptive Sampling

Two-phase approach that places a fraction of samples on a stratified grid (Phase 1) for guaranteed spatial coverage, then uses penalized adaptive sampling (Phase 2) for information-driven refinement. The stratified scaffold prevents the adaptive phase from becoming local.

#### 3. Multiscale Adaptive Sampling

Operates at decreasing spatial resolutions. Coarse-scale samples ensure global coverage, while fine-scale samples are guided by entropy estimates. This inherently avoids locality through minimum spacing constraints at each scale.

### Multi-Training-Image Support

New `_update_probability_field_multi_ti()` function estimates conditional probabilities by averaging across multiple training images:

```
P = (1/K) · Σ_k P_k
```

This reduces estimation variance by factor 1/K (ensemble averaging). New `generate_training_ensemble()` function generates ensembles of training images with shared statistical properties but different specific geometries. All three new sampling methods support multi-TI probability estimation.

### Frontend Updates

- Added three new sampling methods to the dropdown selector
- Added a "Training Images" slider control (1-20, default 5) for configuring the number of TIs used by multi-TI methods
- Updated help modal with descriptions of new methods

### Documentation Updates

- Comprehensive theory sections on the locality problem, penalization solution, hybrid approach, multi-TI averaging, and comparison table of all 9 sampling methods
- Updated architecture documentation and references

### Testing

- New tests for `penalized_adaptive_sampling`, `hybrid_stratified_adaptive_sampling`, `multiscale_adaptive_sampling`, and multi-TI probability estimation
- All existing tests continue to pass

---

## v2.0.0 (2026-03-27) -- Complete Python Rewrite

Full reimplementation as a modern Python/FastAPI web application.

### Information-Theoretic Formulation

The AdSEMES algorithm formulates optimal well placement as an information-theoretic sensing design problem.

**Optimal Placement (Maximum Entropy):**
```
f* = argmax H(X_f)
```

where H(X_f) is the conditional entropy of the spatial field given observations at position f.

**Resolvability Capacity:**
```
C_k = I(f*_k) / H(X)
```

The ratio of mutual information gained by the k-th sample to total field entropy, measuring sampling efficiency.

**Binary Entropy (Pattern Statistics):**
```
H_bin(p) = -p·log₂(p) - (1-p)·log₂(1-p)
```

Used for computing conditional entropy from pattern matching probabilities.

**Submodularity Guarantee:**
The greedy sequential approach achieves a (1 - 1/e) approximation to the optimal K-sample placement, leveraging the submodularity of entropy as a set function.

> See `docs/diagrams/architecture.svg` for visual reference.

### Technical Stack

- **Backend**: Python 3.10+, FastAPI, numpy, scipy, scikit-learn
- **Frontend**: Vanilla HTML5/CSS3/JavaScript with canvas rendering
- **Architecture**: REST API + WebSocket for real-time adaptive sampling
- **Testing**: Comprehensive unit and integration tests
- **Documentation**: Exhaustive theory documentation with equations

### Key Improvements Over MATLAB

1. Interactive web-based visualization
2. Real-time step-by-step adaptive sampling via WebSocket
3. Multiple reconstruction methods (nearest, kriging, entropy-weighted)
4. Comprehensive performance metrics dashboard
5. Synthetic field generator with multiple geological patterns
6. Vectorized entropy computation for improved performance
7. Complete documentation with mathematical foundations

---

## v1.x (2014-2016) -- Original MATLAB Implementation [Legacy]

### Origins

Developed at the IDS (Information and Decision Systems) Group, Department of Electrical Engineering, Universidad de Chile, under Fondecyt Grant 1140840. PI: Prof. Jorge F. Silva.

The project originated from the intersection of information theory and geostatistics, addressing the fundamental question: how to optimally place measurement points (wells) in a spatial random field to maximize information about the entire field.

Key innovation: formulating the well placement problem as an information-theoretic sensing design problem, connecting Shannon entropy with spatial sampling optimization.

### Mathematical Contribution

The AdSEMES (Adaptive Sequential Empirical Maximum Entropy Sampling) algorithm provides a greedy O(K * N^2) solution to the NP-hard optimal placement problem, leveraging:

- Pattern statistics from training images (multiple-point geostatistics)
- Conditional entropy estimation via pattern matching
- Iterative maximum-entropy position selection
- Submodularity-based optimality guarantee (1 - 1/e approximation)

### Original Implementation (2016)

The original implementation was in MATLAB, using:
- Custom MPS (Multiple-Point Statistics) routines
- Variogram-based spatial analysis
- Batch processing of simulation experiments
- MAT file storage for large field realizations

### Legacy Data

The `legacy/` directory contains:
- `_0_RawDB/`: Raw experimental databases
- `_1_DB/`: Processed databases (MAT files, >70MB each)
- `_2_OutComes/`: Simulation results
- `_3_Analysis/`: Analysis outputs
- `__Codes/`: Original MATLAB code
- `docs/`: Original documentation

These files are preserved for reference but not used by the new application. Large MAT files are excluded from git via `.gitignore`.

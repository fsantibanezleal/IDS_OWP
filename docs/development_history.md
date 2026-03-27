# Development History

## Project History

### Origins (2014-2016)

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

Code and data stored in `legacy/` directory (preserved, not modified).

### v2.0.0 (2026-03-27) -- Complete Python Rewrite

Full reimplementation as a modern Python/FastAPI web application:

- **Backend**: Python 3.10+, FastAPI, numpy, scipy, scikit-learn
- **Frontend**: Vanilla HTML5/CSS3/JavaScript with canvas rendering
- **Architecture**: REST API + WebSocket for real-time adaptive sampling
- **Testing**: Comprehensive unit and integration tests
- **Documentation**: Exhaustive theory documentation with equations

Key improvements over the MATLAB version:
1. Interactive web-based visualization
2. Real-time step-by-step adaptive sampling via WebSocket
3. Multiple reconstruction methods (nearest, kriging, entropy-weighted)
4. Comprehensive performance metrics dashboard
5. Synthetic field generator with multiple geological patterns
6. Vectorized entropy computation for improved performance
7. Complete documentation with mathematical foundations

### Legacy Data

The `legacy/` directory contains:
- `_0_RawDB/`: Raw experimental databases
- `_1_DB/`: Processed databases (MAT files, >70MB each)
- `_2_OutComes/`: Simulation results
- `_3_Analysis/`: Analysis outputs
- `__Codes/`: Original MATLAB code
- `docs/`: Original documentation

These files are preserved for reference but not used by the new application. Large MAT files are excluded from git via `.gitignore`.

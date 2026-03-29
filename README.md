# OWP - Optimal Well Placement

Information-theoretic framework for optimal spatial sampling design in binary random fields.

---

## Motivation & Problem

In subsurface exploration, each measurement well costs millions. Placing wells optimally to maximize information while minimizing cost is a combinatorial optimization problem. Shannon information theory provides a principled framework: sample where entropy is highest.

---

## Mathematical Model

### Shannon Entropy

The information content of a random field X is measured by:

```
H(X) = -Sum p(x) * log_2(p(x))
```

### Optimal Next Sample

The next sample location maximizes the conditional entropy of the unsampled field:

```
f* = argmax H(X_bar_f)
```

where `X_bar_f` is the remaining unsampled field conditioned on all samples including candidate *f*.

### Resolvability Capacity

The information contribution of the k-th sample normalized by total field entropy:

```
C_k = I(f*_k) / H(X)
```

### Particle Size Distribution (Rosin-Rammler)

The cumulative retained fraction for the PSO-based grain size optimization:

```
R(x) = 1 - exp(-(x / x_0)^n)
```

where `x_0` is the characteristic grain size and `n` is the spread index.

---

## Overview

This application implements the AdSEMES (Adaptive Sequential Empirical Maximum Entropy Sampling) algorithm for optimal well placement in channelized geological reservoirs. It provides an interactive web interface for:

- Generating synthetic binary fields (channelized, branching, random)
- Comparing 9 sampling strategies (random, stratified, multiscale, oracle, adaptive, penalized, hybrid, multiscale-adaptive)
- Reconstructing fields from sparse samples (nearest neighbor, kriging, entropy-weighted)
- Evaluating performance (SNR, accuracy, resolvability capacity)

![AdSEMES Algorithm](docs/svg/adsemes_algorithm.svg)
![Sampling Comparison](docs/svg/sampling_comparison.svg)

---

## Frontend

![Frontend](docs/png/frontend.png)

---

## Architecture

![Architecture](docs/svg/architecture.svg)

---

## Demo

<video src="docs/video/Adaptive_sampling.mp4" controls width="100%"></video>

[![OWP AdSEMES — YouTube Demo](https://img.youtube.com/vi/KnTyQgQcpCQ/0.jpg)](https://youtu.be/KnTyQgQcpCQ)

---

## Features

- **9 sampling strategies** -- random, stratified, Latin hypercube, multiscale, oracle, AdSEMES, penalized, hybrid, multiscale-adaptive
- **Synthetic field generation** -- channelized, branching, and random binary fields with configurable complexity
- **3 reconstruction methods** -- nearest neighbor, kriging, entropy-weighted interpolation
- **Performance metrics** -- SNR, accuracy, F1-score, resolvability capacity curves
- **Entropy heatmaps** -- real-time visualization of conditional entropy landscapes
- **Parallel comparison** -- side-by-side strategy comparison at `/compare`
- **WebSocket streaming** -- live updates during adaptive sampling iterations
- **REST API** -- full control via HTTP endpoints with Swagger/ReDoc docs

---

## Quick Start

```bash
cd "d:/_Repos/_SCIENCE/IDS_OWP"
python -m venv .venv
source .venv/Scripts/activate   # Windows Git Bash
pip install fastapi "uvicorn[standard]" numpy scipy websockets pydantic scikit-learn
python -m uvicorn app.main:app --port 8008
```

Open http://localhost:8008 in your browser.

### Testing

```bash
source .venv/Scripts/activate
python tests/test_entropy.py
python tests/test_sampling.py
python tests/test_integration.py
```

---

## Project Structure

```
IDS_OWP/
├── app/
│   ├── __init__.py
│   ├── main.py                          # FastAPI application (port 8008)
│   ├── api/
│   │   ├── __init__.py
│   │   └── routes.py                    # REST + WebSocket endpoints
│   ├── simulation/
│   │   ├── __init__.py
│   │   ├── entropy.py                   # Shannon entropy computation
│   │   ├── sampling.py                  # 9 sampling schemes (random, stratified, AdSEMES, ...)
│   │   ├── field_generator.py           # Synthetic binary field generation
│   │   ├── inference.py                 # 3 reconstruction methods (NN, kriging, entropy-weighted)
│   │   ├── pattern_matching.py          # Training Image pattern statistics
│   │   └── metrics.py                   # Performance metrics (SNR, accuracy, F1, resolvability)
│   └── static/
│       ├── index.html                   # Main application page
│       ├── compare.html                 # Side-by-side strategy comparison page
│       ├── css/
│       │   └── style.css                # Dark theme stylesheet
│       └── js/
│           ├── app.js                   # Frontend application logic
│           ├── renderer.js              # Canvas rendering for fields and heatmaps
│           └── websocket.js             # WebSocket client for live updates
├── tests/
│   ├── __init__.py
│   ├── test_entropy.py                  # Entropy computation tests
│   ├── test_sampling.py                 # Sampling strategy tests
│   └── test_integration.py             # End-to-end integration tests
├── docs/
│   ├── architecture.md                  # System design documentation
│   ├── owp_theory.md                    # Information-theoretic foundations
│   ├── development_history.md           # Project evolution log
│   ├── references.md                    # Academic references
│   ├── png/
│   │   └── frontend.png                # Frontend screenshot
│   ├── svg/
│   │   ├── architecture.svg             # System architecture diagram
│   │   ├── adsemes_algorithm.svg        # AdSEMES algorithm flowchart
│   │   ├── sampling_comparison.svg      # Sampling strategy comparison
│   │   ├── information_theory.svg       # Information theory concepts
│   │   └── resolvability_curve.svg      # Resolvability capacity curve
│   └── video/
│       └── Adaptive_sampling.mp4        # Adaptive sampling demo video
├── legacy/                              # Original MATLAB implementation (preserved)
├── build.spec                           # PyInstaller spec file
├── Build_PyInstaller.ps1                # PowerShell build script
├── run_app.py                           # Uvicorn launcher with auto-browser
├── requirements.txt                     # Python dependencies
└── __init__.py
```

---

## API Documentation

### REST Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Serve the web application |
| `POST` | `/api/field/generate` | Generate a new synthetic binary field |
| `GET` | `/api/field/state` | Current field and sampling state |
| `POST` | `/api/sampling/run` | Run a sampling strategy to completion |
| `POST` | `/api/sampling/step` | Advance one adaptive sampling step |
| `POST` | `/api/reconstruction/run` | Reconstruct field from current samples |
| `GET` | `/api/metrics` | Performance metrics for current reconstruction |
| `POST` | `/api/compare` | Run all strategies in parallel and compare |

### WebSocket

| Path | Description |
|------|-------------|
| `WS /ws` | Real-time progress streaming during adaptive sampling |

---

## Port

**8008** -- http://localhost:8008

---

## Documentation

- [Architecture](docs/architecture.md) -- System design documentation
- [OWP Theory](docs/owp_theory.md) -- Information-theoretic foundations
- [Development History](docs/development_history.md) -- Project evolution log
- [References](docs/references.md) -- Academic references

## Background

Developed at the IDS Group, Universidad de Chile, under Fondecyt Grant 1140840 (PI: Prof. Jorge F. Silva). The mathematical framework connects Shannon information theory with geostatistical spatial sampling, providing a principled approach to well placement optimization with provable approximation guarantees.

---

## References

- Silva, J.F. & Mery, D. (2015). Optimal well placement using information-theoretic measures. *Mathematical Geosciences*, 47(2).
- Shannon, C.E. (1948). A mathematical theory of communication. *Bell System Technical Journal*, 27(3).
- Goovaerts, P. (1997). *Geostatistics for Natural Resources Evaluation*. Oxford University Press.
- Rosin, P. & Rammler, E. (1933). The laws governing the fineness of powdered coal. *Journal of the Institute of Fuel*, 7:29-36.
- Santibañez, F. et al. (2019). Adaptive entropy-based spatial sampling for binary fields. *Spatial Statistics*, 30.

See `docs/references.md` for the complete reference list.

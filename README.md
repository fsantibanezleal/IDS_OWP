# OWP - Optimal Well Placement

Information-theoretic framework for optimal spatial sampling design in binary random fields.

## Overview

This application implements the AdSEMES (Adaptive Sequential Empirical Maximum Entropy Sampling) algorithm for optimal well placement in channelized geological reservoirs. It provides an interactive web interface for:

- Generating synthetic binary fields (channelized, branching, random)
- Comparing 6 sampling strategies (random, stratified, multiscale, oracle, adaptive)
- Reconstructing fields from sparse samples (nearest neighbor, kriging, entropy-weighted)
- Evaluating performance (SNR, accuracy, resolvability capacity)

## Quick Start

```bash
cd "d:/_Repos/_SCIENCE/IDS_OWP"
python -m venv .venv
source .venv/Scripts/activate   # Windows Git Bash
pip install fastapi "uvicorn[standard]" numpy scipy websockets pydantic scikit-learn
python -m uvicorn app.main:app --port 8008
```

Open http://localhost:8008 in your browser.

## Project Structure

```
app/
  main.py              FastAPI application (port 8008)
  simulation/          Core computation modules
    entropy.py         Shannon entropy computation
    sampling.py        6 sampling schemes
    field_generator.py Synthetic binary field generation
    inference.py       3 reconstruction methods
    pattern_matching.py Training Image pattern statistics
    metrics.py         Performance metrics
  api/routes.py        REST + WebSocket endpoints
  static/              Frontend (HTML/CSS/JS)
tests/                 Unit and integration tests
docs/                  Theory, architecture, references
legacy/                Original MATLAB implementation (preserved)
```

## Testing

```bash
source .venv/Scripts/activate
python tests/test_entropy.py
python tests/test_sampling.py
python tests/test_integration.py
```

## Background

Developed at the IDS Group, Universidad de Chile, under Fondecyt Grant 1140840 (PI: Prof. Jorge F. Silva). The mathematical framework connects Shannon information theory with geostatistical spatial sampling, providing a principled approach to well placement optimization with provable approximation guarantees.

## References

See `docs/references.md` for the complete reference list.

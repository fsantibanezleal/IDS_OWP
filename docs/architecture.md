# OWP Architecture

## Overview

The Optimal Well Placement (OWP) application is a Python/FastAPI web application that implements an information-theoretic framework for optimal spatial sampling design in binary random fields.

## System Architecture

```
Browser (HTML/JS/CSS)
    |
    |-- REST API (POST /api/generate, /api/sample, /api/infer)
    |-- WebSocket (/api/ws) for real-time adaptive sampling
    |
FastAPI Application (port 8008)
    |
    |-- app/main.py          -- Application entry point
    |-- app/api/routes.py    -- API endpoints + WebSocket handler
    |
    |-- app/simulation/      -- Core computation engine
        |-- entropy.py           -- Shannon entropy (binary_entropy, conditional)
        |-- sampling.py          -- 6 sampling schemes
        |-- field_generator.py   -- Synthetic binary field generation
        |-- inference.py         -- 3 reconstruction methods
        |-- pattern_matching.py  -- Training Image pattern statistics
        |-- metrics.py           -- Performance evaluation
```

## Data Flow

1. **Generate**: User selects field type and size. Server generates a true field (ground truth) and a training image (prior knowledge). The true field is hidden from the user.

2. **Sample**: User selects a sampling method and number of samples. The server places wells and reveals true values at those positions.

3. **Reconstruct**: User selects a reconstruction method. The server estimates the full field from sparse samples.

4. **Evaluate**: Metrics are computed comparing reconstruction to ground truth.

## Key Design Decisions

- **Single-user state**: Application state is stored in module-level variables. This is appropriate for a research/demonstration tool, not production.
- **Synchronous computation**: Sampling and reconstruction run in the main thread. For adaptive sampling, a WebSocket provides step-by-step updates.
- **Canvas rendering**: The frontend renders fields as pixel grids on HTML5 canvas elements with custom colormaps.
- **No external database**: All data is in-memory during a session.

## Technology Stack

- **Backend**: Python 3.10+, FastAPI, uvicorn, numpy, scipy, scikit-learn
- **Frontend**: Vanilla HTML/CSS/JavaScript (no framework)
- **Communication**: REST API + WebSocket

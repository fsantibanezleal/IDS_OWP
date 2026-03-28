"""
FastAPI Application for Optimal Well Placement (OWP).

This is the main entry point for the OWP web application.
It serves the frontend static files and mounts the API routes.

Run with:
    uvicorn app.main:app --port 8008 --reload

Or:
    python -m uvicorn app.main:app --port 8008
"""

from pathlib import Path
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

from .api.routes import router as api_router

# Application metadata
app = FastAPI(
    title="Optimal Well Placement (OWP)",
    description=(
        "Information-theoretic framework for optimal spatial sampling "
        "design in binary random fields. Based on Shannon entropy "
        "maximization and the AdSEMES algorithm."
    ),
    version="2.0.0",
)

# Mount API routes (includes REST + WebSocket)
app.include_router(api_router)

# Static files directory
STATIC_DIR = Path(__file__).parent / "static"


# Mount static files for CSS and JS
app.mount("/css", StaticFiles(directory=str(STATIC_DIR / "css")), name="css")
app.mount("/js", StaticFiles(directory=str(STATIC_DIR / "js")), name="js")


@app.get("/")
async def root():
    """Serve the main frontend page."""
    return FileResponse(str(STATIC_DIR / "index.html"))


@app.get("/compare")
async def compare_page():
    """Serve the parallel comparison page."""
    return FileResponse(str(STATIC_DIR / "compare.html"))


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "ok", "app": "OWP", "version": "2.0.0"}

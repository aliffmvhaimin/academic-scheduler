"""FastAPI application entry point."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes.health import router as health_router
from app.api.routes.scheduling import router as scheduling_router


def create_app() -> FastAPI:
    """Creates and configures the FastAPI application."""
    app = FastAPI(
        title="Academic Task Scheduler API",
        description="FastAPI + DEAP Genetic Algorithm Scheduling Engine for Academic Tasks",
        version="1.0.0",
        docs_url="/docs",
        redoc_url="/redoc"
    )

    # Configure CORS for Flutter mobile client and local testing
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Include root health check
    app.include_router(health_router)

    # Include v1 API routes
    app.include_router(health_router, prefix="/api/v1")
    app.include_router(scheduling_router, prefix="/api/v1")

    return app


app = create_app()

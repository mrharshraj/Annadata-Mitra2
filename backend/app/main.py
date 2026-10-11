"""Annadata Mitra FastAPI entrypoint (Phase 3 foundation)."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .errors import register_error_handlers
from .logging_conf import RequestIdMiddleware, configure_logging
from .middleware.rate_limit import RateLimitMiddleware
from .routers.health import router as root_health_router
from .routers.v1 import v1


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)

    app = FastAPI(title=settings.app_name, version=settings.app_version)
    app.add_middleware(RateLimitMiddleware)
    app.add_middleware(RequestIdMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", "X-Request-Id"],
    )
    register_error_handlers(app)

    # Spec contract: GET /health -> {"status": "ok"}.
    app.include_router(root_health_router)
    app.include_router(v1)
    return app


app = create_app()

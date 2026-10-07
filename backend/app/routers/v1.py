"""Versioned API router. Feature routers (auth/location/farmers/fields/
crops/tasks/weather/advisories/ai/scanner) mount here in later phases."""

from fastapi import APIRouter

from .health import router as health_router
from .weather import router as weather_router
from .ai import router as ai_router
from .scanner import router as scanner_router

v1 = APIRouter(prefix="/api/v1")
v1.include_router(health_router)
v1.include_router(weather_router)
v1.include_router(ai_router)
v1.include_router(scanner_router)

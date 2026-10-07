"""Weather endpoints: normalized current/forecast + rule advisories.

Village lat/lon come from Supabase seed data; Flutter calls these through
the versioned API. Upstream failures surface as 502 with a stable shape —
never raw tracebacks or provider internals."""

import httpx
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel

from ..deps import get_current_user_id
from ..errors import AppError
from ..services.advisory import Advisory, build_advisories
from ..services.weather import (
    CurrentWeather,
    DayForecast,
    fetch_open_meteo,
    normalize_current,
    normalize_daily,
)

router = APIRouter(prefix="/weather", tags=["weather"])


class CurrentResponse(BaseModel):
    temperature_c: float
    humidity_pct: float | None
    wind_kmh: float | None
    rain_prob_pct: float | None
    summary: str


class DayResponse(BaseModel):
    date: str
    max_c: float | None
    min_c: float | None
    rain_mm: float | None
    rain_prob_pct: float | None


class AdvisoryResponse(BaseModel):
    kind: str
    severity: str
    title: str
    text: str


class ForecastResponse(BaseModel):
    current: CurrentResponse
    daily: list[DayResponse]
    advisories: list[AdvisoryResponse]


def _to_current(c: CurrentWeather) -> CurrentResponse:
    return CurrentResponse(
        temperature_c=c.temperature_c,
        humidity_pct=c.humidity_pct,
        wind_kmh=c.wind_kmh,
        rain_prob_pct=c.rain_prob_pct,
        summary=c.summary,
    )


def _to_day(d: DayForecast) -> DayResponse:
    return DayResponse(
        date=d.date,
        max_c=d.max_c,
        min_c=d.min_c,
        rain_mm=d.rain_mm,
        rain_prob_pct=d.rain_prob_pct,
    )


def _to_advisory(a: Advisory) -> AdvisoryResponse:
    return AdvisoryResponse(
        kind=a.kind, severity=a.severity, title=a.title, text=a.text
    )


async def _load(
    lat: float, lon: float
) -> tuple[CurrentWeather, list[DayForecast]]:
    try:
        payload = await fetch_open_meteo(lat, lon)
    except (httpx.HTTPError, ValueError, TimeoutError) as e:
        raise AppError(
            "Weather provider unavailable. Showing last cached data.",
            code="weather_unavailable",
            status_code=502,
        ) from e
    return normalize_current(payload), normalize_daily(payload)


@router.get("/current", response_model=CurrentResponse)
async def current(
    lat: float = Query(...),
    lon: float = Query(...),
    _: str = Depends(get_current_user_id),
) -> CurrentResponse:
    weather, _ = await _load(lat, lon)
    return _to_current(weather)


@router.get("/forecast", response_model=ForecastResponse)
async def forecast(
    lat: float = Query(...),
    lon: float = Query(...),
    _: str = Depends(get_current_user_id),
) -> ForecastResponse:
    weather, days = await _load(lat, lon)
    advisories = build_advisories(weather, days)
    return ForecastResponse(
        current=_to_current(weather),
        daily=[_to_day(d) for d in days],
        advisories=[_to_advisory(a) for a in advisories],
    )

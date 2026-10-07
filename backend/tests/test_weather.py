"""Weather service tests: normalization, rules, endpoint shape (mocked)."""

from fastapi.testclient import TestClient

from app.main import create_app
from app.services.advisory import build_advisories
from app.services.weather import (
    CurrentWeather,
    DayForecast,
    normalize_current,
    normalize_daily,
)

PAYLOAD = {
    "current": {
        "temperature_2m": 24.0,
        "relative_humidity_2m": 90,
        "weather_code": 61,
        "wind_speed_10m": 35.0,
    },
    "hourly": {"precipitation_probability": [80]},
    "daily": {
        "time": ["2026-10-07", "2026-10-08"],
        "temperature_2m_max": [27.0, 26.0],
        "temperature_2m_min": [14.0, 15.0],
        "precipitation_sum": [2.0, 18.0],
        "precipitation_probability_max": [40, 78],
    },
}


def test_normalize_current():
    c = normalize_current(PAYLOAD)
    assert c.temperature_c == 24.0
    assert c.humidity_pct == 90.0
    assert c.wind_kmh == 35.0
    assert c.rain_prob_pct == 80.0
    assert c.summary == "Light rain"


def test_normalize_daily():
    days = normalize_daily(PAYLOAD)
    assert len(days) == 2
    assert days[1].rain_mm == 18.0


def test_rules_fire_rain_wind_humidity():
    current = normalize_current(PAYLOAD)
    kinds = {a.kind for a in build_advisories(current, normalize_daily(PAYLOAD))}
    assert {"rain", "wind", "humidity"} <= kinds
    assert all(a.severity in ("info", "watch", "warning") for a in build_advisories(current, normalize_daily(PAYLOAD)))


def test_rules_calm_day_info_only():
    calm = CurrentWeather(
        temperature_c=24, humidity_pct=50, wind_kmh=5,
        rain_prob_pct=0, summary="Clear",
    )
    dry = [DayForecast(date="2026-10-07", max_c=27, min_c=14, rain_mm=0, rain_prob_pct=5)]
    advisories = build_advisories(calm, dry)
    assert [a.kind for a in advisories] == ["irrigation"]


def test_forecast_endpoint_shape(monkeypatch):
    async def fake_fetch(lat, lon):
        assert lat == 29.9 and lon == 76.9
        return PAYLOAD

    import app.routers.weather as weather_router

    monkeypatch.setattr(weather_router, "fetch_open_meteo", fake_fetch)

    import app.deps as deps

    async def fake_user(authorization=None, settings=None):
        return "user-1"

    app = create_app()
    app.dependency_overrides[deps.get_current_user_id] = fake_user
    res = TestClient(app).get("/api/v1/weather/forecast?lat=29.9&lon=76.9")
    assert res.status_code == 200
    body = res.json()
    assert body["current"]["temperature_c"] == 24.0
    assert len(body["daily"]) == 2
    assert body["advisories"]


def test_provider_failure_is_502(monkeypatch):
    async def boom(lat, lon):
        raise ValueError("down")

    import app.routers.weather as weather_router

    monkeypatch.setattr(weather_router, "fetch_open_meteo", boom)

    import app.deps as deps

    async def fake_user(authorization=None, settings=None):
        return "user-1"

    app = create_app()
    app.dependency_overrides[deps.get_current_user_id] = fake_user
    res = TestClient(app).get("/api/v1/weather/current?lat=29.9&lon=76.9")
    assert res.status_code == 502
    assert res.json()["code"] == "weather_unavailable"


def test_weather_requires_auth():
    res = TestClient(create_app()).get("/api/v1/weather/current?lat=1&lon=2")
    assert res.status_code in (401, 503)

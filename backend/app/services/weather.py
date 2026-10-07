"""Weather provider abstraction. Default provider is Open-Meteo
(keyless, farmer-safe); WEATHER_API_KEY remains reserved for a future
commercial provider without changing the router contract."""

from dataclasses import dataclass

import httpx

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"


@dataclass
class CurrentWeather:
    temperature_c: float
    humidity_pct: float | None
    wind_kmh: float | None
    rain_prob_pct: float | None
    summary: str


@dataclass
class DayForecast:
    date: str
    max_c: float | None
    min_c: float | None
    rain_mm: float | None
    rain_prob_pct: float | None


def _code_summary(code: int | None) -> str:
    mapping = {
        0: "Clear", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
        45: "Fog", 48: "Icy fog", 51: "Light drizzle", 53: "Drizzle",
        55: "Heavy drizzle", 61: "Light rain", 63: "Rain", 65: "Heavy rain",
        71: "Light snow", 73: "Snow", 75: "Heavy snow", 80: "Light showers",
        81: "Showers", 82: "Violent showers", 95: "Thunderstorm",
        96: "Storm with hail", 99: "Storm with hail",
    }
    return mapping.get(code or 0, "Unknown")


async def fetch_open_meteo(lat: float, lon: float) -> dict:
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m",
        "hourly": "precipitation_probability",
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max",
        "timezone": "auto",
        "forecast_days": 3,
    }
    async with httpx.AsyncClient(timeout=15) as client:
        res = await client.get(OPEN_METEO_URL, params=params)
        res.raise_for_status()
        data = res.json()
        if not isinstance(data, dict):
            raise ValueError("Unexpected weather payload.")
        return data


def normalize_current(payload: dict) -> CurrentWeather:
    current = payload.get("current") or {}
    hourly = payload.get("hourly") or {}
    probs = hourly.get("precipitation_probability") or []
    return CurrentWeather(
        temperature_c=float(current.get("temperature_2m", 0.0)),
        humidity_pct=_opt_float(current.get("relative_humidity_2m")),
        wind_kmh=_opt_float(current.get("wind_speed_10m")),
        rain_prob_pct=_opt_float(probs[0] if probs else None),
        summary=_code_summary(current.get("weather_code")),
    )


def normalize_daily(payload: dict) -> list[DayForecast]:
    daily = payload.get("daily") or {}
    dates = daily.get("time") or []
    out: list[DayForecast] = []
    for i, day in enumerate(dates):
        out.append(
            DayForecast(
                date=str(day),
                max_c=_at(daily.get("temperature_2m_max"), i),
                min_c=_at(daily.get("temperature_2m_min"), i),
                rain_mm=_at(daily.get("precipitation_sum"), i),
                rain_prob_pct=_at(
                    daily.get("precipitation_probability_max"), i
                ),
            )
        )
    return out


def _opt_float(v: object) -> float | None:
    return None if v is None else float(v)  # type: ignore[arg-type]


def _at(values: object, i: int) -> float | None:
    if not isinstance(values, list) or i >= len(values):
        return None
    v = values[i]
    return None if v is None else float(v)

"""Deterministic agricultural rules over normalized weather.

Rules are intentionally transparent (thresholds in code, no ML claims);
the AI layer (Phase 9) adds contextual explanations on top."""

from dataclasses import dataclass

from .weather import CurrentWeather, DayForecast


@dataclass
class Advisory:
    kind: str  # rain | heat | cold | wind | humidity | irrigation
    severity: str  # info | watch | warning
    title: str
    text: str


def build_advisories(
    current: CurrentWeather, days: list[DayForecast]
) -> list[Advisory]:
    out: list[Advisory] = []
    tomorrow = days[1] if len(days) > 1 else (days[0] if days else None)

    if tomorrow and (tomorrow.rain_mm or 0) >= 10:
        out.append(
            Advisory(
                kind="rain",
                severity="warning",
                title="Postpone irrigation",
                text=(
                    f"{tomorrow.rain_mm:.0f} mm rain expected "
                    f"{tomorrow.date}; irrigating now risks waterlogging."
                ),
            )
        )
    if current.temperature_c >= 40:
        out.append(
            Advisory(
                kind="heat",
                severity="warning",
                title="Heat stress risk",
                text="Above 40°C: irrigate early morning, mulch exposed soil.",
            )
        )
    if current.temperature_c <= 5:
        out.append(
            Advisory(
                kind="cold",
                severity="watch",
                title="Cold night risk",
                text="Near 5°C or below: protect seedlings, delay sowing.",
            )
        )
    if (current.wind_kmh or 0) >= 30:
        out.append(
            Advisory(
                kind="wind",
                severity="watch",
                title="Strong wind",
                text="Above 30 km/h: pause spraying, secure young plants.",
            )
        )
    if (current.humidity_pct or 0) >= 85:
        out.append(
            Advisory(
                kind="humidity",
                severity="watch",
                title="Disease-favourable humidity",
                text="Above 85% humidity: scout for fungal disease and pests.",
            )
        )
    if not out:
        out.append(
            Advisory(
                kind="irrigation",
                severity="info",
                title="Conditions normal",
                text="No weather warnings. Follow the regular irrigation plan.",
            )
        )
    return out

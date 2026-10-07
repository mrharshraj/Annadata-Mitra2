"""AI provider abstraction. No invented certainty: the stub refuses to
answer when no provider key is configured, and every reply carries a
confidence note. Gemini REST is implemented; it is only constructed when
GEMINI_API_KEY exists in the server environment (never in Flutter)."""

from dataclasses import dataclass
from typing import Protocol

import httpx

GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "gemini-2.0-flash:generateContent"
)


@dataclass
class AiReply:
    text: str
    low_confidence: bool = False


@dataclass
class FarmContext:
    farmer_name: str | None = None
    village: str | None = None
    crop: str | None = None
    crop_stage: str | None = None
    weather_summary: str | None = None
    language: str = "hi"


def system_prompt(ctx: FarmContext) -> str:
    parts = ["You are Annadata Mitra, a practical farming assistant."]
    if ctx.farmer_name:
        parts.append(f"Farmer: {ctx.farmer_name}.")
    if ctx.village:
        parts.append(f"Village: {ctx.village}.")
    if ctx.crop:
        stage = f" ({ctx.crop_stage})" if ctx.crop_stage else ""
        parts.append(f"Crop: {ctx.crop}{stage}.")
    if ctx.weather_summary:
        parts.append(f"Weather: {ctx.weather_summary}.")
    parts.append(
        "Reply in "
        + ("Hindi" if ctx.language == "hi" else "English")
        + ", farmer-friendly, concise, actionable. "
        "State uncertainty clearly; never invent facts."
    )
    return " ".join(parts)


class AiProvider(Protocol):
    async def complete(self, message: str, ctx: FarmContext) -> AiReply:
        ...


class StubProvider:
    """Honest fallback: raises instead of hallucinating without a key."""

    async def complete(self, message: str, ctx: FarmContext) -> AiReply:
        raise RuntimeError(
            "AI provider not configured (GEMINI_API_KEY missing)."
        )


class GeminiProvider:
    def __init__(self, api_key: str):
        self._key = api_key

    async def complete(self, message: str, ctx: FarmContext) -> AiReply:
        body = {
            "system_instruction": {"parts": [{"text": system_prompt(ctx)}]},
            "contents": [{"parts": [{"text": message}]}],
        }
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                res = await client.post(
                    GEMINI_URL,
                    params={"key": self._key},
                    json=body,
                )
                res.raise_for_status()
                data = res.json()
        except (httpx.HTTPError, ValueError, TimeoutError) as e:
            raise RuntimeError(f"AI provider error: {e}") from e
        try:
            text = data["candidates"][0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError, TypeError) as e:
            raise RuntimeError("AI provider returned an empty reply.") from e
        return AiReply(text=str(text).strip())


def select_provider(api_key: str | None) -> AiProvider:
    if api_key:
        return GeminiProvider(api_key)
    return StubProvider()

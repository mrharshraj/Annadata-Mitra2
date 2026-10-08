"""Crop image analysis. Validation first (MIME + size), then vision AI.

Without a provider key the service refuses honestly (503) rather than
inventing a diagnosis. Confidence is always returned and the UI must
surface uncertainty when it is low."""

from dataclasses import dataclass

import httpx

ALLOWED_MIME = {"image/jpeg", "image/png", "image/webp"}
MAX_BYTES = 8 * 1024 * 1024

GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "gemini-3.8-flash:generateContent"
)


@dataclass
class ScanResult:
    detected_crop: str | None
    detected_issue: str | None
    confidence: float
    notes: str


def validate_upload(mime: str, size: int) -> None:
    if mime not in ALLOWED_MIME:
        raise ValueError(f"Unsupported image type: {mime}.")
    if size <= 0 or size > MAX_BYTES:
        raise ValueError("Image must be non-empty and under 8 MB.")


def scan_prompt() -> str:
    return (
        "You are a plant pathologist assistant. Look at this crop photo and "
        "reply with: most likely crop, most likely visible issue (or 'none "
        "visible'), a confidence score between 0 and 1, and one practical "
        "next step. If unsure, say so and keep confidence below 0.5. "
        "Format: CROP: ... ISSUE: ... CONFIDENCE: ... NEXT: ..."
    )


def parse_reply(text: str) -> ScanResult:
    crop = issue = nxt = None
    conf = 0.0
    for line in text.splitlines():
        head, sep, tail = line.partition(":")
        if not sep:
            continue
        key, val = head.strip().upper(), tail.strip()
        if key == "CROP":
            crop = val or None
        elif key == "ISSUE":
            issue = None if val.lower().startswith("none") else (val or None)
        elif key == "CONFIDENCE":
            try:
                conf = max(0.0, min(1.0, float(val)))
            except ValueError:
                conf = 0.0
        elif key == "NEXT":
            nxt = val or None
    return ScanResult(
        detected_crop=crop,
        detected_issue=issue,
        confidence=conf,
        notes=nxt or "Consult a local agronomist to confirm.",
    )


async def analyze_with_gemini(
    api_key: str, image_bytes: bytes, mime: str
) -> ScanResult:
    import base64

    body = {
        "system_instruction": {"parts": [{"text": scan_prompt()}]},
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": mime,
                            "data": base64.b64encode(image_bytes).decode(),
                        }
                    }
                ]
            }
        ],
    }
    try:
        async with httpx.AsyncClient(timeout=60) as client:
            res = await client.post(
                GEMINI_URL, params={"key": api_key}, json=body
            )
            res.raise_for_status()
            data = res.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"]
    except (httpx.HTTPError, ValueError, TimeoutError) as e:
        raise RuntimeError(f"Vision provider error: {e}") from e
    except (KeyError, IndexError, TypeError) as e:
        raise RuntimeError("Vision provider returned no result.") from e
    return parse_reply(str(text))

"""One-shot Gemini key validity check. Prints status only, never the key."""

import os
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]

sys.path.insert(0, str(ROOT / "backend"))

import httpx
from dotenv import load_dotenv

load_dotenv(ROOT / "backend" / ".env")
key = os.environ.get("GEMINI_API_KEY", "")
if not key:
    print("GEMINI: MISSING")
    sys.exit(2)

body = {"contents": [{"parts": [{"text": "Reply with exactly: OK"}]}]}
try:
    res = httpx.post(
        "https://generativelanguage.googleapis.com/v1beta/models/"
        "gemini-3.8-flash:generateContent",
        params={"key": key},
        json=body,
        timeout=30,
    )
    data = res.json()
    if res.status_code != 200:
        err = data.get("error", {})
        import re

        msg = re.sub(r"key=[^&\s]+", "key=<redacted>", str(err.get("message")))
        print(f"GEMINI: HTTP {res.status_code} code={err.get('code')} "
              f"status={err.get('status')} msg={msg[:200]}")
        print("GEMINI: INVALID")
        sys.exit(3)
    text = data["candidates"][0]["content"]["parts"][0]["text"]
    print(f"GEMINI: HTTP {res.status_code}, reply_len={len(str(text))}")
    print("GEMINI: VALID")
except SystemExit:
    raise
except Exception as e:
    print(f"GEMINI: ERROR {type(e).__name__}")
    sys.exit(1)

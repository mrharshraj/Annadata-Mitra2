"""List Gemini models available to the configured key. Names only."""

import os
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]

import httpx
from dotenv import load_dotenv

load_dotenv(ROOT / "backend" / ".env")
key = os.environ.get("GEMINI_API_KEY", "")
if not key:
    print("GEMINI MODELS: MISSING KEY")
    sys.exit(2)

res = httpx.get(
    "https://generativelanguage.googleapis.com/v1beta/models",
    params={"key": key},
    timeout=30,
)
data = res.json()
if res.status_code != 200:
    err = data.get("error", {})
    print(f"GEMINI MODELS: HTTP {res.status_code} status={err.get('status')}")
    sys.exit(3)
names = [
    m.get("name", "").replace("models/", "")
    for m in data.get("models", [])
    if "generateContent" in (m.get("supportedGenerationMethods") or [])
]
print(f"GEMINI MODELS: HTTP 200, {len(names)} generateContent models")
for n in sorted(names)[:15]:
    print(f"MODEL: {n}")

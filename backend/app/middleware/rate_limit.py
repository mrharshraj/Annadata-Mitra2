"""Minimal fixed-window rate limiter for expensive endpoints (AI, scanner).

No new dependencies. Per-client-IP + path counters with a 60s window;
excess requests get a 429 JSON envelope (same shape as error handlers).
Designed for single-instance Render free tier; a multi-instance deploy
would need a shared store (noted in code, not implemented).
"""

import time

from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

# path prefix -> (max requests per 60s window)
LIMITS = {
    "/api/v1/ai/": 20,
    "/api/v1/scanner/": 10,
}

WINDOW_SECONDS = 60.0


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, limits: dict | None = None):
        super().__init__(app)
        self.limits = limits if limits is not None else LIMITS
        self._hits: dict[str, list[float]] = {}

    def _limited_prefix(self, path: str) -> str | None:
        for prefix in self.limits:
            if path.startswith(prefix):
                return prefix
        return None

    async def dispatch(self, request: Request, call_next):
        prefix = self._limited_prefix(request.url.path)
        if prefix is None:
            return await call_next(request)
        client = request.client.host if request.client else "unknown"
        key = f"{client}|{prefix}"
        now = time.monotonic()
        window = [t for t in self._hits.get(key, []) if now - t < WINDOW_SECONDS]
        if len(window) >= self.limits[prefix]:
            return JSONResponse(
                status_code=429,
                content={
                    "detail": "Too many requests. Try again shortly.",
                    "code": "rate_limited",
                },
            )
        window.append(now)
        self._hits[key] = window
        return await call_next(request)

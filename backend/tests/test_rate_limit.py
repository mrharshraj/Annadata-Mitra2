"""Rate limiter tests: expensive paths throttled, others untouched."""

from fastapi.testclient import TestClient

from app.main import create_app
from app.middleware.rate_limit import RateLimitMiddleware


def test_ai_path_throttled_after_limit():
    app = create_app()
    client = TestClient(app, raise_server_exceptions=False)
    statuses = [
        client.post("/api/v1/ai/chat", json={"message": "hi"}).status_code
        for _ in range(25)
    ]
    assert 429 in statuses
    # Health (cheap path) never throttled.
    assert client.get("/health").status_code == 200


def test_custom_limits_respected():
    from fastapi import FastAPI

    inner = FastAPI()

    @inner.get("/api/v1/ai/ping")
    def ping():
        return {"ok": True}

    inner.add_middleware(RateLimitMiddleware, limits={"/api/v1/ai/": 2})
    client = TestClient(inner, raise_server_exceptions=False)
    assert client.get("/api/v1/ai/ping").status_code == 200
    assert client.get("/api/v1/ai/ping").status_code == 200
    third = client.get("/api/v1/ai/ping")
    assert third.status_code == 429
    assert third.json()["code"] == "rate_limited"

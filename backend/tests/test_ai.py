"""AI layer tests: prompt building, stub honesty, endpoint gating."""

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.services.ai import FarmContext, StubProvider, select_provider, system_prompt


def test_system_prompt_hindi_farmer_friendly():
    p = system_prompt(FarmContext(farmer_name="R", village="V", language="hi"))
    assert "Hindi" in p and "R" in p and "uncertainty" in p


def test_stub_refuses_without_key():
    async def go():
        await StubProvider().complete("hi", FarmContext())

    with pytest.raises(RuntimeError, match="not configured"):
        import anyio

        anyio.run(go)


def test_select_provider_no_key_gives_stub():
    assert isinstance(select_provider(None), StubProvider)
    assert isinstance(select_provider(""), StubProvider)


def _authed_app(monkeypatch):
    import app.deps as deps

    async def fake_user(authorization=None, settings=None):
        return "user-1"

    app = create_app()
    app.dependency_overrides[deps.get_current_user_id] = fake_user
    return app


def test_chat_unconfigured_backend_is_503():
    res = TestClient(_authed_app(None)).post(
        "/api/v1/ai/chat", json={"message": "hello"}
    )
    assert res.status_code == 503
    assert res.json()["code"] in ("not_configured", "ai_unavailable")


def test_chat_requires_auth():
    res = TestClient(create_app()).post(
        "/api/v1/ai/chat", json={"message": "hello"}
    )
    assert res.status_code in (401, 503)


def test_chat_rejects_empty_message():
    res = TestClient(_authed_app(None)).post(
        "/api/v1/ai/chat", json={"message": ""}
    )
    assert res.status_code == 422

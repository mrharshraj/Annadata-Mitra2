"""Admin router tests: gating without a live backend."""

from fastapi.testclient import TestClient

from app.main import create_app


def _authed_app():
    import app.deps as deps

    async def fake_user(authorization=None, settings=None):
        return "user-1"

    app = create_app()
    app.dependency_overrides[deps.get_current_user_id] = fake_user
    return app


def test_admin_unconfigured_is_503():
    res = TestClient(_authed_app()).get("/api/v1/admin/overview")
    assert res.status_code == 503


def test_admin_requires_auth():
    res = TestClient(create_app()).get("/api/v1/admin/overview")
    assert res.status_code in (401, 503)


def test_admin_email_parsing(monkeypatch):
    from app.config import Settings

    monkeypatch.setenv("ADMIN_EMAILS", "Admin@Example.in , ops@example.in")
    s = Settings()
    assert s.admin_email_set == {"admin@example.in", "ops@example.in"}

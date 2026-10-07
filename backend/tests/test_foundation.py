"""Phase 3 foundation tests: health contract, config gating, error shape."""

from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


def _client() -> TestClient:
    return TestClient(create_app())


def test_health_root_contract():
    res = _client().get("/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


def test_health_v1_alias():
    res = _client().get("/api/v1/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


def test_request_id_header_present():
    res = _client().get("/health")
    assert res.headers.get("x-request-id")


def test_unknown_route_is_json_envelope():
    res = _client().get("/nope")
    assert res.status_code == 404
    assert "detail" in res.json()


def test_settings_require_backend_without_secrets():
    s = Settings()
    assert s.backend_configured is False
    try:
        s.require_backend()
    except RuntimeError as e:
        assert "SUPABASE_URL" in str(e)
    else:
        raise AssertionError("require_backend should raise when unconfigured")


def test_settings_accepts_env_values(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "test-key")
    monkeypatch.setenv("SUPABASE_JWT_SECRET", "test-secret")
    s = Settings()
    assert s.backend_configured is True
    s.require_backend()

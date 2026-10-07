"""Scanner tests: upload validation, reply parsing, endpoint gating."""

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.services.scanner import parse_reply, validate_upload


def test_validate_allows_jpeg_png_webp():
    for mime in ("image/jpeg", "image/png", "image/webp"):
        validate_upload(mime, 100)


def test_validate_rejects_bad_mime_and_size():
    with pytest.raises(ValueError, match="Unsupported"):
        validate_upload("image/gif", 100)
    with pytest.raises(ValueError, match="8 MB"):
        validate_upload("image/jpeg", 9 * 1024 * 1024)
    with pytest.raises(ValueError, match="non-empty"):
        validate_upload("image/jpeg", 0)


def test_parse_reply_structured():
    r = parse_reply(
        "CROP: Wheat\nISSUE: brown blight\nCONFIDENCE: 0.82\nNEXT: Spray X"
    )
    assert r.detected_crop == "Wheat"
    assert r.detected_issue == "brown blight"
    assert r.confidence == pytest.approx(0.82)
    assert "Spray" in r.notes


def test_parse_reply_none_issue_and_garbage_confidence():
    r = parse_reply("CROP: Mustard\nISSUE: none visible\nCONFIDENCE: high")
    assert r.detected_issue is None
    assert r.confidence == 0.0


def _authed_app():
    import app.deps as deps

    async def fake_user(authorization=None, settings=None):
        return "user-1"

    app = create_app()
    app.dependency_overrides[deps.get_current_user_id] = fake_user
    return app


def test_analyze_rejects_foreign_prefix(monkeypatch):
    from app.config import get_settings

    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "test-key")
    monkeypatch.setenv("SUPABASE_JWT_SECRET", "test-secret")
    get_settings.cache_clear()
    try:
        res = TestClient(_authed_app()).post(
            "/api/v1/scanner/analyze",
            json={"image_path": "someone-else/a.jpg"},
        )
    finally:
        get_settings.cache_clear()
    assert res.status_code == 403
    assert res.json()["code"] == "forbidden"


def test_analyze_requires_auth():
    res = TestClient(create_app()).post(
        "/api/v1/scanner/analyze", json={"image_path": "u/a.jpg"}
    )
    assert res.status_code in (401, 503)


def test_analyze_rejects_empty_path():
    res = TestClient(_authed_app()).post(
        "/api/v1/scanner/analyze", json={"image_path": ""}
    )
    assert res.status_code == 422

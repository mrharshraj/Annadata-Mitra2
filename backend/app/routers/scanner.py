"""Crop scanner: Storage upload verification + vision analysis + record.

POST /api/v1/scanner/analyze {image_path, field_id?}:
- caller must own the storage object prefix and the field (if given);
- image downloaded server-side, validated, analyzed;
- result row written to crop_scans; low confidence flagged, never hidden.
"""

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from ..config import Settings, get_settings
from ..database import get_service_client
from ..deps import get_current_user_id
from ..errors import AppError
from ..services.scanner import analyze_with_gemini, validate_upload

router = APIRouter(prefix="/scanner", tags=["scanner"])


class AnalyzeRequest(BaseModel):
    image_path: str = Field(min_length=1, max_length=500)
    field_id: str | None = None


class AnalyzeResponse(BaseModel):
    scan_id: str
    detected_crop: str | None
    detected_issue: str | None
    confidence: float
    notes: str


def _owned_prefix(user_id: str, path: str) -> bool:
    return path == f"{user_id}" or path.startswith(f"{user_id}/")


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(
    req: AnalyzeRequest,
    user_id: str = Depends(get_current_user_id),
    settings: Settings = Depends(get_settings),
) -> AnalyzeResponse:
    if not settings.backend_configured:
        raise AppError("Backend not configured.", code="not_configured", status_code=503)
    if not _owned_prefix(user_id, req.image_path):
        raise AppError("Not your image.", code="forbidden", status_code=403)
    if req.field_id is not None:
        db = get_service_client()
        try:
            own = (
                db.table("fields")
                .select("id")
                .eq("id", req.field_id)
                .eq("profile_id", user_id)
                .execute()
            )
        except Exception as e:
            raise AppError("Field lookup failed.", code="lookup_failed", status_code=502) from e
        if not own.data:
            raise AppError("Field not found.", code="not_found", status_code=404)

    db = get_service_client()
    try:
        stored = db.storage.from_("crop-scans").download(req.image_path)
    except Exception as e:
        raise AppError("Could not fetch image.", code="fetch_failed", status_code=502) from e
    mime = "image/jpeg"
    try:
        validate_upload(mime, len(stored))
    except ValueError as e:
        raise AppError(str(e), code="invalid_image", status_code=400) from e

    if not settings.gemini_api_key:
        raise AppError(
            "Vision analysis not configured.", code="ai_unavailable", status_code=503
        )
    try:
        result = await analyze_with_gemini(settings.gemini_api_key, stored, mime)
    except RuntimeError as e:
        raise AppError(str(e), code="ai_unavailable", status_code=503) from e

    try:
        row = (
            db.table("crop_scans")
            .insert({
                "profile_id": user_id,
                "field_id": req.field_id,
                "image_path": req.image_path,
                "detected_crop": result.detected_crop,
                "detected_issue": result.detected_issue,
                "confidence": result.confidence,
                "analysis": {"notes": result.notes},
                "status": "done",
            })
            .execute()
        )
    except Exception as e:
        raise AppError("Could not save scan.", code="persist_failed", status_code=502) from e

    return AnalyzeResponse(
        scan_id=row.data[0]["id"],
        detected_crop=result.detected_crop,
        detected_issue=result.detected_issue,
        confidence=result.confidence,
        notes=result.notes,
    )

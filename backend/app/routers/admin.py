"""Essential admin overview: aggregate counts via the service role.

Access requires BOTH a valid user session AND an allowlisted admin email
(ADMIN_EMAILS, comma-separated, server env). Never exposed to Flutter
beyond the authenticated admin user. Read-only: no mutations here."""

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from ..config import Settings, get_settings
from ..database import get_service_client
from ..deps import get_current_user_id
from ..errors import AppError

router = APIRouter(prefix="/admin", tags=["admin"])


class AdminOverview(BaseModel):
    profiles: int
    fields: int
    tasks: int
    scans: int
    conversations: int


def _admin_emails(settings: Settings) -> set[str]:
    return settings.admin_email_set


async def _caller_email(user_id: str) -> str | None:
    try:
        client = get_service_client()
        res = client.auth.admin.get_user_by_id(user_id)
        user = res.user
        return (user.email or "").lower() if user else None
    except Exception:
        return None


@router.get("/overview", response_model=AdminOverview)
async def overview(
    user_id: str = Depends(get_current_user_id),
    settings: Settings = Depends(get_settings),
) -> AdminOverview:
    if not settings.backend_configured:
        raise AppError("Backend not configured.", code="not_configured", status_code=503)
    email = await _caller_email(user_id)
    if email is None or email not in _admin_emails(settings):
        raise AppError("Admin only.", code="forbidden", status_code=403)
    db = get_service_client()
    try:
        counts = {}
        for table in (
            "profiles",
            "fields",
            "tasks",
            "crop_scans",
            "ai_conversations",
        ):
            res = db.table(table).select("id", count="exact").limit(0).execute()
            counts[table] = res.count or 0
    except Exception as e:
        raise AppError("Admin query failed.", code="lookup_failed", status_code=502) from e
    return AdminOverview(
        profiles=counts["profiles"],
        fields=counts["fields"],
        tasks=counts["tasks"],
        scans=counts["crop_scans"],
        conversations=counts["ai_conversations"],
    )

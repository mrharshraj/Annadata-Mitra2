"""Authentication verification for Supabase-issued JWTs.

Flow: Flutter (Supabase Auth session) -> Authorization: Bearer <token>
-> FastAPI verifies via the Supabase Auth API -> user id available to
routers. Returns 401 for bad tokens, 503 when the backend itself is
unconfigured (never leaks key material in errors).
"""

from fastapi import Depends, Header, HTTPException, status

from .config import Settings, get_settings
from .database import get_service_client


async def get_current_user_id(
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
) -> str:
    if not settings.backend_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Backend not configured.",
        )
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token.",
        )
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token.",
        )
    try:
        client = get_service_client()
        user_response = client.auth.get_user(token)
        user = user_response.user
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token.",
        ) from None
    if user is None or not user.id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token.",
        )
    return user.id

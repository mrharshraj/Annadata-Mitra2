"""Server-side Supabase client (service role). Never exposed to Flutter."""

from functools import lru_cache

from supabase import Client, create_client

from .config import get_settings


@lru_cache
def get_service_client() -> Client:
    """Create the privileged client. Raises RuntimeError when unconfigured."""
    settings = get_settings()
    settings.require_backend()
    return create_client(settings.supabase_url, settings.supabase_service_role_key)

"""Annadata Mitra backend settings — environment only, never committed secrets.

Required in production (see backend/.env.example):
  SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_JWT_SECRET
Optional: SUPABASE_ANON_KEY, AI/weather/search keys (later phases),
  API_HOST, API_PORT, CORS_ORIGINS, LOG_LEVEL.
"""

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "annadata-mitra-api"
    app_version: str = "0.1.0"
    log_level: str = "INFO"

    supabase_url: str = Field(default="", alias="SUPABASE_URL")
    supabase_service_role_key: str = Field(
        default="", alias="SUPABASE_SERVICE_ROLE_KEY"
    )
    supabase_jwt_secret: str = Field(default="", alias="SUPABASE_JWT_SECRET")

    # Later-phase provider keys (empty = provider disabled, honest 503).
    gemini_api_key: str = Field(default="", alias="GEMINI_API_KEY")

    api_host: str = Field(default="0.0.0.0", alias="API_HOST")
    api_port: int = Field(default=8000, alias="API_PORT")
    cors_origins: str = Field(
        default="http://localhost:3000", alias="CORS_ORIGINS"
    )

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def backend_configured(self) -> bool:
        return bool(
            self.supabase_url
            and self.supabase_service_role_key
            and self.supabase_jwt_secret
        )

    def require_backend(self) -> None:
        if not self.backend_configured:
            raise RuntimeError(
                "Backend not configured: set SUPABASE_URL, "
                "SUPABASE_SERVICE_ROLE_KEY and SUPABASE_JWT_SECRET."
            )


@lru_cache
def get_settings() -> Settings:
    return Settings()

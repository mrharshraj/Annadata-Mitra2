"""Conversational AI: context-aware reply + Supabase chat persistence.

POST /api/v1/ai/chat {message, conversation_id?, context?} -> assistant
reply stored alongside the user message in ai_conversations/ai_messages
(owner RLS applies to direct client access; the service role writes here
after verifying the caller owns the conversation).
"""

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from ..config import Settings, get_settings
from ..database import get_service_client
from ..deps import get_current_user_id
from ..errors import AppError
from ..services.ai import FarmContext, select_provider

router = APIRouter(prefix="/ai", tags=["ai"])


class ChatContext(BaseModel):
    farmer_name: str | None = None
    village: str | None = None
    crop: str | None = None
    crop_stage: str | None = None
    weather_summary: str | None = None
    language: str = "hi"


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    conversation_id: str | None = None
    context: ChatContext = ChatContext()


class ChatResponse(BaseModel):
    reply: str
    conversation_id: str
    low_confidence: bool = False


@router.post("/chat", response_model=ChatResponse)
async def chat(
    req: ChatRequest,
    user_id: str = Depends(get_current_user_id),
    settings: Settings = Depends(get_settings),
) -> ChatResponse:
    if not settings.backend_configured:
        raise AppError(
            "Backend not configured.", code="not_configured", status_code=503
        )

    provider = select_provider(settings.gemini_api_key or None)
    ctx = FarmContext(**req.context.model_dump())
    try:
        reply = await provider.complete(req.message, ctx)
    except RuntimeError as e:
        raise AppError(str(e), code="ai_unavailable", status_code=503) from e

    db = get_service_client()
    try:
        conv_id = req.conversation_id
        if conv_id is None:
            conv = (
                db.table("ai_conversations")
                .insert({"profile_id": user_id, "language": ctx.language})
                .execute()
            )
            conv_id = conv.data[0]["id"]
        else:
            owned = (
                db.table("ai_conversations")
                .select("id")
                .eq("id", conv_id)
                .eq("profile_id", user_id)
                .execute()
            )
            if not owned.data:
                raise AppError("Conversation not found.", code="not_found", status_code=404)
        db.table("ai_messages").insert([
            {"conversation_id": conv_id, "role": "user", "content": req.message},
            {"conversation_id": conv_id, "role": "assistant", "content": reply.text},
        ]).execute()
    except AppError:
        raise
    except Exception as e:
        raise AppError("Could not save chat.", code="persist_failed", status_code=502) from e

    return ChatResponse(
        reply=reply.text, conversation_id=conv_id, low_confidence=reply.low_confidence
    )

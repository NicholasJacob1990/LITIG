from fastapi import APIRouter, Depends, HTTPException

from backend.auth import get_current_user
from backend.services.redis_service import redis_service

router = APIRouter(prefix="/health", tags=["Health Checks"])


@router.get("/redis")
async def redis_health(user: dict = Depends(get_current_user)):
    """Verifica a saúde do serviço Redis."""
    health = await redis_service.health_check()

    if health["status"] == "healthy":
        return health
    else:
        raise HTTPException(status_code=503, detail=health)

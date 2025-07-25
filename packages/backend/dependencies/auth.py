"""
Authentication dependencies for FastAPI
Extracts user information and plan from JWT tokens
"""
import jwt
import os
from fastapi import HTTPException, Depends, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional, Dict, Any

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> Dict[str, Any]:
    """
    Extract user information from JWT token.
    Includes plan information from claims.
    """
    try:
        token = credentials.credentials
        
        # Decode JWT token
        # In production, use proper JWT validation with Supabase public key
        payload = jwt.decode(
            token, 
            options={"verify_signature": False}  # For development only
        )
        
        user_data = {
            "id": payload.get("sub"),
            "email": payload.get("email"),
            "plan": payload.get("plan", "FREE"),  # Extract plan from claims
            "role": payload.get("role", "client"),
            "user_metadata": payload.get("user_metadata", {})
        }
        
        if not user_data["id"]:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        return user_data
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
    except Exception as e:
        raise HTTPException(status_code=401, detail="Authentication failed")


async def get_user_plan(
    current_user: Dict[str, Any] = Depends(get_current_user)
) -> str:
    """Extract only the user's plan from JWT claims."""
    return current_user.get("plan", "FREE")


async def require_plan(required_plans: list):
    """
    Create a dependency that requires specific plans.
    Usage: Depends(require_plan(["VIP", "ENTERPRISE"]))
    """
    def check_plan(current_user: Dict[str, Any] = Depends(get_current_user)):
        user_plan = current_user.get("plan", "FREE")
        if user_plan not in required_plans:
            raise HTTPException(
                status_code=403, 
                detail=f"Plan {user_plan} not authorized. Required: {required_plans}"
            )
        return current_user
    return check_plan


async def get_admin_user(
    current_user: Dict[str, Any] = Depends(get_current_user)
) -> Dict[str, Any]:
    """Require admin role."""
    if current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user 
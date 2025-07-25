from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from pydantic import BaseModel, field_validator
from typing import List, Optional
from datetime import datetime
from sqlalchemy import func

from database import get_async_session
from models.premium_criteria import PremiumCriteria, Client
from schemas.premium_criteria import (
    PremiumCriteriaResponse, PremiumCriteriaCreate, PremiumCriteriaUpdate,
    ClientResponse, ClientUpdate, ClientPlanUpdate, ClientPlan
)

router = APIRouter(prefix="/admin", tags=["admin"])

# Existing Premium Criteria routes
@router.get("/premium-criteria/", response_model=List[PremiumCriteriaResponse])
async def list_premium_criteria(session: AsyncSession = Depends(get_async_session)):
    """List all premium criteria."""
    result = await session.execute(select(PremiumCriteria).order_by(PremiumCriteria.id))
    criteria = result.scalars().all()
    return criteria

@router.post("/premium-criteria/", response_model=PremiumCriteriaResponse, status_code=status.HTTP_201_CREATED)
async def create_premium_criteria(
    criteria: PremiumCriteriaCreate,
    session: AsyncSession = Depends(get_async_session)
):
    """Create new premium criteria."""
    db_criteria = PremiumCriteria(**criteria.model_dump())
    session.add(db_criteria)
    await session.commit()
    await session.refresh(db_criteria)
    return db_criteria

@router.get("/premium-criteria/{criteria_id}", response_model=PremiumCriteriaResponse)
async def get_premium_criteria(
    criteria_id: int,
    session: AsyncSession = Depends(get_async_session)
):
    """Get premium criteria by ID."""
    criteria = await session.get(PremiumCriteria, criteria_id)
    if not criteria:
        raise HTTPException(status_code=404, detail="Premium criteria not found")
    return criteria

@router.put("/premium-criteria/{criteria_id}", response_model=PremiumCriteriaResponse)
async def update_premium_criteria(
    criteria_id: int,
    criteria_update: PremiumCriteriaUpdate,
    session: AsyncSession = Depends(get_async_session)
):
    """Update premium criteria."""
    criteria = await session.get(PremiumCriteria, criteria_id)
    if not criteria:
        raise HTTPException(status_code=404, detail="Premium criteria not found")
    
    update_data = criteria_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(criteria, field, value)
    
    await session.commit()
    await session.refresh(criteria)
    return criteria

@router.delete("/premium-criteria/{criteria_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_premium_criteria(
    criteria_id: int,
    session: AsyncSession = Depends(get_async_session)
):
    """Delete premium criteria."""
    criteria = await session.get(PremiumCriteria, criteria_id)
    if not criteria:
        raise HTTPException(status_code=404, detail="Premium criteria not found")
    
    await session.delete(criteria)
    await session.commit()
    return

# New Client Plan Management routes
@router.get("/clients/", response_model=List[ClientResponse])
async def list_clients(
    plan: Optional[ClientPlan] = None,
    limit: int = 100,
    offset: int = 0,
    session: AsyncSession = Depends(get_async_session)
):
    """List all clients with optional plan filter."""
    query = select(Client).where(Client.role == 'client')
    
    if plan:
        query = query.where(Client.plan == plan.value)
    
    query = query.offset(offset).limit(limit).order_by(Client.created_at.desc())
    
    result = await session.execute(query)
    clients = result.scalars().all()
    return clients

@router.get("/clients/{client_id}", response_model=ClientResponse)
async def get_client(
    client_id: str,
    session: AsyncSession = Depends(get_async_session)
):
    """Get client by ID."""
    client = await session.get(Client, client_id)
    if not client or client.role != 'client':
        raise HTTPException(status_code=404, detail="Client not found")
    return client

@router.patch("/clients/{client_id}", response_model=ClientResponse)
async def update_client(
    client_id: str,
    client_update: ClientUpdate,
    session: AsyncSession = Depends(get_async_session)
):
    """Update client information including plan."""
    client = await session.get(Client, client_id)
    if not client or client.role != 'client':
        raise HTTPException(status_code=404, detail="Client not found")
    
    update_data = client_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == 'plan' and value:
            setattr(client, field, value.value)
        elif value is not None:
            setattr(client, field, value)
    
    await session.commit()
    await session.refresh(client)
    return client

@router.patch("/clients/{client_id}/plan", response_model=ClientResponse)
async def update_client_plan(
    client_id: str,
    plan_update: ClientPlanUpdate,
    session: AsyncSession = Depends(get_async_session)
):
    """Update client plan specifically (VIP/ENTERPRISE upgrade/downgrade)."""
    client = await session.get(Client, client_id)
    if not client or client.role != 'client':
        raise HTTPException(status_code=404, detail="Client not found")
    
    # Update the plan
    client.plan = plan_update.plan.value
    
    await session.commit()
    await session.refresh(client)
    return client

@router.get("/clients/stats/plans")
async def get_client_plan_stats(session: AsyncSession = Depends(get_async_session)):
    """Get statistics about client plans distribution."""
    
    # Count clients by plan
    result = await session.execute(
        select(Client.plan, func.count(Client.id).label('count'))
        .where(Client.role == 'client')
        .group_by(Client.plan)
    )
    
    plan_counts = {row.plan: row.count for row in result}
    
    # Ensure all plans are represented
    stats = {
        "FREE": plan_counts.get("FREE", 0),
        "VIP": plan_counts.get("VIP", 0),
        "ENTERPRISE": plan_counts.get("ENTERPRISE", 0),
        "total": sum(plan_counts.values())
    }
    
    return stats 
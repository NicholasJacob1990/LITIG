"""
Contextual Offers API Routes
Endpoints for managing contextual offers based on allocation types

This module provides REST API endpoints for:
- Creating contextual offers based on allocation types
- Retrieving offers with filtering by allocation type and status
- Responding to offers with acceptance/rejection
- Getting insights and recommendations for offer performance
- Analytics and maintenance operations

Endpoints:
- POST /api/contextual-offers/ - Create contextual offer
- GET /api/contextual-offers/lawyer/{lawyer_id} - Get offers for lawyer
- GET /api/contextual-offers/{offer_id} - Get specific offer
- POST /api/contextual-offers/{offer_id}/respond - Respond to offer
- GET /api/contextual-offers/insights/{lawyer_id} - Get insights
- GET /api/contextual-offers/recommendations/{lawyer_id} - Get recommendations
- GET /api/contextual-offers/analytics/overview - Get analytics (admin only)
- POST /api/contextual-offers/maintenance/expire-old - Expire old offers (admin only)
- GET /api/contextual-offers/health - Health check
"""

from typing import Dict, List, Optional, Any
from datetime import datetime
import logging
from dataclasses import dataclass
from enum import Enum

from ..services.contextual_offers_service import (
    ContextualOffersService,
    AllocationType,
    OfferStatus,
    ContextualOfferData,
    OfferInsights,
    OfferRecommendation
)

logger = logging.getLogger(__name__)


# Request/Response Models
@dataclass
class CreateContextualOfferRequest:
    """Request model for creating contextual offers"""
    case_id: str
    target_lawyer_id: str
    allocation_type: AllocationType
    delegation_details: Optional[Dict[str, Any]] = None
    partnership_details: Optional[Dict[str, Any]] = None
    match_details: Optional[Dict[str, Any]] = None
    custom_deadline: Optional[datetime] = None
    priority_level: Optional[int] = None


@dataclass
class RespondToOfferRequest:
    """Request model for responding to offers"""
    response: str  # "accepted" or "declined"
    response_notes: Optional[str] = None
    negotiation_terms: Optional[Dict[str, Any]] = None


@dataclass
class ContextualOfferResponse:
    """Response model for contextual offers"""
    id: str
    case_id: str
    target_lawyer_id: str
    allocation_type: AllocationType
    priority_level: int
    response_deadline: datetime
    context_metadata: Dict[str, Any]
    status: OfferStatus
    created_at: datetime
    updated_at: datetime
    delegation_details: Optional[Dict[str, Any]]
    partnership_details: Optional[Dict[str, Any]]
    match_details: Optional[Dict[str, Any]]


class ContextualOffersAPI:
    """API handler for contextual offers endpoints"""
    
    def __init__(self, supabase_client):
        self.service = ContextualOffersService(supabase_client)
        
    async def create_contextual_offer(
        self,
        request: CreateContextualOfferRequest,
        current_user: Dict[str, Any]
    ) -> ContextualOfferResponse:
        """
        Create a new contextual offer
        
        Creates an offer based on the allocation type with appropriate context and metadata.
        The system automatically sets deadlines and priority levels based on the allocation type.
        """
        try:
            # Create contextual offer
            offer = await self.service.create_contextual_offer(
                case_id=request.case_id,
                target_lawyer_id=request.target_lawyer_id,
                allocation_type=request.allocation_type,
                delegation_details=request.delegation_details,
                partnership_details=request.partnership_details,
                match_details=request.match_details,
                custom_deadline=request.custom_deadline,
                priority_level=request.priority_level
            )
            
            return ContextualOfferResponse(
                id=offer.id,
                case_id=offer.case_id,
                target_lawyer_id=offer.target_lawyer_id,
                allocation_type=offer.allocation_type,
                priority_level=offer.priority_level,
                response_deadline=offer.response_deadline,
                context_metadata=offer.context_metadata,
                status=offer.status,
                created_at=offer.created_at,
                updated_at=offer.updated_at,
                delegation_details=offer.delegation_details,
                partnership_details=offer.partnership_details,
                match_details=offer.match_details
            )
            
        except Exception as e:
            logger.error(f"Error creating contextual offer: {str(e)}")
            raise

    async def get_contextual_offers_for_lawyer(
        self,
        lawyer_id: str,
        allocation_type: Optional[AllocationType] = None,
        status: Optional[OfferStatus] = None,
        limit: int = 50,
        offset: int = 0,
        current_user: Dict[str, Any] = None
    ) -> List[ContextualOfferResponse]:
        """
        Get contextual offers for a specific lawyer
        
        Returns offers filtered by allocation type and status, with proper pagination.
        Includes contextual metadata based on the allocation type.
        """
        try:
            # Validate access (user can only access their own offers or if they have admin role)
            if current_user and current_user["id"] != lawyer_id and current_user.get("role") != "admin":
                raise ValueError("Access denied")
            
            offers = await self.service.get_contextual_offers_for_lawyer(
                lawyer_id=lawyer_id,
                allocation_type=allocation_type,
                status=status,
                limit=limit,
                offset=offset
            )
            
            return [
                ContextualOfferResponse(
                    id=offer.id,
                    case_id=offer.case_id,
                    target_lawyer_id=offer.target_lawyer_id,
                    allocation_type=offer.allocation_type,
                    priority_level=offer.priority_level,
                    response_deadline=offer.response_deadline,
                    context_metadata=offer.context_metadata,
                    status=offer.status,
                    created_at=offer.created_at,
                    updated_at=offer.updated_at,
                    delegation_details=offer.delegation_details,
                    partnership_details=offer.partnership_details,
                    match_details=offer.match_details
                )
                for offer in offers
            ]
            
        except Exception as e:
            logger.error(f"Error getting contextual offers for lawyer {lawyer_id}: {str(e)}")
            raise

    async def get_contextual_offer(
        self,
        offer_id: str,
        current_user: Dict[str, Any]
    ) -> ContextualOfferResponse:
        """
        Get a specific contextual offer by ID
        
        Returns detailed information about a specific offer including all contextual metadata.
        """
        try:
            offer = await self.service.get_contextual_offer_by_id(offer_id)
            
            if not offer:
                raise ValueError("Offer not found")
            
            # Validate access
            if (current_user["id"] != offer.target_lawyer_id and 
                current_user.get("role") != "admin"):
                raise ValueError("Access denied")
            
            return ContextualOfferResponse(
                id=offer.id,
                case_id=offer.case_id,
                target_lawyer_id=offer.target_lawyer_id,
                allocation_type=offer.allocation_type,
                priority_level=offer.priority_level,
                response_deadline=offer.response_deadline,
                context_metadata=offer.context_metadata,
                status=offer.status,
                created_at=offer.created_at,
                updated_at=offer.updated_at,
                delegation_details=offer.delegation_details,
                partnership_details=offer.partnership_details,
                match_details=offer.match_details
            )
            
        except Exception as e:
            logger.error(f"Error getting contextual offer {offer_id}: {str(e)}")
            raise

    async def respond_to_contextual_offer(
        self,
        offer_id: str,
        request: RespondToOfferRequest,
        current_user: Dict[str, Any]
    ) -> ContextualOfferResponse:
        """
        Respond to a contextual offer
        
        Accept or decline an offer with optional notes and negotiation terms.
        The response is validated against the offer's deadline and current status.
        """
        try:
            # Validate response
            if request.response not in ["accepted", "declined"]:
                raise ValueError("Response must be 'accepted' or 'declined'")
            
            offer = await self.service.respond_to_contextual_offer(
                offer_id=offer_id,
                lawyer_id=current_user["id"],
                response=request.response,
                response_notes=request.response_notes,
                negotiation_terms=request.negotiation_terms
            )
            
            return ContextualOfferResponse(
                id=offer.id,
                case_id=offer.case_id,
                target_lawyer_id=offer.target_lawyer_id,
                allocation_type=offer.allocation_type,
                priority_level=offer.priority_level,
                response_deadline=offer.response_deadline,
                context_metadata=offer.context_metadata,
                status=offer.status,
                created_at=offer.created_at,
                updated_at=offer.updated_at,
                delegation_details=offer.delegation_details,
                partnership_details=offer.partnership_details,
                match_details=offer.match_details
            )
            
        except Exception as e:
            logger.error(f"Error responding to contextual offer {offer_id}: {str(e)}")
            raise

    async def get_contextual_offer_insights(
        self,
        lawyer_id: str,
        allocation_type: Optional[AllocationType] = None,
        days_back: int = 30,
        current_user: Dict[str, Any] = None
    ) -> List[OfferInsights]:
        """
        Get contextual offer insights for a lawyer
        
        Returns analytics and performance metrics for offers, broken down by allocation type.
        Includes acceptance rates, response times, and priority distributions.
        """
        try:
            # Validate access
            if current_user and current_user["id"] != lawyer_id and current_user.get("role") != "admin":
                raise ValueError("Access denied")
            
            insights = await self.service.get_contextual_offer_insights(
                lawyer_id=lawyer_id,
                allocation_type=allocation_type,
                days_back=days_back
            )
            
            return insights
            
        except Exception as e:
            logger.error(f"Error getting contextual offer insights for lawyer {lawyer_id}: {str(e)}")
            raise

    async def get_contextual_offer_recommendations(
        self,
        lawyer_id: str,
        allocation_type: AllocationType,
        current_user: Dict[str, Any]
    ) -> List[OfferRecommendation]:
        """
        Get contextual offer recommendations for a lawyer
        
        Returns actionable recommendations for improving offer performance based on
        historical data and performance patterns.
        """
        try:
            # Validate access
            if current_user["id"] != lawyer_id and current_user.get("role") != "admin":
                raise ValueError("Access denied")
            
            recommendations = await self.service.get_contextual_offer_recommendations(
                lawyer_id=lawyer_id,
                allocation_type=allocation_type
            )
            
            return recommendations
            
        except Exception as e:
            logger.error(f"Error getting contextual offer recommendations for lawyer {lawyer_id}: {str(e)}")
            raise

    async def get_contextual_offers_analytics(
        self,
        current_user: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Get general contextual offers analytics
        
        Returns system-wide analytics about offers performance by allocation type.
        Available only for admin users.
        """
        try:
            # Validate admin access
            if current_user.get("role") != "admin":
                raise ValueError("Admin access required")
            
            analytics = await self.service.get_contextual_offers_analytics()
            
            return {
                "analytics": analytics,
                "generated_at": datetime.now().isoformat(),
                "total_allocation_types": len(analytics)
            }
            
        except Exception as e:
            logger.error(f"Error getting contextual offers analytics: {str(e)}")
            raise

    async def expire_old_offers(
        self,
        current_user: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Expire old pending offers
        
        Maintenance endpoint to mark expired offers as expired.
        Should be called periodically by a cron job.
        """
        try:
            # Validate admin access
            if current_user.get("role") != "admin":
                raise ValueError("Admin access required")
            
            expired_count = await self.service.expire_old_offers()
            
            return {
                "expired_offers": expired_count,
                "processed_at": datetime.now().isoformat(),
                "message": f"Successfully expired {expired_count} offers"
            }
            
        except Exception as e:
            logger.error(f"Error expiring old offers: {str(e)}")
            raise

    def health_check(self) -> Dict[str, str]:
        """Health check endpoint for contextual offers service"""
        return {
            "status": "healthy",
            "service": "contextual-offers",
            "timestamp": datetime.now().isoformat()
        }


# Usage Example:
"""
# Initialize the API handler
api = ContextualOffersAPI(supabase_client)

# Create a contextual offer
offer_request = CreateContextualOfferRequest(
    case_id="case-123",
    target_lawyer_id="lawyer-456",
    allocation_type=AllocationType.PLATFORM_MATCH_DIRECT,
    match_details={
        "algorithm_version": "2.7",
        "score": 0.95,
        "factors": {"expertise": 0.9, "experience": 0.8}
    },
    priority_level=5
)

offer_response = await api.create_contextual_offer(offer_request, current_user)

# Get offers for a lawyer
offers = await api.get_contextual_offers_for_lawyer(
    lawyer_id="lawyer-456",
    allocation_type=AllocationType.PLATFORM_MATCH_DIRECT,
    status=OfferStatus.PENDING,
    current_user=current_user
)

# Respond to an offer
response_request = RespondToOfferRequest(
    response="accepted",
    response_notes="Aceito o caso",
    negotiation_terms={"hourly_rate": 200}
)

response = await api.respond_to_contextual_offer(
    offer_id="offer-789",
    request=response_request,
    current_user=current_user
)
""" 
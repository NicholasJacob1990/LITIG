"""
Contextual Offers Service
Manages offers based on allocation types with context-specific logic
"""

from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta
from uuid import UUID
import logging
from dataclasses import dataclass, asdict
from enum import Enum
import json

logger = logging.getLogger(__name__)


class AllocationType(str, Enum):
    """Types of case allocation"""
    PLATFORM_MATCH_DIRECT = "platform_match_direct"
    PLATFORM_MATCH_PARTNERSHIP = "platform_match_partnership"
    PARTNERSHIP_PROACTIVE_SEARCH = "partnership_proactive_search"
    PARTNERSHIP_PLATFORM_SUGGESTION = "partnership_platform_suggestion"
    INTERNAL_DELEGATION = "internal_delegation"


class OfferStatus(str, Enum):
    """Offer statuses"""
    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    EXPIRED = "expired"
    WITHDRAWN = "withdrawn"


@dataclass
class ContextualOfferData:
    """Data structure for contextual offer information"""
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
    
    # Contextual fields
    delegation_details: Optional[Dict[str, Any]] = None
    partnership_details: Optional[Dict[str, Any]] = None
    match_details: Optional[Dict[str, Any]] = None


@dataclass
class OfferInsights:
    """Analytics and insights for contextual offers"""
    allocation_type: AllocationType
    total_offers: int
    acceptance_rate: float
    avg_response_time_hours: float
    priority_distribution: Dict[str, int]
    top_rejection_reasons: List[Dict[str, Any]]
    performance_trend: List[Dict[str, Any]]


@dataclass
class OfferRecommendation:
    """Recommendation for offer optimization"""
    recommendation_type: str
    title: str
    description: str
    action_required: bool
    priority: int


class ContextualOffersService:
    """Service for managing contextual offers"""

    def __init__(self, supabase_client):
        self.supabase = supabase_client
        self.table_name = "offers"

    async def create_contextual_offer(
        self,
        case_id: str,
        target_lawyer_id: str,
        allocation_type: AllocationType,
        delegation_details: Optional[Dict[str, Any]] = None,
        partnership_details: Optional[Dict[str, Any]] = None,
        match_details: Optional[Dict[str, Any]] = None,
        custom_deadline: Optional[datetime] = None,
        priority_level: Optional[int] = None,
    ) -> ContextualOfferData:
        """
        Create a contextual offer based on allocation type
        
        Args:
            case_id: ID of the case
            target_lawyer_id: ID of the target lawyer
            allocation_type: Type of allocation
            delegation_details: Details for internal delegation
            partnership_details: Details for partnership offers
            match_details: Details for algorithmic matches
            custom_deadline: Custom response deadline
            priority_level: Custom priority level
        
        Returns:
            ContextualOfferData: Created offer data
        """
        try:
            # Prepare offer data
            offer_data = {
                "case_id": case_id,
                "target_lawyer_id": target_lawyer_id,
                "allocation_type": allocation_type.value,
                "status": OfferStatus.PENDING.value,
                "delegation_details": delegation_details or {},
                "partnership_details": partnership_details or {},
                "match_details": match_details or {},
            }
            
            # Add custom deadline if provided
            if custom_deadline:
                offer_data["response_deadline"] = custom_deadline.isoformat()
                
            # Add custom priority if provided
            if priority_level:
                offer_data["priority_level"] = priority_level

            # Create offer (trigger will set context_metadata automatically)
            result = self.supabase.table(self.table_name).insert(offer_data).execute()
            
            if not result.data:
                raise ValueError("Failed to create contextual offer")
                
            offer_record = result.data[0]
            
            # Convert to ContextualOfferData
            contextual_offer = ContextualOfferData(
                id=offer_record["id"],
                case_id=offer_record["case_id"],
                target_lawyer_id=offer_record["target_lawyer_id"],
                allocation_type=AllocationType(offer_record["allocation_type"]),
                priority_level=offer_record["priority_level"],
                response_deadline=datetime.fromisoformat(offer_record["response_deadline"]),
                context_metadata=offer_record["context_metadata"],
                status=OfferStatus(offer_record["status"]),
                created_at=datetime.fromisoformat(offer_record["created_at"]),
                updated_at=datetime.fromisoformat(offer_record["updated_at"]),
                delegation_details=offer_record.get("delegation_details"),
                partnership_details=offer_record.get("partnership_details"),
                match_details=offer_record.get("match_details")
            )
            
            # Log contextual offer creation
            logger.info(f"Created contextual offer {contextual_offer.id} for case {case_id} with allocation type {allocation_type.value}")
            
            return contextual_offer
            
        except Exception as e:
            logger.error(f"Error creating contextual offer: {str(e)}")
            raise

    async def get_contextual_offers_for_lawyer(
        self,
        lawyer_id: str,
        allocation_type: Optional[AllocationType] = None,
        status: Optional[OfferStatus] = None,
        limit: int = 50,
        offset: int = 0
    ) -> List[ContextualOfferData]:
        """Get contextual offers for a specific lawyer"""
        try:
            query = self.supabase.table(self.table_name).select("*").eq("target_lawyer_id", lawyer_id)
            
            # Apply filters
            if allocation_type:
                query = query.eq("allocation_type", allocation_type.value)
            if status:
                query = query.eq("status", status.value)
                
            # Apply pagination and ordering
            query = query.order("created_at", desc=True).range(offset, offset + limit - 1)
            
            result = query.execute()
            
            offers = []
            for record in result.data:
                offer = ContextualOfferData(
                    id=record["id"],
                    case_id=record["case_id"],
                    target_lawyer_id=record["target_lawyer_id"],
                    allocation_type=AllocationType(record["allocation_type"]),
                    priority_level=record["priority_level"],
                    response_deadline=datetime.fromisoformat(record["response_deadline"]),
                    context_metadata=record["context_metadata"],
                    status=OfferStatus(record["status"]),
                    created_at=datetime.fromisoformat(record["created_at"]),
                    updated_at=datetime.fromisoformat(record["updated_at"]),
                    delegation_details=record.get("delegation_details"),
                    partnership_details=record.get("partnership_details"),
                    match_details=record.get("match_details")
                )
                offers.append(offer)
                
            return offers
            
        except Exception as e:
            logger.error(f"Error getting contextual offers for lawyer {lawyer_id}: {str(e)}")
            raise

    async def respond_to_contextual_offer(
        self,
        offer_id: str,
        lawyer_id: str,
        response: str,  # "accepted" or "declined"
        response_notes: Optional[str] = None,
        negotiation_terms: Optional[Dict[str, Any]] = None
    ) -> ContextualOfferData:
        """Respond to a contextual offer"""
        try:
            # Validate response
            if response not in ["accepted", "declined"]:
                raise ValueError("Response must be 'accepted' or 'declined'")
            
            # Get current offer to validate
            current_offer = await self.get_contextual_offer_by_id(offer_id)
            if not current_offer:
                raise ValueError(f"Offer {offer_id} not found")
                
            if current_offer.target_lawyer_id != lawyer_id:
                raise ValueError("Lawyer not authorized to respond to this offer")
                
            if current_offer.status != OfferStatus.PENDING:
                raise ValueError(f"Offer is not pending (current status: {current_offer.status})")
                
            # Check if offer has expired
            if current_offer.response_deadline < datetime.now():
                # Mark as expired
                await self._update_offer_status(offer_id, OfferStatus.EXPIRED)
                raise ValueError("Offer has expired")
            
            # Update offer status and metadata
            update_data = {
                "status": response,
                "updated_at": datetime.now().isoformat()
            }
            
            # Add response metadata
            context_metadata = current_offer.context_metadata.copy()
            context_metadata.update({
                "response_timestamp": datetime.now().isoformat(),
                "response_notes": response_notes,
                "negotiation_terms": negotiation_terms or {}
            })
            update_data["context_metadata"] = json.dumps(context_metadata)
            
            # Update offer
            result = self.supabase.table(self.table_name).update(update_data).eq("id", offer_id).execute()
            
            if not result.data:
                raise ValueError("Failed to update offer")
                
            updated_offer = result.data[0]
            
            # Convert to ContextualOfferData
            contextual_offer = ContextualOfferData(
                id=updated_offer["id"],
                case_id=updated_offer["case_id"],
                target_lawyer_id=updated_offer["target_lawyer_id"],
                allocation_type=AllocationType(updated_offer["allocation_type"]),
                priority_level=updated_offer["priority_level"],
                response_deadline=datetime.fromisoformat(updated_offer["response_deadline"]),
                context_metadata=updated_offer["context_metadata"],
                status=OfferStatus(updated_offer["status"]),
                created_at=datetime.fromisoformat(updated_offer["created_at"]),
                updated_at=datetime.fromisoformat(updated_offer["updated_at"]),
                delegation_details=updated_offer.get("delegation_details"),
                partnership_details=updated_offer.get("partnership_details"),
                match_details=updated_offer.get("match_details")
            )
            
            # Log response
            logger.info(f"Lawyer {lawyer_id} responded '{response}' to offer {offer_id}")
            
            return contextual_offer
            
        except Exception as e:
            logger.error(f"Error responding to contextual offer {offer_id}: {str(e)}")
            raise

    async def get_contextual_offer_by_id(self, offer_id: str) -> Optional[ContextualOfferData]:
        """Get a specific contextual offer by ID"""
        try:
            result = self.supabase.table(self.table_name).select("*").eq("id", offer_id).execute()
            
            if not result.data:
                return None
                
            record = result.data[0]
            
            return ContextualOfferData(
                id=record["id"],
                case_id=record["case_id"],
                target_lawyer_id=record["target_lawyer_id"],
                allocation_type=AllocationType(record["allocation_type"]),
                priority_level=record["priority_level"],
                response_deadline=datetime.fromisoformat(record["response_deadline"]),
                context_metadata=record["context_metadata"],
                status=OfferStatus(record["status"]),
                created_at=datetime.fromisoformat(record["created_at"]),
                updated_at=datetime.fromisoformat(record["updated_at"]),
                delegation_details=record.get("delegation_details"),
                partnership_details=record.get("partnership_details"),
                match_details=record.get("match_details")
            )
            
        except Exception as e:
            logger.error(f"Error getting contextual offer {offer_id}: {str(e)}")
            return None

    async def get_contextual_offer_insights(
        self,
        lawyer_id: str,
        allocation_type: Optional[AllocationType] = None,
        days_back: int = 30
    ) -> List[OfferInsights]:
        """Get insights about contextual offers for a lawyer"""
        try:
            # Use the database function
            result = self.supabase.rpc(
                "get_contextual_offer_insights",
                {
                    "p_user_id": lawyer_id,
                    "p_allocation_type": allocation_type.value if allocation_type else None,
                    "p_days_back": days_back
                }
            ).execute()
            
            insights = []
            for record in result.data:
                insight = OfferInsights(
                    allocation_type=AllocationType(record["allocation_type"]),
                    total_offers=record["total_offers"],
                    acceptance_rate=record["acceptance_rate"],
                    avg_response_time_hours=record["avg_response_time_hours"],
                    priority_distribution=record["priority_distribution"],
                    top_rejection_reasons=record["top_rejection_reasons"],
                    performance_trend=record["performance_trend"]
                )
                insights.append(insight)
                
            return insights
            
        except Exception as e:
            logger.error(f"Error getting contextual offer insights for lawyer {lawyer_id}: {str(e)}")
            raise

    async def get_contextual_offer_recommendations(
        self,
        lawyer_id: str,
        allocation_type: AllocationType
    ) -> List[OfferRecommendation]:
        """Get recommendations for improving offer performance"""
        try:
            # Use the database function
            result = self.supabase.rpc(
                "get_contextual_offer_recommendations",
                {
                    "p_user_id": lawyer_id,
                    "p_allocation_type": allocation_type.value
                }
            ).execute()
            
            recommendations = []
            for record in result.data:
                recommendation = OfferRecommendation(
                    recommendation_type=record["recommendation_type"],
                    title=record["title"],
                    description=record["description"],
                    action_required=record["action_required"],
                    priority=record["priority"]
                )
                recommendations.append(recommendation)
                
            return recommendations
            
        except Exception as e:
            logger.error(f"Error getting contextual offer recommendations for lawyer {lawyer_id}: {str(e)}")
            raise

    async def get_contextual_offers_analytics(self) -> Dict[str, Any]:
        """Get general analytics about contextual offers"""
        try:
            result = self.supabase.table("contextual_offers_analytics").select("*").execute()
            
            analytics = {}
            for record in result.data:
                analytics[record["allocation_type"]] = {
                    "total_offers": record["total_offers"],
                    "accepted_offers": record["accepted_offers"],
                    "declined_offers": record["declined_offers"],
                    "pending_offers": record["pending_offers"],
                    "avg_acceptance_time_hours": record["avg_acceptance_time_hours"],
                    "avg_priority_level": record["avg_priority_level"],
                    "expired_offers": record["expired_offers"]
                }
                
            return analytics
            
        except Exception as e:
            logger.error(f"Error getting contextual offers analytics: {str(e)}")
            raise

    async def expire_old_offers(self) -> int:
        """Mark expired offers as expired"""
        try:
            result = self.supabase.table(self.table_name).update({
                "status": OfferStatus.EXPIRED.value,
                "updated_at": datetime.now().isoformat()
            }).eq("status", OfferStatus.PENDING.value).lt("response_deadline", datetime.now().isoformat()).execute()
            
            expired_count = len(result.data) if result.data else 0
            logger.info(f"Expired {expired_count} old offers")
            
            return expired_count
            
        except Exception as e:
            logger.error(f"Error expiring old offers: {str(e)}")
            raise

    async def _update_offer_status(self, offer_id: str, status: OfferStatus) -> None:
        """Update offer status"""
        try:
            self.supabase.table(self.table_name).update({
                "status": status.value,
                "updated_at": datetime.now().isoformat()
            }).eq("id", offer_id).execute()
            
        except Exception as e:
            logger.error(f"Error updating offer status: {str(e)}") 
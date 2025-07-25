from fastapi import APIRouter, HTTPException, Depends
from typing import Dict, Any, List, Optional
import logging
from datetime import datetime, timedelta
import asyncio
from pydantic import BaseModel

from ..schemas.firm_schemas import (
    EnrichedFirmResponse,
    FirmTransparencyReport,
    FirmTeamData,
    FirmFinancialSummary
)
from ..data.mock_enriched_firms_data import ENRICHED_FIRMS_MOCK_DATA

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/enriched-firms", tags=["enriched-firms"])

@router.get("/firm/{firm_id}/complete", response_model=EnrichedFirmResponse)
async def get_enriched_firm_complete(firm_id: str):
    """
    Retrieve complete enriched data for a specific law firm.
    
    This endpoint provides comprehensive information about a law firm including:
    - Basic firm information and contact details
    - Team composition (partners, associates, specialists)
    - Certifications and awards
    - Financial information
    - Data quality and transparency metrics
    - Performance statistics
    """
    try:
        logger.info(f"Fetching complete enriched data for firm: {firm_id}")
        
        if firm_id not in ENRICHED_FIRMS_MOCK_DATA:
            logger.warning(f"Firm not found: {firm_id}")
            raise HTTPException(status_code=404, detail=f"Firm {firm_id} not found")
        
        firm_data = ENRICHED_FIRMS_MOCK_DATA[firm_id]
        logger.info(f"Successfully retrieved data for firm: {firm_id}")
        
        return EnrichedFirmResponse(**firm_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching enriched firm data for {firm_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/firm/{firm_id}/refresh", response_model=EnrichedFirmResponse)
async def refresh_enriched_firm_data(firm_id: str):
    """
    Refresh enriched data for a specific law firm.
    
    This endpoint triggers a fresh data collection from all available sources
    and returns the updated enriched firm profile.
    """
    try:
        logger.info(f"Refreshing enriched data for firm: {firm_id}")
        
        if firm_id not in ENRICHED_FIRMS_MOCK_DATA:
            raise HTTPException(status_code=404, detail=f"Firm {firm_id} not found")
        
        # Simulate data refresh process
        await asyncio.sleep(0.5)  # Simulate API calls
        
        firm_data = ENRICHED_FIRMS_MOCK_DATA[firm_id].copy()
        
        # Update timestamps to show refresh
        current_time = datetime.utcnow().isoformat() + "Z"
        firm_data["last_consolidated"] = current_time
        
        for source_name, source_info in firm_data["data_sources"].items():
            source_info["last_updated"] = current_time
            # Slightly improve quality scores on refresh
            source_info["quality_score"] = min(1.0, source_info["quality_score"] + 0.01)
        
        # Recalculate overall quality score
        total_quality = sum(source["quality_score"] for source in firm_data["data_sources"].values())
        firm_data["overall_quality_score"] = total_quality / len(firm_data["data_sources"])
        
        logger.info(f"Successfully refreshed data for firm: {firm_id}")
        
        return EnrichedFirmResponse(**firm_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error refreshing enriched firm data for {firm_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/firm/{firm_id}/team", response_model=FirmTeamData)
async def get_firm_team_data(firm_id: str):
    """
    Get detailed team information for a specific law firm.
    """
    try:
        logger.info(f"Fetching team data for firm: {firm_id}")
        
        if firm_id not in ENRICHED_FIRMS_MOCK_DATA:
            raise HTTPException(status_code=404, detail=f"Firm {firm_id} not found")
        
        firm_data = ENRICHED_FIRMS_MOCK_DATA[firm_id]
        
        # Calculate team statistics
        all_lawyers = firm_data["partners"] + firm_data["associates"]
        avg_success_rate = sum(lawyer["features"]["successRate"] for lawyer in all_lawyers) / len(all_lawyers) if all_lawyers else 0.0
        avg_response_time = sum(lawyer["features"]["responseTime"] for lawyer in all_lawyers) / len(all_lawyers) if all_lawyers else 0.0
        
        team_data = {
            "firm_id": firm_id,
            "partners": firm_data["partners"],
            "associates": firm_data["associates"],
            "total_lawyers": firm_data["total_lawyers"],
            "specialists_by_area": firm_data["specialists_by_area"],
            "team_stats": {
                "average_experience": 8.5,  # Mock calculation - could be enhanced
                "average_success_rate": avg_success_rate,
                "average_response_time": avg_response_time
            }
        }
        
        return FirmTeamData(**team_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching firm team data for {firm_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/firm/{firm_id}/transparency-report", response_model=FirmTransparencyReport)
async def get_firm_transparency_report(firm_id: str):
    """
    Get detailed transparency report for a specific law firm's data sources.
    """
    try:
        logger.info(f"Generating transparency report for firm: {firm_id}")
        
        if firm_id not in ENRICHED_FIRMS_MOCK_DATA:
            raise HTTPException(status_code=404, detail=f"Firm {firm_id} not found")
        
        firm_data = ENRICHED_FIRMS_MOCK_DATA[firm_id]
        
        report = {
            "firm_id": firm_id,
            "report_generated_at": datetime.utcnow().isoformat() + "Z",
            "data_sources": firm_data["data_sources"],
            "overall_quality_score": firm_data["overall_quality_score"],
            "completeness_score": firm_data["completeness_score"],
            "last_update": firm_data["last_consolidated"],
            "quality_breakdown": {
                "excellent": len([s for s in firm_data["data_sources"].values() if s["quality_score"] >= 0.9]),
                "good": len([s for s in firm_data["data_sources"].values() if 0.7 <= s["quality_score"] < 0.9]),
                "fair": len([s for s in firm_data["data_sources"].values() if 0.5 <= s["quality_score"] < 0.7]),
                "poor": len([s for s in firm_data["data_sources"].values() if s["quality_score"] < 0.5])
            },
            "data_collection_policy": {
                "public_sources_only": True,
                "regulatory_compliance": True,
                "regular_updates": True,
                "user_consent_required": True
            }
        }
        
        return FirmTransparencyReport(**report)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating transparency report for {firm_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/firm/{firm_id}/financial", response_model=FirmFinancialSummary)
async def get_firm_financial_summary(firm_id: str):
    """
    Get financial summary for a specific law firm (public information only).
    """
    try:
        logger.info(f"Fetching financial summary for firm: {firm_id}")
        
        if firm_id not in ENRICHED_FIRMS_MOCK_DATA:
            raise HTTPException(status_code=404, detail=f"Firm {firm_id} not found")
        
        firm_data = ENRICHED_FIRMS_MOCK_DATA[firm_id]
        financial_info = firm_data.get("financial_info", {})
        
        # Determine market position based on stats
        total_cases = firm_data["stats"]["total_cases"]
        if total_cases > 2000:
            market_position = "Leading"
        elif total_cases > 1000:
            market_position = "Established"
        elif total_cases > 500:
            market_position = "Growing"
        else:
            market_position = "Emerging"
        
        summary = {
            "firm_id": firm_id,
            "revenue_range": financial_info.get("revenue_range"),
            "founded_year": financial_info.get("founded_year"),
            "legal_structure": financial_info.get("legal_structure"),
            "employee_count": financial_info.get("employee_count"),
            "office_locations": financial_info.get("office_locations", []),
            "market_position": market_position,
            "growth_indicators": {
                "cases_this_year": firm_data["stats"]["cases_this_year"],
                "success_rate": firm_data["stats"]["success_rate"],
                "client_retention": 0.89  # Mock data - could be enhanced
            }
        }
        
        return FirmFinancialSummary(**summary)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching financial summary for {firm_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/search")
async def search_enriched_firms(
    query: Optional[str] = None,
    specialization: Optional[str] = None,
    location: Optional[str] = None,
    min_team_size: Optional[int] = None,
    max_team_size: Optional[int] = None,
    limit: int = 10,
    offset: int = 0
):
    """
    Search for law firms based on various criteria.
    """
    try:
        logger.info(f"Searching firms with query='{query}', specialization='{specialization}', location='{location}'")
        
        results = []
        
        for firm_id, firm_data in ENRICHED_FIRMS_MOCK_DATA.items():
            # Apply filters
            if query and query.lower() not in firm_data["name"].lower():
                continue
                
            if specialization and specialization not in firm_data["specializations"]:
                continue
                
            if location and location.lower() not in firm_data["location"]["city"].lower():
                continue
                
            if min_team_size and firm_data["total_lawyers"] < min_team_size:
                continue
                
            if max_team_size and firm_data["total_lawyers"] > max_team_size:
                continue
            
            # Add basic firm info to results
            results.append({
                "id": firm_data["id"],
                "name": firm_data["name"],
                "specializations": firm_data["specializations"],
                "location": f"{firm_data['location']['city']}, {firm_data['location']['state']}",
                "team_size": firm_data["total_lawyers"],
                "success_rate": firm_data["stats"]["success_rate"],
                "overall_quality_score": firm_data["overall_quality_score"]
            })
        
        # Apply pagination
        paginated_results = results[offset:offset + limit]
        
        return {
            "firms": paginated_results,
            "total": len(results),
            "limit": limit,
            "offset": offset,
            "has_more": offset + limit < len(results)
        }
        
    except Exception as e:
        logger.error(f"Error searching firms: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/stats")
async def get_enriched_firms_stats():
    """
    Get aggregated statistics about enriched firms data.
    """
    try:
        total_firms = len(ENRICHED_FIRMS_MOCK_DATA)
        total_lawyers = sum(firm["total_lawyers"] for firm in ENRICHED_FIRMS_MOCK_DATA.values())
        avg_quality_score = sum(firm["overall_quality_score"] for firm in ENRICHED_FIRMS_MOCK_DATA.values()) / total_firms
        
        specializations = {}
        for firm in ENRICHED_FIRMS_MOCK_DATA.values():
            for spec in firm["specializations"]:
                specializations[spec] = specializations.get(spec, 0) + 1
        
        return {
            "total_firms": total_firms,
            "total_lawyers": total_lawyers,
            "average_quality_score": round(avg_quality_score, 2),
            "top_specializations": dict(sorted(specializations.items(), key=lambda x: x[1], reverse=True)[:5]),
            "data_freshness": {
                "last_update": max(firm["last_consolidated"] for firm in ENRICHED_FIRMS_MOCK_DATA.values()),
                "sources_count": len(set().union(*[firm["data_sources"].keys() for firm in ENRICHED_FIRMS_MOCK_DATA.values()]))
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting enriched firms stats: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error") 
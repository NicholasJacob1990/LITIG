from pydantic import BaseModel, Field
from typing import Optional

# Supondo que o schema de Lawyer já existe em schemas.lawyer
from .lawyer import Lawyer

class Recommendation(BaseModel):
    """
    Representa uma recomendação final, que pode ser orgânica ou patrocinada.
    """
    lawyer: Lawyer
    fair_score: float = Field(
        ...,
        description="A pontuação final de 'justiça' do algoritmo de matching."
    )
    is_sponsored: bool = Field(
        False,
        description="Flag que indica se a recomendação é um anúncio patrocinado."
    )
    ad_campaign_id: Optional[str] = Field(
        None,
        description="ID da campanha de anúncio, se for patrocinado."
    )

    class Config:
        orm_mode = True 
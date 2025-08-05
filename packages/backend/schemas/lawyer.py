from pydantic import BaseModel, Field
from typing import Optional, List

class Lawyer(BaseModel):
    """
    Schema básico para representar um advogado.
    """
    id: str = Field(..., description="ID único do advogado")
    name: str = Field(..., description="Nome completo do advogado")
    oab_number: Optional[str] = Field(None, description="Número OAB")
    email: Optional[str] = Field(None, description="Email do advogado")
    phone: Optional[str] = Field(None, description="Telefone do advogado")
    specializations: Optional[List[str]] = Field(None, description="Lista de especializações")
    experience_years: Optional[int] = Field(None, description="Anos de experiência")
    rating: Optional[float] = Field(None, description="Avaliação média")
    cases_count: Optional[int] = Field(None, description="Número de casos")
    
    class Config:
        orm_mode = True 
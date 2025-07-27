"""
External Profile Enrichment Service

Serviço responsável por buscar e enriquecer perfis públicos de advogados
usando LLM + Web Search quando a base interna não tem suficientes resultados.
"""

import asyncio
import json
import logging
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
import os
import re

try:
    import aiohttp
    from openai import AsyncOpenAI
    HAS_OPENAI = True
except ImportError:
    HAS_OPENAI = False
    class AsyncOpenAI:
        pass

logger = logging.getLogger(__name__)

@dataclass
class ExternalLawyerProfile:
    """Estrutura de dados para perfil externo de advogado."""
    name: str
    email: Optional[str] = None
    linkedin_url: Optional[str] = None
    firm_name: Optional[str] = None
    specializations: List[str] = None
    location: Optional[str] = None
    experience_description: Optional[str] = None
    education: Optional[str] = None
    oab_number: Optional[str] = None
    confidence_score: float = 0.5

    def __post_init__(self):
        if self.specializations is None:
            self.specializations = []


class ExternalProfileEnrichmentService:
    """
    Serviço para buscar perfis públicos de advogados usando LLM + Web Search.
    
    Este serviço é ativado quando a busca interna não retorna resultados suficientes,
    expandindo a cobertura da plataforma para incluir especialistas não cadastrados.
    """
    
    def __init__(self):
        self.openai_client = None
        self.openrouter_api_key = os.getenv("OPENROUTER_API_KEY")
        self.perplexity_api_key = os.getenv("PERPLEXITY_API_KEY")
        
        if HAS_OPENAI and self.openrouter_api_key:
            self.openai_client = AsyncOpenAI(
                base_url="https://openrouter.ai/api/v1",
                api_key=self.openrouter_api_key,
            )
    
    async def search_public_profiles(self, 
                                   case_area: str, 
                                   location: tuple, 
                                   urgency_h: int = 48,
                                   limit: int = 5) -> List[ExternalLawyerProfile]:
        """
        Busca perfis públicos de advogados usando LLM + Web Search.
        
        Args:
            case_area: Área jurídica do caso (ex: "Direito Tributário")
            location: Tupla (lat, lon) da localização do cliente
            urgency_h: Urgência do caso em horas
            limit: Número máximo de perfis a retornar
            
        Returns:
            Lista de perfis externos encontrados
        """
        if not self._is_service_available():
            logger.warning("External profile service not available - missing API keys")
            return []
        
        try:
            # Construir query de busca contextualizada
            search_query = self._build_search_query(case_area, location, urgency_h)
            
            # Usar Perplexity como provider principal (tem web search nativo)
            if self.perplexity_api_key:
                profiles = await self._search_with_perplexity(search_query, limit)
            else:
                # Fallback para OpenRouter (sem web search)
                profiles = await self._search_with_openrouter(search_query, limit)
            
            # Filtrar e validar resultados
            valid_profiles = self._validate_and_filter_profiles(profiles, case_area)
            
            logger.info(f"External search found {len(valid_profiles)} valid profiles for {case_area}")
            return valid_profiles[:limit]
            
        except Exception as e:
            logger.error(f"Error in external profile search: {e}")
            return []
    
    async def enrich_profile_contact_info(self, profile: ExternalLawyerProfile) -> ExternalLawyerProfile:
        """
        Enriquece um perfil com informações de contato adicionais.
        
        Args:
            profile: Perfil a ser enriquecido
            
        Returns:
            Perfil enriquecido com dados de contato
        """
        if not self._is_service_available():
            return profile
        
        try:
            # Buscar e-mail e LinkedIn do advogado/escritório
            contact_query = f"""
            Encontre informações de contato para o advogado {profile.name} 
            {f"do escritório {profile.firm_name}" if profile.firm_name else ""}.
            
            Procure especificamente por:
            1. E-mail profissional público
            2. Perfil no LinkedIn
            3. Site do escritório
            
            Retorne apenas informações que estejam publicamente disponíveis.
            """
            
            if self.perplexity_api_key:
                contact_info = await self._search_contact_with_perplexity(contact_query)
            else:
                contact_info = await self._search_contact_with_openrouter(contact_query)
            
            # Atualizar perfil com informações encontradas
            if contact_info.get('email'):
                profile.email = contact_info['email']
            if contact_info.get('linkedin_url'):
                profile.linkedin_url = contact_info['linkedin_url']
            
            return profile
            
        except Exception as e:
            logger.error(f"Error enriching profile {profile.name}: {e}")
            return profile
    
    def _is_service_available(self) -> bool:
        """Verifica se o serviço está disponível (tem pelo menos uma API key)."""
        return bool(self.perplexity_api_key or self.openrouter_api_key)
    
    def _build_search_query(self, case_area: str, location: tuple, urgency_h: int) -> str:
        """Constrói query de busca contextualizada."""
        lat, lon = location
        
        # Mapear coordenadas para cidade (simplificado)
        city = self._coords_to_city(lat, lon)
        
        # Ajustar urgência
        urgency_text = "urgente" if urgency_h <= 24 else "normal"
        
        return f"""
        Encontre advogados especialistas em {case_area} na região de {city}.
        
        Critérios:
        - Experiência comprovada em {case_area}
        - Atuação em {city} ou região metropolitana
        - Disponibilidade para casos de prioridade {urgency_text}
        - Escritórios ou advogados autônomos reconhecidos
        
        Para cada advogado, retorne:
        1. Nome completo
        2. Escritório/firma (se aplicável)
        3. Áreas de especialização
        4. Localização
        5. Resumo da experiência
        6. Formação acadêmica (se disponível)
        7. Número da OAB (se público)
        
        Limite: 8 advogados máximo.
        Priorize qualidade sobre quantidade.
        """
    
    def _coords_to_city(self, lat: float, lon: float) -> str:
        """Converte coordenadas em nome da cidade (implementação simplificada)."""
        # Implementação básica - em produção usar geocoding API
        if -23.7 <= lat <= -23.4 and -46.8 <= lon <= -46.4:
            return "São Paulo, SP"
        elif -22.95 <= lat <= -22.8 and -43.3 <= lon <= -43.1:
            return "Rio de Janeiro, RJ"
        elif -15.85 <= lat <= -15.7 and -48.0 <= lon <= -47.8:
            return "Brasília, DF"
        else:
            return "Brasil"
    
    async def _search_with_perplexity(self, query: str, limit: int) -> List[ExternalLawyerProfile]:
        """Busca usando Perplexity API (com web search nativo)."""
        if not self.perplexity_api_key:
            return []
        
        try:
            async with aiohttp.ClientSession() as session:
                headers = {
                    "Authorization": f"Bearer {self.perplexity_api_key}",
                    "Content-Type": "application/json"
                }
                
                payload = {
                    "model": "llama-3.1-sonar-large-128k-online",
                    "messages": [
                        {
                            "role": "system",
                            "content": "Você é um assistente especializado em encontrar advogados. Retorne respostas em formato JSON estruturado."
                        },
                        {
                            "role": "user", 
                            "content": query
                        }
                    ],
                    "return_citations": True,
                    "search_domain_filter": ["linkedin.com", "oab.org.br", "jusbrasil.com.br"],
                    "search_recency_filter": "month"
                }
                
                async with session.post(
                    "https://api.perplexity.ai/chat/completions",
                    headers=headers,
                    json=payload,
                    timeout=30
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
                        return self._parse_search_results(content)
                    else:
                        logger.warning(f"Perplexity API returned status {response.status}")
                        return []
                        
        except Exception as e:
            logger.error(f"Error with Perplexity API: {e}")
            return []
    
    async def _search_with_openrouter(self, query: str, limit: int) -> List[ExternalLawyerProfile]:
        """Busca usando OpenRouter (fallback sem web search)."""
        if not self.openai_client:
            return []
        
        try:
            response = await self.openai_client.chat.completions.create(
                model="anthropic/claude-3.5-sonnet",
                messages=[
                    {
                        "role": "system",
                        "content": "Você é um assistente que ajuda a encontrar advogados. Use seu conhecimento geral para sugerir profissionais conhecidos na área solicitada. Retorne em formato JSON."
                    },
                    {
                        "role": "user",
                        "content": query
                    }
                ],
                temperature=0.1,
                max_tokens=2000
            )
            
            content = response.choices[0].message.content
            return self._parse_search_results(content)
            
        except Exception as e:
            logger.error(f"Error with OpenRouter API: {e}")
            return []
    
    async def _search_contact_with_perplexity(self, query: str) -> Dict[str, str]:
        """Busca informações de contato usando Perplexity."""
        # Implementação similar ao _search_with_perplexity mas focada em contato
        # Por brevidade, retornando estrutura básica
        return {}
    
    async def _search_contact_with_openrouter(self, query: str) -> Dict[str, str]:
        """Busca informações de contato usando OpenRouter."""
        # Implementação similar ao _search_with_openrouter mas focada em contato
        # Por brevidade, retornando estrutura básica
        return {}
    
    def _parse_search_results(self, content: str) -> List[ExternalLawyerProfile]:
        """
        Parse dos resultados da busca para estrutura de dados.
        
        Args:
            content: Resposta textual do LLM
            
        Returns:
            Lista de perfis estruturados
        """
        profiles = []
        
        try:
            # Tentar parse como JSON primeiro
            if content.strip().startswith('{') or content.strip().startswith('['):
                data = json.loads(content)
                if isinstance(data, list):
                    for item in data:
                        profile = self._dict_to_profile(item)
                        if profile:
                            profiles.append(profile)
                elif isinstance(data, dict) and 'advogados' in data:
                    for item in data['advogados']:
                        profile = self._dict_to_profile(item)
                        if profile:
                            profiles.append(profile)
            else:
                # Parse textual como fallback
                profiles = self._parse_text_results(content)
                
        except json.JSONDecodeError:
            # Fallback para parse textual
            profiles = self._parse_text_results(content)
        
        return profiles
    
    def _dict_to_profile(self, data: Dict[str, Any]) -> Optional[ExternalLawyerProfile]:
        """Converte dicionário em perfil estruturado."""
        try:
            name = data.get('nome') or data.get('name') or data.get('advogado')
            if not name:
                return None
            
            return ExternalLawyerProfile(
                name=str(name).strip(),
                email=data.get('email'),
                linkedin_url=data.get('linkedin') or data.get('linkedin_url'),
                firm_name=data.get('escritorio') or data.get('firm') or data.get('firma'),
                specializations=data.get('especializacoes') or data.get('specializations') or [],
                location=data.get('localizacao') or data.get('location') or data.get('cidade'),
                experience_description=data.get('experiencia') or data.get('experience'),
                education=data.get('formacao') or data.get('education'),
                oab_number=data.get('oab') or data.get('oab_number'),
                confidence_score=0.7  # Score padrão para perfis estruturados
            )
        except Exception as e:
            logger.warning(f"Error parsing profile dict: {e}")
            return None
    
    def _parse_text_results(self, content: str) -> List[ExternalLawyerProfile]:
        """Parse textual como fallback."""
        profiles = []
        
        # Regex simples para extrair nomes que parecem ser de advogados
        name_patterns = [
            r"Dr\.?\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)",
            r"Advogad[oa]\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)",
            r"([A-Z][a-z]+\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s*-\s*OAB"
        ]
        
        for pattern in name_patterns:
            matches = re.findall(pattern, content, re.IGNORECASE)
            for match in matches:
                if len(match.split()) >= 2:  # Nome + sobrenome mínimo
                    profile = ExternalLawyerProfile(
                        name=match.strip(),
                        confidence_score=0.4  # Score baixo para parse textual
                    )
                    profiles.append(profile)
        
        return profiles[:8]  # Limite máximo
    
    def _validate_and_filter_profiles(self, 
                                    profiles: List[ExternalLawyerProfile], 
                                    target_area: str) -> List[ExternalLawyerProfile]:
        """
        Valida e filtra perfis baseado em critérios de qualidade.
        
        Args:
            profiles: Lista de perfis a validar
            target_area: Área jurídica target para scoring
            
        Returns:
            Lista de perfis válidos e ordenados por relevância
        """
        valid_profiles = []
        
        for profile in profiles:
            # Validações básicas
            if not profile.name or len(profile.name.split()) < 2:
                continue
            
            # Score baseado em relevância e completude
            relevance_score = self._calculate_relevance_score(profile, target_area)
            completeness_score = self._calculate_completeness_score(profile)
            
            # Score final combinado
            profile.confidence_score = (relevance_score * 0.6 + completeness_score * 0.4)
            
            # Filtrar apenas perfis com score mínimo
            if profile.confidence_score >= 0.3:
                valid_profiles.append(profile)
        
        # Ordenar por score descendente
        valid_profiles.sort(key=lambda p: p.confidence_score, reverse=True)
        
        return valid_profiles
    
    def _calculate_relevance_score(self, profile: ExternalLawyerProfile, target_area: str) -> float:
        """Calcula score de relevância baseado na especialização."""
        if not profile.specializations:
            return 0.5
        
        target_lower = target_area.lower()
        for specialization in profile.specializations:
            if target_lower in specialization.lower():
                return 1.0
        
        # Score baseado em palavras-chave relacionadas
        related_keywords = {
            "tributário": ["fiscal", "imposto", "tributo"],
            "trabalhista": ["trabalho", "clt", "emprego"],
            "civil": ["contrato", "família", "consumidor"],
            "penal": ["criminal", "defesa"],
            "empresarial": ["societário", "corporativo", "empresa"]
        }
        
        for keyword in related_keywords.get(target_lower, []):
            for specialization in profile.specializations:
                if keyword in specialization.lower():
                    return 0.8
        
        return 0.3
    
    def _calculate_completeness_score(self, profile: ExternalLawyerProfile) -> float:
        """Calcula score baseado na completude dos dados."""
        score = 0.0
        total_fields = 8
        
        # Pontuação por campo preenchido
        if profile.name: score += 1.0
        if profile.email: score += 1.0
        if profile.linkedin_url: score += 1.0
        if profile.firm_name: score += 1.0
        if profile.specializations: score += 1.0
        if profile.location: score += 1.0
        if profile.experience_description: score += 1.0
        if profile.oab_number: score += 1.0
        
        return score / total_fields 
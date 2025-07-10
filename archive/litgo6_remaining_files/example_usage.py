#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
example_usage.py

Exemplo prático de como usar a API FastAPI do LITGO5 em código Python.
Demonstra integração completa com o sistema de matching jurídico.
"""

import asyncio
import json
from datetime import datetime
from typing import List, Dict, Optional

import httpx


class LITGO5API:
    """Cliente Python para a API FastAPI do LITGO5"""
    
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.timeout = 30.0
    
    async def health_check(self) -> Dict:
        """Verifica saúde da API"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(f"{self.base_url}/health")
            response.raise_for_status()
            return response.json()
    
    async def find_lawyers(
        self,
        title: str,
        description: str,
        area: str,
        subarea: str,
        latitude: float,
        longitude: float,
        urgency_hours: int = 48,
        complexity: str = "MEDIUM",
        estimated_value: Optional[float] = None,
        top_n: int = 5,
        preset: str = "balanced",
        include_jusbrasil: bool = True
    ) -> Dict:
        """
        Encontra advogados para um caso específico
        
        Args:
            title: Título do caso
            description: Descrição detalhada
            area: Área jurídica (Trabalhista, Civil, etc.)
            subarea: Subárea específica
            latitude: Latitude do cliente
            longitude: Longitude do cliente
            urgency_hours: Urgência em horas
            complexity: LOW, MEDIUM ou HIGH
            estimated_value: Valor estimado da causa
            top_n: Número de advogados a retornar
            preset: fast, balanced ou expert
            include_jusbrasil: Incluir dados históricos
            
        Returns:
            Resposta da API com advogados rankeados
        """
        request_data = {
            "case": {
                "title": title,
                "description": description,
                "area": area,
                "subarea": subarea,
                "urgency_hours": urgency_hours,
                "coordinates": {
                    "latitude": latitude,
                    "longitude": longitude
                },
                "complexity": complexity,
                "estimated_value": estimated_value
            },
            "top_n": top_n,
            "preset": preset,
            "include_jusbrasil_data": include_jusbrasil
        }
        
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/api/match",
                json=request_data
            )
            response.raise_for_status()
            return response.json()
    
    async def list_lawyers(
        self,
        area: Optional[str] = None,
        uf: Optional[str] = None,
        lat: Optional[float] = None,
        lon: Optional[float] = None,
        radius_km: Optional[float] = None,
        min_rating: Optional[float] = None,
        limit: int = 20,
        offset: int = 0
    ) -> Dict:
        """Lista advogados com filtros"""
        params = {
            "limit": limit,
            "offset": offset
        }
        
        if area:
            params["area"] = area
        if uf:
            params["uf"] = uf
        if lat is not None:
            params["lat"] = lat
        if lon is not None:
            params["lon"] = lon
        if radius_km is not None:
            params["radius_km"] = radius_km
        if min_rating is not None:
            params["min_rating"] = min_rating
        
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/api/lawyers",
                params=params
            )
            response.raise_for_status()
            return response.json()
    
    async def get_lawyer_sync_status(self, lawyer_id: str) -> Dict:
        """Obtém status de sincronização com Jusbrasil"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/api/lawyers/{lawyer_id}/sync-status"
            )
            response.raise_for_status()
            return response.json()
    
    async def force_lawyer_sync(self, lawyer_id: str) -> Dict:
        """Força sincronização de advogado"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/api/admin/sync-lawyer/{lawyer_id}"
            )
            response.raise_for_status()
            return response.json()


# Exemplos de uso
async def exemplo_caso_trabalhista():
    """Exemplo: Encontrar advogados para caso trabalhista"""
    print("📋 Exemplo: Caso Trabalhista")
    print("=" * 50)
    
    api = LITGO5API()
    
    # Verificar saúde da API
    try:
        health = await api.health_check()
        print(f"✅ API Status: {health['status']}")
    except Exception as e:
        print(f"❌ API não disponível: {e}")
        return
    
    # Buscar advogados
    try:
        result = await api.find_lawyers(
            title="Rescisão Indireta por Assédio Moral",
            description="""
            Cliente trabalhou por 3 anos em empresa e sofreu assédio moral 
            sistemático nos últimos 6 meses. Supervisor constantemente 
            desqualificava o trabalho em público, sobrecarregava com tarefas 
            impossíveis e fazia comentários depreciativos. Cliente possui 
            prints de mensagens, emails e testemunhas. Necessita rescisão 
            indireta com todas as verbas rescisórias mais indenização por 
            danos morais.
            """,
            area="Trabalhista",
            subarea="Rescisão",
            latitude=-23.5505,  # São Paulo
            longitude=-46.6333,
            urgency_hours=48,
            complexity="MEDIUM",
            estimated_value=30000.0,
            top_n=3,
            preset="balanced"
        )
        
        print(f"📊 Resultados:")
        print(f"   Case ID: {result['case_id']}")
        print(f"   Advogados avaliados: {result['total_lawyers_evaluated']}")
        print(f"   Tempo execução: {result['execution_time_ms']:.1f}ms")
        print(f"   Algoritmo: {result['algorithm_version']}")
        
        print(f"\n🏆 Top {len(result['lawyers'])} Advogados:")
        for i, lawyer in enumerate(result['lawyers'], 1):
            scores = lawyer['scores']
            print(f"\n   {i}. {lawyer['nome']}")
            print(f"      📍 {lawyer['distancia_km']:.1f}km de distância")
            print(f"      💯 Score: {scores['fair_score']:.3f}")
            print(f"      ⭐ Success Rate: {scores['success_rate']:.1%}")
            print(f"      🎯 Similaridade: {scores['case_similarity']:.1%}")
            
            if scores.get('jusbrasil_data'):
                jb = scores['jusbrasil_data']
                print(f"      📊 Histórico: {jb['victories']}/{jb['total_cases']} vitórias")
        
    except Exception as e:
        print(f"❌ Erro no matching: {e}")


async def exemplo_busca_advogados():
    """Exemplo: Buscar advogados com filtros"""
    print("\n🔍 Exemplo: Busca com Filtros")
    print("=" * 50)
    
    api = LITGO5API()
    
    try:
        # Buscar advogados trabalhistas em SP
        result = await api.list_lawyers(
            area="Trabalhista",
            uf="SP",
            lat=-23.5505,
            lon=-46.6333,
            radius_km=50,
            min_rating=4.0,
            limit=5
        )
        
        print(f"📊 Encontrados: {result['total']} advogados")
        print(f"📄 Mostrando: {len(result['lawyers'])} resultados")
        
        for lawyer in result['lawyers']:
            print(f"\n   👤 {lawyer['nome']}")
            print(f"      📍 {lawyer['distancia_km']:.1f}km")
            print(f"      ⭐ Rating: {lawyer['kpi']['avaliacao_media']:.1f}/5")
            print(f"      📊 Success Rate: {lawyer['kpi']['success_rate']:.1%}")
            
    except Exception as e:
        print(f"❌ Erro na busca: {e}")


async def exemplo_monitoramento():
    """Exemplo: Monitoramento de sincronização"""
    print("\n📊 Exemplo: Monitoramento")
    print("=" * 50)
    
    api = LITGO5API()
    
    # Simular ID de advogado
    lawyer_id = "lawyer_001"
    
    try:
        # Verificar status de sincronização
        status = await api.get_lawyer_sync_status(lawyer_id)
        print(f"🔄 Status Sync: {status['sync_status']}")
        print(f"📅 Última sync: {status['last_sync']}")
        print(f"📊 Total casos: {status['total_cases']}")
        
        # Forçar sincronização se necessário
        if status['sync_status'] == 'outdated':
            print("\n🔄 Forçando sincronização...")
            sync_result = await api.force_lawyer_sync(lawyer_id)
            print(f"✅ {sync_result['message']}")
            
    except Exception as e:
        print(f"❌ Erro no monitoramento: {e}")


async def exemplo_completo():
    """Exemplo completo de uso da API"""
    print("🚀 LITGO5 API - Exemplos de Uso")
    print("=" * 60)
    print(f"🕐 Executado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Executar todos os exemplos
    await exemplo_caso_trabalhista()
    await exemplo_busca_advogados()
    await exemplo_monitoramento()
    
    print("\n" + "=" * 60)
    print("🎉 Todos os exemplos executados com sucesso!")
    print("📖 Documentação completa: http://localhost:8000/docs")


# Classe helper para integração com React Native
class ReactNativeHelper:
    """Helper para integração com React Native"""
    
    @staticmethod
    def format_case_for_api(case_data: dict) -> dict:
        """Formata dados do caso para a API"""
        return {
            "case": {
                "title": case_data.get("title", ""),
                "description": case_data.get("description", ""),
                "area": case_data.get("area", ""),
                "subarea": case_data.get("subarea", ""),
                "urgency_hours": case_data.get("urgencyHours", 48),
                "coordinates": {
                    "latitude": case_data.get("coordinates", {}).get("latitude", 0),
                    "longitude": case_data.get("coordinates", {}).get("longitude", 0)
                },
                "complexity": case_data.get("complexity", "MEDIUM"),
                "estimated_value": case_data.get("estimatedValue")
            },
            "top_n": case_data.get("topN", 5),
            "preset": case_data.get("preset", "balanced"),
            "include_jusbrasil_data": case_data.get("includeJusbrasil", True)
        }
    
    @staticmethod
    def format_lawyers_for_frontend(api_response: dict) -> dict:
        """Formata resposta da API para o frontend"""
        return {
            "success": api_response.get("success", False),
            "caseId": api_response.get("case_id", ""),
            "lawyers": [
                {
                    "id": lawyer.get("id", ""),
                    "nome": lawyer.get("nome", ""),
                    "oabNumero": lawyer.get("oab_numero", ""),
                    "uf": lawyer.get("uf", ""),
                    "especialidades": lawyer.get("especialidades", []),
                    "distanciaKm": lawyer.get("distancia_km", 0),
                    "scores": {
                        "finalScore": lawyer.get("scores", {}).get("fair_score", 0),
                        "successRate": lawyer.get("scores", {}).get("success_rate", 0),
                        "similarity": lawyer.get("scores", {}).get("case_similarity", 0),
                        "jusbrasilData": lawyer.get("scores", {}).get("jusbrasil_data")
                    },
                    "kpi": {
                        "avaliacaoMedia": lawyer.get("kpi", {}).get("avaliacao_media", 0),
                        "successRate": lawyer.get("kpi", {}).get("success_rate", 0),
                        "cases30d": lawyer.get("kpi", {}).get("cases_30d", 0)
                    }
                }
                for lawyer in api_response.get("lawyers", [])
            ],
            "metadata": {
                "totalEvaluated": api_response.get("total_lawyers_evaluated", 0),
                "executionTime": api_response.get("execution_time_ms", 0),
                "algorithmVersion": api_response.get("algorithm_version", "")
            }
        }


if __name__ == "__main__":
    print("💡 Para executar os exemplos:")
    print("   1. Certifique-se de que a API está rodando")
    print("   2. Execute: python example_usage.py")
    print("   3. Ou use as classes no seu código")
    print()
    
    # Executar exemplos
    asyncio.run(exemplo_completo()) 
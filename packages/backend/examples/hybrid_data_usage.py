#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Exemplo de Uso - Sistema de Dados Híbridos
==========================================

Este script demonstra como utilizar os endpoints de dados híbridos
para obter informações consolidadas sobre advogados com transparência
completa das fontes de dados.
"""

import asyncio
import json
from datetime import datetime
from typing import Dict, Any

import aiohttp
import requests


class HybridDataClient:
    """Cliente para interagir com os endpoints de dados híbridos."""
    
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.session = None
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def get_lawyer_hybrid_data(self, lawyer_id: str, force_refresh: bool = False) -> Dict[str, Any]:
        """Obtém dados híbridos de um advogado."""
        url = f"{self.base_url}/api/v1/hybrid/lawyers/{lawyer_id}"
        params = {"force_refresh": force_refresh}
        
        async with self.session.get(url, params=params) as response:
            if response.status == 200:
                return await response.json()
            else:
                raise Exception(f"Erro {response.status}: {await response.text()}")
    
    async def get_sync_status(self) -> Dict[str, Any]:
        """Obtém status de sincronização."""
        url = f"{self.base_url}/api/v1/hybrid/sync/status"
        
        async with self.session.get(url) as response:
            if response.status == 200:
                return await response.json()
            else:
                raise Exception(f"Erro {response.status}: {await response.text()}")
    
    async def get_sync_report(self) -> Dict[str, Any]:
        """Obtém relatório de sincronização."""
        url = f"{self.base_url}/api/v1/hybrid/sync/report"
        
        async with self.session.get(url) as response:
            if response.status == 200:
                return await response.json()
            else:
                raise Exception(f"Erro {response.status}: {await response.text()}")
    
    async def trigger_sync(self, lawyer_id: str = None, force_refresh: bool = False) -> Dict[str, Any]:
        """Dispara sincronização."""
        url = f"{self.base_url}/api/v1/hybrid/sync/trigger"
        params = {}
        
        if lawyer_id:
            params["lawyer_id"] = lawyer_id
        if force_refresh:
            params["force_refresh"] = force_refresh
        
        async with self.session.post(url, params=params) as response:
            if response.status == 200:
                return await response.json()
            else:
                raise Exception(f"Erro {response.status}: {await response.text()}")
    
    async def get_data_sources(self) -> Dict[str, Any]:
        """Lista fontes de dados disponíveis."""
        url = f"{self.base_url}/api/v1/hybrid/data-sources"
        
        async with self.session.get(url) as response:
            if response.status == 200:
                return await response.json()
            else:
                raise Exception(f"Erro {response.status}: {await response.text()}")
    
    async def get_quality_metrics(self, lawyer_id: str) -> Dict[str, Any]:
        """Obtém métricas de qualidade de um advogado."""
        url = f"{self.base_url}/api/v1/hybrid/quality-metrics/{lawyer_id}"
        
        async with self.session.get(url) as response:
            if response.status == 200:
                return await response.json()
            else:
                raise Exception(f"Erro {response.status}: {await response.text()}")
    
    async def get_sync_logs(self, entity_type: str = None, status: str = None, limit: int = 10) -> Dict[str, Any]:
        """Obtém logs de sincronização."""
        url = f"{self.base_url}/api/v1/hybrid/sync/logs"
        params = {"limit": limit}
        
        if entity_type:
            params["entity_type"] = entity_type
        if status:
            params["status"] = status
        
        async with self.session.get(url, params=params) as response:
            if response.status == 200:
                return await response.json()
            else:
                raise Exception(f"Erro {response.status}: {await response.text()}")


def print_section(title: str):
    """Imprime seção formatada."""
    print(f"\n{'='*60}")
    print(f"🔍 {title}")
    print('='*60)


def print_transparency_info(data: Dict[str, Any]):
    """Imprime informações de transparência."""
    if "data_transparency" in data:
        print("\n📊 Transparência de Dados:")
        for i, transparency in enumerate(data["data_transparency"], 1):
            print(f"  {i}. Fonte: {transparency['source']}")
            print(f"     • Confiança: {transparency['confidence_score']:.2f}")
            print(f"     • Frescor: {transparency['data_freshness_hours']}h")
            print(f"     • Status: {transparency['validation_status']}")
            print(f"     • Atualizado: {transparency['last_updated']}")
            if transparency.get('source_url'):
                print(f"     • URL: {transparency['source_url']}")
            print()


def print_quality_metrics(data: Dict[str, Any]):
    """Imprime métricas de qualidade."""
    if "data_quality" in data:
        quality = data["data_quality"]
        print("\n📈 Métricas de Qualidade:")
        print(f"  • Score geral: {quality.get('quality_score', 'N/A')}")
        print(f"  • Fontes utilizadas: {quality.get('sources', 'N/A')}")
        print(f"  • Frescor médio: {quality.get('freshness', 'N/A')}")
        print(f"  • Fonte primária: {quality.get('primary_source', 'N/A')}")
        print(f"  • Última sincronização: {quality.get('last_sync', 'N/A')}")


async def demo_hybrid_data_system():
    """Demonstração completa do sistema de dados híbridos."""
    
    print("🚀 Demonstração do Sistema de Dados Híbridos LITGO6")
    print("="*60)
    
    async with HybridDataClient() as client:
        
        # 1. Listar fontes de dados disponíveis
        print_section("Fontes de Dados Disponíveis")
        try:
            sources = await client.get_data_sources()
            print(f"Total de fontes: {sources['total_sources']}")
            print(f"Fontes ativas: {sources['active_sources']}")
            print("\nFontes configuradas:")
            for source in sources['sources']:
                print(f"  • {source['display_name']} ({source['name']})")
                print(f"    Peso: {source['confidence_weight']} | TTL: {source['cache_ttl_hours']}h")
                print(f"    Status: {source['status']} | Versão: {source['api_version']}")
        except Exception as e:
            print(f"❌ Erro ao obter fontes: {e}")
        
        # 2. Status de sincronização
        print_section("Status de Sincronização")
        try:
            status = await client.get_sync_status()
            print(f"Total de advogados: {status['total_lawyers']}")
            print(f"Advogados sincronizados: {status['synced_lawyers']}")
            print(f"Recentemente sincronizados: {status['recently_synced']}")
            print(f"Cobertura de sincronização: {status['sync_coverage']:.1f}%")
            print(f"Confiança média: {status['avg_confidence']:.3f}")
            print(f"Erros: {status.get('error_count', 0)}")
        except Exception as e:
            print(f"❌ Erro ao obter status: {e}")
        
        # 3. Relatório detalhado
        print_section("Relatório de Sincronização")
        try:
            report = await client.get_sync_report()
            for entity_report in report:
                print(f"\n📋 {entity_report['entity_type'].upper()}:")
                print(f"  • Total: {entity_report['total_entities']}")
                print(f"  • Sincronizados: {entity_report['synced_entities']}")
                print(f"  • Cobertura: {entity_report['sync_coverage']:.1f}%")
                print(f"  • Recentes: {entity_report['recently_synced']}")
                print(f"  • Qualidade média: {entity_report['avg_quality_score']:.3f}")
                print(f"  • Erros: {entity_report['error_count']}")
        except Exception as e:
            print(f"❌ Erro ao obter relatório: {e}")
        
        # 4. Exemplo com advogado específico (usar ID fictício)
        print_section("Dados de Advogado Específico")
        lawyer_id = "example-lawyer-id"  # Substituir por ID real
        try:
            lawyer_data = await client.get_lawyer_hybrid_data(lawyer_id)
            print(f"👤 Advogado: {lawyer_data['name']}")
            print(f"📋 OAB: {lawyer_data['oab_number']}")
            print(f"🎯 Especializações: {', '.join(lawyer_data['specializations'])}")
            print(f"⭐ Reputação: {lawyer_data['reputation_score']:.2f}")
            print(f"📊 Casos ganhos: {lawyer_data['cases_won']}/{lawyer_data['cases_total']}")
            print(f"⏱️ Duração média: {lawyer_data['avg_case_duration_days']:.1f} dias")
            
            # Métricas de sucesso
            if lawyer_data['success_metrics']:
                print(f"\n📈 Métricas de Sucesso:")
                for metric, value in lawyer_data['success_metrics'].items():
                    print(f"  • {metric}: {value:.3f}")
            
            # Transparência
            print_transparency_info(lawyer_data)
            
            # Qualidade
            print_quality_metrics(lawyer_data)
            
        except Exception as e:
            print(f"❌ Erro ao obter dados do advogado: {e}")
        
        # 5. Métricas de qualidade detalhadas
        print_section("Métricas de Qualidade Detalhadas")
        try:
            quality_metrics = await client.get_quality_metrics(lawyer_id)
            print(f"👤 Advogado: {quality_metrics['lawyer_id']}")
            print(f"📊 Fontes: {quality_metrics['total_sources']}")
            print(f"🕒 Última atualização: {quality_metrics['last_updated']}")
            
            print("\n📋 Métricas por fonte:")
            for source, metrics in quality_metrics['metrics_by_source'].items():
                print(f"  🔗 {source.upper()}:")
                for metric_name, metric_data in metrics.items():
                    print(f"    • {metric_name}: {metric_data['value']:.3f}")
                    print(f"      Medido em: {metric_data['measured_at']}")
                
        except Exception as e:
            print(f"❌ Erro ao obter métricas de qualidade: {e}")
        
        # 6. Logs de sincronização
        print_section("Logs de Sincronização")
        try:
            logs = await client.get_sync_logs(entity_type="lawyer", limit=5)
            print(f"📋 Logs retornados: {logs['total_returned']}")
            
            for log in logs['logs']:
                print(f"\n🔄 Sincronização:")
                print(f"  • ID: {log['id']}")
                print(f"  • Tipo: {log['sync_type']}")
                print(f"  • Status: {log['status']}")
                print(f"  • Fontes: {', '.join(log['sources_used'])}")
                print(f"  • Tempo: {log['execution_time_ms']}ms")
                print(f"  • Data: {log['created_at']}")
                
                if log['error_message']:
                    print(f"  • Erro: {log['error_message']}")
                
                if log['changes_detected']:
                    print(f"  • Mudanças: {len(log['changes_detected'])} detectadas")
                
        except Exception as e:
            print(f"❌ Erro ao obter logs: {e}")
        
        # 7. Disparar sincronização de exemplo
        print_section("Disparar Sincronização")
        try:
            sync_result = await client.trigger_sync(lawyer_id=lawyer_id)
            print(f"✅ Sincronização disparada:")
            print(f"  • Mensagem: {sync_result['message']}")
            print(f"  • Task ID: {sync_result['task_id']}")
            print(f"  • Tipo: {sync_result['type']}")
            
        except Exception as e:
            print(f"❌ Erro ao disparar sincronização: {e}")
    
    print("\n🎯 Demonstração concluída!")
    print("="*60)


def demo_sync_requests():
    """Demonstração usando requests síncronos."""
    
    print("\n🔄 Demonstração com Requests Síncronos")
    print("="*40)
    
    base_url = "http://localhost:8080"
    
    # Status de sincronização
    try:
        response = requests.get(f"{base_url}/api/v1/hybrid/sync/status")
        if response.status_code == 200:
            status = response.json()
            print(f"📊 Status: {status['synced_lawyers']}/{status['total_lawyers']} sincronizados")
            print(f"📈 Cobertura: {status['sync_coverage']:.1f}%")
        else:
            print(f"❌ Erro: {response.status_code}")
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
    
    # Disparar sincronização completa
    try:
        response = requests.post(f"{base_url}/api/v1/hybrid/sync/trigger")
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Sincronização disparada: {result['message']}")
        else:
            print(f"❌ Erro: {response.status_code}")
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")


if __name__ == "__main__":
    print("🚀 Iniciando demonstração do Sistema de Dados Híbridos")
    
    # Demonstração assíncrona completa
    asyncio.run(demo_hybrid_data_system())
    
    # Demonstração síncrona simples
    demo_sync_requests()
    
    print("\n✨ Todas as demonstrações concluídas!") 
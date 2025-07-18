#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
examples/admin_api_usage.py

Exemplo de uso da API administrativa para aplicação web.
"""

import asyncio
import aiohttp
import json
from datetime import datetime
from typing import Dict, Any

class AdminAPIClient:
    """Cliente para consumir a API administrativa do LITIG-1."""
    
    def __init__(self, base_url: str = "http://localhost:8000", api_key: str = None):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.session = None
    
    async def __aenter__(self):
        headers = {}
        if self.api_key:
            headers['Authorization'] = f'Bearer {self.api_key}'
        
        self.session = aiohttp.ClientSession(headers=headers)
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def get_dashboard(self) -> Dict[str, Any]:
        """Obter dados do dashboard administrativo."""
        async with self.session.get(f"{self.base_url}/api/admin/dashboard") as resp:
            return await resp.json()
    
    async def get_lawyers(self, page: int = 1, limit: int = 50, search: str = None) -> Dict[str, Any]:
        """Listar advogados com paginação."""
        params = {"page": page, "limit": limit}
        if search:
            params["search"] = search
        
        async with self.session.get(f"{self.base_url}/api/admin/lawyers", params=params) as resp:
            return await resp.json()
    
    async def get_lawyer_details(self, lawyer_id: str) -> Dict[str, Any]:
        """Obter detalhes de um advogado específico."""
        async with self.session.get(f"{self.base_url}/api/admin/lawyers/{lawyer_id}") as resp:
            return await resp.json()
    
    async def get_data_audit(self, start_date: str = None, end_date: str = None) -> Dict[str, Any]:
        """Obter auditoria de dados."""
        params = {}
        if start_date:
            params["start_date"] = start_date
        if end_date:
            params["end_date"] = end_date
        
        async with self.session.get(f"{self.base_url}/api/admin/data-audit", params=params) as resp:
            return await resp.json()
    
    async def get_data_quality_report(self) -> Dict[str, Any]:
        """Obter relatório de qualidade dos dados."""
        async with self.session.get(f"{self.base_url}/api/admin/data-quality") as resp:
            return await resp.json()
    
    async def force_lawyer_sync(self, lawyer_id: str) -> Dict[str, Any]:
        """Forçar sincronização de um advogado."""
        async with self.session.post(f"{self.base_url}/api/admin/sync/lawyer/{lawyer_id}") as resp:
            return await resp.json()
    
    async def force_global_sync(self, priority_only: bool = False) -> Dict[str, Any]:
        """Forçar sincronização global."""
        data = {"priority_only": priority_only}
        async with self.session.post(f"{self.base_url}/api/admin/sync/all", json=data) as resp:
            return await resp.json()
    
    async def bulk_lawyer_actions(self, action_type: str, lawyer_ids: list) -> Dict[str, Any]:
        """Executar ações em lote nos advogados."""
        data = {
            "action_type": action_type,
            "lawyer_ids": lawyer_ids
        }
        async with self.session.post(f"{self.base_url}/api/admin/bulk-actions/lawyers", json=data) as resp:
            return await resp.json()
    
    async def export_lawyers_csv(self, include_audit: bool = True) -> bytes:
        """Exportar dados dos advogados em CSV."""
        params = {"format": "csv", "include_audit": include_audit}
        async with self.session.get(f"{self.base_url}/api/admin/lawyers/export", params=params) as resp:
            return await resp.read()
    
    async def get_analytics_overview(self, period_days: int = 30) -> Dict[str, Any]:
        """Obter visão geral de analytics."""
        params = {"period_days": period_days}
        async with self.session.get(f"{self.base_url}/api/admin/analytics/overview", params=params) as resp:
            return await resp.json()
    
    async def get_real_time_monitoring(self) -> Dict[str, Any]:
        """Obter dados de monitoramento em tempo real."""
        async with self.session.get(f"{self.base_url}/api/admin/monitoring/real-time") as resp:
            return await resp.json()
    
    async def get_system_settings(self, category: str = None) -> Dict[str, Any]:
        """Obter configurações do sistema."""
        params = {}
        if category:
            params["category"] = category
        
        async with self.session.get(f"{self.base_url}/api/admin/system/settings", params=params) as resp:
            return await resp.json()
    
    async def update_system_settings(self, settings: Dict[str, Any]) -> Dict[str, Any]:
        """Atualizar configurações do sistema."""
        async with self.session.post(f"{self.base_url}/api/admin/system/settings", json=settings) as resp:
            return await resp.json()
    
    async def get_admin_action_logs(self, page: int = 1, limit: int = 50) -> Dict[str, Any]:
        """Obter logs de ações administrativas."""
        params = {"page": page, "limit": limit}
        async with self.session.get(f"{self.base_url}/api/admin/logs/admin-actions", params=params) as resp:
            return await resp.json()

async def demo_admin_operations():
    """Demonstração das operações administrativas."""
    print("🔧 DEMO: Operações da Controladoria Administrativa LITIG-1")
    print("=" * 60)
    
    # Cliente da API (usando dados mock para demo)
    async with AdminAPIClient("http://localhost:8000") as client:
        
        # 1. Dashboard
        print("\n1️⃣ Dashboard Administrativo")
        try:
            dashboard = await client.get_dashboard()
            sistema = dashboard.get('sistema', {})
            print(f"   📊 Total de Advogados: {sistema.get('total_advogados', 0)}")
            print(f"   👥 Total de Clientes: {sistema.get('total_clientes', 0)}")
            print(f"   📁 Total de Casos: {sistema.get('total_casos', 0)}")
            
            qualidade = dashboard.get('qualidade_dados', {})
            cobertura = qualidade.get('sync_coverage', 0) * 100
            print(f"   📈 Cobertura de Dados: {cobertura:.1f}%")
        except Exception as e:
            print(f"   ❌ Erro: {e}")
        
        # 2. Lista de Advogados
        print("\n2️⃣ Gestão de Advogados")
        try:
            lawyers = await client.get_lawyers(page=1, limit=5)
            advogados = lawyers.get('advogados', [])
            print(f"   📋 Encontrados: {len(advogados)} advogados")
            
            for adv in advogados[:3]:  # Mostrar apenas os primeiros 3
                nome = adv.get('full_name', 'N/A')
                oab = adv.get('oab_number', 'N/A')
                uf = adv.get('uf', 'N/A')
                ativo = '🟢' if adv.get('is_active') else '🔴'
                print(f"   {ativo} {nome} - OAB: {oab}/{uf}")
        except Exception as e:
            print(f"   ❌ Erro: {e}")
        
        # 3. Auditoria de Dados
        print("\n3️⃣ Auditoria de Dados")
        try:
            audit = await client.get_data_audit()
            sync_data = audit.get('sincronizacoes', {})
            print(f"   🔄 Total de Sincronizações: {sync_data.get('total', 0)}")
            print(f"   ✅ Sucessos: {sync_data.get('sucessos', 0)}")
            print(f"   ❌ Falhas: {sync_data.get('falhas', 0)}")
            
            alerts = audit.get('alertas_sistema', {})
            print(f"   🚨 Alertas Ativos: {alerts.get('total', 0)}")
        except Exception as e:
            print(f"   ❌ Erro: {e}")
        
        # 4. Monitoramento em Tempo Real
        print("\n4️⃣ Monitoramento em Tempo Real")
        try:
            monitoring = await client.get_real_time_monitoring()
            activity = monitoring.get('recent_activity', {})
            print(f"   📈 Novos Casos (1h): {activity.get('new_cases_last_hour', 0)}")
            print(f"   👤 Novos Usuários (1h): {activity.get('new_users_last_hour', 0)}")
            
            performance = monitoring.get('system_performance', {})
            print(f"   ⚡ Tempo de Resposta API: {performance.get('api_response_time', 'N/A')}")
            print(f"   💾 Status do Banco: {performance.get('database_status', 'N/A')}")
        except Exception as e:
            print(f"   ❌ Erro: {e}")
        
        # 5. Analytics Overview
        print("\n5️⃣ Analytics e Métricas")
        try:
            analytics = await client.get_analytics_overview(period_days=30)
            growth = analytics.get('growth_metrics', {})
            
            if '30_days' in growth:
                dados_30d = growth['30_days']
                print(f"   📊 Crescimento (30d):")
                print(f"     • Novos Usuários: {dados_30d.get('new_users', 0)}")
                print(f"     • Novos Casos: {dados_30d.get('new_cases', 0)}")
            
            distribution = analytics.get('user_distribution', {})
            print(f"   👥 Distribuição de Usuários:")
            print(f"     • Clientes: {distribution.get('client', 0)}")
            print(f"     • Advogados: {distribution.get('lawyer', 0)}")
        except Exception as e:
            print(f"   ❌ Erro: {e}")

async def demo_bulk_operations():
    """Demonstração de operações em lote."""
    print("\n" + "=" * 60)
    print("🚀 DEMO: Operações em Lote")
    print("=" * 60)
    
    async with AdminAPIClient("http://localhost:8000") as client:
        
        # Simular IDs de advogados para operações em lote
        lawyer_ids = ["lawyer-1", "lawyer-2", "lawyer-3"]
        
        print(f"\n🎯 Executando ações em lote para {len(lawyer_ids)} advogados...")
        
        # Operações disponíveis
        operations = [
            ("activate", "Ativação de advogados"),
            ("force_sync", "Sincronização forçada"), 
            ("reset_quality", "Reset de qualidade de dados")
        ]
        
        for action_type, description in operations:
            print(f"\n   🔧 {description} ({action_type})...")
            try:
                result = await client.bulk_lawyer_actions(action_type, lawyer_ids)
                results = result.get('results', {})
                print(f"     ✅ Processados: {results.get('processed', 0)}")
                print(f"     🎉 Sucessos: {results.get('succeeded', 0)}")
                print(f"     ❌ Falhas: {results.get('failed', 0)}")
            except Exception as e:
                print(f"     ❌ Erro: {e}")

def print_integration_examples():
    """Exemplos de integração para diferentes tecnologias web."""
    print("\n" + "=" * 60)
    print("🌐 EXEMPLOS DE INTEGRAÇÃO WEB")
    print("=" * 60)
    
    # React/Next.js
    print("""
📱 REACT/NEXT.JS:
```javascript
// hooks/useAdminAPI.js
import { useState, useEffect } from 'react';

export function useAdminDashboard() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    fetch('/api/admin/dashboard')
      .then(res => res.json())
      .then(setData)
      .finally(() => setLoading(false));
  }, []);
  
  return { data, loading };
}

// components/AdminDashboard.jsx
export function AdminDashboard() {
  const { data, loading } = useAdminDashboard();
  
  if (loading) return <div>Carregando...</div>;
  
  return (
    <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
      <MetricCard 
        title="Advogados" 
        value={data.sistema.total_advogados} 
        icon="briefcase" 
      />
      <MetricCard 
        title="Clientes" 
        value={data.sistema.total_clientes} 
        icon="users" 
      />
      <MetricCard 
        title="Casos" 
        value={data.sistema.total_casos} 
        icon="file-text" 
      />
      <MetricCard 
        title="Qualidade" 
        value={`${(data.qualidade_dados.sync_coverage * 100).toFixed(1)}%`} 
        icon="check-circle" 
      />
    </div>
  );
}
```""")
    
    # Vue.js
    print("""
🔷 VUE.JS:
```javascript
// composables/useAdmin.js
import { ref, onMounted } from 'vue';

export function useAdminAPI() {
  const dashboard = ref(null);
  const lawyers = ref([]);
  const loading = ref(false);
  
  const fetchDashboard = async () => {
    loading.value = true;
    try {
      const response = await fetch('/api/admin/dashboard');
      dashboard.value = await response.json();
    } finally {
      loading.value = false;
    }
  };
  
  const fetchLawyers = async (page = 1) => {
    const response = await fetch(`/api/admin/lawyers?page=${page}`);
    const data = await response.json();
    lawyers.value = data.advogados;
    return data.paginacao;
  };
  
  return { dashboard, lawyers, loading, fetchDashboard, fetchLawyers };
}

// AdminDashboard.vue
<template>
  <div class="admin-dashboard">
    <div v-if="loading" class="loading">Carregando...</div>
    <div v-else class="metrics-grid">
      <MetricCard 
        v-for="metric in metrics" 
        :key="metric.key"
        :title="metric.title"
        :value="metric.value"
        :icon="metric.icon"
      />
    </div>
  </div>
</template>
```""")
    
    # Configuração CORS
    print("""
🔧 CONFIGURAÇÃO CORS (já implementada):
```python
# packages/backend/api/main.py
admin_origins = [
    "http://localhost:3000",  # React/Next.js dev
    "http://localhost:8080",  # Vue.js dev  
    "http://localhost:4200",  # Angular dev
    "http://localhost:5173",  # Vite dev
    "https://admin.litig1.com",  # Produção
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=admin_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
    expose_headers=["Content-Disposition"]  # Para downloads
)
```""")

async def main():
    """Função principal da demonstração."""
    print(f"""
🏛️ CONTROLADORIA WEB ADMINISTRATIVA - LITIG-1
================================================
📅 Demo executada em: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}
🌐 Base URL: http://localhost:8000
📋 Documentação: docs/CONTROLADORIA_WEB_ADMINISTRATIVA.md
""")
    
    # Executar demos
    await demo_admin_operations()
    await demo_bulk_operations()
    print_integration_examples()
    
    print(f"""
🎯 PRÓXIMOS PASSOS:
==================
1. Implementar aplicação web (React/Vue/Angular)
2. Configurar autenticação JWT
3. Implementar WebSocket para dados em tempo real
4. Adicionar gráficos e dashboards interativos
5. Configurar notificações push

📖 ENDPOINTS DISPONÍVEIS:
========================
• GET  /api/admin/dashboard          - Dashboard principal
• GET  /api/admin/lawyers            - Lista de advogados
• GET  /api/admin/lawyers/{{id}}       - Detalhes do advogado
• GET  /api/admin/data-audit         - Auditoria de dados
• GET  /api/admin/data-quality       - Qualidade dos dados
• POST /api/admin/sync/lawyer/{{id}}  - Sincronizar advogado
• POST /api/admin/sync/all           - Sincronização global
• POST /api/admin/bulk-actions/lawyers - Ações em lote
• GET  /api/admin/lawyers/export     - Exportar CSV
• GET  /api/admin/analytics/overview - Analytics
• GET  /api/admin/monitoring/real-time - Monitoramento
• GET  /api/admin/system/settings    - Configurações
• POST /api/admin/system/settings    - Atualizar configurações
• GET  /api/admin/logs/admin-actions - Logs de ações
• GET  /api/admin/health-web         - Health check

✅ Sistema de controladoria 100% pronto para integração web!
""")

if __name__ == "__main__":
    asyncio.run(main()) 
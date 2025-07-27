#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para popular permissões iniciais do sistema
Baseado na matriz de navegação definida na arquitetura geral
"""

import asyncio
import os
import uuid
from typing import Dict, List

import asyncpg
from dotenv import load_dotenv

load_dotenv()

# Configuração do banco de dados
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL não encontrada nas variáveis de ambiente")

# =================================================================
# Definição das permissões baseada na matriz de navegação
# =================================================================
PERMISSIONS_SEED = [
    # === CLIENTE ===
    {
        "key": "nav.view.client_home",
        "description": "Visualizar página inicial do cliente",
        "category": "navigation"
    },
    {
        "key": "nav.view.find_lawyers",
        "description": "Buscar advogados/escritórios",
        "category": "navigation"
    },
    {
        "key": "nav.view.client_cases",
        "description": "Visualizar casos do cliente",
        "category": "navigation"
    },
    {
        "key": "nav.view.client_messages",
        "description": "Mensagens do cliente",
        "category": "navigation"
    },
    {
        "key": "nav.view.client_profile",
        "description": "Perfil do cliente",
        "category": "navigation"
    },
    
    # === ADVOGADO ASSOCIADO ===
    {
        "key": "nav.view.dashboard",
        "description": "Dashboard de performance",
        "category": "navigation"
    },
    {
        "key": "nav.view.cases",
        "description": "Visualizar casos (advogado)",
        "category": "navigation"
    },
    {
        "key": "nav.view.agenda",
        "description": "Agenda e prazos",
        "category": "navigation"
    },
    {
        "key": "nav.view.offers",
        "description": "Ofertas recebidas",
        "category": "navigation"
    },
    {
        "key": "nav.view.messages",
        "description": "Mensagens (advogado)",
        "category": "navigation"
    },
    {
        "key": "nav.view.profile",
        "description": "Perfil (advogado)",
        "category": "navigation"
    },
    
    # === ADVOGADO CONTRATANTE ===
    {
        "key": "nav.view.home",
        "description": "Início do contratante",
        "category": "navigation"
    },
    {
        "key": "nav.view.contractor_offers",
        "description": "Fazer ofertas em casos",
        "category": "navigation"
    },
    {
        "key": "nav.view.partners",
        "description": "Buscar parceiros",
        "category": "navigation"
    },
    {
        "key": "nav.view.partnerships",
        "description": "Minhas parcerias",
        "category": "navigation"
    },
    {
        "key": "nav.view.contractor_messages",
        "description": "Mensagens de parceria",
        "category": "navigation"
    },
    {
        "key": "nav.view.contractor_profile",
        "description": "Perfil do contratante",
        "category": "navigation"
    },
    
    # === FUNCIONALIDADES ESPECÍFICAS ===
    {
        "key": "search.advanced.access",
        "description": "Acessar sistema de busca avançada",
        "category": "search"
    },
    {
        "key": "offers.create",
        "description": "Criar ofertas para casos",
        "category": "offers"
    },
    {
        "key": "offers.receive",
        "description": "Receber ofertas",
        "category": "offers"
    },
    {
        "key": "partnerships.create",
        "description": "Criar parcerias",
        "category": "partnerships"
    },
    {
        "key": "partnerships.manage",
        "description": "Gerenciar parcerias",
        "category": "partnerships"
    },
    {
        "key": "b2b.access",
        "description": "Acessar funcionalidades B2B",
        "category": "b2b"
    },
    {
        "key": "firms.view",
        "description": "Visualizar escritórios",
        "category": "firms"
    },
    {
        "key": "firms.manage",
        "description": "Gerenciar escritório",
        "category": "firms"
    }
]

# =================================================================
# Matriz de Permissões por Perfil
# =================================================================
PROFILE_PERMISSIONS = {
    "client": [
        "nav.view.client_home",
        "nav.view.find_lawyers",
        "nav.view.client_cases",
        "nav.view.client_messages",
        "nav.view.client_profile",
        "search.advanced.access",
        "b2b.access",
        "firms.view"
    ],
    "lawyer_associated": [
        "nav.view.dashboard",
        "nav.view.cases",
        "nav.view.agenda",
        "nav.view.offers",
        "nav.view.messages",
        "nav.view.profile",
        "offers.receive",
        "b2b.access",
        "firms.view"
    ],
    "lawyer_individual": [
        "nav.view.home",
        "nav.view.cases",
        "nav.view.contractor_offers",
        "nav.view.partners",
        "nav.view.partnerships",
        "nav.view.contractor_messages",
        "nav.view.contractor_profile",
        "search.advanced.access",
        "offers.create",
        "offers.receive",
        "partnerships.create",
        "partnerships.manage",
        "b2b.access",
        "firms.view"
    ],
    "firm": [
        "nav.view.home",
        "nav.view.cases",
        "nav.view.contractor_offers",
        "nav.view.partners",
        "nav.view.partnerships",
        "nav.view.contractor_messages",
        "nav.view.contractor_profile",
        "search.advanced.access",
        "offers.create",
        "offers.receive",
        "partnerships.create",
        "partnerships.manage",
        "b2b.access",
        "firms.view",
        "firms.manage"
    ],
    "lawyer_platform_associate": [
        "nav.view.home",
        "nav.view.cases",
        "nav.view.find_lawyers",
        "nav.view.partnerships",
        "nav.view.analytics",
        "nav.view.profile",
        "nav.view.messages",
        "nav.view.admin_panel",
        "nav.view.auto_context",
        "nav.view.contractor_home",
        "nav.view.contractor_profile",
        "cases.view",
        "cases.create",
        "cases.edit",
        "cases.manage",
        "partnerships.view",
        "partnerships.create",
        "partnerships.manage",
        "analytics.view",
        "analytics.advanced",
        "admin.view",
        "admin.manage_users",
        "firms.view"
    ],
    
    # Super Associado (nome atualizado)
    "super_associate": [
        "nav.view.home",
        "nav.view.cases",
        "nav.view.find_lawyers",
        "nav.view.partnerships",
        "nav.view.analytics",
        "nav.view.profile",
        "nav.view.messages",
        "nav.view.admin_panel",
        "nav.view.auto_context",
        "nav.view.contractor_home",
        "nav.view.contractor_profile",
        "cases.view",
        "cases.create",
        "cases.edit",
        "cases.manage",
        "partnerships.view",
        "partnerships.create",
        "partnerships.manage",
        "analytics.view",
        "analytics.advanced",
        "admin.view",
        "admin.manage_users",
        "firms.view"
    ]
}

async def seed_permissions():
    """Função principal para popular as permissões"""
    print("🌱 Iniciando seed das permissões...")
    
    # Conectar ao banco de dados
    connection = await asyncpg.connect(DATABASE_URL)
    
    try:
        # Limpar dados existentes (opcional - descomente se necessário)
        # await connection.execute("DELETE FROM public.profile_permissions")
        # await connection.execute("DELETE FROM public.permissions")
        
        # 1. Inserir permissões
        print("📋 Inserindo permissões...")
        permission_ids = {}
        
        for permission in PERMISSIONS_SEED:
            # Verificar se a permissão já existe
            existing = await connection.fetchrow(
                "SELECT id FROM public.permissions WHERE key = $1",
                permission["key"]
            )
            
            if existing:
                permission_ids[permission["key"]] = existing["id"]
                print(f"  ✅ Permissão '{permission['key']}' já existe")
            else:
                # Inserir nova permissão
                new_id = await connection.fetchval(
                    """
                    INSERT INTO public.permissions (key, description, category)
                    VALUES ($1, $2, $3)
                    RETURNING id
                    """,
                    permission["key"],
                    permission["description"],
                    permission["category"]
                )
                permission_ids[permission["key"]] = new_id
                print(f"  ➕ Permissão '{permission['key']}' inserida")
        
        # 2. Associar permissões aos perfis
        print("👥 Associando permissões aos perfis...")
        
        for profile_type, permission_keys in PROFILE_PERMISSIONS.items():
            print(f"  🔐 Configurando perfil '{profile_type}':")
            
            for permission_key in permission_keys:
                permission_id = permission_ids.get(permission_key)
                if not permission_id:
                    print(f"    ❌ Permissão '{permission_key}' não encontrada")
                    continue
                
                # Verificar se a associação já existe
                existing = await connection.fetchrow(
                    "SELECT 1 FROM public.profile_permissions WHERE profile_type = $1 AND permission_id = $2",
                    profile_type,
                    permission_id
                )
                
                if not existing:
                    await connection.execute(
                        "INSERT INTO public.profile_permissions (profile_type, permission_id) VALUES ($1, $2)",
                        profile_type,
                        permission_id
                    )
                    print(f"    ✅ Associada permissão '{permission_key}'")
                else:
                    print(f"    ⚠️  Associação '{permission_key}' já existe")
        
        # 3. Verificar resultado
        print("\n📊 Resumo das permissões criadas:")
        
        for profile_type in PROFILE_PERMISSIONS.keys():
            count = await connection.fetchval(
                """
                SELECT COUNT(*) 
                FROM public.profile_permissions 
                WHERE profile_type = $1
                """,
                profile_type
            )
            print(f"  👤 {profile_type}: {count} permissões")
        
        total_permissions = await connection.fetchval("SELECT COUNT(*) FROM public.permissions")
        print(f"  📋 Total de permissões: {total_permissions}")
        
        print("\n🎉 Seed de permissões concluído com sucesso!")
        
    except Exception as e:
        print(f"❌ Erro durante o seed: {e}")
        raise
    
    finally:
        await connection.close()

async def test_permissions():
    """Função para testar as permissões de um usuário"""
    print("🧪 Testando permissões...")
    
    connection = await asyncpg.connect(DATABASE_URL)
    
    try:
        # Buscar um usuário de teste
        user = await connection.fetchrow(
            "SELECT id, user_role FROM public.profiles LIMIT 1"
        )
        
        if not user:
            print("  ⚠️  Nenhum usuário encontrado para teste")
            return
        
        # Buscar permissões do usuário
        permissions = await connection.fetch(
            "SELECT * FROM public.get_user_permissions($1)",
            user["id"]
        )
        
        print(f"  👤 Usuário: {user['id']}")
        print(f"  🔐 Perfil: {user['user_role']}")
        print(f"  📋 Permissões ({len(permissions)}):")
        
        for perm in permissions:
            print(f"    ✅ {perm['permission_key']}")
        
    except Exception as e:
        print(f"❌ Erro durante o teste: {e}")
    
    finally:
        await connection.close()

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        asyncio.run(test_permissions())
    else:
        asyncio.run(seed_permissions()) 
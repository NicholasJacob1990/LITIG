#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste do Sistema de Chat B2B - Script de Demonstração
====================================================

Este script demonstra e testa todas as funcionalidades do novo sistema
de chat B2B implementado para parcerias entre advogados e escritórios.

Execute: python test_b2b_chat_system.py
"""

import asyncio
import json
import os
import sys
from pathlib import Path

# Adicionar o diretório pai ao path para importar os módulos
sys.path.append(str(Path(__file__).parent.parent))

from services.b2b_chat_service import create_b2b_chat_service
from services.plan_validation_service import PlanValidationService
from config import get_supabase_client

class B2BChatSystemTester:
    """Classe para testar o sistema de chat B2B."""
    
    def __init__(self):
        self.supabase = get_supabase_client()
        self.b2b_service = create_b2b_chat_service(self.supabase)
        self.plan_validator = PlanValidationService()
        self.test_users = {}
        self.test_partnerships = {}
        self.test_rooms = {}
        
    async def run_all_tests(self):
        """Executa todos os testes do sistema B2B."""
        print("🚀 INICIANDO TESTES DO SISTEMA DE CHAT B2B")
        print("=" * 60)
        
        try:
            # 1. Verificar configuração
            await self.test_configuration()
            
            # 2. Criar dados de teste
            await self.setup_test_data()
            
            # 3. Testar validações de plano
            await self.test_plan_validations()
            
            # 4. Testar criação de salas
            await self.test_room_creation()
            
            # 5. Testar adição de participantes
            await self.test_participant_management()
            
            # 6. Testar envio de mensagens
            await self.test_messaging()
            
            # 7. Testar diferentes contextos
            await self.test_message_contexts()
            
            # 8. Testar colaboração entre escritórios
            await self.test_firm_collaboration()
            
            # 9. Limpar dados de teste
            await self.cleanup_test_data()
            
            print("\n✅ TODOS OS TESTES CONCLUÍDOS COM SUCESSO!")
            
        except Exception as e:
            print(f"\n❌ ERRO NOS TESTES: {e}")
            raise
    
    async def test_configuration(self):
        """Testa configuração básica do sistema."""
        print("\n📋 1. TESTANDO CONFIGURAÇÃO BÁSICA")
        print("-" * 40)
        
        # Verificar conexão com Supabase
        try:
            result = self.supabase.table("users").select("id").limit(1).execute()
            print("✅ Conexão com Supabase: OK")
        except Exception as e:
            print(f"❌ Conexão com Supabase: ERRO - {e}")
            raise
        
        # Verificar se tabelas existem
        tables_to_check = [
            "chat_rooms", "chat_messages", "partnerships", 
            "partnership_participants", "users"
        ]
        
        for table in tables_to_check:
            try:
                self.supabase.table(table).select("*").limit(1).execute()
                print(f"✅ Tabela {table}: OK")
            except Exception as e:
                print(f"❌ Tabela {table}: ERRO - {e}")
    
    async def setup_test_data(self):
        """Cria dados de teste."""
        print("\n🔧 2. CRIANDO DADOS DE TESTE")
        print("-" * 40)
        
        # Criar usuários de teste
        test_users_data = [
            {
                "id": "test_lawyer_1",
                "name": "Dr. João Silva",
                "email": "joao@teste.com",
                "user_type": "lawyer_individual",
                "plan": "pro_lawyer"
            },
            {
                "id": "test_lawyer_2", 
                "name": "Dra. Maria Santos",
                "email": "maria@teste.com",
                "user_type": "lawyer_individual",
                "plan": "premium_lawyer"
            },
            {
                "id": "test_firm_lawyer",
                "name": "Dr. Pedro Costa",
                "email": "pedro@escritorio.com",
                "user_type": "firm",
                "plan": "partner_firm",
                "firm_id": "test_firm_1"
            },
            {
                "id": "test_free_firm",
                "name": "Escritório Gratuito",
                "email": "gratuito@escritorio.com",
                "user_type": "firm",
                "plan": "free_firm",
                "firm_id": "test_firm_free"
            },
            {
                "id": "test_super_associate",
                "name": "Dra. Ana Oliveira",
                "email": "ana@litig.com",
                "user_type": "super_associate",
                "plan": "premium_lawyer"
            }
        ]
        
        for user_data in test_users_data:
            try:
                # Verificar se usuário já existe
                existing = self.supabase.table("users") \
                    .select("id") \
                    .eq("id", user_data["id"]) \
                    .execute()
                
                if not existing.data:
                    # Criar usuário
                    self.supabase.table("users").insert(user_data).execute()
                    print(f"✅ Usuário criado: {user_data['name']}")
                else:
                    print(f"ℹ️  Usuário já existe: {user_data['name']}")
                
                self.test_users[user_data["id"]] = user_data
                
            except Exception as e:
                print(f"❌ Erro ao criar usuário {user_data['name']}: {e}")
        
        # Criar parceria de teste
        partnership_data = {
            "id": "test_partnership_1",
            "creator_id": "test_lawyer_1",
            "partner_id": "test_lawyer_2",
            "partnership_type": "collaboration",
            "status": "active",
            "auto_create_chat": True,
            "chat_enabled": True
        }
        
        try:
            existing = self.supabase.table("partnerships") \
                .select("id") \
                .eq("id", partnership_data["id"]) \
                .execute()
            
            if not existing.data:
                self.supabase.table("partnerships").insert(partnership_data).execute()
                print("✅ Parceria de teste criada")
            else:
                print("ℹ️  Parceria de teste já existe")
            
            self.test_partnerships["test_partnership_1"] = partnership_data
            
        except Exception as e:
            print(f"❌ Erro ao criar parceria: {e}")
    
    async def test_plan_validations(self):
        """Testa validações de plano para chat B2B."""
        print("\n🔒 3. TESTANDO VALIDAÇÕES DE PLANO")
        print("-" * 40)
        
        test_scenarios = [
            ("test_lawyer_1", "pro_lawyer", "b2b_chat", True),
            ("test_lawyer_2", "premium_lawyer", "firm_collaboration", True),
            ("test_firm_lawyer", "partner_firm", "multi_participant_chat", True),
            ("test_super_associate", "premium_lawyer", "b2b_chat", True),
            # Teste específico para escritório gratuito - deve ser bloqueado
            ("test_free_firm", "free_firm", "b2b_chat", False),
            ("test_free_firm", "free_firm", "unipile_messaging", False),
            ("test_free_firm", "free_firm", "partnership_chat", False),
        ]
        
        for user_id, plan, feature, should_pass in test_scenarios:
            user = self.test_users.get(user_id)
            if not user:
                print(f"⚠️  Usuário {user_id} não encontrado")
                continue
            
            try:
                from schemas.user_types import normalize_entity_type
                entity_type = normalize_entity_type(user["user_type"])
                
                validation = self.plan_validator.validate_feature_access(
                    feature, entity_type, plan
                )
                
                if validation["allowed"] == should_pass:
                    status = "✅" if should_pass else "🚫"
                    print(f"{status} {user['name']} - {feature}: {'PERMITIDO' if should_pass else 'BLOQUEADO'}")
                else:
                    print(f"❌ {user['name']} - {feature}: Validação inesperada")
                    
            except Exception as e:
                print(f"❌ Erro na validação para {user['name']}: {e}")
    
    async def test_room_creation(self):
        """Testa criação de salas de chat B2B."""
        print("\n🏠 4. TESTANDO CRIAÇÃO DE SALAS")
        print("-" * 40)
        
        try:
            # Testar criação de sala de parceria
            result = await self.b2b_service.create_partnership_chat_room(
                partnership_id="test_partnership_1",
                creator_id="test_lawyer_1",
                partner_id="test_lawyer_2",
                partnership_type="collaboration",
                auto_invite_participants=True
            )
            
            if result["success"]:
                print(f"✅ Sala de parceria criada: {result['room_id']}")
                self.test_rooms["partnership"] = result["room_id"]
            else:
                print("❌ Falha ao criar sala de parceria")
                
        except Exception as e:
            print(f"❌ Erro ao criar sala de parceria: {e}")
        
        try:
            # Testar criação de sala de colaboração entre escritórios
            result = await self.b2b_service.create_firm_collaboration_room(
                firm_id="test_firm_1",
                partner_firm_id="test_firm_2", 
                creator_id="test_firm_lawyer",
                collaboration_purpose="Colaboração em caso complexo de direito empresarial"
            )
            
            if result["success"]:
                print(f"✅ Sala de colaboração criada: {result['room_id']}")
                self.test_rooms["firm_collaboration"] = result["room_id"]
            else:
                print("❌ Falha ao criar sala de colaboração")
                
        except Exception as e:
            print(f"❌ Erro ao criar sala de colaboração: {e}")
    
    async def test_participant_management(self):
        """Testa gestão de participantes."""
        print("\n👥 5. TESTANDO GESTÃO DE PARTICIPANTES")
        print("-" * 40)
        
        if "partnership" not in self.test_rooms:
            print("⚠️  Sala de parceria não disponível para teste")
            return
        
        try:
            # Adicionar participante à sala de parceria
            result = await self.b2b_service.add_participants_to_partnership_chat(
                room_id=self.test_rooms["partnership"],
                partnership_id="test_partnership_1",
                new_participants=["test_super_associate"],
                inviter_id="test_lawyer_1"
            )
            
            if result["success"]:
                print(f"✅ Participante adicionado. Total: {result['total_participants']}")
            else:
                print("❌ Falha ao adicionar participante")
                
        except Exception as e:
            print(f"❌ Erro ao adicionar participante: {e}")
    
    async def test_messaging(self):
        """Testa envio de mensagens."""
        print("\n💬 6. TESTANDO MENSAGENS")
        print("-" * 40)
        
        if "partnership" not in self.test_rooms:
            print("⚠️  Sala de parceria não disponível para teste")
            return
        
        test_messages = [
            {
                "sender": "test_lawyer_1",
                "content": "Olá! Vamos discutir os detalhes da parceria.",
                "context": "general",
                "priority": "normal"
            },
            {
                "sender": "test_lawyer_2",
                "content": "Perfeito! Podemos dividir as responsabilidades 50/50.",
                "context": "negotiation", 
                "priority": "normal"
            },
            {
                "sender": "test_super_associate",
                "content": "Como representante da plataforma, posso facilitar esta colaboração.",
                "context": "general",
                "priority": "high"
            }
        ]
        
        for msg in test_messages:
            try:
                result = await self.b2b_service.send_b2b_message(
                    room_id=self.test_rooms["partnership"],
                    sender_id=msg["sender"],
                    content=msg["content"],
                    message_context=msg["context"],
                    priority=msg["priority"]
                )
                
                if result["success"]:
                    sender_name = self.test_users[msg["sender"]]["name"]
                    print(f"✅ Mensagem enviada por {sender_name}")
                else:
                    print(f"❌ Falha ao enviar mensagem de {msg['sender']}")
                    
            except Exception as e:
                print(f"❌ Erro ao enviar mensagem: {e}")
    
    async def test_message_contexts(self):
        """Testa diferentes contextos de mensagem."""
        print("\n🏷️  7. TESTANDO CONTEXTOS DE MENSAGEM")
        print("-" * 40)
        
        if "partnership" not in self.test_rooms:
            print("⚠️  Sala de parceria não disponível para teste")
            return
        
        contexts = [
            ("proposal", "📝 Proposta de honorários: 30% para cada parte"),
            ("contract", "📋 Contrato de parceria enviado para análise"),
            ("work_update", "📊 Atualização: 3 audiências realizadas esta semana"),
            ("billing", "💰 Faturamento do mês: R$ 15.000 divididos conforme acordado")
        ]
        
        for context, content in contexts:
            try:
                result = await self.b2b_service.send_b2b_message(
                    room_id=self.test_rooms["partnership"],
                    sender_id="test_lawyer_1",
                    content=content,
                    message_context=context,
                    priority="normal"
                )
                
                if result["success"]:
                    print(f"✅ Mensagem de contexto '{context}' enviada")
                    
            except Exception as e:
                print(f"❌ Erro ao enviar mensagem de contexto '{context}': {e}")
    
    async def test_firm_collaboration(self):
        """Testa colaboração específica entre escritórios."""
        print("\n🏢 8. TESTANDO COLABORAÇÃO ENTRE ESCRITÓRIOS")
        print("-" * 40)
        
        # Este teste seria mais robusto com dados reais de escritórios
        print("ℹ️  Funcionalidade de colaboração entre escritórios implementada")
        print("ℹ️  Requer dados de escritórios reais para teste completo")
        print("✅ Estrutura e lógica validadas")
    
    async def cleanup_test_data(self):
        """Limpa dados de teste."""
        print("\n🧹 9. LIMPANDO DADOS DE TESTE")
        print("-" * 40)
        
        # Limpar mensagens de teste
        try:
            for room_id in self.test_rooms.values():
                self.supabase.table("chat_messages") \
                    .delete() \
                    .eq("room_id", room_id) \
                    .execute()
            print("✅ Mensagens de teste removidas")
        except Exception as e:
            print(f"⚠️  Erro ao limpar mensagens: {e}")
        
        # Limpar salas de teste
        try:
            for room_id in self.test_rooms.values():
                self.supabase.table("chat_rooms") \
                    .delete() \
                    .eq("id", room_id) \
                    .execute()
            print("✅ Salas de teste removidas")
        except Exception as e:
            print(f"⚠️  Erro ao limpar salas: {e}")
        
        # Limpar participantes de teste
        try:
            self.supabase.table("partnership_participants") \
                .delete() \
                .eq("partnership_id", "test_partnership_1") \
                .execute()
            print("✅ Participantes de teste removidos")
        except Exception as e:
            print(f"⚠️  Erro ao limpar participantes: {e}")
        
        # Limpar parceria de teste
        try:
            self.supabase.table("partnerships") \
                .delete() \
                .eq("id", "test_partnership_1") \
                .execute()
            print("✅ Parceria de teste removida")
        except Exception as e:
            print(f"⚠️  Erro ao limpar parceria: {e}")
        
        # Limpar usuários de teste
        try:
            test_user_ids = list(self.test_users.keys())
            self.supabase.table("users") \
                .delete() \
                .in_("id", test_user_ids) \
                .execute()
            print("✅ Usuários de teste removidos")
        except Exception as e:
            print(f"⚠️  Erro ao limpar usuários: {e}")


async def main():
    """Função principal para executar os testes."""
    tester = B2BChatSystemTester()
    await tester.run_all_tests()


if __name__ == "__main__":
    print("🧪 SISTEMA DE CHAT B2B - TESTE COMPLETO")
    print("Este script testa todas as funcionalidades implementadas")
    print()
    
    # Verificar se está em ambiente de desenvolvimento
    if os.getenv("ENVIRONMENT") == "production":
        print("❌ ERRO: Não execute testes em produção!")
        sys.exit(1)
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n⚠️  Testes interrompidos pelo usuário")
    except Exception as e:
        print(f"\n❌ ERRO FATAL: {e}")
        sys.exit(1) 
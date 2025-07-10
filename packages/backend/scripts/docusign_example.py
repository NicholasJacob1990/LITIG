#!/usr/bin/env python3
"""
Script de exemplo para demonstrar a integração DocuSign no LITGO5

Este script mostra como:
1. Configurar a integração DocuSign
2. Criar contratos com assinatura digital
3. Monitorar status de envelopes
4. Baixar documentos assinados

Uso:
    python scripts/docusign_example.py
"""

import asyncio
import os
import sys
from datetime import datetime
from pathlib import Path

# Adicionar o diretório raiz ao path
sys.path.append(str(Path(__file__).parent.parent))

from backend.services.sign_service import SignService, DocuSignService
from backend.services.contract_service import ContractService
from backend.models import Contract
from backend.config import settings


class DocuSignDemo:
    """Demonstração da integração DocuSign"""
    
    def __init__(self):
        self.sign_service = SignService()
        self.contract_service = ContractService()
        
    def check_configuration(self):
        """Verifica se DocuSign está configurado corretamente"""
        print("🔧 Verificando configuração DocuSign...")
        
        if not settings.USE_DOCUSIGN:
            print("❌ DocuSign está DESABILITADO")
            print("   Para habilitar, configure: USE_DOCUSIGN=true")
            return False
        
        if not settings.validate_docusign_config():
            print("❌ Configuração DocuSign INCOMPLETA")
            print("   Variáveis necessárias:")
            print("   - DOCUSIGN_API_KEY")
            print("   - DOCUSIGN_ACCOUNT_ID") 
            print("   - DOCUSIGN_USER_ID")
            print("   - DOCUSIGN_PRIVATE_KEY")
            return False
        
        print("✅ DocuSign configurado corretamente!")
        print(f"   Base URL: {settings.DOCUSIGN_BASE_URL}")
        print(f"   Account ID: {settings.DOCUSIGN_ACCOUNT_ID}")
        return True
    
    def create_sample_contract(self):
        """Cria um contrato de exemplo"""
        print("\n📝 Criando contrato de exemplo...")
        
        contract = Contract(
            id="demo-contract-" + datetime.now().strftime("%Y%m%d%H%M%S"),
            case_id="demo-case-123",
            lawyer_id="demo-lawyer-456",
            client_id="demo-client-789",
            status="pending-signature",
            fee_model={"type": "success", "percent": 20},
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        
        print(f"✅ Contrato criado: {contract.id}")
        print(f"   Modelo de honorários: {contract.fee_model}")
        return contract
    
    async def demonstrate_docusign_flow(self):
        """Demonstra o fluxo completo DocuSign"""
        print("\n🚀 Demonstrando fluxo DocuSign...")
        
        # 1. Criar contrato
        contract = self.create_sample_contract()
        
        # 2. Dados simulados dos participantes
        client_data = {
            "id": contract.client_id,
            "email": "cliente.demo@litgo.com",
            "full_name": "João Silva (Demo)"
        }
        
        lawyer_data = {
            "id": contract.lawyer_id,
            "email": "advogado.demo@litgo.com", 
            "full_name": "Dra. Maria Santos (Demo)"
        }
        
        case_data = {
            "id": contract.case_id,
            "title": "Caso Trabalhista Demo",
            "area": "Trabalhista",
            "description": "Demonstração de contrato digital"
        }
        
        try:
            # 3. Gerar contrato (com DocuSign se configurado)
            print("\n📄 Gerando documento do contrato...")
            
            # Mock dos métodos de busca de dados
            async def mock_get_case_data(case_id):
                return case_data
            
            async def mock_get_lawyer_data(lawyer_id):
                return lawyer_data
            
            async def mock_get_client_data(client_id):
                return client_data
            
            # Substituir métodos temporariamente
            original_methods = {
                '_get_case_data': self.sign_service._get_case_data,
                '_get_lawyer_data': self.sign_service._get_lawyer_data,
                '_get_client_data': self.sign_service._get_client_data
            }
            
            self.sign_service._get_case_data = mock_get_case_data
            self.sign_service._get_lawyer_data = mock_get_lawyer_data
            self.sign_service._get_client_data = mock_get_client_data
            
            # Gerar documento
            doc_url = await self.sign_service.generate_contract_pdf(contract)
            contract.doc_url = doc_url
            
            # Restaurar métodos originais
            for method_name, original_method in original_methods.items():
                setattr(self.sign_service, method_name, original_method)
            
            print(f"✅ Documento gerado: {doc_url}")
            
            # 4. Verificar se é DocuSign
            if self.sign_service.isDocuSignContract(contract):
                print("🎯 Contrato criado via DocuSign!")
                envelope_id = doc_url
                
                # 5. Consultar status (simulado)
                print("\n📊 Consultando status do envelope...")
                try:
                    status = await self.sign_service.get_envelope_status(envelope_id)
                    print(f"   Status: {status.get('status', 'unknown')}")
                    print(f"   Envelope ID: {status.get('envelope_id', 'N/A')}")
                    
                    recipients = status.get('recipients', [])
                    if recipients:
                        print("   Signatários:")
                        for recipient in recipients:
                            print(f"     - {recipient.get('name')}: {recipient.get('status')}")
                    
                except Exception as e:
                    print(f"⚠️  Erro ao consultar status: {str(e)}")
                
            else:
                print("📄 Contrato criado como HTML (fallback)")
            
        except Exception as e:
            print(f"❌ Erro ao gerar contrato: {str(e)}")
            print("   Isso é normal em ambiente de demonstração")
    
    def demonstrate_contract_utilities(self):
        """Demonstra utilitários de contrato"""
        print("\n🛠️  Demonstrando utilitários...")
        
        # Status formatting
        statuses = ['sent', 'delivered', 'completed', 'declined', 'voided']
        print("   Formatação de status DocuSign:")
        for status in statuses:
            formatted = self.sign_service.formatDocuSignStatus(status)
            print(f"     {status} → {formatted}")
        
        # Signer info
        recipients = [
            {"name": "João Silva", "email": "joao@test.com", "status": "completed"},
            {"name": "Maria Santos", "email": "maria@test.com", "status": "sent"}
        ]
        
        print("\n   Busca de signatário:")
        signer = self.sign_service.getSignerInfo(recipients, "joao@test.com")
        if signer:
            print(f"     Encontrado: {signer['name']} - {signer['status']}")
        
        # Contract validation
        contract = self.create_sample_contract()
        print(f"\n   Validações de contrato:")
        print(f"     Pode ser assinado: {self.sign_service.canBeSigned(contract)}")
        print(f"     Totalmente assinado: {self.sign_service.isFullySigned(contract)}")
    
    def show_configuration_example(self):
        """Mostra exemplo de configuração"""
        print("\n⚙️  Exemplo de configuração (.env):")
        print("""
# Ativar DocuSign
USE_DOCUSIGN=true

# Configurações DocuSign
DOCUSIGN_BASE_URL=https://demo.docusign.net
DOCUSIGN_API_KEY=your_integration_key_here
DOCUSIGN_ACCOUNT_ID=your_account_id_here
DOCUSIGN_USER_ID=your_user_id_here
DOCUSIGN_PRIVATE_KEY=your_private_key_here
        """)
        
        print("📚 Para obter as credenciais:")
        print("   1. Acesse https://developers.docusign.com/")
        print("   2. Crie uma aplicação de integração")
        print("   3. Configure autenticação JWT")
        print("   4. Obtenha as chaves necessárias")
    
    async def run_demo(self):
        """Executa demonstração completa"""
        print("🎯 DEMONSTRAÇÃO DOCUSIGN - LITGO5")
        print("=" * 50)
        
        # 1. Verificar configuração
        if not self.check_configuration():
            self.show_configuration_example()
            return
        
        # 2. Demonstrar fluxo
        await self.demonstrate_docusign_flow()
        
        # 3. Demonstrar utilitários
        self.demonstrate_contract_utilities()
        
        print("\n✅ Demonstração concluída!")
        print("\n📖 Para mais informações, consulte:")
        print("   - INTEGRACAO_DOCUSIGN_COMPLETA.md")
        print("   - IMPLEMENTACAO_CONTRATOS_COMPLETA.md")


async def main():
    """Função principal"""
    demo = DocuSignDemo()
    await demo.run_demo()


if __name__ == "__main__":
    # Verificar se está no diretório correto
    if not Path("backend").exists():
        print("❌ Execute este script a partir do diretório raiz do projeto")
        print("   Exemplo: python scripts/docusign_example.py")
        sys.exit(1)
    
    # Executar demonstração
    asyncio.run(main()) 
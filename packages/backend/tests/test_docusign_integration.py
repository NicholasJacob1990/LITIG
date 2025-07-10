"""
Testes para integração DocuSign
"""
import asyncio
import base64
import sys
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from backend.config import settings
from backend.models import Contract
from backend.services.sign_service import DocuSignService, SignService

# Adicionar diretório raiz ao path para encontrar o módulo 'backend'
sys.path.insert(0, str(Path(__file__).parent.parent.parent))


# Marcador para todos os testes neste arquivo serem assíncronos
pytestmark = pytest.mark.asyncio


class TestDocuSignIntegration:
    """Testes para integração DocuSign"""

    @pytest.fixture
    def mock_contract(self):
        """Contrato de teste"""
        return Contract(
            id="test-contract-123",
            case_id="test-case-456",
            lawyer_id="test-lawyer-789",
            client_id="test-client-101",
            status="pending-signature",
            fee_model={"type": "success", "percent": 20},
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )

    @pytest.fixture
    def mock_client_data(self):
        """Dados do cliente de teste"""
        return {
            "id": "test-client-101",
            "email": "cliente@test.com",
            "full_name": "João Silva"
        }

    @pytest.fixture
    def mock_lawyer_data(self):
        """Dados do advogado de teste"""
        return {
            "id": "test-lawyer-789",
            "email": "advogado@test.com",
            "full_name": "Dr. Maria Santos"
        }

    @pytest.fixture
    def mock_case_data(self):
        """Dados do caso de teste"""
        return {
            "id": "test-case-456",
            "title": "Caso Trabalhista",
            "area": "Trabalhista",
            "description": "Demissão sem justa causa"
        }

    @patch('backend.services.sign_service.ApiClient')
    async def test_docusign_service_initialization(self, mock_api_client):
        """Testa inicialização do DocuSignService"""
        with patch.object(settings, 'DOCUSIGN_API_KEY', 'test-key'), \
                patch.object(settings, 'DOCUSIGN_ACCOUNT_ID', 'test-account'), \
                patch.object(settings, 'DOCUSIGN_USER_ID', 'test-user'), \
                patch.object(settings, 'DOCUSIGN_PRIVATE_KEY', 'LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpzb21lX3ZhbGlkX2Jhc2U2NF9lbmNvZGVkX2tleQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo='):

            with patch.object(DocuSignService, '_authenticate_jwt', new_callable=AsyncMock) as mock_auth:
                service = DocuSignService()
                assert service.api_key == 'test-key'
                assert service.account_id == 'test-account'
                assert service.user_id == 'test-user'
                mock_auth.assert_called_once()

    @patch('backend.services.sign_service.create_client')
    async def test_sign_service_docusign_enabled(self, mock_create_client):
        """Testa SignService com DocuSign habilitado"""
        with patch.object(settings, 'USE_DOCUSIGN', True):
            with patch('backend.services.sign_service.DocuSignService') as mock_ds:
                service = SignService()
                assert service.use_docusign is True
                mock_ds.assert_called_once()

    @patch('backend.services.sign_service.create_client')
    async def test_sign_service_docusign_disabled(self, mock_create_client):
        """Testa SignService com DocuSign desabilitado"""
        with patch.object(settings, 'USE_DOCUSIGN', False):
            service = SignService()
            assert service.use_docusign is False
            assert not hasattr(service, 'docusign_service')

    @patch('backend.services.sign_service.create_client')
    @patch('backend.services.sign_service.FileSystemLoader')
    async def test_generate_contract_pdf_html_fallback(
            self, mock_loader, mock_supabase, mock_contract):
        """Testa geração de PDF com fallback para HTML"""
        with patch('backend.services.sign_service.Environment') as mock_env:
            mock_template = MagicMock()
            mock_template.render.return_value = "<html>Contrato</html>"
            mock_env.return_value.get_template.return_value = mock_template

            mock_supabase_instance = MagicMock()
            mock_supabase_instance.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {}
            mock_storage = MagicMock()
            mock_storage.from_.return_value.upload.return_value.error = None
            mock_storage.from_.return_value.get_public_url.return_value.data = {
                'publicUrl': 'https://test.com/contract.html'}
            mock_supabase_instance.storage = mock_storage
            mock_supabase.return_value = mock_supabase_instance

            with patch.object(settings, 'USE_DOCUSIGN', False):
                with patch('builtins.open', new_callable=MagicMock) as mock_open:
                    with patch('os.remove') as mock_remove:
                        service = SignService()
                        service._get_case_data = AsyncMock(return_value={})
                        service._get_lawyer_data = AsyncMock(return_value={})
                        service._get_client_data = AsyncMock(return_value={})
                        result = await service._generate_simple_html_contract(mock_contract)

                        assert result == 'https://test.com/contract.html'
                        mock_template.render.assert_called_once()

    @patch('backend.services.sign_service.EnvelopesApi')
    async def test_docusign_create_envelope(
            self, mock_envelopes_api, mock_contract, mock_client_data, mock_lawyer_data):
        """Testa criação de envelope no DocuSign"""
        mock_envelope_summary = MagicMock()
        mock_envelope_summary.envelope_id = "test-envelope-123"
        mock_envelopes_api.return_value.create_envelope.return_value = mock_envelope_summary

        with patch.object(DocuSignService, '_authenticate_jwt', new_callable=AsyncMock):
            service = DocuSignService()
            html_content = "<html>Test Contract</html>"

            result = await service.create_envelope(mock_contract, html_content, mock_client_data, mock_lawyer_data)

            assert result == "test-envelope-123"
            mock_envelopes_api.return_value.create_envelope.assert_called_once()

    @patch('backend.services.sign_service.EnvelopesApi')
    async def test_docusign_get_envelope_status(self, mock_envelopes_api):
        """Testa consulta de status do envelope"""
        mock_envelope = MagicMock()
        mock_envelope.envelope_id = "test-envelope-123"
        mock_envelope.status = "completed"
        mock_envelope.created_date_time = "2025-01-01T10:00:00Z"
        mock_envelope.completed_date_time = "2025-01-01T15:00:00Z"

        mock_recipients = MagicMock()
        signer1 = MagicMock()
        signer1.name = "João Silva"
        signer1.email = "cliente@test.com"
        signer1.status = "completed"
        signer1.signed_date_time = "2025-01-01T12:00:00Z"
        signer2 = MagicMock()
        signer2.name = "Dr. Maria Santos"
        signer2.email = "advogado@test.com"
        signer2.status = "completed"
        signer2.signed_date_time = "2025-01-01T15:00:00Z"
        mock_recipients.signers = [signer1, signer2]

        mock_envelopes_api.return_value.get_envelope.return_value = mock_envelope
        mock_envelopes_api.return_value.list_recipients.return_value = mock_recipients

        with patch.object(DocuSignService, '_authenticate_jwt', new_callable=AsyncMock):
            service = DocuSignService()
            result = await service.get_envelope_status("test-envelope-123")

            assert result["envelope_id"] == "test-envelope-123"
            assert result["status"] == "completed"
            assert len(result["recipients"]) == 2
            assert result["recipients"][0]["name"] == "João Silva"

    @patch('backend.services.sign_service.EnvelopesApi')
    async def test_docusign_download_signed_document(self, mock_envelopes_api):
        """Testa download de documento assinado"""
        mock_document_bytes = b"PDF document content"
        mock_envelopes_api.return_value.get_document.return_value = mock_document_bytes

        with patch.object(DocuSignService, '_authenticate_jwt', new_callable=AsyncMock):
            with patch.object(settings, 'DOCUSIGN_ACCOUNT_ID', 'test-account'):
                service = DocuSignService()
                result = await service.download_signed_document("test-envelope-123")

                assert result == mock_document_bytes
                mock_envelopes_api.return_value.get_document.assert_called_once_with(
                    'test-account', 'test-envelope-123', 'combined'
                )

    @patch('backend.services.sign_service.create_client')
    async def test_fallback_on_docusign_error(self, mock_create_client, mock_contract):
        """Testa fallback para HTML quando DocuSign falha"""
        with patch.object(settings, 'USE_DOCUSIGN', True), \
                patch.object(settings, 'validate_docusign_config', return_value=True), \
                patch('backend.services.sign_service.DocuSignService') as mock_ds_class:

            mock_ds_instance = AsyncMock()
            mock_ds_instance.create_envelope.side_effect = Exception(
                "DocuSign API Error")
            mock_ds_class.return_value = mock_ds_instance

            service = SignService()
            service._generate_simple_html_contract = AsyncMock(
                return_value='https://fallback.com/contract.html')

            result = await service.generate_contract_pdf(mock_contract)

            assert result == 'https://fallback.com/contract.html'
            service._generate_simple_html_contract.assert_called_once_with(
                mock_contract)

    @patch('backend.services.sign_service.ApiClient')
    async def test_jwt_authentication_flow(self, mock_api_client):
        """Testa fluxo de autenticação JWT"""
        with patch.object(settings, 'DOCUSIGN_API_KEY', 'test-integration-key'), \
                patch.object(settings, 'DOCUSIGN_USER_ID', 'test-user-id'), \
                patch.object(settings, 'DOCUSIGN_PRIVATE_KEY', 'LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpzb21lX3ZhbGlkX2Jhc2U2NF9lbmNvZGVkX2tleQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo='):

            with patch('backend.services.sign_service.load_pem_private_key'), \
                    patch('backend.services.sign_service.jwt.encode', return_value='test-jwt-token') as mock_jwt, \
                    patch('backend.services.sign_service.httpx.post') as mock_post:

                mock_post.return_value.json.return_value = {
                    "access_token": "test-access-token"}
                mock_post.return_value.raise_for_status = MagicMock()

                service = DocuSignService()
                await asyncio.sleep(0)  # allow background tasks to run

                mock_jwt.assert_called_once()
                mock_api_client.return_value.set_default_header.assert_called_with(
                    "Authorization", "Bearer test-access-token")

    async def test_config_validation(self):
        """Testa validação de configurações DocuSign"""
        # Torna a classe original acessível para o patch
        original_validate = settings.validate_docusign_config

        # Mock para retornar False
        with patch.object(settings, 'validate_docusign_config', return_value=False) as mock_validate_false:
            assert settings.validate_docusign_config() is False
            mock_validate_false.assert_called_once()

        # Mock para retornar True
        with patch.object(settings, 'validate_docusign_config', return_value=True) as mock_validate_true:
            assert settings.validate_docusign_config() is True
            mock_validate_true.assert_called_once()

        # Restaura o método original se necessário
        settings.validate_docusign_config = original_validate

    @patch('backend.services.sign_service.create_client')
    async def test_envelope_id_detection(self, mock_create_client, mock_contract):
        """Testa detecção de contratos DocuSign"""
        service = SignService()
        mock_contract.doc_url = "envelope_abc123def456"
        assert service.isDocuSignContract(mock_contract) is True

        mock_contract.doc_url = "https://storage.com/contract.html"
        assert service.isDocuSignContract(mock_contract) is False

    @patch('backend.services.sign_service.create_client')
    async def test_error_handling_and_logging(self, mock_create_client, mock_contract):
        """Testa tratamento de erros e logging"""
        with patch.object(settings, 'USE_DOCUSIGN', True), \
                patch.object(settings, 'validate_docusign_config', return_value=True), \
                patch('backend.services.sign_service.DocuSignService') as mock_ds_class, \
                patch('builtins.print') as mock_print:

            mock_ds = AsyncMock()
            mock_ds.create_envelope.side_effect = Exception("Network error")
            mock_ds_class.return_value = mock_ds

            service = SignService()
            service._generate_simple_html_contract = AsyncMock(
                return_value='fallback.html')

            # Mock para o template loader
            service.template_env.get_template = MagicMock()

            result = await service.generate_contract_pdf(mock_contract)

            mock_print.assert_any_call(
                "Erro no DocuSign, usando fallback HTML: Erro ao criar envelope DocuSign: Network error")
            assert result == 'fallback.html'


class TestDocuSignUtilities:
    """Testes para utilitários DocuSign"""

    @patch('backend.services.sign_service.create_client')
    async def test_status_formatting(self, mock_create_client):
        """Testa formatação de status DocuSign"""
        service = SignService()
        assert service.format_docusign_status('sent') == 'Enviado para assinatura'
        assert service.format_docusign_status('completed') == 'Completamente assinado'

    @patch('backend.services.sign_service.create_client')
    async def test_signer_info_extraction(self, mock_create_client):
        """Testa extração de informações do signatário"""
        recipients = [{"name": "João", "email": "joao@test.com", "status": "completed"}]
        service = SignService()
        signer = service.get_signer_info(recipients, "joao@test.com")
        assert signer["name"] == "João"

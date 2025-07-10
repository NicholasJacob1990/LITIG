"""
Serviço de assinatura de contratos
Suporta geração de PDF simples e DocuSign
"""
import base64
import json
import os
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

# DocuSign SDK
import docusign_esign as docusign
import httpx
import jwt
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from docusign_esign import (
    ApiClient,
    Document,
    EnvelopeDefinition,
    EnvelopesApi,
    Recipients,
    Signer,
    SignHere,
    Tabs,
)
from jinja2 import Environment, FileSystemLoader

from supabase import create_client

from ..config import settings
from ..models import Contract


class SignService:
    """
    Serviço para geração e assinatura de contratos
    """

    def __init__(self):
        self.supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY
        )
        self.template_env = Environment(
            loader=FileSystemLoader('templates/contracts')
        )
        self.use_docusign = settings.USE_DOCUSIGN

        # Inicializar DocuSign se habilitado
        if self.use_docusign:
            self.docusign_service = DocuSignService()

    async def generate_contract_pdf(self, contract: Contract) -> str:
        """
        Gera PDF do contrato

        Args:
            contract: Dados do contrato

        Returns:
            URL do PDF gerado ou envelope_id do DocuSign
        """
        try:
            if self.use_docusign and settings.validate_docusign_config():
                return await self._generate_docusign_envelope(contract)
            else:
                return await self._generate_simple_html_contract(contract)

        except Exception as e:
            # Fallback para HTML em caso de erro no DocuSign
            if self.use_docusign:
                print(f"Erro no DocuSign, usando fallback HTML: {str(e)}")
                return await self._generate_simple_html_contract(contract)
            raise Exception(f"Erro ao gerar PDF do contrato: {str(e)}")

    async def _generate_simple_html_contract(self, contract: Contract) -> str:
        """
        Gera contrato HTML simples (sem PDF) para MVP
        """
        # Carregar dados relacionados
        case_data = await self._get_case_data(contract.case_id)
        lawyer_data = await self._get_lawyer_data(contract.lawyer_id)
        client_data = await self._get_client_data(contract.client_id)

        # Renderizar template
        template = self.template_env.get_template('contract_template.html')
        html_content = template.render(
            contract=contract,
            case=case_data,
            lawyer=lawyer_data,
            client=client_data,
            generated_at=datetime.now(),
            contract_number=f"CONT-{contract.id[:8].upper()}",
            fee_description=self.format_fee_model(contract.fee_model)
        )

        # Salvar HTML como arquivo temporário
        html_filename = f"contract_{contract.id}.html"
        html_path = f"/tmp/{html_filename}"

        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(html_content)

        # Upload para Supabase Storage
        doc_url = await self._upload_html_to_storage(html_path, html_filename)

        # Limpar arquivo temporário
        os.remove(html_path)

        return doc_url

    async def _generate_docusign_envelope(self, contract: Contract) -> str:
        """
        Cria envelope no DocuSign
        """
        try:
            # Carregar dados relacionados
            case_data = await self._get_case_data(contract.case_id)
            lawyer_data = await self._get_lawyer_data(contract.lawyer_id)
            client_data = await self._get_client_data(contract.client_id)

            # Gerar HTML do contrato
            template = self.template_env.get_template('contract_template.html')
            html_content = template.render(
                contract=contract,
                case=case_data,
                lawyer=lawyer_data,
                client=client_data,
                generated_at=datetime.now(),
                contract_number=f"CONT-{contract.id[:8].upper()}",
                fee_description=self.format_fee_model(contract.fee_model)
            )

            # Criar envelope no DocuSign
            envelope_id = await self.docusign_service.create_envelope(
                contract=contract,
                html_content=html_content,
                client_data=client_data,
                lawyer_data=lawyer_data
            )

            return envelope_id

        except Exception as e:
            raise Exception(f"Erro ao criar envelope DocuSign: {str(e)}")

    async def _upload_html_to_storage(self, file_path: str, filename: str) -> str:
        """
        Upload do HTML para Supabase Storage
        """
        try:
            # Ler arquivo
            with open(file_path, 'rb') as f:
                file_data = f.read()

            # Upload para bucket 'contracts'
            bucket_path = f"contracts/{filename}"

            result = self.supabase.storage.from_('contracts').upload(
                bucket_path,
                file_data,
                file_options={
                    'content-type': 'text/html',
                    'cache-control': '3600'
                }
            )

            if result.error:
                raise Exception(f"Erro no upload: {result.error}")

            # Obter URL pública
            public_url = self.supabase.storage.from_(
                'contracts').get_public_url(bucket_path)

            return public_url.data['publicUrl']

        except Exception as e:
            raise Exception(f"Erro no upload para storage: {str(e)}")

    async def _get_case_data(self, case_id: str) -> Dict[str, Any]:
        """Busca dados do caso"""
        result = self.supabase.table('cases').select(
            '*').eq('id', case_id).single().execute()
        return result.data if result.data else {}

    async def _get_lawyer_data(self, lawyer_id: str) -> Dict[str, Any]:
        """Busca dados do advogado"""
        result = self.supabase.table('profiles').select(
            '*').eq('id', lawyer_id).single().execute()
        return result.data if result.data else {}

    async def _get_client_data(self, client_id: str) -> Dict[str, Any]:
        """Busca dados do cliente"""
        result = self.supabase.table('profiles').select(
            '*').eq('id', client_id).single().execute()
        return result.data if result.data else {}

    def format_fee_model(self, fee_model: Dict[str, Any]) -> str:
        """
        Formata modelo de honorários para exibição
        """
        fee_type = fee_model.get('type')

        if fee_type == 'success':
            percent = fee_model.get('percent', 0)
            return f"Honorários de êxito: {percent}% sobre o valor obtido"
        elif fee_type == 'fixed':
            value = fee_model.get('value', 0)
            return f"Honorários fixos: R$ {value:,.2f}"
        elif fee_type == 'hourly':
            rate = fee_model.get('rate', 0)
            return f"Honorários por hora: R$ {rate:,.2f}/hora"
        else:
            return "Modelo de honorários não especificado"

    async def send_signature_notification(self, contract: Contract, role: str):
        """
        Envia notificação de assinatura
        """
        try:
            # Buscar dados do usuário que precisa assinar
            if role == 'client':
                user_data = await self._get_client_data(contract.client_id)
                other_role = 'advogado'
            else:
                user_data = await self._get_lawyer_data(contract.lawyer_id)
                other_role = 'cliente'

            # Aqui você pode implementar:
            # - Envio de email
            # - Push notification
            # - Webhook para Slack
            # - etc.

            print(
                f"Notificação: {user_data.get('full_name')} precisa assinar o contrato {contract.id}")

        except Exception as e:
            # Log do erro, mas não falha o processo principal
            print(f"Erro ao enviar notificação: {str(e)}")

    async def get_envelope_status(self, envelope_id: str) -> Dict[str, Any]:
        """
        Consulta status do envelope DocuSign
        """
        if not self.use_docusign:
            return {"status": "not_supported"}

        try:
            return await self.docusign_service.get_envelope_status(envelope_id)
        except Exception as e:
            print(f"Erro ao consultar status do envelope: {str(e)}")
            return {"status": "error", "message": str(e)}

    async def download_signed_document(self, envelope_id: str) -> Optional[bytes]:
        """
        Download do documento assinado do DocuSign
        """
        if not self.use_docusign:
            return None

        try:
            return await self.docusign_service.download_signed_document(envelope_id)
        except Exception as e:
            print(f"Erro ao baixar documento assinado: {str(e)}")
            return None

    def isDocuSignContract(self, contract: Contract) -> bool:
        """Verifica se contrato foi criado via DocuSign"""
        return contract.doc_url is not None and contract.doc_url.startswith('envelope_')

    def format_docusign_status(self, status: str) -> str:
        """Formata status do DocuSign para exibição"""
        status_map: Dict[str, str] = {
            'sent': 'Enviado para assinatura',
            'delivered': 'Entregue aos signatários',
            'completed': 'Completamente assinado',
            'declined': 'Recusado',
            'voided': 'Cancelado',
            'created': 'Criado'
        }
        return status_map.get(status, status)

    def get_signer_info(
            self, recipients: List[Dict[str, Any]], user_email: str) -> Optional[Dict[str, Any]]:
        """Obtém informações do signatário DocuSign"""
        for r in recipients:
            if r.get('email') == user_email:
                return r
        return None

    def canBeSigned(self, contract: Contract) -> bool:
        """Verifica se o contrato pode ser assinado"""
        return contract.status == 'pending-signature'

    def isFullySigned(self, contract: Contract) -> bool:
        """Verifica se ambas as partes assinaram"""
        return contract.signed_client is not None and contract.signed_lawyer is not None


class DocuSignService:
    """
    Serviço específico para DocuSign
    """

    def __init__(self):
        self.base_url = settings.DOCUSIGN_BASE_URL
        self.api_key = settings.DOCUSIGN_API_KEY
        self.account_id = settings.DOCUSIGN_ACCOUNT_ID
        self.user_id = settings.DOCUSIGN_USER_ID
        self.private_key = settings.DOCUSIGN_PRIVATE_KEY

        # Configurar cliente DocuSign
        self.api_client = None
        self._setup_client()

    def _setup_client(self):
        """
        Configura o cliente DocuSign
        """
        try:
            self.api_client = ApiClient()
            self.api_client.host = f"{self.base_url}/restapi"

            # Configurar autenticação JWT
            self._authenticate_jwt()

        except Exception as e:
            print(f"Erro ao configurar cliente DocuSign: {str(e)}")

    def _authenticate_jwt(self):
        """
        Autentica usando JWT
        """
        try:
            # Preparar payload JWT
            now = datetime.utcnow()
            payload = {
                "iss": self.api_key,
                "sub": self.user_id,
                "aud": settings.get_docusign_auth_url(),
                "iat": now,
                "exp": now + timedelta(hours=1),
                "scope": "signature impersonation"
            }

            # Decodificar chave privada
            private_key_bytes = self.private_key.encode('utf-8')
            if '-----BEGIN' not in self.private_key:
                private_key_bytes = base64.b64decode(self.private_key)

            private_key = load_pem_private_key(private_key_bytes, password=None)

            # Gerar token JWT
            token = jwt.encode(payload, private_key, algorithm='RS256')

            # Trocar JWT por access token
            auth_url = f"{settings.get_docusign_auth_url()}/oauth/token"
            auth_data = {
                "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                "assertion": token
            }

            response = httpx.post(auth_url, data=auth_data)
            response.raise_for_status()

            auth_result = response.json()
            access_token = auth_result.get("access_token")

            # Configurar token no cliente
            self.api_client.set_default_header(
                "Authorization", f"Bearer {access_token}")

        except Exception as e:
            print(f"Erro na autenticação JWT: {str(e)}")
            raise

    async def create_envelope(
        self,
        contract: Contract,
        html_content: str,
        client_data: Dict[str, Any],
        lawyer_data: Dict[str, Any]
    ) -> str:
        """
        Cria envelope no DocuSign
        """
        try:
            # Criar documento
            document = Document(
                document_base64=base64.b64encode(
                    html_content.encode('utf-8')).decode('utf-8'),
                name=f"Contrato {contract.id[:8].upper()}",
                file_extension="html",
                document_id="1"
            )

            # Criar signatários
            client_signer = Signer(
                email=client_data.get('email', ''),
                name=client_data.get('full_name', ''),
                recipient_id="1",
                routing_order="1"
            )

            lawyer_signer = Signer(
                email=lawyer_data.get('email', ''),
                name=lawyer_data.get('full_name', ''),
                recipient_id="2",
                routing_order="2"
            )

            # Criar campos de assinatura
            client_sign_here = SignHere(
                document_id="1",
                page_number="1",
                recipient_id="1",
                tab_label="ClientSignature",
                x_position="100",
                y_position="200"
            )

            lawyer_sign_here = SignHere(
                document_id="1",
                page_number="1",
                recipient_id="2",
                tab_label="LawyerSignature",
                x_position="100",
                y_position="300"
            )

            # Configurar tabs
            client_signer.tabs = Tabs(sign_here_tabs=[client_sign_here])
            lawyer_signer.tabs = Tabs(sign_here_tabs=[lawyer_sign_here])

            # Criar envelope
            envelope_definition = EnvelopeDefinition(
                email_subject=f"Contrato LITGO - {contract.id[:8].upper()}",
                documents=[document],
                recipients=Recipients(signers=[client_signer, lawyer_signer]),
                status="sent"
            )

            # Enviar envelope
            envelopes_api = EnvelopesApi(self.api_client)
            envelope_summary = envelopes_api.create_envelope(
                self.account_id,
                envelope_definition=envelope_definition
            )

            return envelope_summary.envelope_id

        except Exception as e:
            raise Exception(f"Erro ao criar envelope DocuSign: {str(e)}")

    async def get_envelope_status(self, envelope_id: str) -> Dict[str, Any]:
        """
        Consulta status do envelope
        """
        try:
            envelopes_api = EnvelopesApi(self.api_client)
            envelope = envelopes_api.get_envelope(self.account_id, envelope_id)

            return {
                "envelope_id": envelope.envelope_id,
                "status": envelope.status,
                "created_date": envelope.created_date_time,
                "completed_date": envelope.completed_date_time,
                "recipients": self._get_recipients_status(envelope_id)
            }

        except Exception as e:
            raise Exception(f"Erro ao consultar status do envelope: {str(e)}")

    def _get_recipients_status(self, envelope_id: str) -> List[Dict[str, Any]]:
        """
        Consulta status dos signatários
        """
        try:
            envelopes_api = EnvelopesApi(self.api_client)
            recipients = envelopes_api.list_recipients(self.account_id, envelope_id)

            status_list = []
            for signer in recipients.signers:
                status_list.append({
                    "name": signer.name,
                    "email": signer.email,
                    "status": signer.status,
                    "signed_date": signer.signed_date_time
                })

            return status_list

        except Exception as e:
            print(f"Erro ao consultar status dos signatários: {str(e)}")
            return []

    async def download_signed_document(self, envelope_id: str) -> bytes:
        """
        Download do documento assinado
        """
        try:
            envelopes_api = EnvelopesApi(self.api_client)
            document = envelopes_api.get_document(
                self.account_id,
                envelope_id,
                "combined"  # Documento combinado com todas as assinaturas
            )

            return document

        except Exception as e:
            raise Exception(f"Erro ao baixar documento assinado: {str(e)}")

# Factory para escolher o serviço de assinatura


def get_sign_service() -> SignService:
    """
    Factory para obter serviço de assinatura
    """
    return SignService()

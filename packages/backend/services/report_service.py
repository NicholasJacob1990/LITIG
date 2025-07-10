"""
Serviço para geração de relatórios em PDF.
"""
import os
from datetime import datetime
from fpdf import FPDF
from typing import Any, Dict, List

from supabase import Client

# Configurações
PDF_FONT = "Arial"
PDF_TITLE_SIZE = 16
PDF_H1_SIZE = 14
PDF_H2_SIZE = 12
PDF_BODY_SIZE = 10
PDF_BRAND_COLOR = (15, 23, 42) # Azul escuro (slate-900)

class PDF(FPDF):
    """Classe de PDF customizada com cabeçalho e rodapé."""
    def header(self):
        # Usar a imagem do logo que já existe no projeto
        # O caminho é relativo à raiz do projeto, então precisamos ajustar
        logo_path = os.path.join(os.path.dirname(__file__), '../../assets/images/jacob_logo.png')
        if os.path.exists(logo_path):
            self.image(logo_path, 10, 8, 33)
        
        self.set_font(PDF_FONT, 'B', 12)
        self.cell(80)
        self.cell(30, 10, 'Relatório LITGO', 0, 0, 'C')
        self.ln(20)

    def footer(self):
        self.set_y(-15)
        self.set_font(PDF_FONT, 'I', 8)
        self.set_text_color(128)
        self.cell(0, 10, f'Página {self.page_no()}', 0, 0, 'C')

class ReportService:
    def __init__(self, supabase_client: Client):
        self.db = supabase_client

    def _get_case_details(self, case_id: str) -> Dict[str, Any]:
        """Busca todos os detalhes de um caso, incluindo cliente, advogado e documentos."""
        response = self.db.table("cases").select(
            """
            *,
            client:client_id(full_name, email),
            lawyer:lawyer_id(full_name, email, oab_number),
            documents:case_documents(name, file_type, uploaded_at)
            """
        ).eq("id", case_id).single().execute()
        
        if not response.data:
            raise ValueError(f"Caso com ID {case_id} não encontrado.")
            
        return response.data

    def generate_case_report_pdf(self, case_id: str) -> bytes:
        """Gera um relatório PDF detalhado para um caso específico."""
        
        case_data = self._get_case_details(case_id)

        pdf = PDF()
        pdf.add_page()
        
        # --- Título ---
        pdf.set_font(PDF_FONT, 'B', PDF_TITLE_SIZE)
        pdf.set_text_color(*PDF_BRAND_COLOR)
        pdf.cell(0, 10, f"Relatório do Caso: {case_data.get('title', 'N/A')}", 0, 1, 'L')
        pdf.set_font(PDF_FONT, '', PDF_BODY_SIZE)
        pdf.set_text_color(0)
        pdf.cell(0, 6, f"Gerado em: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}", 0, 1, 'L')
        pdf.ln(10)

        # --- Detalhes do Caso ---
        self._write_section_header(pdf, "Detalhes do Caso")
        self._write_key_value(pdf, "ID do Caso:", str(case_data.get('id')))
        self._write_key_value(pdf, "Status:", case_data.get('status', 'N/A').replace('_', ' ').title())
        self._write_key_value(pdf, "Área:", case_data.get('case_area', 'N/A'))
        self._write_key_value(pdf, "Criado em:", self._format_date(case_data.get('created_at')))
        
        pdf.ln(5)
        pdf.set_font(PDF_FONT, 'B', PDF_BODY_SIZE)
        pdf.multi_cell(0, 6, "Descrição do Problema:")
        pdf.set_font(PDF_FONT, '', PDF_BODY_SIZE)
        pdf.multi_cell(0, 6, case_data.get('description', 'Nenhuma descrição fornecida.'))
        pdf.ln(10)

        # --- Informações das Partes ---
        self._write_section_header(pdf, "Partes Envolvidas")
        client = case_data.get('client', {})
        lawyer = case_data.get('lawyer', {})
        self._write_key_value(pdf, "Cliente:", f"{client.get('full_name', 'N/A')} ({client.get('email', 'N/A')})")
        self._write_key_value(pdf, "Advogado:", f"{lawyer.get('full_name', 'N/A')} (OAB: {lawyer.get('oab_number', 'N/A')})")
        pdf.ln(10)

        # --- Lista de Documentos ---
        self._write_section_header(pdf, "Documentos Anexados")
        documents = case_data.get('documents', [])
        if documents:
            for doc in documents:
                self._write_key_value(pdf, 
                    f"- {doc.get('name', 'Nome não disponível')}",
                    f"(Tipo: {doc.get('file_type', 'N/A')}, Enviado em: {self._format_date(doc.get('uploaded_at'))})"
                )
        else:
            pdf.set_font(PDF_FONT, '', PDF_BODY_SIZE)
            pdf.cell(0, 6, "Nenhum documento anexado a este caso.", 0, 1)

        pdf.ln(10)

        return pdf.output(dest='S').encode('latin-1')

    def _write_section_header(self, pdf: FPDF, title: str):
        """Escreve um cabeçalho de seção padronizado."""
        pdf.set_font(PDF_FONT, 'B', PDF_H1_SIZE)
        pdf.set_fill_color(241, 245, 249) # slate-100
        pdf.set_text_color(*PDF_BRAND_COLOR)
        pdf.cell(0, 8, title, 0, 1, 'L', fill=True)
        pdf.ln(4)

    def _write_key_value(self, pdf: FPDF, key: str, value: str):
        """Escreve um par chave-valor."""
        pdf.set_font(PDF_FONT, 'B', PDF_BODY_SIZE)
        pdf.set_text_color(0)
        pdf.cell(40, 6, key)
        pdf.set_font(PDF_FONT, '', PDF_BODY_SIZE)
        pdf.multi_cell(0, 6, value)

    def _format_date(self, date_str: str) -> str:
        """Formata uma string de data ISO para o formato brasileiro."""
        if not date_str:
            return "N/A"
        try:
            return datetime.fromisoformat(date_str).strftime('%d/%m/%Y')
        except (ValueError, TypeError):
            return date_str

    def _get_lawyer_performance_data(self, lawyer_id: str) -> Dict[str, Any]:
        """Busca dados de performance de um advogado."""
        profile_response = self.db.table("profiles").select(
            "full_name, email, oab_number, created_at, max_concurrent_cases"
        ).eq("id", lawyer_id).single().execute()

        if not profile_response.data:
            raise ValueError(f"Advogado com ID {lawyer_id} não encontrado.")
        
        lawyer_data = profile_response.data
        
        cases_response = self.db.table("cases").select(
            "id, title, status, created_at, final_fee"
        ).eq("lawyer_id", lawyer_id).order("created_at", desc=True).execute()

        lawyer_data["cases"] = cases_response.data if cases_response.data else []
        
        # Calcular estatísticas
        total_cases = len(lawyer_data["cases"])
        completed_cases = [c for c in lawyer_data["cases"] if c.get('status') == 'resolved']
        active_cases = [c for c in lawyer_data["cases"] if c.get('status') not in ['resolved', 'closed', 'cancelled']]
        
        lawyer_data["stats"] = {
            "total_cases": total_cases,
            "active_cases": len(active_cases),
            "success_rate": (len(completed_cases) / total_cases) * 100 if total_cases > 0 else 0,
            "total_revenue": sum(c.get('final_fee', 0) or 0 for c in completed_cases)
        }
        
        return lawyer_data

    def generate_lawyer_performance_report_pdf(self, lawyer_id: str) -> bytes:
        """Gera um relatório de performance para um advogado."""
        lawyer_data = self._get_lawyer_performance_data(lawyer_id)
        
        pdf = PDF()
        pdf.add_page()
        
        # --- Título ---
        pdf.set_font(PDF_FONT, 'B', PDF_TITLE_SIZE)
        pdf.set_text_color(*PDF_BRAND_COLOR)
        pdf.cell(0, 10, f"Relatório de Performance: {lawyer_data.get('full_name', 'N/A')}", 0, 1, 'L')
        pdf.set_font(PDF_FONT, '', PDF_BODY_SIZE)
        pdf.cell(0, 6, f"OAB: {lawyer_data.get('oab_number', 'N/A')} | Membro desde: {self._format_date(lawyer_data.get('created_at'))}", 0, 1, 'L')
        pdf.ln(10)

        # --- Resumo das Métricas ---
        self._write_section_header(pdf, "Resumo de Performance")
        stats = lawyer_data.get('stats', {})
        self._write_key_value(pdf, "Total de Casos Atribuídos:", str(stats.get('total_cases', 0)))
        self._write_key_value(pdf, "Casos Ativos Atualmente:", str(stats.get('active_cases', 0)))
        self._write_key_value(pdf, "Taxa de Sucesso (Casos Resolvidos):", f"{stats.get('success_rate', 0):.2f}%")
        self._write_key_value(pdf, "Receita Total Gerada (de casos resolvidos):", f"R$ {stats.get('total_revenue', 0):,.2f}")
        pdf.ln(10)

        # --- Histórico de Casos ---
        self._write_section_header(pdf, "Histórico de Casos Recentes")
        cases = lawyer_data.get('cases', [])
        if cases:
            # Cabeçalho da tabela
            pdf.set_font(PDF_FONT, 'B', PDF_BODY_SIZE)
            pdf.cell(80, 7, "Título do Caso", 1, 0, 'C')
            pdf.cell(40, 7, "Status", 1, 0, 'C')
            pdf.cell(40, 7, "Data de Criação", 1, 1, 'C')
            
            # Linhas da tabela
            pdf.set_font(PDF_FONT, '', PDF_BODY_SIZE)
            for case in cases[:15]: # Limitar a 15 para não sobrecarregar
                pdf.cell(80, 6, case.get('title', 'N/A'), 1)
                pdf.cell(40, 6, case.get('status', 'N/A').title(), 1)
                pdf.cell(40, 6, self._format_date(case.get('created_at')), 1, 1)
        else:
            pdf.cell(0, 6, "Nenhum caso encontrado para este advogado.", 0, 1)
            
        pdf.ln(10)

        return pdf.output(dest='S').encode('latin-1')

    def _get_client_cases_data(self, client_id: str) -> Dict[str, Any]:
        """Busca o perfil de um cliente e todos os seus casos."""
        profile_response = self.db.table("profiles").select(
            "full_name, email, created_at"
        ).eq("id", client_id).single().execute()

        if not profile_response.data:
            raise ValueError(f"Cliente com ID {client_id} não encontrado.")
        
        client_data = profile_response.data
        
        cases_response = self.db.table("cases").select(
            "id, title, status, case_area, created_at, lawyer:lawyer_id(full_name)"
        ).eq("client_id", client_id).order("created_at", desc=True).execute()

        client_data["cases"] = cases_response.data if cases_response.data else []
        return client_data

    def generate_client_cases_report_pdf(self, client_id: str) -> bytes:
        """Gera um relatório com todos os casos de um cliente."""
        client_data = self._get_client_cases_data(client_id)
        
        pdf = PDF()
        pdf.add_page()
        
        # --- Título ---
        pdf.set_font(PDF_FONT, 'B', PDF_TITLE_SIZE)
        pdf.set_text_color(*PDF_BRAND_COLOR)
        pdf.cell(0, 10, f"Relatório de Casos do Cliente: {client_data.get('full_name', 'N/A')}", 0, 1, 'L')
        pdf.set_font(PDF_FONT, '', PDF_BODY_SIZE)
        pdf.cell(0, 6, f"Email: {client_data.get('email', 'N/A')} | Cliente desde: {self._format_date(client_data.get('created_at'))}", 0, 1, 'L')
        pdf.ln(10)

        # --- Histórico de Casos ---
        self._write_section_header(pdf, "Todos os Casos Registrados")
        cases = client_data.get('cases', [])
        if cases:
            # Cabeçalho da tabela
            pdf.set_font(PDF_FONT, 'B', PDF_BODY_SIZE)
            pdf.cell(70, 7, "Título do Caso", 1, 0, 'C')
            pdf.cell(30, 7, "Área", 1, 0, 'C')
            pdf.cell(30, 7, "Status", 1, 0, 'C')
            pdf.cell(50, 7, "Advogado Responsável", 1, 1, 'C')
            
            # Linhas da tabela
            pdf.set_font(PDF_FONT, '', PDF_BODY_SIZE)
            for case in cases:
                lawyer_name = case.get('lawyer', {}).get('full_name', 'Não atribuído')
                pdf.cell(70, 6, case.get('title', 'N/A'), 1)
                pdf.cell(30, 6, case.get('case_area', 'N/A'), 1)
                pdf.cell(30, 6, case.get('status', 'N/A').title(), 1)
                pdf.cell(50, 6, lawyer_name, 1, 1)
        else:
            pdf.cell(0, 6, "Nenhum caso encontrado para este cliente.", 0, 1)
            
        pdf.ln(10)

        return pdf.output(dest='S').encode('latin-1')

# TODO: Implementar generate_client_cases_report_pdf

# Teste
# report_service = ReportService(supabase_client)
# pdf_bytes = report_service.generate_case_report_pdf("some_case_id")
# print(pdf_bytes) 
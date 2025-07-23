#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
backend/services/contract_service.py

Serviço para geração de contratos jurídicos dinâmicos.
Utiliza templates Jinja2 para criar contratos personalizados.
"""

from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
import os
import uuid
from jinja2 import Environment, FileSystemLoader, Template

from api.schemas import (
    PartnershipResponseSchema,
    ContractResponseSchema
)


class ContractService:
    """Serviço para geração de contratos jurídicos"""

    def __init__(self):
        self.templates_dir = os.path.join(os.path.dirname(__file__), '..', 'templates', 'contracts')
        self.env = Environment(loader=FileSystemLoader(self.templates_dir))

    async def generate_partnership_contract(
        self,
        partnership: PartnershipResponseSchema,
        template_type: str = "default",
        custom_clauses: Optional[List[str]] = None
    ) -> ContractResponseSchema:
        """Gera contrato para parceria jurídica"""
        
        # Dados para o template
            contract_data = {
            'partnership_id': partnership.id,
            'creator_name': partnership.creator_name or "Advogado Contratante",
            'partner_name': partnership.partner_name or "Advogado Contratado",
            'partnership_type': self._get_partnership_type_display(partnership.type),
            'honorarios': partnership.honorarios,
            'proposal_message': partnership.proposal_message,
            'created_at': partnership.created_at.strftime('%d/%m/%Y'),
            'contract_date': datetime.utcnow().strftime('%d/%m/%Y'),
            'custom_clauses': custom_clauses or [],
            'case_title': partnership.case_title
        }
        
        # Template HTML
        template_name = f"partnership_{template_type}.html"
        try:
            template = self.env.get_template(template_name)
        except:
            # Fallback para template padrão
            template = self._get_default_template()
        
        # Gera HTML
        contract_html = template.render(**contract_data)
        
        # Simula upload do contrato (em produção, salvar em S3/Supabase Storage)
        contract_url = f"https://contracts.litgo.com/{partnership.id}/{uuid.uuid4()}.pdf"
        
        # Expira em 30 dias
        expires_at = datetime.utcnow() + timedelta(days=30)
        
        return ContractResponseSchema(
            contract_url=contract_url,
            contract_html=contract_html,
            expires_at=expires_at
        )
    
    def _get_partnership_type_display(self, partnership_type) -> str:
        """Converte tipo de parceria para display"""
        type_map = {
            'consultoria': 'Prestação de Consultoria Jurídica',
            'redacao_tecnica': 'Redação de Peças Técnicas',
            'audiencia': 'Realização de Audiência',
            'suporte_total': 'Suporte Jurídico Total',
            'parceria_recorrente': 'Parceria Jurídica Recorrente'
        }
        
        if hasattr(partnership_type, 'value'):
            return type_map.get(partnership_type.value, 'Prestação de Serviços Jurídicos')
        else:
            return type_map.get(str(partnership_type), 'Prestação de Serviços Jurídicos')
    
    def _get_default_template(self) -> Template:
        """Template padrão de contrato"""
        default_template = """
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contrato de Parceria Jurídica</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 40px; }
        .header { text-align: center; margin-bottom: 40px; }
        .section { margin-bottom: 30px; }
        .clause { margin-bottom: 20px; }
        .signature { margin-top: 60px; }
        .signature-line { border-top: 1px solid #000; width: 300px; margin: 40px auto; text-align: center; padding-top: 10px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>CONTRATO DE PARCERIA JURÍDICA</h1>
        <p><strong>Nº {{ partnership_id }}</strong></p>
    </div>

    <div class="section">
        <h2>PARTES</h2>
        <p><strong>CONTRATANTE:</strong> {{ creator_name }}</p>
        <p><strong>CONTRATADO:</strong> {{ partner_name }}</p>
    </div>

    <div class="section">
        <h2>OBJETO</h2>
        <div class="clause">
            <p><strong>Cláusula 1ª.</strong> O presente contrato tem por objeto a prestação de serviços jurídicos especializados na modalidade de <strong>{{ partnership_type }}</strong>.</p>
        </div>
        
        {% if case_title %}
        <div class="clause">
            <p><strong>Cláusula 2ª.</strong> Os serviços serão prestados em relação ao caso: <strong>{{ case_title }}</strong>.</p>
        </div>
        {% endif %}
    </div>

    <div class="section">
        <h2>HONORÁRIOS</h2>
        <div class="clause">
            <p><strong>Cláusula 3ª.</strong> Pelos serviços prestados, fica acordado o valor de <strong>{{ honorarios }}</strong>.</p>
        </div>
    </div>

    <div class="section">
        <h2>RESPONSABILIDADES</h2>
        <div class="clause">
            <p><strong>Cláusula 4ª.</strong> O CONTRATADO se compromete a prestar os serviços com diligência, observando os prazos acordados e as normas do Código de Ética da OAB.</p>
        </div>
        
        <div class="clause">
            <p><strong>Cláusula 5ª.</strong> O CONTRATANTE fornecerá todas as informações e documentos necessários para a execução dos serviços.</p>
        </div>
    </div>

    <div class="section">
        <h2>CONFIDENCIALIDADE</h2>
        <div class="clause">
            <p><strong>Cláusula 6ª.</strong> As partes se comprometem a manter sigilo absoluto sobre todas as informações trocadas durante a execução deste contrato.</p>
        </div>
    </div>

    {% if custom_clauses %}
    <div class="section">
        <h2>CLÁUSULAS ESPECIAIS</h2>
        {% for clause in custom_clauses %}
        <div class="clause">
            <p><strong>Cláusula Especial {{ loop.index }}ª.</strong> {{ clause }}</p>
        </div>
        {% endfor %}
    </div>
    {% endif %}

    <div class="section">
        <h2>DISPOSIÇÕES GERAIS</h2>
        <div class="clause">
            <p><strong>Cláusula 7ª.</strong> Este contrato entra em vigor na data de sua assinatura digital e permanece válido até o cumprimento de seu objeto.</p>
        </div>
        
        <div class="clause">
            <p><strong>Cláusula 8ª.</strong> Quaisquer alterações deste contrato deverão ser formalizadas por escrito e aceitas por ambas as partes.</p>
        </div>
        
        <div class="clause">
            <p><strong>Cláusula 9ª.</strong> O foro da comarca de domicílio do CONTRATANTE é eleito para dirimir quaisquer questões oriundas deste contrato.</p>
        </div>
    </div>

    <div class="signature">
        <p>{{ contract_date }}</p>
        
        <div class="signature-line">
            {{ creator_name }}<br/>
            <small>CONTRATANTE</small>
        </div>
        
        <div class="signature-line">
            {{ partner_name }}<br/>
            <small>CONTRATADO</small>
        </div>
    </div>

    <div style="margin-top: 40px; font-size: 12px; color: #666; text-align: center;">
        <p>Contrato gerado digitalmente pela plataforma LITGO em {{ contract_date }}</p>
        <p>ID do Documento: {{ partnership_id }}</p>
    </div>
</body>
</html>
        """
        
        return Template(default_template)

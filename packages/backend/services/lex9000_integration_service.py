"""
Serviço de Integração LEX-9000
==============================

Este serviço integra o prompt avançado do LEX-9000 (do openai.ts) com a nova
arquitetura de triagem inteligente, especialmente para casos complexos que
requerem análise jurídica detalhada.
"""

import asyncio
import json
import os
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

import openai
from dotenv import load_dotenv

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")


@dataclass
class LEXAnalysisResult:
    """Resultado da análise detalhada do LEX-9000."""
    classificacao: Dict[str, str]
    dados_extraidos: Dict[str, Any]
    analise_viabilidade: Dict[str, Any]
    urgencia: Dict[str, Any]
    aspectos_tecnicos: Dict[str, Any]
    recomendacoes: Dict[str, Any]
    confidence_score: float
    processing_time_ms: int


class LEX9000IntegrationService:
    """
    Serviço que integra o prompt avançado do LEX-9000 para análises detalhadas.

    Este serviço é usado quando:
    1. A IA Entrevistadora detecta alta complexidade
    2. É necessária análise jurídica estruturada completa
    3. O caso requer schema LEX-9000 detalhado
    """

    def __init__(self):
        if not OPENAI_API_KEY:
            print("Aviso: Chave da API da OpenAI não encontrada. LEX-9000 desabilitado.")
            self.client = None
        else:
            self.client = openai.AsyncOpenAI(api_key=OPENAI_API_KEY)

        # Prompt original do LEX-9000 otimizado para a nova arquitetura
        self.lex_system_prompt = """
# PERSONA
Você é o "LEX-9000", um assistente jurídico especializado em Direito Brasileiro, evoluído para trabalhar com dados conversacionais estruturados. Sua função é realizar análise jurídica profissional detalhada baseada em conversas de triagem já finalizadas.

# ESPECIALIZAÇÃO
- Conhecimento profundo do ordenamento jurídico brasileiro
- Experiência em todas as áreas do direito (civil, trabalhista, criminal, administrativo, etc.)
- Capacidade de identificar urgência, complexidade e viabilidade processual
- Foco em aspectos práticos e estratégicos

# CONTEXTO DE USO
Você recebe dados estruturados de uma conversa de triagem inteligente já finalizada e deve produzir uma análise jurídica completa e detalhada.

# METODOLOGIA DE ANÁLISE
## ANÁLISE ESTRUTURADA COMPLETA
- Classificação jurídica precisa
- Extração de dados factuais organizados
- Análise de viabilidade fundamentada
- Avaliação de urgência e prazos
- Aspectos técnicos e jurisprudenciais
- Recomendações estratégicas práticas

# FORMATO DE RESPOSTA
Retorne APENAS um JSON válido seguindo exatamente esta estrutura:

{
  "classificacao": {
    "area_principal": "Ex: Direito Trabalhista",
    "assunto_principal": "Ex: Rescisão Indireta",
    "subarea": "Ex: Verbas Rescisórias",
    "natureza": "Preventivo|Contencioso"
  },
  "dados_extraidos": {
    "partes": [
      {
        "nome": "Nome da parte",
        "tipo": "Requerente|Requerido|Terceiro",
        "qualificacao": "Pessoa física/jurídica, profissão, etc."
      }
    ],
    "fatos_principais": [
      "Fato 1 em ordem cronológica",
      "Fato 2 em ordem cronológica"
    ],
    "pedidos": [
      "Pedido principal",
      "Pedidos secundários"
    ],
    "valor_causa": "R$ X.XXX,XX ou Inestimável",
    "documentos_mencionados": [
      "Documento 1",
      "Documento 2"
    ],
    "cronologia": "YYYY-MM-DD do fato inicial até hoje"
  },
  "analise_viabilidade": {
    "classificacao": "Viável|Parcialmente Viável|Inviável",
    "pontos_fortes": [
      "Ponto forte 1",
      "Ponto forte 2"
    ],
    "pontos_fracos": [
      "Ponto fraco 1",
      "Ponto fraco 2"
    ],
    "probabilidade_exito": "Alta|Média|Baixa",
    "justificativa": "Análise fundamentada da viabilidade",
    "complexidade": "Baixa|Média|Alta",
    "custos_estimados": "Baixo|Médio|Alto"
  },
  "urgencia": {
    "nivel": "Crítica|Alta|Média|Baixa",
    "motivo": "Justificativa da urgência",
    "prazo_limite": "Data limite ou N/A",
    "acoes_imediatas": [
      "Ação 1",
      "Ação 2"
    ]
  },
  "aspectos_tecnicos": {
    "legislacao_aplicavel": [
      "Lei X, art. Y",
      "Código Z, art. W"
    ],
    "jurisprudencia_relevante": [
      "STF/STJ Tema X",
      "Súmula Y"
    ],
    "competencia": "Justiça Federal/Estadual/Trabalhista",
    "foro": "Comarca/Seção específica",
    "alertas": [
      "Alerta sobre prescrição",
      "Alerta sobre documentação"
    ]
  },
  "recomendacoes": {
    "estrategia_sugerida": "Judicial|Extrajudicial|Negociação",
    "proximos_passos": [
      "Passo 1",
      "Passo 2"
    ],
    "documentos_necessarios": [
      "Documento essencial 1",
      "Documento essencial 2"
    ],
    "observacoes": "Observações importantes para o advogado"
  }
}

# IMPORTANTE
- Mantenha linguagem profissional e técnica
- Use terminologia jurídica brasileira correta
- Seja específico e fundamentado nas análises
- Considere sempre o contexto brasileiro
- Baseie-se apenas nas informações fornecidas
- Se uma informação não estiver disponível, use "N/A" ou array vazio
"""

    async def analyze_complex_case(
            self, conversation_data: Dict[str, Any]) -> Optional[LEXAnalysisResult]:
        """
        Realiza análise completa de caso complexo usando o LEX-9000.

        Args:
            conversation_data: Dados estruturados da conversa de triagem

        Returns:
            LEXAnalysisResult com análise completa ou None se erro
        """
        if not self.client:
            print("LEX-9000 não disponível (OpenAI API key não configurada)")
            return None

        import time
        start_time = time.time()

        try:
            # Preparar contexto da conversa para análise
            context = self._prepare_conversation_context(conversation_data)

            # Executar análise LEX-9000
            response = await self.client.chat.completions.create(
                model="gpt-4o",  # Modelo mais avançado para análise complexa
                messages=[
                    {"role": "system", "content": self.lex_system_prompt},
                    {"role": "user", "content": context}
                ],
                temperature=0.3,  # Baixa para análise precisa
                max_tokens=4096,
                response_format={"type": "json_object"}
            )

            # Extrair e validar resultado
            response_text = response.choices[0].message.content
            analysis_data = json.loads(response_text)

            # Calcular confiança baseada na completude dos dados
            confidence = self._calculate_confidence(analysis_data)

            processing_time = int((time.time() - start_time) * 1000)

            return LEXAnalysisResult(
                classificacao=analysis_data.get("classificacao", {}),
                dados_extraidos=analysis_data.get("dados_extraidos", {}),
                analise_viabilidade=analysis_data.get("analise_viabilidade", {}),
                urgencia=analysis_data.get("urgencia", {}),
                aspectos_tecnicos=analysis_data.get("aspectos_tecnicos", {}),
                recomendacoes=analysis_data.get("recomendacoes", {}),
                confidence_score=confidence,
                processing_time_ms=processing_time
            )

        except Exception as e:
            print(f"Erro na análise LEX-9000: {e}")
            return None

    def _prepare_conversation_context(self, conversation_data: Dict[str, Any]) -> str:
        """Prepara contexto da conversa para análise do LEX-9000."""

        context_parts = ["=== DADOS DA TRIAGEM CONVERSACIONAL ===\n"]

        # Informações básicas
        if "basic_info" in conversation_data:
            basic = conversation_data["basic_info"]
            context_parts.append(f"ÁREA IDENTIFICADA: {basic.get('area', 'N/A')}")
            context_parts.append(f"SUBÁREA: {basic.get('subarea', 'N/A')}")
            context_parts.append(f"URGÊNCIA: {basic.get('urgency_h', 'N/A')} horas")
            context_parts.append(f"RESUMO: {basic.get('summary', 'N/A')}\n")

        # Entidades identificadas
        if "entities" in conversation_data:
            entities = conversation_data["entities"]
            if entities.get("parties"):
                context_parts.append(
                    f"PARTES ENVOLVIDAS: {
                        ', '.join(
                            entities['parties'])}")
            if entities.get("dates"):
                context_parts.append(
                    f"DATAS RELEVANTES: {
                        ', '.join(
                            entities['dates'])}")
            if entities.get("amounts"):
                context_parts.append(
                    f"VALORES MENCIONADOS: {
                        ', '.join(
                            entities['amounts'])}")
            if entities.get("locations"):
                context_parts.append(f"LOCAIS: {', '.join(entities['locations'])}")

        # Fatores de complexidade
        if "complexity_factors" in conversation_data:
            factors = conversation_data["complexity_factors"]
            if factors:
                context_parts.append(f"\nFATORES DE COMPLEXIDADE: {', '.join(factors)}")

        # Palavras-chave
        if "keywords" in conversation_data:
            keywords = conversation_data["keywords"]
            if keywords:
                context_parts.append(f"PALAVRAS-CHAVE: {', '.join(keywords)}")

        # Sentimento
        if "sentiment" in conversation_data:
            context_parts.append(f"SENTIMENTO: {conversation_data['sentiment']}")

        # Resumo da conversa
        if "conversation_summary" in conversation_data:
            context_parts.append(f"\n=== RESUMO DA CONVERSA ===")
            context_parts.append(conversation_data["conversation_summary"])

        # Se há dados já estruturados de análise prévia
        if "classificacao" in conversation_data:
            context_parts.append(f"\n=== ANÁLISE PRÉVIA ===")
            context_parts.append(
                json.dumps(
                    conversation_data,
                    indent=2,
                    ensure_ascii=False))

        return "\n".join(context_parts)

    def _calculate_confidence(self, analysis_data: Dict[str, Any]) -> float:
        """Calcula score de confiança baseado na completude da análise."""

        total_fields = 0
        filled_fields = 0

        # Verificar campos obrigatórios
        required_sections = [
            "classificacao", "dados_extraidos", "analise_viabilidade",
            "urgencia", "aspectos_tecnicos", "recomendacoes"
        ]

        for section in required_sections:
            if section in analysis_data:
                section_data = analysis_data[section]
                if isinstance(section_data, dict):
                    for key, value in section_data.items():
                        total_fields += 1
                        if value and value != "N/A" and value != []:
                            filled_fields += 1

        if total_fields == 0:
            return 0.0

        base_confidence = filled_fields / total_fields

        # Bonus por análises específicas
        bonus = 0.0

        # Bonus se tem legislação aplicável
        if (analysis_data.get("aspectos_tecnicos", {}).get("legislacao_aplicavel") and
                len(analysis_data["aspectos_tecnicos"]["legislacao_aplicavel"]) > 0):
            bonus += 0.1

        # Bonus se tem análise de viabilidade detalhada
        if (analysis_data.get("analise_viabilidade", {}).get("justificativa") and
                len(analysis_data["analise_viabilidade"]["justificativa"]) > 50):
            bonus += 0.1

        # Bonus se tem recomendações específicas
        if (analysis_data.get("recomendacoes", {}).get("proximos_passos") and
                len(analysis_data["recomendacoes"]["proximos_passos"]) >= 2):
            bonus += 0.1

        return min(1.0, base_confidence + bonus)

    async def enhance_simple_case(
            self, simple_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Melhora análise de casos simples com insights do LEX-9000.

        Para casos simples, adiciona apenas campos essenciais sem análise completa.
        """
        if not self.client:
            return simple_data

        enhancement_prompt = """
        Você é o LEX-9000. Receba dados de um caso simples e adicione apenas campos essenciais de análise jurídica, mantendo a simplicidade.

        Retorne JSON com os dados originais + campos adicionais:
        {
            ...dados_originais...,
            "aspectos_legais": {
                "legislacao_principal": "Lei/Código principal aplicável",
                "prazo_prescricional": "Prazo em anos ou N/A",
                "competencia": "Justiça competente"
            },
            "recomendacao_rapida": {
                "acao_prioritaria": "Primeira ação recomendada",
                "probabilidade_exito": "Alta|Média|Baixa",
                "observacao": "Observação importante"
            }
        }
        """

        try:
            context = f"Dados do caso simples:\n{
                json.dumps(
                    simple_data,
                    indent=2,
                    ensure_ascii=False)}"

            response = await self.client.chat.completions.create(
                model="gpt-4o-mini",  # Modelo mais rápido para casos simples
                messages=[
                    {"role": "system", "content": enhancement_prompt},
                    {"role": "user", "content": context}
                ],
                temperature=0.2,
                max_tokens=1000,
                response_format={"type": "json_object"}
            )

            enhanced_data = json.loads(response.choices[0].message.content)
            return enhanced_data

        except Exception as e:
            print(f"Erro ao melhorar caso simples: {e}")
            return simple_data

    def is_available(self) -> bool:
        """Verifica se o LEX-9000 está disponível."""
        return self.client is not None

    async def get_legal_insights(
            self, area: str, summary: str) -> Optional[Dict[str, Any]]:
        """
        Obtém insights jurídicos específicos para uma área e resumo.

        Útil para enriquecer análises com conhecimento jurídico específico.
        """
        if not self.client:
            return None

        insights_prompt = f"""
        Forneça insights jurídicos específicos para a área "{area}" baseado no resumo do caso.

        Retorne JSON:
        {{
            "legislacao_chave": ["Lei principal", "Artigos relevantes"],
            "jurisprudencia": ["Súmula ou precedente relevante"],
            "prazos_importantes": ["Prazo 1", "Prazo 2"],
            "documentos_essenciais": ["Doc 1", "Doc 2"],
            "alertas_praticos": ["Alerta 1", "Alerta 2"]
        }}
        """

        try:
            response = await self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": insights_prompt},
                    {"role": "user", "content": f"Resumo do caso: {summary}"}
                ],
                temperature=0.1,
                max_tokens=800,
                response_format={"type": "json_object"}
            )

            return json.loads(response.choices[0].message.content)

        except Exception as e:
            print(f"Erro ao obter insights jurídicos: {e}")
            return None


# Instância única do serviço
lex9000_integration_service = LEX9000IntegrationService()

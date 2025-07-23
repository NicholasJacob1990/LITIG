# backend/triage_service.py
import asyncio
import json
import os
import re
import time
from functools import wraps
from typing import Dict, List, Literal, Optional

import anthropic
import openai
from dotenv import load_dotenv

# Importação do serviço de embedding
from embedding_service import generate_embedding

load_dotenv()

# --- Configuração dos Clientes ---
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
# Modelo "Juiz" (o mais poderoso disponível)
JUDGE_MODEL_PROVIDER = os.getenv(
    "JUDGE_MODEL_PROVIDER",
    "anthropic")  # 'anthropic' ou 'openai'
JUDGE_MODEL_ANTHROPIC = "claude-3-opus-20240229"
JUDGE_MODEL_OPENAI = "gpt-4-turbo"
SIMPLE_MODEL_CLAUDE = "claude-3-haiku-20240307"

Strategy = Literal["simple", "failover", "ensemble"]


class TriageService:
    def __init__(self):
        # Cliente Anthropic (Claude)
        self.anthropic_client = anthropic.AsyncAnthropic(
            api_key=ANTHROPIC_API_KEY) if ANTHROPIC_API_KEY else None
        # Cliente OpenAI (ChatGPT)
        self.openai_client = openai.AsyncOpenAI(
            api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None

        if not self.anthropic_client:
            print("Aviso: Chave da API da Anthropic não encontrada.")
        if not self.openai_client:
            print("Aviso: Chave da API da OpenAI não encontrada.")

    async def _run_claude_triage(
            self, text: str, model: str = "claude-3-5-sonnet-20240620") -> Dict:
        """Chama um modelo Claude para extrair informações estruturadas."""
        if not self.anthropic_client:
            raise Exception("Cliente Anthropic não inicializado.")

        triage_tool = {
            "name": "extract_case_details",
            "description": "Extrai detalhes estruturados de um relato de caso jurídico.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "area": {"type": "string"}, "subarea": {"type": "string"},
                    "urgency_h": {"type": "integer"}, "summary": {"type": "string"},
                    "keywords": {"type": "array", "items": {"type": "string"}},
                    "sentiment": {"type": "string", "enum": ["Positivo", "Neutro", "Negativo"]}
                },
                "required": ["area", "subarea", "urgency_h", "summary", "keywords", "sentiment"]
            }
        }

        message = await self.anthropic_client.messages.create(
            model=model, max_tokens=1024, tools=[triage_tool],
            tool_choice={"type": "tool", "name": "extract_case_details"},
            messages=[{"role": "user",
                       "content": f"Analise o caso e extraia os detalhes: '{text}'"}]
        )

        if message.content and isinstance(
                message.content, list) and message.content[0].type == 'tool_use':
            return message.content[0].input
        raise Exception(
            f"A resposta do Claude ({model}) não continha os dados esperados.")

    async def _run_openai_triage(self, text: str) -> Dict:
        """Chama a API do ChatGPT para extrair informações com JSON mode."""
        if not self.openai_client:
            raise Exception("Cliente OpenAI não inicializado.")

        prompt = f"Analise a transcrição e extraia os dados em JSON. Transcrição: {text}"

        response = await self.openai_client.chat.completions.create(
            model="gpt-4o", response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": "Você é um assistente que extrai dados de textos legais para um JSON com os campos: area, subarea, urgency_h, summary, keywords, sentiment."},
                {"role": "user", "content": prompt}
            ]
        )
        return json.loads(response.choices[0].message.content)

    def _compare_results(
            self, result1: Optional[Dict], result2: Optional[Dict]) -> bool:
        """Compara se os campos críticos dos dois resultados são idênticos."""
        if not result1 or not result2:
            return False
        critical_fields = ["area", "subarea"]
        return all(str(result1.get(f, "")).strip().lower() == str(
            result2.get(f, "")).strip().lower() for f in critical_fields)

    async def _run_judge_triage(self, text: str, result1: Dict, result2: Dict) -> Dict:
        """Chama uma IA 'juiz' para decidir entre dois resultados conflitantes."""
        prompt = f"Você é um Sócio-Diretor. Revise a transcrição e os dois JSONs dos seus assistentes. Produza um JSON final e definitivo, com uma justificativa.\n\nTranscrição: {text}\n\nAssistente 1 (Claude):\n{
            json.dumps(
                result1,
                indent=2,
                ensure_ascii=False)}\n\nAssistente 2 (OpenAI):\n{
            json.dumps(
                result2,
                indent=2,
                ensure_ascii=False)}\n\nSua Saída Final (apenas JSON):"

        if JUDGE_MODEL_PROVIDER == 'openai' and self.openai_client:
            response = await self.openai_client.chat.completions.create(
                model=JUDGE_MODEL_OPENAI, response_format={"type": "json_object"},
                messages=[{"role": "user", "content": prompt}]
            )
            return json.loads(response.choices[0].message.content)
        elif JUDGE_MODEL_PROVIDER == 'anthropic' and self.anthropic_client:
            message = await self.anthropic_client.messages.create(
                model=JUDGE_MODEL_ANTHROPIC, max_tokens=2048,
                messages=[{"role": "user", "content": prompt}]
            )
            # Extrair JSON da resposta de texto
            match = re.search(r'\{.*\}', message.content[0].text, re.DOTALL)
            if match:
                return json.loads(match.group(0))
            raise Exception("A resposta do Juiz (Claude) não continha um JSON válido.")
        else:
            # Fallback se o juiz preferido não estiver disponível
            return result1

    async def _run_failover_strategy(self, text: str) -> Dict:
        try:
            return await self._run_claude_triage(text)
        except Exception as e:
            print(f"Falha no Claude (principal), tentando OpenAI (backup): {e}")
            return await self._run_openai_triage(text)

    async def _run_ensemble_strategy(self, text: str) -> Dict:
        tasks = [
            self._run_claude_triage(
                text) if self.anthropic_client else asyncio.sleep(0, result=None),
            self._run_openai_triage(
                text) if self.openai_client else asyncio.sleep(0, result=None)
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        successful_results = [res for res in results if not isinstance(res, Exception)]

        if not successful_results:
            raise Exception("Ambas as IAs falharam no ensemble.")
        if len(successful_results) == 1:
            return successful_results[0]

        res1, res2 = successful_results
        if self._compare_results(res1, res2):
            return res1

        print("Resultados divergentes, acionando o Juiz.")
        return await self._run_judge_triage(text, res1, res2)

    async def run_triage(self, text: str, strategy: Strategy) -> dict:
        """Ponto de entrada principal para a triagem."""
        print(f"Executando estratégia de triagem: {strategy}")
        triage_results = {}

        try:
            if strategy == 'simple':
                triage_results = await self._run_claude_triage(text, model=SIMPLE_MODEL_CLAUDE)
            elif strategy == 'ensemble':
                triage_results = await self._run_ensemble_strategy(text)
            else:  # Padrão é 'failover'
                triage_results = await self._run_failover_strategy(text)
        except Exception as e:
            print(f"Estratégia '{strategy}' falhou: {e}. Usando fallback de regex.")
            triage_results = self._run_regex_fallback(text)

        summary = triage_results.get("summary")
        if summary:
            embedding_vector = await generate_embedding(summary)
            triage_results["summary_embedding"] = embedding_vector
        else:
            triage_results["summary_embedding"] = None

        return triage_results

    def _run_regex_fallback(self, text: str) -> dict:
        """
        Fallback simples que usa regex para extrair a área jurídica.
        """
        text_lower = text.lower()

        # -------- Heurística de área --------------------------------------
        area = "Civil"  # padrão
        subarea = "Geral"

        # Padrões de regex para cada área jurídica
        trabalhista = r"trabalho|trabalhista|demitido|verbas? rescisórias|rescisão|salário|clt|fgts|inss|férias|13o?|décimo terceiro|aviso prévio|justa causa|assédio moral|acidente de trabalho"
        criminal = r"pol[ií]cia|crime|criminoso|preso|roubo|furto|homic[ií]dio|delito|penal|detenção|prisão|flagrante|denúncia|queixa"
        consumidor = r"consumidor|produto|compra|loja|defeito|garantia|cdc|código de defesa|vício|dano moral|propaganda enganosa|cobrança indevida"
        tributario = r"tribut|imposto|taxa|contribuição|fiscal|receita federal|icms|iss|iptu|ipva|ir|cofins|pis|dívida ativa"
        previdenciario = r"previdência|aposentadoria|pensão|benefício|inss|auxílio|bpc|loas|perícia médica|tempo de contribuição"
        familia = r"divórcio|separação|pensão alimentícia|guarda|visitação|partilha|união estável|adoção|paternidade|alimentos"
        empresarial = r"empresa|societário|contrato social|ltda|sociedade|sócio|quotas|dissolução|alteração contratual"
        
        # Novas áreas
        administrativo = r"administrativo|servidor público|concurso|licitação|contrato administrativo|improbidade|mandado de segurança|desapropriação"
        imobiliario = r"imóvel|imobiliário|aluguel|locação|despejo|compra e venda|escritura|registro|usucapião|condomínio"
        ambiental = r"ambiental|meio ambiente|poluição|desmatamento|licença ambiental|ibama|crime ambiental|sustentabilidade"
        bancario = r"banco|bancário|conta corrente|empréstimo|financiamento|juros|cheque|cartão de crédito|negativação|spc|serasa"
        saude = r"saúde|plano de saúde|hospital|médico|cirurgia|medicamento|sus|ans|erro médico|negativa de cobertura"
        propriedade_intelectual = r"propriedade intelectual|marca|patente|direito autoral|pirataria|inpi|software|invenção"
        digital = r"digital|internet|dados pessoais|lgpd|privacidade|cyber|hacke|vazamento|redes sociais|e-commerce"

        # Verificação hierárquica de áreas
        if re.search(trabalhista, text_lower):
            area = "Trabalhista"
            if re.search(r"justa causa", text_lower):
                subarea = "Justa Causa"
            elif re.search(r"verbas? rescisórias", text_lower):
                subarea = "Verbas Rescisórias"
            elif re.search(r"assédio moral", text_lower):
                subarea = "Assédio Moral"
            elif re.search(r"acidente de trabalho", text_lower):
                subarea = "Acidente de Trabalho"
        elif re.search(criminal, text_lower):
            area = "Criminal"
            if re.search(r"homic[ií]dio", text_lower):
                subarea = "Homicídio"
            elif re.search(r"roubo|furto", text_lower):
                subarea = "Patrimonial"
            elif re.search(r"tráfico", text_lower):
                subarea = "Tráfico"
        elif re.search(consumidor, text_lower):
            area = "Consumidor"
            if re.search(r"garantia", text_lower):
                subarea = "Garantia"
            elif re.search(r"cobrança indevida", text_lower):
                subarea = "Cobrança Indevida"
        elif re.search(tributario, text_lower):
            area = "Tributário"
            if re.search(r"icms|iss", text_lower):
                subarea = "Impostos Estaduais/Municipais"
            elif re.search(r"ir|imposto de renda", text_lower):
                subarea = "Imposto de Renda"
        elif re.search(previdenciario, text_lower):
            area = "Previdenciário"
            if re.search(r"aposentadoria", text_lower):
                subarea = "Aposentadoria"
            elif re.search(r"auxílio", text_lower):
                subarea = "Benefícios"
        elif re.search(familia, text_lower):
            area = "Família"
            if re.search(r"divórcio|separação", text_lower):
                subarea = "Divórcio"
            elif re.search(r"pensão alimentícia|alimentos", text_lower):
                subarea = "Alimentos"
            elif re.search(r"guarda", text_lower):
                subarea = "Guarda"
        elif re.search(administrativo, text_lower):
            area = "Administrativo"
            if re.search(r"servidor público", text_lower):
                subarea = "Servidor Público"
            elif re.search(r"licitação", text_lower):
                subarea = "Licitações"
            elif re.search(r"concurso", text_lower):
                subarea = "Concurso Público"
        elif re.search(imobiliario, text_lower):
            area = "Imobiliário"
            if re.search(r"locação|aluguel|despejo", text_lower):
                subarea = "Locação"
            elif re.search(r"compra e venda", text_lower):
                subarea = "Compra e Venda"
            elif re.search(r"usucapião", text_lower):
                subarea = "Usucapião"
        elif re.search(ambiental, text_lower):
            area = "Ambiental"
            if re.search(r"licença", text_lower):
                subarea = "Licenciamento"
            elif re.search(r"crime ambiental", text_lower):
                subarea = "Crimes Ambientais"
        elif re.search(bancario, text_lower):
            area = "Bancário"
            if re.search(r"juros", text_lower):
                subarea = "Juros Abusivos"
            elif re.search(r"negativação|spc|serasa", text_lower):
                subarea = "Negativação Indevida"
        elif re.search(saude, text_lower):
            area = "Saúde"
            if re.search(r"plano de saúde", text_lower):
                subarea = "Plano de Saúde"
            elif re.search(r"erro médico", text_lower):
                subarea = "Erro Médico"
        elif re.search(propriedade_intelectual, text_lower):
            area = "Propriedade Intelectual"
            if re.search(r"marca", text_lower):
                subarea = "Marcas"
            elif re.search(r"patente", text_lower):
                subarea = "Patentes"
        elif re.search(digital, text_lower):
            area = "Digital"
            if re.search(r"lgpd|dados pessoais", text_lower):
                subarea = "LGPD"
            elif re.search(r"vazamento", text_lower):
                subarea = "Vazamento de Dados"
        elif re.search(empresarial, text_lower):
            area = "Empresarial"
            if re.search(r"contrato social", text_lower):
                subarea = "Societário"
            elif re.search(r"dissolução", text_lower):
                subarea = "Dissolução"

        # -------- Heurística de urgência ----------------------------------
        # 24h para casos urgentes (liminar, prazo curto, réu preso)
        if re.search(r"\b(liminar|urgente|réu preso)\b", text_lower):
            urgency_h = 24
        # 48h se menciona prazo até 2 dias
        elif re.search(r"\b(48h|2 dias?)\b", text_lower):
            urgency_h = 48
        # Caso mencione prazo específico em dias
        else:
            m = re.search(r"\b(\d{1,2})\s*dias?\b", text_lower)
            if m:
                urgency_h = int(m.group(1)) * 24
            else:
                urgency_h = 72  # padrão

        return {
            "area": area,
            "subarea": subarea,
            "urgency_h": urgency_h,
            "summary": text[:150],
            "keywords": re.findall(r'\b\w{5,}\b', text.lower())[:5],
            "sentiment": "Neutro"
        }

    async def run_detailed_analysis(self, text: str) -> dict:
        """
        Executa análise detalhada usando o schema rico do OpenAI.
        Esta função complementa a triagem básica com insights profundos.
        """
        if not self.openai_client:
            print("Cliente OpenAI não disponível para análise detalhada.")
            return self._generate_fallback_detailed_analysis(text)

        detailed_prompt = """
        Você é o "LEX-9000", um assistente jurídico especializado em Direito Brasileiro.
        Sua função é fornecer uma análise jurídica detalhada e estruturada.

        IMPORTANTE: Retorne APENAS um JSON válido seguindo exatamente esta estrutura:

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
        """

        try:
            response = await self.openai_client.chat.completions.create(
                model="gpt-4o",
                response_format={"type": "json_object"},
                messages=[
                    {"role": "system", "content": detailed_prompt},
                    {"role": "user",
                     "content": f"Analise detalhadamente este caso jurídico:\n\n{text}"}
                ],
                temperature=0.3,
                max_tokens=4096
            )

            detailed_analysis = json.loads(response.choices[0].message.content)
            return detailed_analysis

        except Exception as e:
            print(f"Erro na análise detalhada OpenAI: {e}")
            return self._generate_fallback_detailed_analysis(text)

    def _generate_fallback_detailed_analysis(self, text: str) -> dict:
        """
        Fallback para análise detalhada quando OpenAI não está disponível.
        """
        basic_triage = self._run_regex_fallback(text)

        return {
            "classificacao": {
                "area_principal": basic_triage.get("area", "Não identificado"),
                "assunto_principal": "A ser definido",
                "subarea": basic_triage.get("subarea", "Geral"),
                "natureza": "Contencioso"
            },
            "dados_extraidos": {
                "partes": [{"nome": "Cliente", "tipo": "Requerente", "qualificacao": "Pessoa física"}],
                "fatos_principais": [text[:200] + "..."],
                "pedidos": ["A ser definido"],
                "valor_causa": "A ser estimado",
                "documentos_mencionados": [],
                "cronologia": "Não informado"
            },
            "analise_viabilidade": {
                "classificacao": "Parcialmente Viável",
                "pontos_fortes": ["Necessária análise mais detalhada"],
                "pontos_fracos": ["Informações limitadas"],
                "probabilidade_exito": "Média",
                "justificativa": "Análise preliminar baseada em informações limitadas",
                "complexidade": "Média",
                "custos_estimados": "Médio"
            },
            "urgencia": {
                "nivel": "Média",
                "motivo": "Estimativa baseada na área jurídica",
                "prazo_limite": "N/A",
                "acoes_imediatas": ["Consultar advogado especializado"]
            },
            "aspectos_tecnicos": {
                "legislacao_aplicavel": ["A ser definido"],
                "jurisprudencia_relevante": ["A ser pesquisado"],
                "competencia": "A ser definido",
                "foro": "A ser definido",
                "alertas": ["Análise preliminar - requer revisão especializada"]
            },
            "recomendacoes": {
                "estrategia_sugerida": "Extrajudicial",
                "proximos_passos": ["Consultar advogado", "Reunir documentação"],
                "documentos_necessarios": ["Documentos relacionados ao caso"],
                "observacoes": "Esta é uma análise preliminar. Consulte um advogado para análise completa."
            }
        }


# Instância única
triage_service = TriageService()

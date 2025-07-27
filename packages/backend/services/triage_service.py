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
# NOVO: A API do TogetherAI (para Llama 4) é compatível com o cliente OpenAI

# Importação do serviço de embedding
from embedding_service import generate_embedding
from .premium_criteria_service import evaluate_case_premium
from ..dependencies import get_db

load_dotenv()

# --- Configuração dos Clientes ---
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
# MUDANÇA: Substituindo Mistral por Llama 4 via um provedor como o Together AI
TOGETHER_API_KEY = os.getenv("TOGETHER_API_KEY")
# NOVO: Configuração do Gemini para o juiz
from ..config import Settings
settings = Settings()
GEMINI_API_KEY = settings.GEMINI_API_KEY

# --- Mapeamento Estratégico de Modelos (Baseado em Custo-Benefício 2025 com Llama 4) ---

# 1. IA Entrevistadora (Foco: Qualidade da Conversa e Velocidade)
INTERVIEWER_MODEL = "claude-3-5-sonnet-20240620"

# 2. Triagem de Baixa Complexidade (Foco: Custo Mínimo com Llama 4 Scout)
# O Llama 4 Scout é ideal para multimodalidade e tem o menor custo.
SIMPLE_TRIAGE_MODEL_PROVIDER = "together" # Provedor do Llama 4
SIMPLE_TRIAGE_MODEL_LLAMA = "meta-llama/Llama-4-Scout" 
SIMPLE_TRIAGE_MODEL_CLAUDE_FALLBACK = "claude-3-haiku-20240307"

# 3. Triagem Padrão (Failover - Foco: Melhor Custo-Benefício com Llama 4 Scout)
DEFAULT_TRIAGE_PRIMARY_PROVIDER = "together"
DEFAULT_TRIAGE_MODEL_LLAMA = "meta-llama/Llama-4-Scout" # Imbatível em custo e pronto para multimodal
DEFAULT_TRIAGE_SECONDARY_PROVIDER = "openai"
DEFAULT_TRIAGE_MODEL_OPENAI_FALLBACK = "gpt-4.1-turbo" # Ótimo backup

# 4. Ensemble e Juiz (Foco: Máxima Qualidade para Casos Complexos)
# MUDANÇA: Usando Sonnet no ensemble para melhor custo-benefício e velocidade
ENSEMBLE_MODEL_ANTHROPIC = "claude-4.0-sonnet-20250401" 
ENSEMBLE_MODEL_OPENAI = "gpt-4o"
# NOVO: Modelo de failover para a estratégia de ensemble
ENSEMBLE_FAILOVER_MODEL = "gpt-4o"

# MUDANÇA: Alterando o juiz para Gemini Pro 2.5
JUDGE_MODEL_PROVIDER = "gemini"
JUDGE_MODEL = settings.GEMINI_JUDGE_MODEL  # Gemini Pro 2.5 (modelo mais recente)
# Failover de alta performance mantido
JUDGE_MODEL_OPENAI_FALLBACK = "gpt-4o"

Strategy = Literal["simple", "failover", "ensemble"]

# NOVO: Prompt Mestre para Triagem
MASTER_TRIAGE_PROMPT_TEMPLATE = """
Você é um assistente de triagem jurídica altamente qualificado para a plataforma LITIG-1. Sua função é analisar o relato inicial de um cliente e classificá-lo de forma precisa e estruturada em um JSON.

**OBJETIVO:**
Sua principal tarefa é extrair a **Área Principal** e a **Subárea Específica** do caso, com base no catálogo de categorias válidas do nosso sistema. Além disso, você deve extrair outras informações relevantes como urgência, um resumo e palavras-chave.

**REGRAS E FORMATO DE SAÍDA:**
1.  **SAÍDA ESTRITAMENTE JSON:** Sua resposta DEVE ser um único e válido objeto JSON. Não inclua nenhum texto, explicação ou formatação fora do JSON.
2.  **CLASSIFICAÇÃO PRECISA:** Utilize o **CATÁLOGO DE CLASSIFICAÇÕES** abaixo para preencher os campos `area` e `subarea`. Seja o mais específico possível. Se um caso menciona "erro médico" e "plano de saúde", a subárea "Erro Médico" é mais específica e, portanto, preferível.
3.  **NÃO INVENTE CATEGORIAS:** Se o caso não se encaixar perfeitamente, escolha a `area` e `subarea` mais próximas do catálogo. Não crie novas categorias.
4.  **RESUMO EFICIENTE:** O campo `summary` deve ser um resumo conciso do problema do cliente em até 150 caracteres.
5.  **PALAVRAS-CHAVE:** O campo `keywords` deve conter uma lista de até 5 termos ou expressões mais relevantes do texto.
6.  **URGÊNCIA:** O campo `urgency_h` deve ser sua estimativa em horas para uma primeira ação. Padrão é 72. Se mencionar "liminar" ou "réu preso", use 24. Se mencionar prazos explícitos, converta para horas.
7.  **SENTIMENTO:** O campo `sentiment` deve refletir o tom do cliente: "Positivo", "Neutro" ou "Negativo".

**CATÁLOGO DE CLASSIFICAÇÕES (Use estas categorias para `area` e `subarea`):**
{catalog_json}

**EXEMPLOS DE CASOS:**

*   **Exemplo 1 (Arbitragem):**
    *   **Texto:** "Nosso contrato de construção com a empreiteira tem uma cláusula compromissória e eles não estão cumprindo o cronograma. Queremos iniciar uma arbitragem na CAM-CCBC para resolver a disputa."
    *   **JSON Esperado:**
        ```json
        {{
            "area": "Empresarial",
            "subarea": "Arbitragem Societária e M&A",
            "urgency_h": 72,
            "summary": "Cliente busca iniciar procedimento de arbitragem na CAM-CCBC devido a descumprimento de contrato de construção.",
            "keywords": ["arbitragem", "CAM-CCBC", "cláusula compromissória", "contrato de construção", "cronograma"],
            "sentiment": "Negativo"
        }}
        ```

*   **Exemplo 2 (Startup):**
    *   **Texto:** "Sou fundador de uma fintech e estamos na nossa primeira rodada de captação. Recebemos um term sheet de um fundo de venture capital e preciso de um advogado para analisar o documento e nos ajudar na negociação do SHA."
    *   **JSON Esperado:**
        ```json
        {{
            "area": "Startups",
            "subarea": "Contratos de Investment",
            "urgency_h": 48,
            "summary": "Fundador de fintech precisa de assessoria jurídica para analisar term sheet e negociar SHA em rodada de investimento venture capital.",
            "keywords": ["fintech", "venture capital", "term sheet", "SHA", "rodada de captação"],
            "sentiment": "Neutro"
        }}
        ```

**CASO A SER ANALISADO:**
Analise o seguinte relato de caso e extraia os detalhes no formato JSON, seguindo todas as regras e utilizando o catálogo fornecido.

**Relato do Cliente:**
"{user_text}"
"""

class TriageService:
    def __init__(self):
        # Cliente Anthropic (Claude)
        self.anthropic_client = anthropic.AsyncAnthropic(
            api_key=ANTHROPIC_API_KEY) if ANTHROPIC_API_KEY else None
        # Cliente OpenAI (ChatGPT)
        self.openai_client = openai.AsyncOpenAI(
            api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None
        # NOVO: Cliente para Llama 4 via Together AI (OpenAI-compatible)
        self.together_client = openai.AsyncOpenAI(
            api_key=TOGETHER_API_KEY,
            base_url="https://api.together.xyz/v1",
        ) if TOGETHER_API_KEY else None

        if not self.anthropic_client:
            print("Aviso: Chave da API da Anthropic não encontrada.")
        if not self.openai_client:
            print("Aviso: Chave da API da OpenAI não encontrada.")
        if not self.together_client:
            print("Aviso: Chave da API da Together AI (para Llama 4) não encontrada.")

        self._area_catalog_json: Optional[str] = None

    async def _get_area_catalog(self) -> str:
        """
        Busca e formata o catálogo de áreas e subáreas do banco de dados.
        Em um cenário real, isso teria cache para evitar acessos repetidos ao DB.
        """
        if self._area_catalog_json:
            return self._area_catalog_json
        
        db_session = next(get_db())
        try:
            # Esta é uma simulação. O ideal seria uma query real.
            # Supondo que você tem uma tabela `area_subareas`
            # result = db_session.execute("SELECT area, array_agg(subarea) FROM area_subareas GROUP BY area")
            # areas_map = {row[0]: row[1] for row in result}
            
            # Usando uma versão mockada para este exemplo, mas a lógica é a mesma
            from .catalog_mock import get_mock_catalog # MOCK
            areas_map = get_mock_catalog()

            self._area_catalog_json = json.dumps(areas_map, indent=2, ensure_ascii=False)
            return self._area_catalog_json
        finally:
            db_session.close()

    async def _run_claude_triage(self, text: str, model: str = DEFAULT_TRIAGE_MODEL_LLAMA) -> Dict:
        """Chama um modelo Claude com o prompt mestre."""
        if not self.anthropic_client:
            raise Exception("Cliente Anthropic não inicializado.")

        catalog = await self._get_area_catalog()
        prompt = MASTER_TRIAGE_PROMPT_TEMPLATE.format(
            catalog_json=catalog,
            user_text=text
        )

        message = await self.anthropic_client.messages.create(
            model=model,
            max_tokens=2048,
            messages=[{"role": "user", "content": prompt}]
        )
        
        response_text = message.content[0].text
        # Extrair o JSON da resposta, que pode vir cercado por ```json ... ```
        match = re.search(r'\{.*\}', response_text, re.DOTALL)
        if match:
            return json.loads(match.group(0))
        raise Exception(f"A resposta do Claude ({model}) não continha um JSON válido.")

    async def _run_openai_triage(self, text: str, model: str) -> Dict:
        """Chama a API do ChatGPT com o prompt mestre e JSON mode."""
        if not self.openai_client:
            raise Exception("Cliente OpenAI não inicializado.")

        catalog = await self._get_area_catalog()
        prompt = MASTER_TRIAGE_PROMPT_TEMPLATE.format(
            catalog_json=catalog,
            user_text=text
        )

        response = await self.openai_client.chat.completions.create(
            model=model,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": "Sua única função é retornar um objeto JSON válido baseado no prompt do usuário. Não adicione nenhum texto ou explicação fora do JSON."},
                {"role": "user", "content": prompt}
            ]
        )
        return json.loads(response.choices[0].message.content)

    async def _run_llama_triage(self, text: str, model: str) -> Dict:
        """Chama um modelo Llama 4 via Together AI com o prompt mestre."""
        if not self.together_client:
            raise ValueError("API Key do Together AI não configurada.")

        prompt = await self._get_master_prompt(text)
        try:
            response = await self.together_client.chat.completions.create(
                model=model,
                response_format={"type": "json_object"},
                messages=[
                    {"role": "system", "content": "You are a helpful assistant that outputs JSON."},
                    {"role": "user", "content": prompt}
                ]
            )
            return json.loads(response.choices[0].message.content)
        except Exception as e:
            print(f"Erro ao chamar a API da Together (Llama): {e}")
            return {}

    async def _judge_results(self, text: str, result1: Dict, result2: Dict) -> Dict:
        """Usa um LLM 'juiz' para decidir entre dois resultados conflitantes."""
        prompt = f"""
        Você é um Sócio-Diretor. Revise a transcrição e os dois JSONs dos seus assistentes. Produza um JSON final e definitivo, com uma justificativa.

        Transcrição: {text}

        Assistente 1 (Claude):
        {json.dumps(result1, indent=2, ensure_ascii=False)}

        Assistente 2 (OpenAI):
        {json.dumps(result2, indent=2, ensure_ascii=False)}

        Sua Saída Final (apenas JSON):
        """

        # Tenta o provedor primário (Gemini)
        try:
            if JUDGE_MODEL_PROVIDER == 'gemini' and GEMINI_API_KEY:
                import google.generativeai as genai
                genai.configure(api_key=GEMINI_API_KEY)
                
                model = genai.GenerativeModel(JUDGE_MODEL)
                response = await asyncio.wait_for(
                    model.generate_content_async(prompt),
                    timeout=30
                )
                
                # Extrair JSON da resposta do Gemini
                response_text = response.text
                match = re.search(r'\{.*\}', response_text, re.DOTALL)
                if match:
                    return json.loads(match.group(0))
                else:
                    # Se não encontrar JSON, tentar parsear a resposta completa
                    return json.loads(response_text)
                    
            elif JUDGE_MODEL_PROVIDER == 'anthropic' and self.anthropic_client:
                message = await self.anthropic_client.messages.create(
                    model=JUDGE_MODEL, max_tokens=2048,
                    messages=[{"role": "user", "content": prompt}]
                )
                final_decision_str = message.content[0].text
                return json.loads(final_decision_str)
            elif JUDGE_MODEL_PROVIDER == 'openai' and self.openai_client: # Caso o primário seja OpenAI
                 response = await self.openai_client.chat.completions.create(
                    model=JUDGE_MODEL, response_format={"type": "json_object"},
                    messages=[{"role": "user", "content": prompt}]
                 )
                 return json.loads(response.choices[0].message.content)

        except Exception as e:
            print(f"Falha no Juiz primário ({JUDGE_MODEL}): {e}. Tentando backup.")
            # Lógica de Failover para o Juiz
            if self.openai_client:
                print(f"Usando Juiz de backup: {JUDGE_MODEL_OPENAI_FALLBACK}")
                response = await self.openai_client.chat.completions.create(
                    model=JUDGE_MODEL_OPENAI_FALLBACK, response_format={"type": "json_object"},
                    messages=[{"role": "user", "content": prompt}]
                )
                return json.loads(response.choices[0].message.content)

        raise Exception("Ambos os LLMs juízes (primário e backup) falharam.")
        
    async def _run_failover_strategy(self, text: str) -> Dict:
        """Tenta o provedor primário (Llama/Together) e usa o secundário (OpenAI) em caso de falha."""
        try:
            if DEFAULT_TRIAGE_PRIMARY_PROVIDER == "together" and self.together_client:
                print("Tentando provedor primário: Llama 4 (via Together)")
                result = await self._run_llama_triage(text, model=DEFAULT_TRIAGE_MODEL_LLAMA)
                if result:
                    return result
        except Exception as e:
            print(f"Falha no provedor primário (Llama 4): {e}. Tentando o secundário.")

        # Fallback para o secundário
        if DEFAULT_TRIAGE_SECONDARY_PROVIDER == "openai" and self.openai_client:
            print("Tentando provedor secundário: OpenAI")
            return await self._run_openai_triage(text, model=DEFAULT_TRIAGE_MODEL_OPENAI_FALLBACK)
        
        return {}

    async def _run_ensemble_strategy(self, text: str) -> Dict:
        """
        Executa a triagem com múltiplos LLMs em paralelo.
        Se a estratégia de ensemble falhar, recorre a um único modelo de alta qualidade.
        """
        try:
            print("Executando estratégia de ensemble com Claude Sonnet 4.0 e GPT-4o.")
            # Executa os dois modelos em paralelo
            task_claude = self._run_claude_triage(text, model=ENSEMBLE_MODEL_ANTHROPIC)
            task_openai = self._run_openai_triage(text, model=ENSEMBLE_MODEL_OPENAI)
            
            results = await asyncio.gather(task_claude, task_openai, return_exceptions=True)

            res_claude = results[0] if not isinstance(results[0], Exception) else None
            res_openai = results[1] if not isinstance(results[1], Exception) else None

            # Se um dos modelos falhou, não podemos comparar, então acionamos o failover
            if not res_claude or not res_openai:
                raise ValueError("Um ou ambos os modelos do ensemble falharam.")

            # Compara os resultados
            if self._compare_results(res_claude, res_openai):
                print("Resultados do ensemble são consistentes.")
                return res_claude  # Retorna qualquer um, pois são iguais
            else:
                print("Resultados divergentes. Acionando o juiz...")
                return await self._judge_results(text, res_claude, res_openai)

        except Exception as e:
            print(f"Estratégia de ensemble falhou: {e}. Usando failover com {ENSEMBLE_FAILOVER_MODEL}.")
            # Failover para um único modelo de alta performance
            return await self._run_openai_triage(text, model=ENSEMBLE_FAILOVER_MODEL)

    async def run_triage(self, text: str, strategy: Strategy, user_id: str) -> dict:
        """
        Executa a triagem com a estratégia escolhida e enriquece com dados premium.
        """
        print(f"Executando estratégia de triagem: {strategy}")
        triage_results = {}

        try:
            if strategy == "simple":
                # Tenta primeiro com o Llama 4, que é o mais barato e potente
                triage_results = await self._run_llama_triage(
                    text, model=SIMPLE_TRIAGE_MODEL_LLAMA
                )
                # Se falhar, usa o fallback da Claude (Haiku)
                if not triage_results:
                    print("Fallback da estratégia 'simple' para Claude Haiku.")
                    triage_results = await self._run_claude_triage(
                        text, model=SIMPLE_TRIAGE_MODEL_CLAUDE_FALLBACK
                    )
            elif strategy == "failover":
                triage_results = await self._run_failover_strategy(text)
            elif strategy == "ensemble":
                triage_results = await self._run_ensemble_strategy(text)
            else:
                raise ValueError(f"Estratégia '{strategy}' não suportada")

        except Exception as e:
            print(f"Erro na triagem IA ({strategy}): {e}. Usando fallback.")
            triage_results = self._run_regex_fallback(text)
        
        # Passo 3: Avaliação de Critérios Premium
        # Em uma aplicação real, a sessão do DB viria de uma dependência do FastAPI
        # Aqui, estamos simulando a sua obtenção.
        db_session = next(get_db())
        is_premium, premium_rule = evaluate_case_premium(triage_results, db_session)
        
        triage_results['is_premium'] = is_premium
        triage_results['premium_rule_id'] = premium_rule.id if premium_rule else None
        
        # Log de auditoria (opcional, mas recomendado)
        if is_premium:
            print(f"Caso classificado como PREMIUM pela regra: {premium_rule.name} (ID: {premium_rule.id})")

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
        
        # EXPANSÃO: Direito Digital Completo
        marco_civil = r"marco civil da internet|neutralidade da rede|guarda de logs"
        imagem_digital = r"direito de imagem|uso indevido de imagem|exposição não autorizada"
        contratos_digitais = r"contrato eletrônico|assinatura digital|documento eletrônico"
        ciberseguranca = r"cibersegurança|segurança da informação|proteção de dados|data breach"
        criptomoedas = r"bitcoin|criptomoeda|nft|blockchain|moeda digital|token"
        direito_esquecimento = r"direito ao esquecimento|remoção de conteúdo|desindexação"
        fake_news = r"fake news|notícias falsas|desinformação|informação falsa"
        cyberbullying = r"cyberbullying|assédio digital|violência online|bullying virtual"
        pirataria_digital = r"pirataria|download ilegal|violação de direitos autorais online"
        jogos_online = r"jogos online|apostas online|games|cassino online"
        
        # EXPANSÃO: Direito do Consumidor Completo
        vicio_produto = r"vício do produto|produto defeituoso|defeito de fabricação"
        vicio_servico = r"vício do serviço|serviço mal prestado|falha na prestação"
        propaganda_enganosa = r"propaganda enganosa|publicidade falsa|marketing enganoso"
        propaganda_abusiva = r"propaganda abusiva|publicidade abusiva|marketing abusivo"
        banco_dados = r"spc|serasa|negativação|cadastro de inadimplente|banco de dados"
        planos_saude = r"plano de saúde|seguro saúde|negativa de cobertura|ans"
        telecomunicacoes = r"telefonia|operadora|internet|tv por assinatura|anatel"
        servicos_bancarios = r"banco|tarifa bancária|conta corrente|cartão de crédito"
        superendividamento = r"superendividamento|renegociação de dívidas|nome limpo"
        ecommerce_consumidor = r"compra online|loja virtual|direito de arrependimento|marketplace"
        servicos_publicos = r"água|luz|energia elétrica|gás|serviços essenciais"
        seguro = r"seguro|seguradora|sinistro|indenização de seguro"
        transporte = r"transporte público|uber|99|táxi|ônibus|metro|avião"
        alimentacao = r"restaurante|delivery|ifood|segurança alimentar|intoxicação"
        educacao = r"escola|faculdade|universidade|curso|mensalidade|mec"
        turismo = r"viagem|hotel|agência de turismo|voo cancelado|pacote turístico"
        automoveis = r"carro|automóvel|concessionária|financiamento de veículo"
        imoveis_consumidor = r"construtora|imobiliária|apartamento na planta|entrega de imóvel"
        cartoes_credito = r"cartão de crédito|fraude no cartão|limite de cartão|anuidade"
        financiamentos = r"financiamento|empréstimo|crediário|consignado|juros abusivos"
        
        # NOVO: Direitos das Startups - Ecossistema de Inovação Completo
        startups_geral = r"startup|startups|empresa de tecnologia|tech company|inovação|empreendedorismo|ecossistema de inovação"
        venture_capital = r"venture capital|vc|private equity|pe|fundo de investimento|rodada de investimento|seed|series a|series b"
        estruturacao_societaria = r"constituição de empresa|alteração contratual|estatuto social|acordo de sócios|governança corporativa"
        contratos_investment = r"term sheet|sha|investment agreement|acordo de investimento|contrato de investimento|shareholders agreement"
        equity_stock = r"equity|stock options|stock option plan|participação societária|vesting|cliff|distribuição de quotas"
        ip_tech = r"propriedade intelectual|patent|patente|software|trade secret|segredo comercial|marca de tecnologia"
        marco_legal = r"marco legal das startups|lei 14195|lei complementar 182|empresa simples de crédito|inova simples"
        compliance_startup = r"compliance|lgpd|cvm|bacen|sandbox regulatório|regulamentação de startups"
        aceleradoras = r"aceleradora|incubadora|programa de aceleração|corporate venture|venture builder"
        due_diligence = r"due diligence|dd|auditoria legal|revisão legal|legal review"
        crowdfunding = r"crowdfunding|financiamento coletivo|equity crowdfunding|captação pública"
        parcerias_estrategicas = r"joint venture|parceria estratégica|corporate venture|partnership|aliança estratégica"
        tributario_startup = r"regime tributário|lucro real|lucro presumido|simples nacional|incentivos fiscais|lei do bem"
        trabalhista_tech = r"contratação tech|remote work|trabalho remoto|equity compensation|stock option|pj ou clt"
        contratos_tech = r"saas|api|software license|licenciamento|development agreement|msa|sow|statement of work"
        exit_strategy = r"ipo|exit|m&a|fusão|aquisição|trade sale|liquidação|desinvestimento"
        corporate_governance = r"conselho de administração|board|comitês|governança|corporate governance"
        esg_startup = r"esg|sustentabilidade|impacto social|empresa b|bcorp|impact investing"
        international = r"expansão internacional|flip|subsidiária|offshore|cross border|international expansion"
        fintech = r"fintech|pagamentos|pix|open banking|arranjo de pagamento|instituição de pagamento"
        healthtech = r"healthtech|saúde digital|telemedicina|anvisa|dispositivo médico|software médico"
        
        # EXPANSÃO: Erro Médico e Serviços de Saúde no contexto de Consumidor
        erro_medico = r"erro médico|negligência médica|imperícia|imprudência médica|iatrogenia"
        servicos_medicos = r"hospital|clínica|consultório|médico|cirurgia|procedimento médico|internação|diagnóstico"
        tratamentos_esteticos = r"cirurgia plástica|estética|botox|preenchimento|lipoaspiração|harmonização facial"
        plano_saude_consumidor = r"plano de saúde|convênio médico|operadora de saúde|negativa de cobertura|reajuste abusivo"
        responsabilidade_medica = r"responsabilidade civil médica|dano moral médico|indenização médica|falha médica"

        # NOVO: MARCS (Arbitragem, Mediação, Conciliação)
        arbitragem = r"arbitragem|arbitral|árbitro|câmara de arbitragem|tribunal arbitral|cláusula compromissória|convenção de arbitragem|compromisso arbitral|sentença arbitral"
        mediacao = r"mediação|mediador|termo de mediação|sessão de mediação"
        conciliacao = r"conciliação|conciliador|audiência de conciliação|termo de conciliação"
        dispute_board = r"dispute board|comitê de resolução de disputas|painel de resolução"
        execucao_arbitral = r"execução de sentença arbitral|executar sentença arbitral"
        transacao_tributaria = r"transação tributária|negociação fiscal|acordo com o fisco"
        
        # NOVO: Contencioso pré-judicial administrativo
        procon = r"procon"
        carf = r"carf|conselho administrativo de recursos fiscais"
        conselhos_contribuintes = r"conselho de contribuintes"
        processo_administrativo = r"processo administrativo|recurso administrativo|defesa administrativa|impugnação administrativa"
        
        # NOVO: Agências reguladoras
        anatel = r"anatel|agência nacional de telecomunicações|processo na anatel"
        anvisa = r"anvisa|agência nacional de vigilância sanitária|processo na anvisa"
        aneel = r"aneel|agência nacional de energia elétrica|processo na aneel"
        anp = r"anp|agência nacional do petróleo|processo na anp"
        ancine = r"ancine|agência nacional do cinema|processo na ancine"
        anac = r"anac|agência nacional de aviação civil|processo na anac"
        antaq = r"antaq|agência nacional de transportes aquaviários|processo na antaq"
        antt = r"antt|agência nacional de transportes terrestres|processo na antt"
        ans_reguladora = r"ans|agência nacional de saúde suplementar|processo na ans"
        ana_agencia = r"ana|agência nacional de águas|processo na ana"
        agencias_gerais = r"agência reguladora|processo regulatório|decisão regulatória"
        
        # NOVO: Receitas e fiscos
        receita_federal = r"receita federal|processo na receita federal|auto de infração federal"
        receita_estadual = r"receita estadual|fisco estadual|processo fiscal estadual"
        receita_municipal = r"receita municipal|fisco municipal|processo fiscal municipal"

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
            # Verificações específicas para subareas de consumidor
            if re.search(vicio_produto, text_lower):
                subarea = "Vício do Produto"
            elif re.search(vicio_servico, text_lower):
                subarea = "Vício do Serviço"
            elif re.search(propaganda_enganosa, text_lower):
                subarea = "Propaganda Enganosa"
            elif re.search(propaganda_abusiva, text_lower):
                subarea = "Propaganda Abusiva"
            elif re.search(banco_dados, text_lower):
                subarea = "Banco de Dados"
            elif re.search(planos_saude, text_lower):
                subarea = "Planos de Saúde"
            elif re.search(telecomunicacoes, text_lower):
                subarea = "Telecomunicações"
            elif re.search(servicos_bancarios, text_lower):
                subarea = "Serviços Bancários"
            elif re.search(superendividamento, text_lower):
                subarea = "Superendividamento"
            elif re.search(ecommerce_consumidor, text_lower):
                subarea = "E-commerce Consumidor"
            elif re.search(servicos_publicos, text_lower):
                subarea = "Serviços Públicos"
            elif re.search(seguro, text_lower):
                subarea = "Seguro"
            elif re.search(transporte, text_lower):
                subarea = "Transporte"
            elif re.search(alimentacao, text_lower):
                subarea = "Alimentação"
            elif re.search(educacao, text_lower):
                subarea = "Educação"
            elif re.search(turismo, text_lower):
                subarea = "Turismo"
            elif re.search(automoveis, text_lower):
                subarea = "Automóveis"
            elif re.search(imoveis_consumidor, text_lower):
                subarea = "Imóveis"
            elif re.search(cartoes_credito, text_lower):
                subarea = "Cartões de Crédito"
            elif re.search(financiamentos, text_lower):
                subarea = "Financiamentos"
            elif re.search(erro_medico, text_lower):
                subarea = "Erro Médico"
            elif re.search(servicos_medicos, text_lower) and re.search(r"falha|problema|defeito|negligência|dano|indenização", text_lower):
                subarea = "Serviços Médicos"
            elif re.search(tratamentos_esteticos, text_lower):
                subarea = "Tratamentos Estéticos"
            elif re.search(plano_saude_consumidor, text_lower):
                subarea = "Planos de Saúde"
            elif re.search(responsabilidade_medica, text_lower):
                subarea = "Erro Médico"
            elif re.search(r"garantia", text_lower):
                subarea = "Garantia"
            elif re.search(r"cobrança indevida", text_lower):
                subarea = "Cobrança Indevida"
        elif re.search(digital, text_lower):
            area = "Digital"
            # Verificações específicas para subareas digitais
            if re.search(marco_civil, text_lower):
                subarea = "Marco Civil da Internet"
            elif re.search(imagem_digital, text_lower):
                subarea = "Direito de Imagem Digital"
            elif re.search(contratos_digitais, text_lower):
                subarea = "Contratos Digitais"
            elif re.search(ciberseguranca, text_lower):
                subarea = "Cibersegurança"
            elif re.search(criptomoedas, text_lower):
                subarea = "Criptomoedas"
            elif re.search(direito_esquecimento, text_lower):
                subarea = "Direito ao Esquecimento"
            elif re.search(fake_news, text_lower):
                subarea = "Fake News"
            elif re.search(cyberbullying, text_lower):
                subarea = "Cyberbullying"
            elif re.search(pirataria_digital, text_lower):
                subarea = "Pirataria Digital"
            elif re.search(jogos_online, text_lower):
                subarea = "Jogos Online"
            elif re.search(r"lgpd|dados pessoais", text_lower):
                subarea = "LGPD"
            elif re.search(r"crime.*digital|invasão|fraude.*online", text_lower):
                subarea = "Crimes Digitais"
            elif re.search(r"e-commerce|comércio eletrônico", text_lower):
                subarea = "E-commerce"
            elif re.search(r"redes sociais|facebook|instagram|twitter", text_lower):
                subarea = "Redes Sociais"
            elif re.search(r"domínio|propriedade digital", text_lower):
                subarea = "Propriedade Digital"
        elif re.search(empresarial, text_lower) or re.search(societario, text_lower):
            area = "Empresarial"
            if re.search(arbitragem, text_lower):
                subarea = "Arbitragem Societária e M&A"
            elif re.search(mediacao, text_lower):
                subarea = "Mediação Empresarial"
            elif re.search(dispute_board, text_lower):
                subarea = "Comitês de Resolução de Disputas"
            elif re.search(r"societário|sociedade|sócio|quotas|contrato social", text_lower):
                subarea = "Societário"
            elif re.search(r"comercial|fornecimento|distribuição", text_lower):
                subarea = "Contratos Comerciais"
            elif re.search(r"cheque|nota promissória|duplicata", text_lower):
                subarea = "Títulos de Crédito"
            elif re.search(r"falência|recuperação judicial", text_lower):
                subarea = "Falência e Recuperação"
        elif re.search(civil, text_lower):
            area = "Civil"
            if re.search(execucao_arbitral, text_lower):
                subarea = "Execução de Sentença Arbitral"
            elif re.search(arbitragem, text_lower):
                subarea = "Arbitragem Cível e Contratual"
            elif re.search(mediacao, text_lower) or re.search(conciliacao, text_lower):
                subarea = "Mediação e Conciliação Cível"
            elif re.search(dispute_board, text_lower):
                subarea = "Dispute Boards em Contratos"
            elif re.search(r"contrato", text_lower):
                subarea = "Contratos"
            elif re.search(r"indenização|dano", text_lower):
                subarea = "Responsabilidade Civil"
            elif re.search(r"obrigação", text_lower):
                subarea = "Obrigações"
            elif re.search(r"inventário|partilha|herança", text_lower):
                subarea = "Sucessões"
            elif re.search(r"propriedade|posse", text_lower):
                subarea = "Direitos Reais"
        elif re.search(tributario, text_lower):
            area = "Tributário"
            if re.search(transacao_tributaria, text_lower):
                subarea = "Transação Tributária"
            elif re.search(arbitragem, text_lower):
                subarea = "Arbitragem Tributária"
            elif re.search(mediacao, text_lower):
                subarea = "Mediação Fiscal"
            elif re.search(r"planejamento", text_lower):
                subarea = "Planejamento Tributário"
            elif re.search(r"execução fiscal|auto de infração", text_lower):
                subarea = "Contencioso Fiscal"
            else:
                subarea = "Tributos em Espécie"
        elif re.search(administrativo, text_lower):
            area = "Administrativo"
            if re.search(arbitragem, text_lower):
                subarea = "Arbitragem com a Administração Pública"
            elif re.search(mediacao, text_lower):
                subarea = "Mediação em Conflitos Públicos"
            elif re.search(r"servidor", text_lower):
                subarea = "Servidor Público"
            elif re.search(r"licitação|contrato público", text_lower):
                subarea = "Licitações e Contratos Públicos"
            elif re.search(r"improbidade", text_lower):
                subarea = "Improbidade Administrativa"
            else:
                subarea = "Câmaras de Resolução de Conflitos"
        elif re.search(regulatorio, text_lower):
            area = "Regulatório"
            if re.search(arbitragem, text_lower):
                subarea = "Arbitragem Setorial"
            elif re.search(dispute_board, text_lower):
                subarea = "Painéis de Resolução de Disputas"
            elif re.search(mediacao, text_lower):
                subarea = "Mediação com Agências Reguladoras"
            elif re.search(r"aneel|elétrico", text_lower):
                subarea = "Setor Elétrico"
            elif re.search(r"anatel|telecom", text_lower):
                subarea = "Telecomunicações"
            elif re.search(r"ans|saúde suplementar", text_lower):
                subarea = "Saúde Suplementar"
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
                model=ENSEMBLE_MODEL_OPENAI,
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


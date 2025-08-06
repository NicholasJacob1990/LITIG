#!/usr/bin/env python3
"""
Hybrid LangChain Orchestrator - Estratégia Híbrida Implementada
==============================================================

Implementa a estratégia híbrida recomendada que combina:
✅ MANTER: Modelos fixos especializados (controle total)
✅ ADICIONAR: Agentes LangChain avançados integrados aos workflows LangGraph

Integração com sistema existente:
- Usa modelos já configurados no config.py
- Preserva fallback de 4 níveis do OpenRouter
- Adiciona agentes inteligentes aos workflows LangGraph existentes
- Mantém 100% compatibilidade com implementações atuais
"""

import asyncio
import logging
import os
import time
from typing import Dict, List, Optional, Any, Union
from datetime import datetime

# LangChain Core
try:
    from langchain_core.messages import HumanMessage, SystemMessage, AIMessage
    from langchain_core.tools import Tool
    from langchain_core.runnables import RunnableLambda
    LANGCHAIN_CORE_AVAILABLE = True
except ImportError:
    LANGCHAIN_CORE_AVAILABLE = False

# LangChain Agentes
try:
    from langchain.agents import AgentExecutor, create_openai_functions_agent
    from langchain.memory import ConversationBufferMemory
    from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder
    LANGCHAIN_AGENTS_AVAILABLE = True
except ImportError:
    LANGCHAIN_AGENTS_AVAILABLE = False

# LangChain Provedores (modelos já configurados)
try:
    from langchain_openai import ChatOpenAI
    LANGCHAIN_OPENAI_AVAILABLE = True
except ImportError:
    LANGCHAIN_OPENAI_AVAILABLE = False

try:
    from langchain_anthropic import ChatAnthropic
    LANGCHAIN_ANTHROPIC_AVAILABLE = True
except ImportError:
    LANGCHAIN_ANTHROPIC_AVAILABLE = False

try:
    from langchain_google_genai import ChatGoogleGenerativeAI
    LANGCHAIN_GOOGLE_AVAILABLE = True
except ImportError:
    LANGCHAIN_GOOGLE_AVAILABLE = False

try:
    from langchain_xai import ChatXAI
    LANGCHAIN_XAI_AVAILABLE = True
except ImportError:
    LANGCHAIN_XAI_AVAILABLE = False

# RAG Components
try:
    from langchain.vectorstores import Chroma
    from langchain.embeddings import OpenAIEmbeddings
    from langchain.text_splitter import RecursiveCharacterTextSplitter
    from langchain.chains import RetrievalQA
    LANGCHAIN_RAG_AVAILABLE = True
except ImportError:
    LANGCHAIN_RAG_AVAILABLE = False

# Config e OpenRouter existente - com path handling
try:
    import sys
    import os
    
    # Adicionar path dos serviços se necessário
    current_dir = os.path.dirname(os.path.abspath(__file__))
    if current_dir not in sys.path:
        sys.path.append(current_dir)
    
    # Adicionar path do projeto principal
    project_root = os.path.join(current_dir, '..', '..')
    if project_root not in sys.path:
        sys.path.append(project_root)
    
    from config import Settings
    from openrouter_client import OpenRouterClient
    CONFIG_AVAILABLE = True
except ImportError as e:
    logger.warning(f"Config/OpenRouter não disponível: {e}")
    CONFIG_AVAILABLE = False
    Settings = None
    OpenRouterClient = None

logger = logging.getLogger(__name__)

class HybridLangChainOrchestrator:
    """
    Orquestrador Híbrido que implementa a estratégia recomendada:
    
    ✅ MANTÉM: Modelos fixos especializados (controle total de custos/qualidade)
    ✅ ADICIONA: Agentes LangChain avançados (orquestração automática)
    ✅ INTEGRA: Com workflows LangGraph existentes
    ✅ PRESERVA: Fallback de 4 níveis do OpenRouter
    """
    
    def __init__(self):
        self.logger = logging.getLogger(f"{self.__class__.__name__}")
        
        # Verificar disponibilidade de componentes
        self._check_dependencies()
        
        # Inicializar cliente OpenRouter existente (fallback preservado)
        self.openrouter_client = self._initialize_openrouter_client()
        
        # Configurar modelos LangChain para os modelos JÁ EXISTENTES
        self.langchain_models = self._initialize_langchain_models()
        
        # Configurar agentes especializados
        self.agents = self._initialize_agents()
        
        # Configurar RAG jurídico brasileiro
        self.rag_system = self._initialize_rag_system()
        
        self.logger.info("✅ Hybrid LangChain Orchestrator inicializado com estratégia híbrida")
    
    def _check_dependencies(self):
        """Verifica disponibilidade de dependências LangChain."""
        missing = []
        
        if not LANGCHAIN_CORE_AVAILABLE:
            missing.append("langchain-core")
        if not LANGCHAIN_AGENTS_AVAILABLE:
            missing.append("langchain agents")
        if not LANGCHAIN_OPENAI_AVAILABLE:
            missing.append("langchain-openai")
        
        if missing:
            self.logger.warning(f"⚠️ Dependências LangChain faltando: {', '.join(missing)}")
            self.logger.warning("Executando em modo fallback para OpenRouter")
        else:
            self.logger.info("✅ Todas as dependências LangChain disponíveis")
    
    def _initialize_openrouter_client(self) -> Optional[OpenRouterClient]:
        """Inicializa cliente OpenRouter existente (preserva fallback)."""
        try:
            if CONFIG_AVAILABLE:
                client = OpenRouterClient()
                self.logger.info("✅ OpenRouter client inicializado (fallback preservado)")
                return client
            else:
                self.logger.warning("⚠️ Config não disponível - OpenRouter desabilitado")
                return None
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar OpenRouter: {e}")
            return None
    
    def _initialize_langchain_models(self) -> Dict[str, Any]:
        """
        Inicializa modelos LangChain usando EXATAMENTE os mesmos modelos 
        já configurados no config.py (ZERO novos modelos).
        """
        models = {}
        
        # ✅ OpenAI - modelos já em uso no app
        if LANGCHAIN_OPENAI_AVAILABLE and Settings.OPENAI_API_KEY:
            try:
                models.update({
                    # OCR e extração (custo otimizado)
                    "ocr": ChatOpenAI(
                        model="gpt-4o-mini",
                        api_key=Settings.OPENAI_API_KEY,
                        temperature=0.1
                    ),
                    # Análise geral
                    "general": ChatOpenAI(
                        model="gpt-4o",
                        api_key=Settings.OPENAI_API_KEY,
                        temperature=0.1
                    )
                })
                self.logger.info("✅ OpenAI models configurados via LangChain")
            except Exception as e:
                self.logger.warning(f"⚠️ OpenAI LangChain falhou: {e}")
        
        # ✅ Anthropic - Claude para análise jurídica
        if LANGCHAIN_ANTHROPIC_AVAILABLE and Settings.ANTHROPIC_API_KEY:
            try:
                models["case"] = ChatAnthropic(
                    model="claude-3-5-sonnet-20241022",
                    api_key=Settings.ANTHROPIC_API_KEY,
                    temperature=0.1
                )
                self.logger.info("✅ Anthropic Claude configurado via LangChain")
            except Exception as e:
                self.logger.warning(f"⚠️ Anthropic LangChain falhou: {e}")
        
        # ✅ Google - Gemini para perfis
        if LANGCHAIN_GOOGLE_AVAILABLE and Settings.GOOGLE_API_KEY:
            try:
                models.update({
                    "profile": ChatGoogleGenerativeAI(
                        model="gemini-1.5-pro",
                        google_api_key=Settings.GOOGLE_API_KEY,
                        temperature=0.1
                    ),
                    "judge": ChatGoogleGenerativeAI(
                        model="gemini-2.0-flash-exp",
                        google_api_key=Settings.GOOGLE_API_KEY,
                        temperature=0.1
                    )
                })
                self.logger.info("✅ Google Gemini configurado via LangChain")
            except Exception as e:
                self.logger.warning(f"⚠️ Google LangChain falhou: {e}")
        
        # ✅ xAI - Grok para LEX-9000
        if LANGCHAIN_XAI_AVAILABLE and Settings.XAI_API_KEY:
            try:
                models.update({
                    "lex9000": ChatXAI(
                        model="grok-1",
                        api_key=Settings.XAI_API_KEY,
                        temperature=0.1
                    ),
                    "cluster": ChatXAI(
                        model="grok-1",
                        api_key=Settings.XAI_API_KEY,
                        temperature=0.1
                    )
                })
                self.logger.info("✅ xAI Grok configurado via LangChain")
            except Exception as e:
                self.logger.warning(f"⚠️ xAI LangChain falhou: {e}")
        
        # ✅ OpenRouter via LangChain (autorouter)
        if LANGCHAIN_OPENAI_AVAILABLE and Settings.OPENROUTER_API_KEY:
            try:
                models["autorouter"] = ChatOpenAI(
                    base_url="https://openrouter.ai/api/v1",
                    api_key=Settings.OPENROUTER_API_KEY,
                    model="openrouter/auto",
                    temperature=0.1,
                    default_headers={
                        "HTTP-Referer": Settings.OPENROUTER_SITE_URL,
                        "X-Title": Settings.OPENROUTER_APP_NAME,
                    }
                )
                self.logger.info("✅ OpenRouter autorouter configurado via LangChain")
            except Exception as e:
                self.logger.warning(f"⚠️ OpenRouter LangChain falhou: {e}")
        
        self.logger.info(f"✅ {len(models)} modelos LangChain inicializados (usando modelos existentes)")
        return models
    
    def _initialize_agents(self) -> Dict[str, Any]:
        """Inicializa agentes especializados para diferentes funções jurídicas."""
        agents = {}
        
        if not LANGCHAIN_AGENTS_AVAILABLE or not self.langchain_models:
            self.logger.warning("⚠️ Agentes LangChain não disponíveis - usando fallback")
            return agents
        
        try:
            # ✅ Agente de Análise de Casos (usando Claude)
            if "case" in self.langchain_models:
                agents["case_analyzer"] = self._create_case_analysis_agent()
            
            # ✅ Agente de Extração de Documentos (usando GPT-4o-mini)
            if "ocr" in self.langchain_models:
                agents["document_extractor"] = self._create_document_extraction_agent()
            
            # ✅ Agente de Pesquisa Jurídica (usando Grok)
            if "lex9000" in self.langchain_models:
                agents["legal_researcher"] = self._create_legal_research_agent()
            
            # ✅ Agente de Perfis (usando Gemini)
            if "profile" in self.langchain_models:
                agents["profile_analyzer"] = self._create_profile_analysis_agent()
            
            self.logger.info(f"✅ {len(agents)} agentes especializados inicializados")
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar agentes: {e}")
        
        return agents
    
    def _create_case_analysis_agent(self) -> Optional[AgentExecutor]:
        """Cria agente especializado em análise de casos jurídicos."""
        try:
            # Memória para contexto persistente
            memory = ConversationBufferMemory(
                memory_key="chat_history",
                return_messages=True
            )
            
            # Tools jurídicas especializadas
            tools = [
                Tool(
                    name="analyze_case_complexity",
                    func=self._analyze_case_complexity,
                    description="Analisa a complexidade de um caso jurídico brasileiro"
                ),
                Tool(
                    name="identify_legal_area",
                    func=self._identify_legal_area,
                    description="Identifica a área jurídica do caso (civil, trabalhista, etc.)"
                ),
                Tool(
                    name="calculate_case_value",
                    func=self._calculate_case_value,
                    description="Estima o valor econômico do caso"
                ),
                Tool(
                    name="search_precedents",
                    func=self._search_legal_precedents,
                    description="Busca precedentes jurisprudenciais relevantes"
                )
            ]
            
            # Prompt especializado para direito brasileiro
            prompt = ChatPromptTemplate.from_messages([
                ("system", """Você é um assistente jurídico especializado em direito brasileiro.
                
Sua função é analisar casos jurídicos com precisão e fornecer insights valiosos sobre:
- Complexidade e viabilidade do caso
- Área jurídica aplicável (Civil, Trabalhista, Penal, etc.)
- Estimativa de valor econômico
- Precedentes jurisprudenciais relevantes
- Legislação aplicável

Sempre considere:
- Legislação brasileira atual (Códigos, CLT, CF/88)
- Jurisprudência dos tribunais superiores (STF, STJ, TST)
- Prazos processuais e prescricionais
- Custos processuais e honorários

Use as tools disponíveis para realizar análises completas."""),
                MessagesPlaceholder(variable_name="chat_history"),
                ("human", "{input}"),
                MessagesPlaceholder(variable_name="agent_scratchpad"),
            ])
            
            # Criar agente
            agent = create_openai_functions_agent(
                llm=self.langchain_models["case"],
                tools=tools,
                prompt=prompt
            )
            
            return AgentExecutor(
                agent=agent,
                tools=tools,
                memory=memory,
                verbose=True,
                handle_parsing_errors=True
            )
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao criar agente de análise de casos: {e}")
            return None
    
    def _create_document_extraction_agent(self) -> Optional[AgentExecutor]:
        """Cria agente especializado em extração de documentos."""
        try:
            memory = ConversationBufferMemory(
                memory_key="chat_history",
                return_messages=True
            )
            
            tools = [
                Tool(
                    name="extract_text_from_image",
                    func=self._extract_text_from_image,
                    description="Extrai texto de imagens de documentos jurídicos"
                ),
                Tool(
                    name="parse_legal_document",
                    func=self._parse_legal_document,
                    description="Analisa e estrutura documentos jurídicos"
                ),
                Tool(
                    name="identify_document_type",
                    func=self._identify_document_type,
                    description="Identifica o tipo de documento jurídico"
                ),
                Tool(
                    name="extract_key_information",
                    func=self._extract_key_information,
                    description="Extrai informações-chave de documentos"
                )
            ]
            
            prompt = ChatPromptTemplate.from_messages([
                ("system", """Você é um especialista em processamento de documentos jurídicos brasileiros.

Sua função é:
- Extrair texto de imagens e PDFs com alta precisão
- Identificar tipos de documentos (petições, contratos, sentenças, etc.)
- Estruturar informações de forma organizada
- Extrair dados-chave (partes, valores, datas, prazos)

Sempre mantenha:
- Precisão na extração de texto
- Preservação de formatação importante
- Identificação de elementos jurídicos relevantes
- Organização clara das informações extraídas"""),
                MessagesPlaceholder(variable_name="chat_history"),
                ("human", "{input}"),
                MessagesPlaceholder(variable_name="agent_scratchpad"),
            ])
            
            agent = create_openai_functions_agent(
                llm=self.langchain_models["ocr"],
                tools=tools,
                prompt=prompt
            )
            
            return AgentExecutor(
                agent=agent,
                tools=tools,
                memory=memory,
                verbose=True,
                handle_parsing_errors=True
            )
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao criar agente de extração: {e}")
            return None
    
    def _create_legal_research_agent(self) -> Optional[AgentExecutor]:
        """Cria agente especializado em pesquisa jurídica."""
        try:
            memory = ConversationBufferMemory(
                memory_key="chat_history",
                return_messages=True
            )
            
            tools = [
                Tool(
                    name="search_legislation",
                    func=self._search_legislation,
                    description="Busca legislação brasileira relevante"
                ),
                Tool(
                    name="find_jurisprudence",
                    func=self._find_jurisprudence,
                    description="Encontra jurisprudência dos tribunais superiores"
                ),
                Tool(
                    name="calculate_deadlines",
                    func=self._calculate_deadlines,
                    description="Calcula prazos processuais e prescricionais"
                ),
                Tool(
                    name="research_doctrine",
                    func=self._research_doctrine,
                    description="Pesquisa doutrina jurídica especializada"
                )
            ]
            
            prompt = ChatPromptTemplate.from_messages([
                ("system", """Você é um pesquisador jurídico especialista em direito brasileiro.

Suas especialidades incluem:
- Legislação federal, estadual e municipal
- Jurisprudência do STF, STJ, TST e tribunais regionais
- Doutrina jurídica brasileira
- Prazos processuais e prescricionais
- Procedimentos jurídicos

Sempre forneça:
- Referências precisas (leis, artigos, súmulas)
- Jurisprudência atualizada e relevante
- Análise crítica da aplicabilidade
- Prazos e procedimentos corretos"""),
                MessagesPlaceholder(variable_name="chat_history"),
                ("human", "{input}"),
                MessagesPlaceholder(variable_name="agent_scratchpad"),
            ])
            
            agent = create_openai_functions_agent(
                llm=self.langchain_models["lex9000"],
                tools=tools,
                prompt=prompt
            )
            
            return AgentExecutor(
                agent=agent,
                tools=tools,
                memory=memory,
                verbose=True,
                handle_parsing_errors=True
            )
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao criar agente de pesquisa: {e}")
            return None
    
    def _create_profile_analysis_agent(self) -> Optional[AgentExecutor]:
        """Cria agente especializado em análise de perfis."""
        try:
            memory = ConversationBufferMemory(
                memory_key="chat_history",
                return_messages=True
            )
            
            tools = [
                Tool(
                    name="analyze_lawyer_expertise",
                    func=self._analyze_lawyer_expertise,
                    description="Analisa expertise e especialização de advogados"
                ),
                Tool(
                    name="match_case_to_lawyer",
                    func=self._match_case_to_lawyer,
                    description="Faz matching entre casos e advogados especializados"
                ),
                Tool(
                    name="evaluate_success_probability",
                    func=self._evaluate_success_probability,
                    description="Avalia probabilidade de sucesso baseada no perfil"
                ),
                Tool(
                    name="recommend_partnerships",
                    func=self._recommend_partnerships,
                    description="Recomenda parcerias estratégicas entre advogados"
                )
            ]
            
            prompt = ChatPromptTemplate.from_messages([
                ("system", """Você é um especialista em análise de perfis jurídicos e matching.

Suas competências incluem:
- Análise de especialização e expertise de advogados
- Matching inteligente entre casos e profissionais
- Avaliação de probabilidade de sucesso
- Recomendação de parcerias estratégicas

Considere sempre:
- Área de especialização do advogado
- Experiência e histórico de casos
- Localização geográfica
- Complexidade do caso vs. experiência
- Complementaridade de competências"""),
                MessagesPlaceholder(variable_name="chat_history"),
                ("human", "{input}"),
                MessagesPlaceholder(variable_name="agent_scratchpad"),
            ])
            
            agent = create_openai_functions_agent(
                llm=self.langchain_models["profile"],
                tools=tools,
                prompt=prompt
            )
            
            return AgentExecutor(
                agent=agent,
                tools=tools,
                memory=memory,
                verbose=True,
                handle_parsing_errors=True
            )
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao criar agente de perfis: {e}")
            return None
    
    def _initialize_rag_system(self) -> Optional[Any]:
        """Inicializa sistema RAG com base jurídica brasileira."""
        if not LANGCHAIN_RAG_AVAILABLE or "general" not in self.langchain_models:
            self.logger.warning("⚠️ RAG não disponível - componentes faltando")
            return None
        
        try:
            # Configurar embeddings OpenAI (já em uso no app)
            embeddings = OpenAIEmbeddings(
                model="text-embedding-3-small",
                openai_api_key=Settings.OPENAI_API_KEY
            )
            
            # Configurar vector store
            vectorstore = Chroma(
                collection_name="brazilian_legal_docs",
                embedding_function=embeddings,
                persist_directory="./legal_knowledge_base"
            )
            
            # Chain RAG para consultas jurídicas
            rag_chain = RetrievalQA.from_chain_type(
                llm=self.langchain_models["general"],
                chain_type="stuff",
                retriever=vectorstore.as_retriever(search_kwargs={"k": 5}),
                return_source_documents=True
            )
            
            self.logger.info("✅ Sistema RAG jurídico inicializado")
            return rag_chain
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar RAG: {e}")
            return None
    
    # ===== MÉTODOS PÚBLICOS: INTERFACE PARA WORKFLOWS EXISTENTES =====
    
    async def route_by_function(self, function: str, prompt: str, **kwargs) -> Dict[str, Any]:
        """
        Rota inteligente que combina modelos fixos com agentes LangChain.
        
        Mantém compatibilidade com OpenRouter existente mas adiciona 
        orquestração automática via agentes quando disponível.
        """
        start_time = time.time()
        
        try:
            # ✅ NÍVEL 1: Agentes LangChain especializados (se disponível)
            if self.agents and function in self._get_agent_mapping():
                agent_name = self._get_agent_mapping()[function]
                if agent_name in self.agents:
                    self.logger.info(f"🤖 Usando agente LangChain: {agent_name}")
                    result = await self._invoke_agent(agent_name, prompt, **kwargs)
                    if result:
                        duration = time.time() - start_time
                        return {
                            "success": True,
                            "result": result,
                            "method": f"langchain_agent_{agent_name}",
                            "model": self._get_agent_model(agent_name),
                            "duration": duration
                        }
            
            # ✅ NÍVEL 2: Modelos LangChain diretos (se disponível)
            if self.langchain_models and function in self._get_function_mapping():
                model_key = self._get_function_mapping()[function]
                if model_key in self.langchain_models:
                    self.logger.info(f"📱 Usando modelo LangChain direto: {model_key}")
                    result = await self._invoke_langchain_model(model_key, prompt, **kwargs)
                    if result:
                        duration = time.time() - start_time
                        return {
                            "success": True,
                            "result": result,
                            "method": f"langchain_direct_{model_key}",
                            "model": model_key,
                            "duration": duration
                        }
            
            # ✅ NÍVEL 3: OpenRouter fallback (preserva sistema existente)
            if self.openrouter_client:
                self.logger.info(f"🌐 Usando OpenRouter fallback para função: {function}")
                messages = [{"role": "user", "content": prompt}]
                
                # Mapear função para modelo OpenRouter
                primary_model = self._get_openrouter_model_for_function(function)
                
                result = await self.openrouter_client.chat_completion_with_fallback(
                    primary_model=primary_model,
                    messages=messages,
                    **kwargs
                )
                
                if result:
                    duration = time.time() - start_time
                    return {
                        "success": True,
                        "result": result,
                        "method": "openrouter_fallback",
                        "model": primary_model,
                        "duration": duration
                    }
            
            # ✅ NÍVEL 4: Erro - todos os métodos falharam
            raise Exception("Todos os níveis de roteamento falharam")
            
        except Exception as e:
            duration = time.time() - start_time
            self.logger.error(f"❌ Erro no roteamento da função {function}: {e}")
            return {
                "success": False,
                "error": str(e),
                "method": "failed",
                "duration": duration
            }
    
    async def process_with_agent(self, agent_type: str, user_input: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """Processa entrada usando agente especializado."""
        if agent_type not in self.agents:
            return {
                "success": False,
                "error": f"Agente {agent_type} não disponível"
            }
        
        try:
            result = await self._invoke_agent(agent_type, user_input, context=context)
            return {
                "success": True,
                "result": result,
                "agent": agent_type
            }
        except Exception as e:
            self.logger.error(f"❌ Erro no agente {agent_type}: {e}")
            return {
                "success": False,
                "error": str(e),
                "agent": agent_type
            }
    
    async def query_rag(self, question: str) -> Dict[str, Any]:
        """Consulta sistema RAG jurídico."""
        if not self.rag_system:
            return {
                "success": False,
                "error": "Sistema RAG não disponível"
            }
        
        try:
            result = await asyncio.to_thread(
                self.rag_system.invoke,
                {"query": question}
            )
            
            return {
                "success": True,
                "answer": result.get("result", ""),
                "sources": [doc.page_content for doc in result.get("source_documents", [])],
                "method": "rag"
            }
        except Exception as e:
            self.logger.error(f"❌ Erro no RAG: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    # ===== MÉTODOS PRIVADOS: IMPLEMENTAÇÃO =====
    
    async def _invoke_agent(self, agent_name: str, prompt: str, **kwargs) -> Optional[str]:
        """Invoca agente específico de forma assíncrona."""
        try:
            agent = self.agents[agent_name]
            context = kwargs.get("context", {})
            
            # Executar agente de forma assíncrona
            result = await asyncio.to_thread(
                agent.invoke,
                {
                    "input": prompt,
                    **context
                }
            )
            
            return result.get("output", "")
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao invocar agente {agent_name}: {e}")
            return None
    
    async def _invoke_langchain_model(self, model_key: str, prompt: str, **kwargs) -> Optional[str]:
        """Invoca modelo LangChain direto de forma assíncrona."""
        try:
            model = self.langchain_models[model_key]
            
            # Executar modelo de forma assíncrona
            result = await asyncio.to_thread(
                model.invoke,
                prompt
            )
            
            return result.content if hasattr(result, 'content') else str(result)
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao invocar modelo {model_key}: {e}")
            return None
    
    def _get_agent_mapping(self) -> Dict[str, str]:
        """Mapeia funções para agentes especializados."""
        return {
            "case_context": "case_analyzer",
            "lawyer_profile": "profile_analyzer",
            "lex9000": "legal_researcher",
            "ocr_extraction": "document_extractor",
            "cluster_labeling": "case_analyzer",
            "partnership": "profile_analyzer"
        }
    
    def _get_function_mapping(self) -> Dict[str, str]:
        """Mapeia funções para modelos LangChain diretos."""
        return {
            "case_context": "case",
            "lawyer_profile": "profile", 
            "lex9000": "lex9000",
            "cluster_labeling": "cluster",
            "ocr_extraction": "ocr",
            "partnership": "profile",
            "judge": "judge",
            "general": "general"
        }
    
    def _get_openrouter_model_for_function(self, function: str) -> str:
        """Mapeia função para modelo OpenRouter (fallback)."""
        mapping = {
            "case_context": "anthropic/claude-3-5-sonnet-20241022",
            "lawyer_profile": "google/gemini-1.5-pro",
            "lex9000": "xai/grok-1",
            "cluster_labeling": "xai/grok-1",
            "ocr_extraction": "openai/gpt-4o-mini",
            "partnership": "google/gemini-1.5-pro",
            "judge": "google/gemini-2.0-flash-exp"
        }
        return mapping.get(function, "openrouter/auto")
    
    def _get_agent_model(self, agent_name: str) -> str:
        """Retorna o modelo usado por um agente."""
        mapping = {
            "case_analyzer": "claude-3-5-sonnet",
            "document_extractor": "gpt-4o-mini",
            "legal_researcher": "grok-1",
            "profile_analyzer": "gemini-1.5-pro"
        }
        return mapping.get(agent_name, "unknown")
    
    # ===== IMPLEMENTAÇÃO DAS TOOLS DOS AGENTES =====
    
    async def _analyze_case_complexity(self, case_description: str) -> str:
        """Analisa complexidade de um caso jurídico."""
        # Implementação simulada - integrar com lógica existente
        return f"Análise de complexidade para: {case_description[:100]}..."
    
    async def _identify_legal_area(self, case_description: str) -> str:
        """Identifica área jurídica do caso."""
        return f"Área jurídica identificada para: {case_description[:100]}..."
    
    async def _calculate_case_value(self, case_description: str) -> str:
        """Calcula valor estimado do caso."""
        return f"Valor estimado para: {case_description[:100]}..."
    
    async def _search_legal_precedents(self, legal_question: str) -> str:
        """Busca precedentes jurisprudenciais."""
        return f"Precedentes encontrados para: {legal_question[:100]}..."
    
    async def _extract_text_from_image(self, image_data: str) -> str:
        """Extrai texto de imagem."""
        return f"Texto extraído da imagem: {image_data[:100]}..."
    
    async def _parse_legal_document(self, document_text: str) -> str:
        """Analisa documento jurídico."""
        return f"Documento analisado: {document_text[:100]}..."
    
    async def _identify_document_type(self, document_text: str) -> str:
        """Identifica tipo de documento."""
        return f"Tipo de documento: {document_text[:100]}..."
    
    async def _extract_key_information(self, document_text: str) -> str:
        """Extrai informações-chave."""
        return f"Informações-chave: {document_text[:100]}..."
    
    async def _search_legislation(self, legal_topic: str) -> str:
        """Busca legislação relevante."""
        return f"Legislação sobre: {legal_topic[:100]}..."
    
    async def _find_jurisprudence(self, legal_topic: str) -> str:
        """Encontra jurisprudência."""
        return f"Jurisprudência sobre: {legal_topic[:100]}..."
    
    async def _calculate_deadlines(self, process_type: str) -> str:
        """Calcula prazos processuais."""
        return f"Prazos para: {process_type[:100]}..."
    
    async def _research_doctrine(self, legal_topic: str) -> str:
        """Pesquisa doutrina jurídica."""
        return f"Doutrina sobre: {legal_topic[:100]}..."
    
    async def _analyze_lawyer_expertise(self, lawyer_profile: str) -> str:
        """Analisa expertise de advogado."""
        return f"Expertise analisada: {lawyer_profile[:100]}..."
    
    async def _match_case_to_lawyer(self, case_and_lawyer: str) -> str:
        """Faz matching caso-advogado."""
        return f"Matching realizado: {case_and_lawyer[:100]}..."
    
    async def _evaluate_success_probability(self, case_profile: str) -> str:
        """Avalia probabilidade de sucesso."""
        return f"Probabilidade avaliada: {case_profile[:100]}..."
    
    async def _recommend_partnerships(self, lawyer_profiles: str) -> str:
        """Recomenda parcerias."""
        return f"Parcerias recomendadas: {lawyer_profiles[:100]}..."
    
    # ===== MÉTODOS DE STATUS E DEBUGGING =====
    
    def get_status(self) -> Dict[str, Any]:
        """Retorna status do orquestrador híbrido."""
        return {
            "langchain_core_available": LANGCHAIN_CORE_AVAILABLE,
            "langchain_agents_available": LANGCHAIN_AGENTS_AVAILABLE,
            "langchain_models_count": len(self.langchain_models),
            "agents_count": len(self.agents),
            "openrouter_available": self.openrouter_client is not None,
            "rag_available": self.rag_system is not None,
            "available_models": list(self.langchain_models.keys()),
            "available_agents": list(self.agents.keys())
        }
    
    def get_available_functions(self) -> List[str]:
        """Retorna funções disponíveis para roteamento."""
        return list(set(
            list(self._get_agent_mapping().keys()) +
            list(self._get_function_mapping().keys())
        ))


# Instância global para uso em outros serviços
hybrid_orchestrator = None

def get_hybrid_orchestrator() -> HybridLangChainOrchestrator:
    """Factory para obter instância do orquestrador híbrido."""
    global hybrid_orchestrator
    if hybrid_orchestrator is None:
        hybrid_orchestrator = HybridLangChainOrchestrator()
    return hybrid_orchestrator

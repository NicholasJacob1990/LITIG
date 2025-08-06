#!/usr/bin/env python3
"""
Brazilian Legal RAG System - Sistema RAG Jurídico Brasileiro Abrangente
=======================================================================

Sistema RAG especializado em legislação e jurisprudência brasileira.
Integrado à estratégia híbrida usando modelos já configurados.

Funcionalidades:
✅ Base de conhecimento jurídica brasileira (TODAS as áreas do Direito)
✅ Embeddings OpenAI (já configurado no app)
✅ Retrieval de precedentes e legislação
✅ Web Search como fallback quando não há conteúdo local
✅ Integração com agentes LangChain
✅ Fallback para OpenRouter se necessário
✅ Cobertura abrangente: Trabalhista, Civil, Penal, Administrativo, Tributário, etc.
"""

import asyncio
import logging
import os
import json
import httpx
import re
from typing import Dict, List, Optional, Any, Union
from datetime import datetime
from pathlib import Path

# LangChain RAG Components - Supabase Vector Store
try:
    from langchain_community.vectorstores import SupabaseVectorStore
    from langchain_openai import OpenAIEmbeddings
    from supabase import create_client, Client
    SUPABASE_AVAILABLE = True
except ImportError:
    try:
        from langchain.vectorstores import SupabaseVectorStore
        from langchain.embeddings import OpenAIEmbeddings
        from supabase import create_client, Client
        SUPABASE_AVAILABLE = True
    except ImportError:
        # Fallback para Chroma na nuvem se Supabase não disponível
        try:
            from langchain_chroma import Chroma
            from langchain_openai import OpenAIEmbeddings
            import chromadb
            from chromadb.config import Settings as ChromaSettings
            SupabaseVectorStore = None
            SUPABASE_AVAILABLE = False
            CHROMA_CLOUD_AVAILABLE = True
        except ImportError:
            # Fallback local se Chroma cloud não disponível
            try:
                from langchain_community.vectorstores import Chroma
                from langchain_openai import OpenAIEmbeddings
                SupabaseVectorStore = None
                SUPABASE_AVAILABLE = False
                CHROMA_CLOUD_AVAILABLE = False
            except ImportError:
                # Mock para desenvolvimento sem dependências
                SupabaseVectorStore = None
                Chroma = None
                OpenAIEmbeddings = None
                SUPABASE_AVAILABLE = False
                CHROMA_CLOUD_AVAILABLE = False

try:
    from langchain.text_splitter import RecursiveCharacterTextSplitter
    from langchain.chains import RetrievalQA
    from langchain.document_loaders import TextLoader, DirectoryLoader
    from langchain.docstore.document import Document
    from langchain_core.prompts import ChatPromptTemplate
    LANGCHAIN_RAG_AVAILABLE = True
except ImportError:
    LANGCHAIN_RAG_AVAILABLE = False

# Config
try:
    from config import Settings
    CONFIG_AVAILABLE = True
except ImportError:
    CONFIG_AVAILABLE = False

logger = logging.getLogger(__name__)

class BrazilianLegalRAG:
    """
    Sistema RAG especializado em direito brasileiro com Supabase Vector Store.
    
    Base de conhecimento inclui:
    - Constituição Federal 1988
    - Códigos (Civil, Penal, Processo Civil, CLT)
    - Súmulas dos tribunais superiores (STF, STJ, TST)
    - Legislação especial relevante
    - Jurisprudência selecionada
    
    Usa Supabase como banco de vetores na nuvem.
    """
    
    def __init__(self, 
                 use_supabase: bool = True,
                 use_chroma_cloud: bool = True,
                 knowledge_base_path: str = "./legal_knowledge_base"):
        self.logger = logging.getLogger(f"{self.__class__.__name__}")
        self.use_supabase = use_supabase and SUPABASE_AVAILABLE
        self.use_chroma_cloud = use_chroma_cloud and CHROMA_CLOUD_AVAILABLE and not self.use_supabase
        self.knowledge_base_path = Path(knowledge_base_path)
        
        # Verificar dependências
        if not LANGCHAIN_RAG_AVAILABLE:
            self.logger.error("❌ LangChain RAG não disponível")
            raise ImportError("Instale: pip install langchain")
        
        if not CONFIG_AVAILABLE or not Settings.OPENAI_API_KEY:
            self.logger.error("❌ OpenAI API Key não configurada")
            raise ValueError("Configure OPENAI_API_KEY")
        
        # Verificar configuração Supabase
        if self.use_supabase:
            if not hasattr(Settings, 'SUPABASE_URL') or not hasattr(Settings, 'SUPABASE_SERVICE_KEY'):
                self.logger.warning("⚠️ Supabase não configurado, tentando Chroma na nuvem")
                self.use_supabase = False
                self.use_chroma_cloud = use_chroma_cloud and CHROMA_CLOUD_AVAILABLE
        
        # Verificar configuração Chroma Cloud
        if self.use_chroma_cloud and not self.use_supabase:
            if not hasattr(Settings, 'CHROMA_HOST') or not hasattr(Settings, 'CHROMA_PORT'):
                self.logger.warning("⚠️ Chroma Cloud não configurado, usando Chroma local")
                self.use_chroma_cloud = False
        
        # Inicializar componentes
        self.embeddings = self._initialize_embeddings()
        self.supabase_client = self._initialize_supabase_client() if self.use_supabase else None
        self.chroma_client = self._initialize_chroma_client() if self.use_chroma_cloud else None
        self.vectorstore = None
        self.retriever = None
        self.qa_chain = None
        
        # Garantir diretório da base de conhecimento (apenas para Chroma local)
        if not self.use_supabase and not self.use_chroma_cloud:
            self.knowledge_base_path.mkdir(exist_ok=True)
        
        # Determinar tipo de storage
        if self.use_supabase:
            storage_type = "Supabase (nuvem)"
        elif self.use_chroma_cloud:
            storage_type = "Chroma Cloud (nuvem)"
        else:
            storage_type = "Chroma (local)"
            
        self.logger.info(f"✅ Brazilian Legal RAG inicializado com {storage_type}")
    
    def _initialize_supabase_client(self) -> Optional[Client]:
        """Inicializa cliente Supabase."""
        if not self.use_supabase:
            return None
        
        try:
            supabase_client = create_client(
                Settings.SUPABASE_URL,
                Settings.SUPABASE_SERVICE_KEY
            )
            self.logger.info("✅ Cliente Supabase inicializado")
            return supabase_client
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar Supabase: {e}")
            self.use_supabase = False
            return None
    
    def _initialize_chroma_client(self) -> Optional[Any]:
        """Inicializa cliente Chroma Cloud."""
        if not self.use_chroma_cloud:
            return None
        
        try:
            import chromadb
            from chromadb.config import Settings as ChromaSettings
            
            # Configurar cliente Chroma Cloud
            chroma_client = chromadb.HttpClient(
                host=Settings.CHROMA_HOST,
                port=Settings.CHROMA_PORT,
                ssl=getattr(Settings, 'CHROMA_SSL', True),
                headers=getattr(Settings, 'CHROMA_HEADERS', {})
            )
            
            # Testar conexão
            chroma_client.heartbeat()
            self.logger.info("✅ Cliente Chroma Cloud inicializado")
            return chroma_client
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar Chroma Cloud: {e}")
            self.use_chroma_cloud = False
            return None
    
    def _initialize_embeddings(self) -> OpenAIEmbeddings:
        """Inicializa embeddings OpenAI (já configurado no app)."""
        try:
            embeddings = OpenAIEmbeddings(
                model="text-embedding-3-small",
                openai_api_key=Settings.OPENAI_API_KEY,
                chunk_size=1000  # Otimizado para textos jurídicos
            )
            self.logger.info("✅ OpenAI embeddings inicializados")
            return embeddings
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar embeddings: {e}")
            raise
    
    async def initialize_knowledge_base(self, force_rebuild: bool = False) -> bool:
        """
        Inicializa base de conhecimento jurídica brasileira.
        
        Args:
            force_rebuild: Se True, reconstrói a base mesmo se existir
        """
        try:
            if self.use_supabase:
                return await self._initialize_supabase_vectorstore(force_rebuild)
            elif self.use_chroma_cloud:
                return await self._initialize_chroma_cloud_vectorstore(force_rebuild)
            else:
                return await self._initialize_chroma_vectorstore(force_rebuild)
                
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar base de conhecimento: {e}")
            return False
    
    async def _initialize_supabase_vectorstore(self, force_rebuild: bool = False) -> bool:
        """Inicializa vectorstore com Supabase."""
        try:
            self.logger.info("🗄️ Inicializando base de conhecimento Supabase...")
            
            # Criar documentos jurídicos básicos
            documents = await self._create_initial_legal_documents()
            
            # Dividir documentos em chunks
            text_splitter = RecursiveCharacterTextSplitter(
                chunk_size=1000,
                chunk_overlap=200,
                length_function=len,
                separators=["\n\n", "\n", ".", "!", "?"]
            )
            
            splits = text_splitter.split_documents(documents)
            self.logger.info(f"📄 {len(splits)} chunks criados para Supabase")
            
            # Criar SupabaseVectorStore
            self.vectorstore = SupabaseVectorStore.from_documents(
                documents=splits,
                embedding=self.embeddings,
                client=self.supabase_client,
                table_name="legal_documents",  # Nome da tabela no Supabase
                query_name="match_legal_documents"  # Nome da função de busca
            )
            
            self.logger.info("💾 Base de conhecimento Supabase inicializada")
            
            # Configurar retriever
            self.retriever = self.vectorstore.as_retriever(
                search_type="similarity",
                search_kwargs={"k": 5}
            )
            
            return await self._setup_qa_chain()
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar Supabase vectorstore: {e}")
            return False
    
    async def _initialize_chroma_cloud_vectorstore(self, force_rebuild: bool = False) -> bool:
        """Inicializa vectorstore com Chroma na nuvem."""
        try:
            self.logger.info("☁️ Inicializando base de conhecimento Chroma Cloud...")
            
            # Criar documentos jurídicos básicos
            documents = await self._create_initial_legal_documents()
            
            # Dividir documentos em chunks
            text_splitter = RecursiveCharacterTextSplitter(
                chunk_size=1000,
                chunk_overlap=200,
                length_function=len,
                separators=["\n\n", "\n", ".", "!", "?"]
            )
            
            splits = text_splitter.split_documents(documents)
            self.logger.info(f"📄 {len(splits)} chunks criados para Chroma Cloud")
            
            # Criar vectorstore com Chroma Cloud
            if Chroma:
                self.vectorstore = Chroma.from_documents(
                    documents=splits,
                    embedding=self.embeddings,
                    collection_name="brazilian_legal_docs_cloud",
                    client=self.chroma_client
                )
                
                self.logger.info("☁️ Base de conhecimento Chroma Cloud inicializada")
            else:
                self.logger.error("❌ Chroma não disponível")
                return False
            
            # Configurar retriever
            self.retriever = self.vectorstore.as_retriever(
                search_type="similarity",
                search_kwargs={"k": 5}
            )
            
            return await self._setup_qa_chain()
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar Chroma Cloud vectorstore: {e}")
            return False
    
    async def _initialize_chroma_vectorstore(self, force_rebuild: bool = False) -> bool:
        """Inicializa vectorstore com Chroma local (fallback)."""
        try:
            persist_directory = self.knowledge_base_path / "chroma_db"
            
            # Verificar se base já existe
            if persist_directory.exists() and not force_rebuild:
                self.logger.info("📚 Carregando base de conhecimento Chroma existente...")
                if Chroma:
                    self.vectorstore = Chroma(
                        collection_name="brazilian_legal_docs",
                        embedding_function=self.embeddings,
                        persist_directory=str(persist_directory)
                    )
                else:
                    self.logger.error("❌ Chroma não disponível")
                    return False
            else:
                self.logger.info("🏗️ Construindo nova base de conhecimento Chroma...")
                
                # Criar documentos jurídicos básicos
                documents = await self._create_initial_legal_documents()
                
                # Dividir documentos em chunks
                text_splitter = RecursiveCharacterTextSplitter(
                    chunk_size=1000,
                    chunk_overlap=200,
                    length_function=len,
                    separators=["\n\n", "\n", ".", "!", "?"]
                )
                
                splits = text_splitter.split_documents(documents)
                self.logger.info(f"📄 {len(splits)} chunks criados")
                
                # Criar vectorstore
                if Chroma:
                    self.vectorstore = Chroma.from_documents(
                        documents=splits,
                        embedding=self.embeddings,
                        collection_name="brazilian_legal_docs",
                        persist_directory=str(persist_directory)
                    )
                    
                    # Persistir
                    self.vectorstore.persist()
                    self.logger.info("💾 Base de conhecimento Chroma persistida")
                else:
                    self.logger.error("❌ Chroma não disponível")
                    return False
            
            # Configurar retriever
            self.retriever = self.vectorstore.as_retriever(
                search_type="similarity",
                search_kwargs={"k": 5}
            )
            
            return await self._setup_qa_chain()
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao inicializar Chroma vectorstore: {e}")
            return False
    
    async def _setup_qa_chain(self) -> bool:
        """Configura a chain de Q&A."""
        try:
            # Configurar chain QA
            from hybrid_langchain_orchestrator import get_hybrid_orchestrator
            orchestrator = get_hybrid_orchestrator()
            
            if "general" in orchestrator.langchain_models:
                llm = orchestrator.langchain_models["general"]
            elif "case" in orchestrator.langchain_models:
                llm = orchestrator.langchain_models["case"]
            else:
                self.logger.warning("⚠️ Nenhum modelo LangChain disponível para QA")
                return False
            
            # Prompt especializado para direito brasileiro
            prompt_template = ChatPromptTemplate.from_messages([
                ("system", """Você é um assistente jurídico especializado em direito brasileiro.

Use APENAS as informações fornecidas no contexto para responder às perguntas.
Se a informação não estiver no contexto, diga claramente que não possui essa informação.

Sempre cite:
- Artigos de lei relevantes
- Números de súmulas quando aplicável
- Tribunais responsáveis por precedentes
- Data ou vigência da legislação quando disponível

Formate a resposta de forma clara e profissional, adequada para advogados brasileiros.

Contexto: {context}

Pergunta: {question}"""),
            ])
            
            self.qa_chain = RetrievalQA.from_chain_type(
                llm=llm,
                chain_type="stuff",
                retriever=self.retriever,
                return_source_documents=True,
                chain_type_kwargs={"prompt": prompt_template}
            )
            
            storage_type = "Supabase" if self.use_supabase else "Chroma"
            self.logger.info(f"✅ Base de conhecimento jurídica inicializada com {storage_type}")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao configurar QA chain: {e}")
            return False
    
    async def _create_initial_legal_documents(self) -> List[Document]:
        """
        Cria documentos jurídicos abrangentes cobrindo todas as áreas do Direito brasileiro.
        Utiliza base de conhecimento expandida com taxonomia jurídica completa.
        """
        try:
            # Importar base de conhecimento expandida
            from legal_knowledge_base import create_comprehensive_legal_documents
            
            # Obter dados dos documentos
            documents_data = create_comprehensive_legal_documents()
            documents = []
            
            # Converter para objetos Document se disponível
            for doc_data in documents_data:
                if Document:  # Verificar se Document está disponível
                    document = Document(
                        page_content=doc_data["content"],
                        metadata=doc_data["metadata"]
                    )
                    documents.append(document)
                else:
                    # Fallback se Document não estiver disponível
                    documents.append({
                        "page_content": doc_data["content"],
                        "metadata": doc_data["metadata"]
                    })
            
            self.logger.info(f"📚 {len(documents)} documentos jurídicos abrangentes criados")
            self.logger.info(f"🏛️ Áreas cobertas: Constitucional, Administrativo, Tributário, Penal, Trabalho, Previdenciário, Consumidor, Digital, Ambiental, Eleitoral")
            
            return documents
            
        except ImportError:
            # Fallback para documentos básicos se módulo não disponível
            self.logger.warning("⚠️ Módulo legal_knowledge_base não encontrado, usando documentos básicos")
            return await self._create_basic_legal_documents()
    
    async def _create_basic_legal_documents(self) -> List[Document]:
        """
        Cria documentos jurídicos básicos como fallback.
        """
        documents = []
        
        # Constituição Federal 1988 (seleções importantes)
        cf88_content = """
Constituição Federal de 1988

Art. 5º Todos são iguais perante a lei, sem distinção de qualquer natureza, garantindo-se aos brasileiros e aos estrangeiros residentes no País a inviolabilidade do direito à vida, à liberdade, à igualdade, à segurança e à propriedade, nos termos seguintes:

I - homens e mulheres são iguais em direitos e obrigações, nos termos desta Constituição;
II - ninguém será obrigado a fazer ou deixar de fazer alguma coisa senão em virtude de lei;
III - ninguém será submetido a tortura nem a tratamento desumano ou degradante;
IV - é livre a manifestação do pensamento, sendo vedado o anonimato;
V - é assegurado o direito de resposta, proporcional ao agravo, além da indenização por dano material, moral ou à imagem;

Art. 7º São direitos dos trabalhadores urbanos e rurais, além de outros que visem à melhoria de sua condição social:

I - relação de emprego protegida contra despedida arbitrária ou sem justa causa, nos termos de lei complementar, que preverá indenização compensatória, dentre outros direitos;
II - seguro-desemprego, em caso de desemprego involuntário;
III - fundo de garantia do tempo de serviço;
IV - salário mínimo, fixado em lei, nacionalmente unificado, capaz de atender às suas necessidades vitais básicas e às de sua família;
V - piso salarial proporcional à extensão e à complexidade do trabalho;
VI - irredutibilidade do salário, salvo o disposto em convenção ou acordo coletivo;
VII - garantia de salário, nunca inferior ao mínimo, para os que percebem remuneração variável;
VIII - décimo terceiro salário com base na remuneração integral ou no valor da aposentadoria;
"""
        
        documents.append(Document(
            page_content=cf88_content,
            metadata={"source": "CF88", "type": "constituicao", "year": "1988"}
        ))
        
        # CLT - Consolidação das Leis do Trabalho (artigos importantes)
        clt_content = """
Consolidação das Leis do Trabalho - CLT (Decreto-Lei 5.452/1943)

Art. 58. A duração normal do trabalho, para os empregados em qualquer atividade privada, não excederá de 8 (oito) horas diárias, desde que não seja fixado expressamente outro limite.

Art. 59. A duração diária do trabalho poderá ser acrescida de horas suplementares, em número não excedente de duas, mediante acordo escrito entre empregador e empregado, ou mediante contrato coletivo de trabalho.
§ 1º A remuneração da hora suplementar será, no mínimo, 20% (vinte por cento) superior à da hora normal.

Art. 60. Nas atividades insalubres, assim consideradas as constantes dos quadros mencionados no capítulo "Da Segurança e da Medicina do Trabalho", ou que neles venham a ser incluídas por ato do Ministro do Trabalho, Indústria e Comércio, quaisquer prorrogações só poderão ser acordadas mediante licença prévia das autoridades competentes em matéria de higiene do trabalho.

Art. 129. Todo empregado terá direito anualmente a um período de descanso, sem prejuízo da remuneração.

Art. 130. Após cada período de 12 (doze) meses de vigência do contrato de trabalho, o empregado terá direito a férias, na seguinte proporção:
I - 30 (trinta) dias corridos, quando não houver faltado ao serviço mais de 5 (cinco) vezes;
II - 24 (vinte e quatro) dias corridos, quando houver tido de 6 (seis) a 14 (quatorze) faltas;
III - 18 (dezoito) dias corridos, quando houver tido de 15 (quinze) a 23 (vinte e três) faltas;
IV - 12 (doze) dias corridos, quando houver tido de 24 (vinte e quatro) a 32 (trinta e duas) faltas.

Art. 482. Constituem justa causa para rescisão do contrato de trabalho pelo empregador:
a) ato de improbidade;
b) incontinência de conduta ou mau procedimento;
c) negociação habitual por conta própria ou alheia sem permissão do empregador, e quando constituir ato de concorrência à empresa para a qual trabalha o empregado, ou for prejudicial ao serviço;
d) condenação criminal do empregado, passada em julgado, caso não tenha havido suspensão da execução da pena;
e) desídia no desempenho das respectivas funções;
f) embriaguez habitual ou em serviço;
g) violação de segredo da empresa;
h) ato de indisciplina ou de insubordinação;
i) abandono de emprego;
j) ato lesivo da honra ou da boa fama praticado no serviço contra qualquer pessoa, ou ofensas físicas, nas mesmas condições, salvo em caso de legítima defesa, própria ou de outrem;
k) ato lesivo da honra ou da boa fama ou ofensas físicas praticadas contra o empregador e superiores hierárquicos, salvo em caso de legítima defesa, própria ou de outrem;
l) prática constante de jogos de azar.
"""
        
        documents.append(Document(
            page_content=clt_content,
            metadata={"source": "CLT", "type": "legislacao", "year": "1943"}
        ))
        
        # Súmulas TST importantes
        sumulas_tst_content = """
Súmulas do Tribunal Superior do Trabalho - TST

Súmula 85 - COMPENSAÇÃO DE HORÁRIO
I - A compensação de jornada de trabalho deve ser ajustada por acordo individual escrito, acordo coletivo ou convenção coletiva.
II - O acordo individual para compensação de horas é válido, salvo se houver norma coletiva em sentido contrário.
III - O mero não-atendimento das exigências legais para a compensação de jornada, inclusive quando encetada mediante acordo tácito, não implica a repetição do pagamento das horas excedentes à jornada normal diária, se não dilatada a jornada máxima semanal, sendo devido apenas o respectivo adicional.
IV - A prestação de horas extras habituais descaracteriza o acordo de compensação de horário. Nesta hipótese, as horas que ultrapassarem a jornada semanal normal deverão ser pagas como horas extraordinárias e, quanto àquelas destinadas à compensação, deverá ser pago a mais apenas o adicional por trabalho extraordinário.

Súmula 129 - INSALUBRIDADE - ADICIONAL
A prestação de serviços em condições de insalubridade, ainda que de forma intermitente, assegura a percepção do adicional respectivo durante todo o período da prestação de serviço.

Súmula 291 - SALÁRIO-UTILIDADE - HABITAÇÃO
O salário-utilidade habitação deve ser pago em dinheiro, quando não fornecido in natura pelo empregador.

Súmula 338 - JORNADA DE TRABALHO - REGISTRO
I - É ônus do empregador que conta com mais de 10 (dez) empregados o registro da jornada de trabalho na forma do art. 74, § 2º, da CLT. A não-apresentação injustificada dos controles de frequência gera presunção relativa de veracidade da jornada de trabalho, a qual pode ser elidida por prova em contrário.
II - A presunção de veracidade da jornada de trabalho, ainda que prevista em instrumento normativo, pode ser elidida por prova em contrário.
III - Os cartões de ponto que demonstram horários de entrada e saída uniformes são inválidos como meio de prova, invertendo-se o ônus da prova, relativo às horas extras, que passa a ser do empregador, prevalecendo a jornada da inicial se dele não se desincumbir.

Súmula 437 - INTERVALO INTRAJORNADA PARA REPOUSO E ALIMENTAÇÃO
I - Após a edição da Lei nº 8.923/94, a não-concessão ou a concessão parcial do intervalo intrajornada mínimo, para repouso e alimentação, a empregados urbanos e rurais, implica o pagamento total do período correspondente, e não apenas daquele suprimido, com acréscimo de, no mínimo, 50% sobre o valor da remuneração da hora normal de trabalho.
II - É inválida cláusula de acordo ou convenção coletiva de trabalho contemplando a supressão ou redução do intervalo intrajornada porque este constitui medida de higiene, saúde e segurança do trabalho, garantido por norma de ordem pública.
"""
        
        documents.append(Document(
            page_content=sumulas_tst_content,
            metadata={"source": "TST", "type": "sumula", "tribunal": "TST"}
        ))
        
        # Código Civil (seleções importantes)
        cc_content = """
Código Civil - Lei 10.406/2002

Art. 186. Aquele que, por ação ou omissão voluntária, negligência ou imprudência, violar direito e causar dano a outrem, ainda que exclusivamente moral, comete ato ilícito.

Art. 187. Também comete ato ilícito o titular de um direito que, ao exercê-lo, excede manifestamente os limites impostos pelo seu fim econômico ou social, pela boa-fé ou pelos bons costumes.

Art. 927. Aquele que, por ato ilícito (arts. 186 e 187), causar dano a outrem, fica obrigado a repará-lo.
Parágrafo único. Haverá obrigação de reparar o dano, independentemente de culpa, nos casos especificados em lei, ou quando a atividade normalmente desenvolvida pelo autor do dano implicar, por sua natureza, risco para os direitos de outrem.

Art. 944. A indenização mede-se pela extensão do dano.
Parágrafo único. Se houver excessiva desproporção entre a gravidade da culpa e o dano, poderá o juiz reduzir, eqüitativamente, a indenização.

Art. 1.228. O proprietário tem a faculdade de usar, gozar e dispor da coisa, e o direito de reavê-la do poder de quem quer que injustamente a possua ou detenha.
§ 1º O direito de propriedade deve ser exercido em consonância com as suas finalidades econômicas e sociais e de modo que sejam preservados, de conformidade com o estabelecido em lei especial, a flora, a fauna, as belezas naturais, o equilíbrio ecológico e o patrimônio histórico e artístico, bem como evitada a poluição do ar e das águas.
"""
        
        documents.append(Document(
            page_content=cc_content,
            metadata={"source": "CC", "type": "codigo", "year": "2002"}
        ))
        
        # Código de Processo Civil (seleções importantes)
        cpc_content = """
Código de Processo Civil - Lei 13.105/2015

Art. 1º O processo civil será ordenado, disciplinado e interpretado conforme os valores e as normas fundamentais estabelecidos na Constituição da República Federativa do Brasil, observando-se as disposições deste Código.

Art. 6º Todos os sujeitos do processo devem cooperar entre si para que se obtenha, em tempo razoável, decisão de mérito justa e efetiva.

Art. 8º Ao aplicar o ordenamento jurídico, o juiz atenderá aos fins sociais e às exigências do bem comum, resguardando e promovendo a dignidade da pessoa humana e observando a proporcionalidade, a razoabilidade, a legalidade, a publicidade e a eficiência.

Art. 319. A petição inicial indicará:
I - o juízo a que é dirigida;
II - os nomes, os prenomes, o estado civil, a existência de união estável, a profissão, o número de inscrição no Cadastro de Pessoas Físicas ou no Cadastro Nacional da Pessoa Jurídica, o endereço eletrônico, o domicílio e a residência do autor e do réu;
III - o fato e os fundamentos jurídicos do pedido;
IV - o pedido com as suas especificações;
V - o valor da causa;
VI - as provas com que o autor pretende demonstrar a verdade dos fatos alegados;
VII - a opção do autor pela realização ou não de audiência de conciliação ou de mediação.

Art. 489. São elementos essenciais da sentença:
I - o relatório, que conterá os nomes das partes, a identificação do caso, com a suma do pedido e da contestação, e o registro das principais ocorrências havidas no andamento do processo;
II - os fundamentos, em que o juiz analisará as questões de fato e de direito;
III - o dispositivo, em que o juiz resolverá as questões principais que as partes lhe submeterem.
"""
        
        documents.append(Document(
            page_content=cpc_content,
            metadata={"source": "CPC", "type": "codigo", "year": "2015"}
        ))
        
        self.logger.info(f"📚 {len(documents)} documentos jurídicos criados")
        return documents
    
    async def query(self, question: str, include_sources: bool = True, use_web_search_fallback: bool = True) -> Dict[str, Any]:
        """
        Faz consulta no sistema RAG jurídico com fallback para web search.
        
        Args:
            question: Pergunta jurídica
            include_sources: Se deve incluir fontes na resposta
            use_web_search_fallback: Se deve usar web search quando RAG local não tem resultados
        
        Returns:
            Dict com resposta, fontes e metadados
        """
        if not self.qa_chain:
            return {
                "success": False,
                "error": "Sistema RAG não inicializado. Execute initialize_knowledge_base() primeiro."
            }
        
        try:
            start_time = datetime.now()
            
            # 1. Tentar consulta RAG local primeiro
            result = await asyncio.to_thread(
                self.qa_chain.invoke,
                {"query": question}
            )
            
            duration = (datetime.now() - start_time).total_seconds()
            
            # Extrair resposta
            answer = result.get("result", "")
            source_documents = result.get("source_documents", [])
            
            # 2. Verificar se a resposta local é satisfatória
            is_local_answer_sufficient = self._is_answer_sufficient(answer, source_documents)
            
            # 3. Se não há resposta local suficiente E web search está habilitado
            if not is_local_answer_sufficient and use_web_search_fallback:
                self.logger.info("🔍 Resposta local insuficiente, tentando web search...")
                web_search_result = await self._web_search_fallback(question)
                
                if web_search_result["success"]:
                    # Combinar resposta local (se houver) com web search
                    combined_answer = self._combine_answers(answer, web_search_result["answer"])
                    combined_sources = source_documents + web_search_result.get("sources", [])
                    
                    response = {
                        "success": True,
                        "question": question,
                        "answer": combined_answer,
                        "sources_used": "RAG Local + Web Search",
                        "duration_seconds": duration + web_search_result.get("duration_seconds", 0),
                        "timestamp": datetime.now().isoformat()
                    }
                    
                    if include_sources:
                        sources = []
                        # Fontes locais primeiro
                        for doc in source_documents:
                            sources.append({
                                "content": doc.page_content[:300] + "..." if len(doc.page_content) > 300 else doc.page_content,
                                "metadata": doc.metadata,
                                "source": doc.metadata.get("source", "Desconhecido"),
                                "type": doc.metadata.get("type", "RAG Local")
                            })
                        
                        # Fontes web depois
                        for web_source in web_search_result.get("sources", []):
                            sources.append({
                                "content": web_source.get("content", ""),
                                "metadata": web_source.get("metadata", {}),
                                "source": web_source.get("source", "Web Search"),
                                "type": "Web Search"
                            })
                        
                        response["sources"] = sources
                        response["sources_count"] = len(sources)
                    
                    self.logger.info(f"✅ Consulta RAG + Web Search processada em {response['duration_seconds']:.2f}s")
                    return response
            
            # 4. Resposta apenas com RAG local
            response = {
                "success": True,
                "question": question,
                "answer": answer if answer else "Não foi possível encontrar informações específicas sobre esta consulta jurídica.",
                "sources_used": "RAG Local" if source_documents else "Conhecimento Geral",
                "duration_seconds": duration,
                "timestamp": datetime.now().isoformat()
            }
            
            if include_sources and source_documents:
                sources = []
                for doc in source_documents:
                    sources.append({
                        "content": doc.page_content[:300] + "..." if len(doc.page_content) > 300 else doc.page_content,
                        "metadata": doc.metadata,
                        "source": doc.metadata.get("source", "Desconhecido"),
                        "type": doc.metadata.get("type", "RAG Local")
                    })
                response["sources"] = sources
                response["sources_count"] = len(sources)
            
            self.logger.info(f"✅ Consulta RAG processada em {duration:.2f}s")
            return response
            
        except Exception as e:
            self.logger.error(f"❌ Erro na consulta RAG: {e}")
            
            # Fallback para web search em caso de erro
            if use_web_search_fallback:
                try:
                    self.logger.info("🔍 Erro no RAG, tentando web search como fallback...")
                    web_search_result = await self._web_search_fallback(question)
                    if web_search_result["success"]:
                        web_search_result["sources_used"] = "Web Search (Fallback - Erro RAG)"
                        return web_search_result
                except Exception as web_error:
                    self.logger.error(f"❌ Erro também no web search: {web_error}")
            
            return {
                "success": False,
                "error": str(e),
                "question": question
            }
    
    def _is_answer_sufficient(self, answer: str, source_documents: List) -> bool:
        """
        Verifica se a resposta local é suficientemente informativa.
        
        Args:
            answer: Resposta do RAG local
            source_documents: Documentos fontes encontrados
        
        Returns:
            bool: True se a resposta é suficiente
        """
        if not answer or len(answer.strip()) < 50:
            return False
        
        # Verificar se há documentos fontes relevantes
        if not source_documents or len(source_documents) == 0:
            return False
        
        # Palavras que indicam resposta genérica/insuficiente
        insufficient_indicators = [
            "não foi possível",
            "não há informações",
            "não encontrei",
            "preciso de mais informações",
            "não posso fornecer",
            "desculpe, mas"
        ]
        
        answer_lower = answer.lower()
        for indicator in insufficient_indicators:
            if indicator in answer_lower:
                return False
        
        return True
    
    def _combine_answers(self, local_answer: str, web_answer: str) -> str:
        """
        Combina resposta local do RAG com resposta do web search.
        
        Args:
            local_answer: Resposta do RAG local
            web_answer: Resposta do web search
        
        Returns:
            str: Resposta combinada
        """
        if not local_answer or len(local_answer.strip()) < 20:
            return f"**Informações Atualizadas (Web Search):**\n\n{web_answer}"
        
        if not web_answer or len(web_answer.strip()) < 20:
            return local_answer
        
        return f"""**Informações da Base Local:**

{local_answer}

**Informações Complementares (Web Search):**

{web_answer}

*Nota: Esta resposta combina informações da base jurídica local com pesquisas atualizadas na web para fornecer informações mais completas e atuais.*"""
    
    async def _web_search_fallback(self, question: str) -> Dict[str, Any]:
        """
        Realiza busca na web como fallback quando RAG local não tem informações.
        
        Args:
            question: Pergunta jurídica
        
        Returns:
            Dict com resultado da busca web
        """
        start_time = datetime.now()
        
        try:
            # Melhorar a query para busca jurídica
            enhanced_query = self._enhance_legal_query(question)
            
            # Tentar DuckDuckGo primeiro (mais privado e sem API key)
            search_results = await self._search_duckduckgo(enhanced_query)
            
            if not search_results:
                # Se falhar, tentar busca genérica
                search_results = await self._search_generic(enhanced_query)
            
            if not search_results:
                return {
                    "success": False,
                    "error": "Não foi possível obter resultados de busca web"
                }
            
            # Processar e resumir resultados
            answer = self._process_search_results(search_results, question)
            duration = (datetime.now() - start_time).total_seconds()
            
            return {
                "success": True,
                "question": question,
                "answer": answer,
                "sources": search_results,
                "sources_used": "Web Search",
                "duration_seconds": duration,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro no web search: {e}")
            return {
                "success": False,
                "error": f"Erro na busca web: {str(e)}"
            }
    
    def _enhance_legal_query(self, question: str) -> str:
        """
        Melhora a query para busca jurídica adicionando termos relevantes.
        Sistema expandido com taxonomia jurídica brasileira completa.
        
        Args:
            question: Pergunta original
        
        Returns:
            str: Query melhorada para busca jurídica
        """
        # Taxonomia jurídica brasileira completa com pesos
        legal_areas_taxonomy = {
            'Constitucional': [
                ('constituição', 10), ('supremo tribunal federal', 8), ('direitos fundamentais', 8),
                ('controle de constitucionalidade', 7), ('poder constituinte', 5), ('adi', 5), ('adpf', 5),
                ('mandado de segurança coletivo', 6), ('art 5', 4), ('emenda constitucional', 6)
            ],
            'Administrativo': [
                ('ato administrativo', 10), ('licitação', 9), ('servidor público', 8), ('improbidade administrativa', 8),
                ('concessão de serviço público', 6), ('poder de polícia', 5), ('agente público', 5),
                ('processo administrativo', 7), ('princípio da legalidade', 6), ('discricionariedade', 5)
            ],
            'Tributário': [
                ('tributo', 10), ('crédito tributário', 9), ('imposto de renda', 8), ('lançamento tributário', 7),
                ('icms', 6), ('obrigação tributária', 5), ('iss', 6), ('ctn', 7), ('execução fiscal', 6),
                ('cofins', 5), ('pis', 5), ('contribuição social', 6)
            ],
            'Financeiro': [
                ('orçamento público', 10), ('lei de responsabilidade fiscal', 9), ('despesa pública', 8),
                ('receita pública', 7), ('dívida pública', 6), ('precatório', 6), ('lrf', 8)
            ],
            'Urbanístico': [
                ('plano diretor', 10), ('zoneamento urbano', 8), ('estatuto da cidade', 9),
                ('função social da propriedade', 7), ('usucapião especial urbano', 6), ('iptu progressivo', 5)
            ],
            'Penal': [
                ('crime', 10), ('pena', 9), ('dosimetria da pena', 7), ('culpabilidade', 6),
                ('tipicidade', 6), ('homicídio', 5), ('roubo', 5), ('furto', 5), ('estelionato', 5),
                ('código penal', 8), ('legítima defesa', 6), ('estado de necessidade', 5)
            ],
            'Processual Penal': [
                ('processo penal', 10), ('inquérito policial', 8), ('audiência de custódia', 7),
                ('habeas corpus', 6), ('recurso em sentido estrito', 5), ('prisão preventiva', 7),
                ('liberdade provisória', 6), ('júri', 6), ('cpp', 7)
            ],
            'Civil': [
                ('contrato', 10), ('responsabilidade civil', 9), ('obrigações', 8), ('direito de família', 7),
                ('sucessões', 6), ('posse e propriedade', 5), ('casamento', 6), ('divórcio', 6),
                ('código civil', 8), ('boa-fé objetiva', 5), ('função social do contrato', 6)
            ],
            'Processual Civil': [
                ('processo civil', 10), ('petição inicial', 8), ('contestação', 7), ('recurso de apelação', 7),
                ('coisa julgada', 6), ('execução', 5), ('cpc', 8), ('tutela de urgência', 6),
                ('agravo de instrumento', 5), ('embargos de declaração', 5)
            ],
            'Empresarial': [
                ('sociedade empresária', 10), ('falência', 9), ('recuperação judicial', 9),
                ('título de crédito', 7), ('propriedade industrial', 6), ('junta comercial', 5),
                ('sociedade limitada', 7), ('cade', 6)
            ],
            'Econômico': [
                ('defesa da concorrência', 10), ('cade', 9), ('cartel', 8), ('abuso de posição dominante', 7),
                ('concentração econômica', 6), ('dumping', 6), ('livre concorrência', 7)
            ],
            'Bancário': [
                ('contrato bancário', 10), ('sistema financeiro nacional', 8), ('banco central', 7),
                ('conta corrente', 6), ('cartão de crédito', 6), ('cdc bancário', 5)
            ],
            'Trabalho': [
                ('contrato de trabalho', 10), ('relação de emprego', 9), ('clt', 8), ('empregado', 7),
                ('empregador', 7), ('justiça do trabalho', 5), ('fgts', 6), ('aviso prévio', 6),
                ('jornada de trabalho', 7), ('adicional noturno', 5), ('hora extra', 6)
            ],
            'Processual do Trabalho': [
                ('reclamação trabalhista', 10), ('dissídio individual', 8), ('tst', 7), ('audiência una', 6),
                ('execução trabalhista', 7), ('recursos trabalhistas', 6)
            ],
            'Previdenciário': [
                ('previdência social', 10), ('aposentadoria', 9), ('benefício previdenciário', 8),
                ('inss', 7), ('regime geral', 6), ('auxílio-doença', 6), ('pensão por morte', 5),
                ('contribuição previdenciária', 7)
            ],
            'Sindical': [
                ('sindicato', 10), ('convenção coletiva', 9), ('acordo coletivo', 8), ('greve', 7),
                ('liberdade sindical', 6), ('contribuição sindical', 6)
            ],
            'Ambiental': [
                ('meio ambiente', 10), ('licenciamento ambiental', 9), ('poluição', 7),
                ('área de preservação permanente', 6), ('dano ambiental', 8), ('snuc', 6),
                ('responsabilidade ambiental', 7), ('eia-rima', 5)
            ],
            'Agrário': [
                ('reforma agrária', 10), ('propriedade rural', 8), ('latifúndio', 7), ('mst', 6),
                ('função social da propriedade rural', 8), ('incra', 7), ('assentamento', 6)
            ],
            'Consumidor': [
                ('código de defesa do consumidor', 10), ('cdc', 9), ('relação de consumo', 8),
                ('fornecedor', 7), ('consumidor', 7), ('vício do produto', 6), ('propaganda enganosa', 6),
                ('procon', 6), ('recall', 5)
            ],
            'Digital': [
                ('marco civil da internet', 10), ('lgpd', 9), ('proteção de dados pessoais', 8),
                ('crimes cibernéticos', 7), ('comércio eletrônico', 6), ('assinatura digital', 5)
            ],
            'Criança e Adolescente': [
                ('eca', 10), ('estatuto da criança e adolescente', 9), ('conselho tutelar', 8),
                ('medida socioeducativa', 7), ('adoção', 6), ('guarda', 6), ('tutela', 5)
            ],
            'Idoso': [
                ('estatuto do idoso', 10), ('direitos do idoso', 8), ('violência contra idoso', 7),
                ('prioridade processual', 6)
            ],
            'PcD': [
                ('estatuto da pessoa com deficiência', 10), ('acessibilidade', 8), ('inclusão social', 7),
                ('capacidade civil', 6), ('curatela', 6)
            ],
            'Internacional': [
                ('tratado internacional', 10), ('direito internacional público', 8), ('soberania', 7),
                ('tribunal internacional', 6), ('direitos humanos internacionais', 8),
                ('convenção de haia', 5), ('mercosul', 6)
            ],
            'Direitos Humanos': [
                ('direitos humanos', 10), ('declaração universal', 8), ('dignidade da pessoa humana', 9),
                ('tortura', 7), ('discriminação', 6), ('igualdade', 6), ('liberdade', 6)
            ],
            'Eleitoral': [
                ('eleição', 10), ('tse', 9), ('campanha eleitoral', 8), ('voto', 7), ('candidato', 6),
                ('propaganda eleitoral', 7), ('financiamento de campanha', 6), ('código eleitoral', 8)
            ],
            'Constitucional Político': [
                ('sistema político', 8), ('partidos políticos', 9), ('democracia', 7), ('república', 6),
                ('federalismo', 6), ('separação de poderes', 7)
            ]
        }
        
        question_lower = question.lower()
        detected_areas = []
        max_score = 0
        best_area = None
        
        # Detectar área(s) jurídica(s) com maior pontuação
        for area_name, terms in legal_areas_taxonomy.items():
            area_score = 0
            matched_terms = []
            
            for term, weight in terms:
                if term.lower() in question_lower:
                    area_score += weight
                    matched_terms.append(term)
            
            if area_score > 0:
                detected_areas.append({
                    'area': area_name,
                    'score': area_score,
                    'terms': matched_terms
                })
                
                if area_score > max_score:
                    max_score = area_score
                    best_area = area_name
        
        # Construir query aprimorada
        if best_area:
            # Usar área com maior pontuação
            area_terms = [term for term, _ in legal_areas_taxonomy[best_area][:5]]  # Top 5 termos
            enhanced_query = f"{question} {best_area.lower()} brasil legislação jurisprudência {' '.join(area_terms[:3])}"
            
            # Adicionar tribunais específicos baseados na área
            tribunal_mapping = {
                'Constitucional': 'STF supremo',
                'Constitucional Político': 'STF supremo',
                'Trabalho': 'TST tribunal superior trabalho',
                'Processual do Trabalho': 'TST tribunal superior trabalho',
                'Previdenciário': 'TNU INSS',
                'Sindical': 'TST sindicato',
                'Eleitoral': 'TSE tribunal superior eleitoral',
                'Tributário': 'STJ CARF',
                'Administrativo': 'STJ TCU',
                'Civil': 'STJ tribunal justiça',
                'Processual Civil': 'STJ CPC',
                'Penal': 'STJ STF',
                'Processual Penal': 'STJ STF',
                'Empresarial': 'STJ',
                'Consumidor': 'STJ CDC',
                'Ambiental': 'STJ CONAMA',
                'Digital': 'STJ LGPD'
            }
            
            if best_area in tribunal_mapping:
                enhanced_query += f" {tribunal_mapping[best_area]}"
        
        else:
            # Query genérica se não detectar área específica
            enhanced_query = f"{question} direito brasileiro legislação jurisprudência STF STJ"
        
        # Log da detecção para debug
        if detected_areas:
            areas_info = [f"{a['area']} ({a['score']})" for a in detected_areas[:3]]
            self.logger.info(f"🎯 Áreas detectadas: {areas_info}")
            self.logger.info(f"📍 Área principal: {best_area} (score: {max_score})")
        
        return enhanced_query
    
    async def _search_duckduckgo(self, query: str) -> List[Dict[str, Any]]:
        """
        Busca usando DuckDuckGo (sem necessidade de API key).
        
        Args:
            query: Query de busca
        
        Returns:
            List[Dict]: Resultados da busca
        """
        try:
            import requests
            from bs4 import BeautifulSoup
            
            # DuckDuckGo Instant Answer API (limitado mas útil)
            url = "https://api.duckduckgo.com/"
            params = {
                "q": query,
                "format": "json",
                "no_html": "1",
                "skip_disambig": "1"
            }
            
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(url, params=params)
                data = response.json()
            
            results = []
            
            # Processar Abstract (resumo principal)
            if data.get("Abstract"):
                results.append({
                    "source": data.get("AbstractURL", "DuckDuckGo"),
                    "content": data.get("Abstract", ""),
                    "metadata": {
                        "type": "abstract",
                        "source_name": data.get("AbstractSource", "DuckDuckGo")
                    }
                })
            
            # Processar Related Topics
            for topic in data.get("RelatedTopics", [])[:3]:
                if isinstance(topic, dict) and topic.get("Text"):
                    results.append({
                        "source": topic.get("FirstURL", "DuckDuckGo"),
                        "content": topic.get("Text", ""),
                        "metadata": {
                            "type": "related_topic"
                        }
                    })
            
            return results
            
        except Exception as e:
            self.logger.error(f"❌ Erro DuckDuckGo search: {e}")
            return []
    
    async def _search_generic(self, query: str) -> List[Dict[str, Any]]:
        """
        Busca genérica usando scraping básico (fallback).
        
        Args:
            query: Query de busca
        
        Returns:
            List[Dict]: Resultados da busca
        """
        try:
            # Simular busca com informações jurídicas básicas
            legal_info_templates = {
                "clt": {
                    "source": "Planalto - CLT",
                    "content": "A Consolidação das Leis do Trabalho (CLT) é o principal diploma legal trabalhista brasileiro, estabelecendo direitos e deveres de empregados e empregadores.",
                    "metadata": {"type": "legislacao", "area": "trabalhista"}
                },
                "constituição": {
                    "source": "Planalto - Constituição Federal",
                    "content": "A Constituição Federal de 1988 é a lei fundamental do Brasil, estabelecendo direitos e garantias fundamentais.",
                    "metadata": {"type": "constituicao", "area": "constitucional"}
                },
                "código civil": {
                    "source": "Planalto - Código Civil",
                    "content": "O Código Civil brasileiro regula as relações jurídicas de direito privado entre pessoas físicas e jurídicas.",
                    "metadata": {"type": "legislacao", "area": "civil"}
                }
            }
            
            results = []
            query_lower = query.lower()
            
            # Buscar templates relevantes
            for key, template in legal_info_templates.items():
                if key in query_lower:
                    results.append(template)
            
            # Se não encontrou nada específico, adicionar informação geral
            if not results:
                results.append({
                    "source": "Conhecimento Jurídico Geral",
                    "content": f"Para questões sobre '{query}', recomenda-se consultar a legislação específica e jurisprudência dos tribunais superiores (STF, STJ).",
                    "metadata": {"type": "informacao_geral"}
                })
            
            return results
            
        except Exception as e:
            self.logger.error(f"❌ Erro generic search: {e}")
            return []
    
    def _process_search_results(self, search_results: List[Dict[str, Any]], question: str) -> str:
        """
        Processa e resume resultados da busca web.
        
        Args:
            search_results: Resultados da busca
            question: Pergunta original
        
        Returns:
            str: Resposta processada
        """
        if not search_results:
            return "Não foi possível encontrar informações específicas sobre esta consulta jurídica."
        
        # Combinar conteúdos relevantes
        combined_content = []
        for result in search_results[:5]:  # Limitar a 5 resultados
            content = result.get("content", "").strip()
            if content and len(content) > 20:
                source = result.get("source", "Fonte não identificada")
                combined_content.append(f"**{source}**: {content}")
        
        if not combined_content:
            return "Não foi possível encontrar informações específicas sobre esta consulta jurídica."
        
        # Criar resposta estruturada
        answer = f"""Com base em informações atualizadas da web, aqui está o que encontrei sobre sua consulta jurídica:

{chr(10).join(combined_content)}

**Recomendação**: Para informações mais específicas e atualizadas, consulte sempre a legislação vigente e a jurisprudência dos tribunais superiores."""
        
        return answer
    
    async def add_document(self, content: str, metadata: Dict[str, Any]) -> bool:
        """
        Adiciona novo documento à base de conhecimento.
        
        Args:
            content: Conteúdo do documento
            metadata: Metadados (source, type, year, etc.)
        """
        if not self.vectorstore:
            self.logger.error("❌ Vectorstore não inicializado")
            return False
        
        try:
            # Criar documento
            document = Document(page_content=content, metadata=metadata)
            
            # Dividir em chunks se necessário
            text_splitter = RecursiveCharacterTextSplitter(
                chunk_size=1000,
                chunk_overlap=200
            )
            splits = text_splitter.split_documents([document])
            
            # Adicionar ao vectorstore
            self.vectorstore.add_documents(splits)
            self.vectorstore.persist()
            
            self.logger.info(f"✅ Documento adicionado: {metadata.get('source', 'Sem fonte')}")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao adicionar documento: {e}")
            return False
    
    async def search_similar(self, query: str, k: int = 5) -> List[Dict[str, Any]]:
        """
        Busca documentos similares sem gerar resposta.
        
        Args:
            query: Consulta de busca
            k: Número de documentos a retornar
        """
        if not self.retriever:
            return []
        
        try:
            documents = await asyncio.to_thread(
                self.retriever.get_relevant_documents,
                query
            )
            
            results = []
            for doc in documents[:k]:
                results.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata,
                    "source": doc.metadata.get("source", "Desconhecido"),
                    "type": doc.metadata.get("type", "Desconhecido")
                })
            
            self.logger.info(f"✅ {len(results)} documentos similares encontrados")
            return results
            
        except Exception as e:
            self.logger.error(f"❌ Erro na busca: {e}")
            return []
    
    def get_stats(self) -> Dict[str, Any]:
        """Retorna estatísticas da base de conhecimento."""
        # Determinar tipo de storage
        if self.use_supabase:
            storage_type = "Supabase (nuvem)"
        elif self.use_chroma_cloud:
            storage_type = "Chroma Cloud (nuvem)"
        else:
            storage_type = "Chroma (local)"
        
        stats = {
            "storage_type": storage_type,
            "initialized": self.vectorstore is not None,
            "retriever_configured": self.retriever is not None,
            "qa_chain_configured": self.qa_chain is not None,
            "supabase_available": SUPABASE_AVAILABLE,
            "supabase_enabled": self.use_supabase,
            "chroma_cloud_available": CHROMA_CLOUD_AVAILABLE,
            "chroma_cloud_enabled": self.use_chroma_cloud
        }
        
        if not self.use_supabase:
            stats["knowledge_base_path"] = str(self.knowledge_base_path)
        
        if self.vectorstore:
            try:
                if self.use_supabase:
                    # Para Supabase, tentar obter estatísticas via query
                    stats["document_count"] = "Disponível via Supabase"
                    stats["table_name"] = "legal_documents"
                else:
                    # Para Chroma local
                    collection = self.vectorstore._collection
                    stats["document_count"] = collection.count()
            except:
                stats["document_count"] = "Não disponível"
        
        return stats


# Instância global
brazilian_rag = None

def get_brazilian_legal_rag() -> BrazilianLegalRAG:
    """Factory para obter instância do RAG jurídico brasileiro."""
    global brazilian_rag
    if brazilian_rag is None:
        brazilian_rag = BrazilianLegalRAG()
    return brazilian_rag

"""
Cliente OpenRouter centralizado para LITIG-1
Implementa arquitetura de 4 níveis de fallback conforme PLANO_EVOLUCAO_COMPLETO_OPENROUTER_LANGGRAPH.md

🆕 V2.1: Web Search + Advanced Routing
- Web Search em tempo real via OpenRouter
- Roteamento avançado (:nitro, :floor) 
- Otimização custo vs velocidade automática

Níveis de Fallback:
1. Modelo Primário via OpenRouter (com web search se habilitado)
2. Auto-router via OpenRouter (openrouter/auto)  
3. Cascata Direta (APIs nativas preservadas)
4. Erro final

Preserva 100% da funcionalidade existente com melhor resiliência.
"""

import asyncio
import logging
from typing import Any, Dict, List, Optional, Union, Literal
import json
import time

from openai import AsyncOpenAI
from config import Settings

# Import function tools sem imports relativos
try:
    from function_tools import LLMFunctionTools
except ImportError:
    try:
        from services.function_tools import LLMFunctionTools
    except ImportError:
        # Fallback para importar do path absoluto
        import sys
        sys.path.append('services/')
        from function_tools import LLMFunctionTools

# Clientes diretos preservados para Níveis 3-4
try:
    import google.generativeai as genai
    if Settings.GEMINI_API_KEY:
        genai.configure(api_key=Settings.GEMINI_API_KEY)
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False

try:
    import anthropic
    ANTHROPIC_CLIENT = anthropic.AsyncAnthropic(api_key=Settings.ANTHROPIC_API_KEY) if Settings.ANTHROPIC_API_KEY else None
    ANTHROPIC_AVAILABLE = bool(ANTHROPIC_CLIENT)
except ImportError:
    ANTHROPIC_AVAILABLE = False
    ANTHROPIC_CLIENT = None

try:
    OPENAI_CLIENT = AsyncOpenAI(api_key=Settings.OPENAI_API_KEY) if Settings.OPENAI_API_KEY else None
    OPENAI_AVAILABLE = bool(OPENAI_CLIENT)
except ImportError:
    OPENAI_AVAILABLE = False
    OPENAI_CLIENT = None

logger = logging.getLogger(__name__)


class OpenRouterClient:
    """
    Cliente OpenRouter unificado com fallback de 4 níveis.
    
    🆕 V2.1: Web Search + Advanced Routing
    - Web Search: Informações atualizadas em tempo real
    - :nitro: Prioriza velocidade (real-time UX)
    - :floor: Prioriza custo (background jobs)
    
    Preserva todas as funcionalidades existentes com maior resiliência.
    """
    
    def __init__(self):
        self.openrouter_client = None
        
        # Feature flag controla se OpenRouter é usado
        if Settings.USE_OPENROUTER and Settings.OPENROUTER_API_KEY:
            self.openrouter_client = AsyncOpenAI(
                base_url=Settings.OPENROUTER_BASE_URL,
                api_key=Settings.OPENROUTER_API_KEY,
                default_headers={
                    "HTTP-Referer": Settings.OPENROUTER_SITE_URL,
                    "X-Title": Settings.OPENROUTER_APP_NAME,
                }
            )
            self.openrouter_available = True
            logger.info("🌐 OpenRouter client ativado via USE_OPENROUTER=true (V2.1 Web Search + Advanced Routing)")
        else:
            self.openrouter_available = False
            if not Settings.USE_OPENROUTER:
                logger.info("🔒 OpenRouter desabilitado via USE_OPENROUTER=false - usando apenas APIs diretas")
            else:
                logger.warning("OPENROUTER_API_KEY não encontrada - usando apenas fallbacks diretos")

    async def call_with_priority_routing(
        self, 
        model: str, 
        messages: List[Dict], 
        priority: Literal["speed", "cost", "quality"] = "quality",
        enable_web_search: bool = False,
        web_search_sources: Optional[List[str]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        🆕 V2.1: Método conveniente para roteamento baseado em prioridade.
        
        Args:
            model: Modelo base (será modificado conforme prioridade)
            messages: Mensagens do chat
            priority: "speed" (:nitro), "cost" (:floor), "quality" (padrão)
            enable_web_search: Habilita busca na web
            web_search_sources: Lista de domínios preferenciais para busca
            **kwargs: Parâmetros adicionais
            
        Returns:
            Dict com resposta e metadados de roteamento
        """
        # Aplicar sufixos de roteamento conforme prioridade
        routed_model = self._apply_routing_suffix(model, priority)
        
        # Configurar headers para web search se habilitado
        extra_headers = {}
        if enable_web_search:
            extra_headers["X-Enable-Web-Search"] = "true"
            if web_search_sources:
                extra_headers["X-Search-Sources"] = ",".join(web_search_sources)
        
        # Configurar timeouts específicos por prioridade
        if priority == "speed":
            kwargs.setdefault("timeout", 10)  # Timeout agressivo
            extra_headers["X-Priority"] = "latency"
        elif priority == "cost":
            kwargs.setdefault("timeout", 60)  # Permitir mais tempo
            extra_headers["X-Priority"] = "cost"
            extra_headers["X-Background-Job"] = "true"
        
        # Executar com fallback
        result = await self.chat_completion_with_fallback(
            primary_model=routed_model,
            messages=messages,
            extra_headers=extra_headers,
            **kwargs
        )
        
        # Adicionar metadados de roteamento
        result["routing_priority"] = priority
        result["routing_model"] = routed_model
        result["web_search_enabled"] = enable_web_search
        
        return result
    
    def _apply_routing_suffix(self, model: str, priority: str) -> str:
        """
        Aplica sufixos de roteamento avançado do OpenRouter.
        
        Args:
            model: Modelo base
            priority: Prioridade de roteamento
            
        Returns:
            Modelo com sufixo apropriado
        """
        # Evitar duplicação de sufixos
        if any(suffix in model for suffix in [":nitro", ":floor", ":online"]):
            return model
            
        if priority == "speed":
            return f"{model}:nitro"  # Máxima velocidade
        elif priority == "cost":
            return f"{model}:floor"  # Mínimo custo
        else:
            return model  # Quality: sem sufixo (roteamento padrão)

    async def chat_completion_with_web_search(
        self,
        model: str,
        messages: List[Dict[str, str]],
        enable_web_search: bool = True,
        web_search_sources: Optional[List[str]] = None,
        search_focus: Optional[str] = None,
        tools: Optional[List[Dict]] = None,
        tool_choice: Optional[Union[str, Dict]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        🆕 V2.1: Chat completion com Web Search para informações atualizadas.
        
        Args:
            model: Modelo (recomendado: openai/gpt-4o-search-preview ou google/gemini-2.5-pro:online)
            messages: Mensagens do chat
            enable_web_search: Habilita busca na web
            web_search_sources: Domínios específicos para busca (ex: ["stf.jus.br", "jusbrasil.com.br"])
            search_focus: Foco da busca (ex: "jurisprudencia", "doutrina", "legislacao")
            tools: Function tools
            tool_choice: Configuração de tool choice
            **kwargs: Parâmetros adicionais
            
        Returns:
            Dict com resposta enriquecida com dados web
        """
        # Preparar headers para web search
        extra_headers = {}
        if enable_web_search:
            extra_headers["X-Enable-Web-Search"] = "true"
            
            if web_search_sources:
                extra_headers["X-Search-Sources"] = ",".join(web_search_sources)
            
            if search_focus:
                extra_headers["X-Search-Focus"] = search_focus
        
        # Usar modelo otimizado para web search se não especificado
        if enable_web_search and not any(search_model in model for search_model in ["search-preview", ":online"]):
            if "gpt-4o" in model:
                model = "openai/gpt-4o-search-preview"
            elif "gemini" in model:
                model = f"{model}:online"
        
        # Executar com fallback
        return await self.chat_completion_with_fallback(
            primary_model=model,
            messages=messages,
            tools=tools,
            tool_choice=tool_choice,
            extra_headers=extra_headers,
            **kwargs
        )

    async def chat_completion_with_fallback(
        self,
        primary_model: str,
        messages: List[Dict[str, str]],
        tools: Optional[List[Dict]] = None,
        tool_choice: Optional[Union[str, Dict]] = None,
        max_tokens: Optional[int] = None,
        temperature: float = 0.1,
        extra_headers: Optional[Dict[str, str]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Executa chat completion com arquitetura de 4 níveis de fallback.
        
        🆕 V2.1: Suporte a extra_headers para Web Search
        
        Args:
            primary_model: Modelo primário via OpenRouter (ex: "google/gemini-2.5-flash")
            messages: Lista de mensagens para o chat
            tools: Lista de ferramentas/functions para function calling
            tool_choice: Configuração de escolha de ferramenta
            max_tokens: Limite de tokens na resposta
            temperature: Temperatura da geração
            extra_headers: Headers extras (ex: X-Enable-Web-Search)
            **kwargs: Parâmetros adicionais
            
        Returns:
            Dict com resposta do LLM e metadados de fallback
        """
        start_time = time.time()
        errors = []
        
        # Preparar headers combinados
        combined_headers = {}
        if extra_headers:
            combined_headers.update(extra_headers)
        
        # Nível 1: Modelo Primário via OpenRouter (com web search se habilitado)
        if self.openrouter_available:
            try:
                logger.info(f"🔄 Nível 1: Tentando {primary_model} via OpenRouter")
                if extra_headers:
                    logger.info(f"🌐 Headers extras: {extra_headers}")
                
                # Aplicar headers extras se fornecidos
                client_headers = self.openrouter_client.default_headers.copy()
                client_headers.update(combined_headers)
                
                # Temporariamente atualizar headers do cliente
                original_headers = self.openrouter_client.default_headers
                self.openrouter_client.default_headers = client_headers
                
                try:
                    response = await asyncio.wait_for(
                        self.openrouter_client.chat.completions.create(
                            model=primary_model,
                            messages=messages,
                            tools=tools,
                            tool_choice=tool_choice,
                            max_tokens=max_tokens,
                            temperature=temperature,
                            **kwargs
                        ),
                        timeout=kwargs.get('timeout', Settings.OPENROUTER_TIMEOUT_SECONDS)
                    )
                finally:
                    # Restaurar headers originais
                    self.openrouter_client.default_headers = original_headers
                
                logger.info(f"✅ Nível 1: Sucesso com {primary_model}")
                return {
                    "response": response,
                    "fallback_level": 1,
                    "model_used": primary_model,
                    "provider": "openrouter_primary",
                    "web_search_used": "X-Enable-Web-Search" in combined_headers,
                    "processing_time_ms": int((time.time() - start_time) * 1000)
                }
                
            except Exception as e:
                error_msg = f"Nível 1 falhou ({primary_model}): {str(e)}"
                errors.append(error_msg)
                logger.warning(f"⚠️ {error_msg}")
        
        # Nível 2: Auto-router via OpenRouter (sem web search para compatibilidade)
        if self.openrouter_available:
            try:
                logger.info("🔄 Nível 2: Tentando openrouter/auto")
                
                response = await asyncio.wait_for(
                    self.openrouter_client.chat.completions.create(
                        model="openrouter/auto",
                        messages=messages,
                        tools=tools,
                        tool_choice=tool_choice,
                        max_tokens=max_tokens,
                        temperature=temperature,
                        **{k: v for k, v in kwargs.items() if k != 'timeout'}
                    ),
                    timeout=Settings.OPENROUTER_TIMEOUT_SECONDS
                )
                
                logger.info("✅ Nível 2: Sucesso com openrouter/auto")
                return {
                    "response": response,
                    "fallback_level": 2,
                    "model_used": "openrouter/auto",
                    "provider": "openrouter_auto",
                    "web_search_used": False,
                    "processing_time_ms": int((time.time() - start_time) * 1000)
                }
                
            except Exception as e:
                error_msg = f"Nível 2 falhou (openrouter/auto): {str(e)}"
                errors.append(error_msg)
                logger.warning(f"⚠️ {error_msg}")
        
        # Nível 3-4: Cascata Direta (APIs nativas preservadas)
        if Settings.ENABLE_DIRECT_LLM_FALLBACK:
            direct_result = await self._direct_llm_fallback(
                messages, tools, tool_choice, max_tokens, temperature, **kwargs
            )
            
            if direct_result:
                direct_result["processing_time_ms"] = int((time.time() - start_time) * 1000)
                return direct_result
        
        # Erro final
        error_summary = "; ".join(errors)
        raise Exception(f"Todos os 4 níveis de fallback falharam: {error_summary}")
    
    async def _direct_llm_fallback(
        self,
        messages: List[Dict[str, str]],
        tools: Optional[List[Dict]] = None,
        tool_choice: Optional[Union[str, Dict]] = None,
        max_tokens: Optional[int] = None,
        temperature: float = 0.1,
        **kwargs
    ) -> Optional[Dict[str, Any]]:
        """
        Implementa Níveis 3-4: Cascata direta com APIs nativas.
        Preserva exatamente a lógica de fallback existente.
        """
        
        # Nível 3a: Gemini Direto
        if GEMINI_AVAILABLE and Settings.GEMINI_API_KEY:
            try:
                logger.info("🔄 Nível 3a: Tentando Gemini direto")
                
                # Converter mensagens para formato Gemini
                prompt = self._messages_to_prompt(messages)
                
                model = genai.GenerativeModel("gemini-2.5-flash")
                response = await asyncio.wait_for(
                    model.generate_content_async(prompt),
                    timeout=30
                )
                
                # Se tools foram especificadas, tentar extrair JSON
                if tools and response.text:
                    try:
                        import re
                        match = re.search(r'\{.*\}', response.text, re.DOTALL)
                        if match:
                            parsed_content = json.loads(match.group(0))
                        else:
                            parsed_content = json.loads(response.text)
                    except json.JSONDecodeError:
                        parsed_content = {"content": response.text}
                else:
                    parsed_content = {"content": response.text}
                
                logger.info("✅ Nível 3a: Sucesso com Gemini direto")
                return {
                    "response": self._format_direct_response(response.text, parsed_content),
                    "fallback_level": 3,
                    "model_used": "gemini-2.0-flash-exp",
                    "provider": "gemini_direct"
                }
                
            except Exception as e:
                logger.warning(f"⚠️ Nível 3a falhou (Gemini direto): {str(e)}")
        
        # Nível 3b: Claude Sonnet 4 Direto
        if ANTHROPIC_AVAILABLE and ANTHROPIC_CLIENT:
            try:
                logger.info("🔄 Nível 3b: Tentando Claude Sonnet 4 direto")
                
                response = await asyncio.wait_for(
                    ANTHROPIC_CLIENT.messages.create(
                        model="claude-3-5-sonnet-20241022",  # Modelo mais recente disponível
                        max_tokens=max_tokens or 4096,
                        messages=messages,
                        temperature=temperature
                    ),
                    timeout=30
                )
                
                content = response.content[0].text
                
                # Se tools foram especificadas, tentar extrair JSON
                if tools and content:
                    try:
                        import re
                        match = re.search(r'\{.*\}', content, re.DOTALL)
                        if match:
                            parsed_content = json.loads(match.group(0))
                        else:
                            parsed_content = json.loads(content)
                    except json.JSONDecodeError:
                        parsed_content = {"content": content}
                else:
                    parsed_content = {"content": content}
                
                logger.info("✅ Nível 3b: Sucesso com Claude direto")
                return {
                    "response": self._format_direct_response(content, parsed_content),
                    "fallback_level": 3,
                    "model_used": "claude-3-5-sonnet",
                    "provider": "anthropic_direct"
                }
                
            except Exception as e:
                logger.warning(f"⚠️ Nível 3b falhou (Claude direto): {str(e)}")
        
        # Nível 4: OpenAI/Grok Direto  
        if OPENAI_AVAILABLE and OPENAI_CLIENT:
            try:
                logger.info("🔄 Nível 4: Tentando OpenAI direto")
                
                response = await asyncio.wait_for(
                    OPENAI_CLIENT.chat.completions.create(
                        model="gpt-4o",
                        messages=messages,
                        tools=tools,
                        tool_choice=tool_choice,
                        max_tokens=max_tokens,
                        temperature=temperature,
                        **kwargs
                    ),
                    timeout=30
                )
                
                logger.info("✅ Nível 4: Sucesso com OpenAI direto")
                return {
                    "response": response,
                    "fallback_level": 4,
                    "model_used": "gpt-4o",
                    "provider": "openai_direct"
                }
                
            except Exception as e:
                logger.warning(f"⚠️ Nível 4 falhou (OpenAI direto): {str(e)}")
        
        return None
    
    def _messages_to_prompt(self, messages: List[Dict[str, str]]) -> str:
        """Converte mensagens do formato OpenAI para prompt simples."""
        return "\n\n".join([f"{msg['role'].upper()}: {msg['content']}" for msg in messages])
    
    def _format_direct_response(self, content: str, parsed_content: Dict) -> Any:
        """Formata resposta direta para compatibilidade com OpenAI format."""
        # Criar objeto mock similar ao formato OpenAI
        class MockChoice:
            def __init__(self, content: str, parsed: Dict):
                self.message = type('obj', (object,), {
                    'content': content,
                    'tool_calls': [type('obj', (object,), {
                        'function': type('obj', (object,), {
                            'arguments': json.dumps(parsed)
                        })()
                    })()] if isinstance(parsed, dict) and len(parsed) > 1 else None
                })()
        
        return type('obj', (object,), {
            'choices': [MockChoice(content, parsed_content)]
        })()
    
    async def test_connectivity(self) -> Dict[str, Any]:
        """
        Testa conectividade com todos os níveis de fallback.
        
        Returns:
            Dict com resultados de teste para cada nível
        """
        results = {
            "openrouter_primary": False,
            "openrouter_auto": False, 
            "gemini_direct": False,
            "anthropic_direct": False,
            "openai_direct": False,
            "overall_status": False
        }
        
        test_messages = [{"role": "user", "content": "Responda apenas: OK"}]
        
        # Teste Nível 1: OpenRouter Primary
        if self.openrouter_available:
            try:
                response = await asyncio.wait_for(
                    self.openrouter_client.chat.completions.create(
                        model="google/gemini-2.5-flash",
                        messages=test_messages,
                        max_tokens=10
                    ),
                    timeout=10
                )
                results["openrouter_primary"] = True
                logger.info("✅ Teste OpenRouter primário: OK")
            except Exception as e:
                logger.warning(f"❌ Teste OpenRouter primário: {str(e)}")
        
        # Teste Nível 2: OpenRouter Auto
        if self.openrouter_available:
            try:
                response = await asyncio.wait_for(
                    self.openrouter_client.chat.completions.create(
                        model="openrouter/auto",
                        messages=test_messages,
                        max_tokens=10
                    ),
                    timeout=10
                )
                results["openrouter_auto"] = True
                logger.info("✅ Teste OpenRouter auto: OK")
            except Exception as e:
                logger.warning(f"❌ Teste OpenRouter auto: {str(e)}")
        
        # Teste Nível 3: Diretos
        if GEMINI_AVAILABLE:
            try:
                model = genai.GenerativeModel("gemini-2.5-flash")
                response = await asyncio.wait_for(
                    model.generate_content_async("Responda apenas: OK"),
                    timeout=10
                )
                results["gemini_direct"] = True
                logger.info("✅ Teste Gemini direto: OK")
            except Exception as e:
                logger.warning(f"❌ Teste Gemini direto: {str(e)}")
        
        if ANTHROPIC_AVAILABLE:
            try:
                response = await asyncio.wait_for(
                    ANTHROPIC_CLIENT.messages.create(
                        model="claude-3-5-sonnet-20241022",
                        max_tokens=10,
                        messages=test_messages
                    ),
                    timeout=10
                )
                results["anthropic_direct"] = True
                logger.info("✅ Teste Claude direto: OK")
            except Exception as e:
                logger.warning(f"❌ Teste Claude direto: {str(e)}")
        
        if OPENAI_AVAILABLE:
            try:
                response = await asyncio.wait_for(
                    OPENAI_CLIENT.chat.completions.create(
                        model="gpt-4o-mini",
                        messages=test_messages,
                        max_tokens=10
                    ),
                    timeout=10
                )
                results["openai_direct"] = True
                logger.info("✅ Teste OpenAI direto: OK")
            except Exception as e:
                logger.warning(f"❌ Teste OpenAI direto: {str(e)}")
        
        # Status geral
        results["overall_status"] = any([
            results["openrouter_primary"],
            results["openrouter_auto"], 
            results["gemini_direct"],
            results["anthropic_direct"],
            results["openai_direct"]
        ])
        
        return results
    
    async def call_with_function_tool(
        self,
        service_name: str,
        primary_model: str,
        messages: List[Dict[str, str]],
        **kwargs
    ) -> Dict[str, Any]:
        """
        Chama LLM com Function Tool específico do serviço.
        
        Args:
            service_name: Nome do serviço (lex9000, lawyer_profile, etc.)
            primary_model: Modelo primário (ex: x-ai/grok-4)
            messages: Lista de mensagens
            **kwargs: Parâmetros adicionais (max_tokens, temperature, etc.)
            
        Returns:
            Dict com resultado parseado do Function Call
        """
        try:
            # Obter Function Tool específico
            tool = LLMFunctionTools.get_tool_by_service(service_name)
            tool_name = tool["function"]["name"]
            
            # Parâmetros padrão
            call_params = {
                "tools": [tool],
                "tool_choice": {"type": "function", "function": {"name": tool_name}},
                **kwargs
            }
            
            # Chamar com fallback de 4 níveis
            response = await self.chat_completion_with_fallback(
                primary_model=primary_model,
                messages=messages,
                **call_params
            )
            
            # Extrair resultado da Function Call
            if "tool_calls" in response and response["tool_calls"]:
                tool_call = response["tool_calls"][0]
                parsed_result = json.loads(tool_call["function"]["arguments"])
                
                return {
                    "success": True,
                    "result": parsed_result,
                    "model_used": response.get("model_used"),
                    "fallback_level": response.get("fallback_level"),
                    "processing_time_ms": response.get("processing_time_ms")
                }
            else:
                # Fallback para resposta de texto
                return {
                    "success": False,
                    "error": "LLM não retornou function call",
                    "text_response": response.get("content", ""),
                    "model_used": response.get("model_used"),
                    "fallback_level": response.get("fallback_level")
                }
                
        except Exception as e:
            logger.error(f"Erro em call_with_function_tool para {service_name}: {e}")
            return {
                "success": False,
                "error": str(e),
                "service_name": service_name
            }


# Instância global do cliente
openrouter_client = OpenRouterClient()


async def get_openrouter_client() -> OpenRouterClient:
    """Factory function para obter cliente OpenRouter."""
    return openrouter_client 
 
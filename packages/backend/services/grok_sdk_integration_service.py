#!/usr/bin/env python3
"""
Grok SDK Integration Service - 3 SDKs Essenciais
================================================

Combina apenas os 3 SDKs xAI essenciais para máxima eficiência:
1. OpenRouter (x-ai/grok-4) - Gateway unificado
2. xai-sdk oficial - Produção, streaming, 256k tokens  
3. langchain-xai - Workflows complexos, LangGraph
4. Cascata tradicional - Fallback final
"""

import asyncio
import json
import logging
import time
from typing import Dict, Any, List, Optional, Union
from dataclasses import dataclass
from datetime import datetime

# Imports para os 3 SDKs essenciais
try:
    from xai_sdk import Client, AsyncClient
    XAI_SDK_AVAILABLE = True
except ImportError:
    XAI_SDK_AVAILABLE = False

try:
    from langchain_xai import ChatXAI
    LANGCHAIN_XAI_AVAILABLE = True
except ImportError:
    LANGCHAIN_XAI_AVAILABLE = False

# Import config
try:
    from config import Settings
except ImportError:
    import sys
    sys.path.append('..')
    from config import Settings

# Import OpenRouter client existente
try:
    from openrouter_client import get_openrouter_client
except ImportError:
    from services.openrouter_client import get_openrouter_client

logger = logging.getLogger(__name__)

@dataclass
class GrokSDKResponse:
    """Resposta padronizada independente do SDK usado."""
    content: str
    model_used: str
    sdk_level: int
    sdk_name: str
    processing_time: float
    tokens_used: Optional[int] = None
    raw_response: Optional[Dict[str, Any]] = None

@dataclass 
class GrokSDKConfig:
    """Configuração para os 3 SDKs essenciais."""
    openrouter_api_key: Optional[str] = None
    xai_api_key: Optional[str] = None
    timeout_seconds: float = 30.0
    max_tokens: int = 4000
    temperature: float = 0.1

class GrokSDKIntegrationService:
    """
    Serviço que integra os 3 SDKs xAI essenciais para máxima eficiência.
    
    Arquitetura de 4 níveis:
    1. OpenRouter (x-ai/grok-4) - Gateway unificado
    2. xai-sdk oficial - Produção, streaming, 256k tokens
    3. LangChain-XAI - Workflows complexos, LangGraph  
    4. Cascata tradicional - Fallback final
    """
    
    def __init__(self, config: Optional[GrokSDKConfig] = None):
        self.config = config or self._load_default_config()
        self.logger = logging.getLogger(f"{self.__class__.__name__}")
        
        # Initialize 3 essential SDKs
        self.openrouter_client = None
        self.xai_sdk_client = None
        self.langchain_xai_client = None
        
        self._initialize_sdks()
    
    def _load_default_config(self) -> GrokSDKConfig:
        """Carrega configuração padrão das environment variables."""
        try:
            settings = Settings()
            return GrokSDKConfig(
                openrouter_api_key=getattr(settings, 'OPENROUTER_API_KEY', None),
                xai_api_key=getattr(settings, 'XAI_API_KEY', None),
                timeout_seconds=30.0,
                max_tokens=4000,
                temperature=0.1
            )
        except Exception as e:
            self.logger.warning(f"Erro ao carregar config: {e}")
            return GrokSDKConfig()
    
    def _initialize_sdks(self):
        """Inicializa os 3 SDKs essenciais."""
        
        # 1. OpenRouter Client (gateway unificado)
        try:
            self.openrouter_client = get_openrouter_client()
            self.logger.info("✅ OpenRouter client inicializado")
        except Exception as e:
            self.logger.warning(f"❌ OpenRouter client falhou: {e}")
        
        # 2. xai-sdk oficial (produção, streaming, 256k tokens)
        if XAI_SDK_AVAILABLE and self.config.xai_api_key:
            try:
                self.xai_sdk_client = AsyncClient(api_key=self.config.xai_api_key)
                self.logger.info("✅ xai-sdk oficial inicializado")
            except Exception as e:
                self.logger.warning(f"❌ xai-sdk oficial falhou: {e}")
        
        # 3. LangChain-XAI (workflows complexos, LangGraph)
        if LANGCHAIN_XAI_AVAILABLE and self.config.xai_api_key:
            try:
                self.langchain_xai_client = ChatXAI(
                    api_key=self.config.xai_api_key,
                    model="grok-3",
                    temperature=self.config.temperature,
                    max_tokens=self.config.max_tokens
                )
                self.logger.info("✅ LangChain-XAI client inicializado")
            except Exception as e:
                self.logger.warning(f"❌ LangChain-XAI client falhou: {e}")
    
    async def generate_completion(
        self, 
        messages: List[Dict[str, str]], 
        system_prompt: Optional[str] = None,
        function_tool: Optional[Dict[str, Any]] = None,
        use_streaming: bool = False
    ) -> GrokSDKResponse:
        """
        Gera completion usando a arquitetura de 4 níveis essenciais.
        
        Args:
            messages: Lista de mensagens para o chat
            system_prompt: Prompt de sistema opcional
            function_tool: Tool de função para structured output
            use_streaming: Se deve usar streaming (apenas xai-sdk oficial)
        
        Returns:
            GrokSDKResponse com o resultado da melhor fonte disponível
        """
        
        # Preparar mensagens
        if system_prompt:
            full_messages = [{"role": "system", "content": system_prompt}] + messages
        else:
            full_messages = messages
        
        # Nível 1: OpenRouter (gateway unificado)
        result = await self._try_openrouter_grok(full_messages, function_tool)
        if result:
            return result
        
        # Nível 2: xai-sdk oficial (produção, streaming, 256k tokens)
        result = await self._try_xai_sdk_official(full_messages, function_tool, use_streaming)
        if result:
            return result
        
        # Nível 3: LangChain-XAI (workflows complexos)
        result = await self._try_langchain_xai(full_messages)
        if result:
            return result
        
        # Nível 4: Cascata tradicional (fallback final)
        result = await self._try_traditional_cascade(full_messages, function_tool)
        if result:
            return result
        
        # Se tudo falhar
        raise Exception("Todos os 4 níveis essenciais falharam")
    
    async def _try_openrouter_grok(
        self, 
        messages: List[Dict[str, str]], 
        function_tool: Optional[Dict[str, Any]] = None
    ) -> Optional[GrokSDKResponse]:
        """Nível 1: OpenRouter com x-ai/grok-4 (gateway unificado)."""
        
        if not self.openrouter_client:
            return None
        
        start_time = time.time()
        try:
            if function_tool:
                # Com function calling
                response = await self.openrouter_client.chat.completions.create(
                    model="x-ai/grok-4",
                    messages=messages,
                    tools=[function_tool],
                    tool_choice={"type": "function", "function": {"name": function_tool["function"]["name"]}},
                    timeout=self.config.timeout_seconds
                )
                
                # Parse function call response
                tool_call = response.choices[0].message.tool_calls[0]
                content = tool_call.function.arguments
                
            else:
                # Chat normal
                response = await self.openrouter_client.chat.completions.create(
                    model="x-ai/grok-4",
                    messages=messages,
                    max_tokens=self.config.max_tokens,
                    temperature=self.config.temperature,
                    timeout=self.config.timeout_seconds
                )
                content = response.choices[0].message.content
            
            processing_time = time.time() - start_time
            
            return GrokSDKResponse(
                content=content,
                model_used="x-ai/grok-4",
                sdk_level=1,
                sdk_name="OpenRouter Gateway",
                processing_time=processing_time,
                tokens_used=getattr(response, 'usage', {}).get('total_tokens'),
                raw_response=response.model_dump() if hasattr(response, 'model_dump') else None
            )
            
        except Exception as e:
            processing_time = time.time() - start_time
            self.logger.warning(f"Nível 1 (OpenRouter Gateway) falhou ({processing_time:.2f}s): {e}")
            return None
    
    async def _try_xai_sdk_official(
        self, 
        messages: List[Dict[str, str]], 
        function_tool: Optional[Dict[str, Any]] = None,
        use_streaming: bool = False
    ) -> Optional[GrokSDKResponse]:
        """Nível 2: xai-sdk oficial (produção, streaming, 256k tokens)."""
        
        if not self.xai_sdk_client:
            return None
        
        start_time = time.time()
        try:
            # Preparar parâmetros para xai-sdk
            params = {
                "model": "grok-3",  # Modelo disponível no SDK oficial
                "messages": messages,
                "max_tokens": self.config.max_tokens,
                "temperature": self.config.temperature
            }
            
            if function_tool:
                params["tools"] = [function_tool]
                params["tool_choice"] = {"type": "function", "function": {"name": function_tool["function"]["name"]}}
            
            if use_streaming:
                # Streaming mode (vantagem do SDK oficial)
                response_chunks = []
                async for chunk in await self.xai_sdk_client.chat.completions.create(**params, stream=True):
                    if chunk.choices and chunk.choices[0].delta.content:
                        response_chunks.append(chunk.choices[0].delta.content)
                
                content = "".join(response_chunks)
                tokens_used = None  # Streaming não retorna usage imediatamente
                
            else:
                # Mode normal
                response = await self.xai_sdk_client.chat.completions.create(**params)
                
                if function_tool and response.choices[0].message.tool_calls:
                    tool_call = response.choices[0].message.tool_calls[0]
                    content = tool_call.function.arguments
                else:
                    content = response.choices[0].message.content
                
                tokens_used = getattr(response, 'usage', {}).get('total_tokens')
            
            processing_time = time.time() - start_time
            
            return GrokSDKResponse(
                content=content,
                model_used="grok-3",
                sdk_level=2,
                sdk_name="xai-sdk oficial",
                processing_time=processing_time,
                tokens_used=tokens_used,
                raw_response={"streaming": use_streaming}
            )
            
        except Exception as e:
            processing_time = time.time() - start_time
            self.logger.warning(f"Nível 2 (xai-sdk oficial) falhou ({processing_time:.2f}s): {e}")
            return None
    
    async def _try_langchain_xai(
        self, 
        messages: List[Dict[str, str]]
    ) -> Optional[GrokSDKResponse]:
        """Nível 3: LangChain-XAI (workflows complexos, LangGraph)."""
        
        if not self.langchain_xai_client:
            return None
        
        start_time = time.time()
        try:
            # Converter formato de mensagens para LangChain
            from langchain_core.messages import HumanMessage, SystemMessage, AIMessage
            
            lc_messages = []
            for msg in messages:
                if msg["role"] == "system":
                    lc_messages.append(SystemMessage(content=msg["content"]))
                elif msg["role"] == "user":
                    lc_messages.append(HumanMessage(content=msg["content"]))
                elif msg["role"] == "assistant":
                    lc_messages.append(AIMessage(content=msg["content"]))
            
            response = await self.langchain_xai_client.ainvoke(lc_messages)
            
            processing_time = time.time() - start_time
            
            return GrokSDKResponse(
                content=response.content,
                model_used="grok-3",
                sdk_level=3,
                sdk_name="LangChain-XAI",
                processing_time=processing_time,
                raw_response={"response": str(response)}
            )
            
        except Exception as e:
            processing_time = time.time() - start_time
            self.logger.warning(f"Nível 3 (LangChain-XAI) falhou ({processing_time:.2f}s): {e}")
            return None
    
    async def _try_traditional_cascade(
        self, 
        messages: List[Dict[str, str]], 
        function_tool: Optional[Dict[str, Any]] = None
    ) -> Optional[GrokSDKResponse]:
        """Nível 4: Cascata tradicional (fallback final)."""
        
        if not self.openrouter_client:
            return None
        
        # Tentar modelos em ordem de preferência
        fallback_models = [
            "google/gemini-2.5-pro",
            "anthropic/claude-sonnet-4-20250514", 
            "openai/gpt-4.1-mini"
        ]
        
        for model in fallback_models:
            start_time = time.time()
            try:
                if function_tool:
                    response = await self.openrouter_client.chat.completions.create(
                        model=model,
                        messages=messages,
                        tools=[function_tool],
                        tool_choice={"type": "function", "function": {"name": function_tool["function"]["name"]}},
                        timeout=self.config.timeout_seconds
                    )
                    tool_call = response.choices[0].message.tool_calls[0]
                    content = tool_call.function.arguments
                else:
                    response = await self.openrouter_client.chat.completions.create(
                        model=model,
                        messages=messages,
                        max_tokens=self.config.max_tokens,
                        temperature=self.config.temperature,
                        timeout=self.config.timeout_seconds
                    )
                    content = response.choices[0].message.content
                
                processing_time = time.time() - start_time
                
                return GrokSDKResponse(
                    content=content,
                    model_used=model,
                    sdk_level=4,
                    sdk_name="Cascata Tradicional",
                    processing_time=processing_time,
                    tokens_used=getattr(response, 'usage', {}).get('total_tokens'),
                    raw_response=response.model_dump() if hasattr(response, 'model_dump') else None
                )
                
            except Exception as e:
                processing_time = time.time() - start_time
                self.logger.warning(f"Nível 4 ({model}) falhou ({processing_time:.2f}s): {e}")
                continue
        
        return None
    
    async def test_all_levels(self) -> Dict[str, Any]:
        """
        Testa todos os 4 níveis essenciais para diagnosticar disponibilidade.
        
        Returns:
            Dict com status de cada nível
        """
        
        test_messages = [{"role": "user", "content": "Responda apenas: 'Teste OK'"}]
        results = {}
        
        # Testar cada nível individualmente
        levels = [
            ("Nível 1: OpenRouter Gateway", self._try_openrouter_grok),
            ("Nível 2: xai-sdk Oficial", self._try_xai_sdk_official),
            ("Nível 3: LangChain-XAI", self._try_langchain_xai),
            ("Nível 4: Cascata Tradicional", self._try_traditional_cascade)
        ]
        
        for level_name, level_func in levels:
            try:
                if level_name == "Nível 2: xai-sdk Oficial":
                    result = await level_func(test_messages, None, False)  # sem streaming
                elif level_name == "Nível 4: Cascata Tradicional":
                    result = await level_func(test_messages, None)
                else:
                    result = await level_func(test_messages, None)
                
                if result:
                    results[level_name] = {
                        "status": "✅ Disponível",
                        "model": result.model_used,
                        "time": f"{result.processing_time:.3f}s",
                        "sdk": result.sdk_name
                    }
                else:
                    results[level_name] = {
                        "status": "❌ Falhou",
                        "error": "Retornou None"
                    }
                    
            except Exception as e:
                results[level_name] = {
                    "status": "❌ Erro",
                    "error": str(e)
                }
        
        return results
    
    def get_sdk_status(self) -> Dict[str, bool]:
        """Retorna status de disponibilidade dos 3 SDKs essenciais."""
        return {
            "openrouter_client": self.openrouter_client is not None,
            "xai_sdk_official": self.xai_sdk_client is not None,
            "langchain_xai": self.langchain_xai_client is not None,
            "xai_sdk_available": XAI_SDK_AVAILABLE,
            "langchain_xai_available": LANGCHAIN_XAI_AVAILABLE
        }


# Factory function para fácil uso
def get_grok_sdk_service(config: Optional[GrokSDKConfig] = None) -> GrokSDKIntegrationService:
    """Factory function para criar instância do serviço."""
    return GrokSDKIntegrationService(config)


if __name__ == "__main__":
    # Teste básico
    async def test_basic():
        service = get_grok_sdk_service()
        
        print("🔍 Status dos 3 SDKs Essenciais:")
        status = service.get_sdk_status()
        for sdk, available in status.items():
            print(f"   {'✅' if available else '❌'} {sdk}")
        
        print("\n🧪 Testando todos os níveis:")
        results = await service.test_all_levels()
        for level, result in results.items():
            print(f"   {result['status']} {level}")
            if "model" in result:
                print(f"      🤖 Modelo: {result['model']} ({result['time']})")
            elif "error" in result:
                print(f"      ❌ Erro: {result['error']}")
    
    asyncio.run(test_basic()) 
 
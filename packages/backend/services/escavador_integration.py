#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
services/escavador_integration.py

Serviço para integração com a API do Escavador.
- Usa o SDK oficial do Escavador (V1 e V2) para todas as operações.
- Extrai processos por OAB com paginação completa.
- Inclui um classificador de NLP para determinar o resultado dos processos.
- Acesso aos autos de processos com certificado digital via SDK V1.
- Atualização de processos via SDK V2.
"""

import asyncio
import logging
import os
import re
from typing import Any, Dict, List, Optional

import httpx  # Apenas para download de documentos
from fastapi import HTTPException

# Tentar importar dependências externas e fornecer instruções claras se falhar
try:
    import escavador
    from dotenv import load_dotenv
    from escavador import CriterioOrdenacao, Ordem
    from escavador.exceptions import ApiKeyNotFoundException, FailedRequest
    from escavador.v2 import Processo as ProcessoV2
    from escavador.v1 import Pessoa, Processo as ProcessoV1, BuscaAssincrona
except ImportError as e:
    print(f"Erro: Dependência não instalada: {e.name}")
    print("Por favor, execute: pip install escavador python-dotenv")
    exit(1)

# Carregar variáveis de ambiente
load_dotenv()

# Import do serviço de cache (pode falhar se não existir ainda)
try:
    from services.process_cache_service import process_cache_service
    CACHE_ENABLED = True
except ImportError:
    logger.warning("Serviço de cache não disponível - funcionando sem cache")
    process_cache_service = None
    CACHE_ENABLED = False

# Configuração
ESCAVADOR_API_KEY = os.getenv("ESCAVADOR_API_KEY")

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class OutcomeClassifier:
    """
    Classifica o resultado de um processo (vitória/derrota) com base no texto
    das suas movimentações, usando NLP e heurísticas jurídicas.
    """

    # Padrões mais fortes para vitória (indicam ganho de causa)
    VICTORY_PATTERNS = [
        r"julgo\s+procedente",
        r"sentença\s+de\s+procedência",
        r"provimento\s+ao\s+recurso\s+do\s+autor",
        r"recurso\s+do\s+reclamante\s+provido",
        r"condeno\s+a\s+ré",
        r"acordo\s+homologado",
        r"embargos\s+à\s+execução\s+julgados\s+improcedentes",
    ]

    # Padrões mais fortes para derrota (indicam perda de causa)
    DEFEAT_PATTERNS = [
        r"julgo\s+improcedente",
        r"sentença\s+de\s+improcedência",
        r"nego\s+provimento\s+ao\s+recurso",
        r"recurso\s+não\s+conhecido",
        r"extinção\s+do\s+processo\s+sem\s+resolução\s+do\s+mérito",
        r"mantida\s+a\s+sentença\s+de\s+improcedência",
    ]

    # Padrões que indicam processo em andamento
    ONGOING_PATTERNS = [
        r"audiência\s+designada",
        r"citação\s+expedida",
        r"concluso\s+para\s+despacho",
        r"prazo\s+em\s+curso",
        r"juntada\s+de\s+petição",
    ]

    def __init__(self):
        self.victory_regex = [re.compile(p, re.IGNORECASE | re.DOTALL)
                              for p in self.VICTORY_PATTERNS]
        self.defeat_regex = [re.compile(p, re.IGNORECASE | re.DOTALL)
                             for p in self.DEFEAT_PATTERNS]
        self.ongoing_regex = [re.compile(p, re.IGNORECASE | re.DOTALL)
                              for p in self.ONGOING_PATTERNS]

    def classify(self, movements: List[str]) -> Optional[bool]:
        """
        Classifica o resultado de um processo.

        Args:
            movements: Lista de textos das movimentações do processo.

        Returns:
            True se for vitória, False se for derrota, None se estiver em andamento.
        """
        full_text = " ".join(movements).lower()

        # Verificar padrões de vitória
        for pattern in self.victory_regex:
            if pattern.search(full_text):
                logger.debug(f"Vitória detectada pelo padrão: {pattern.pattern}")
                return True

        # Verificar padrões de derrota
        for pattern in self.defeat_regex:
            if pattern.search(full_text):
                logger.debug(f"Derrota detectada pelo padrão: {pattern.pattern}")
                return False

        # Verificar padrões de andamento
        for pattern in self.ongoing_regex:
            if pattern.search(full_text):
                logger.debug(f"Em andamento detectado pelo padrão: {pattern.pattern}")
                return None

        # Se nenhuma regra forte foi acionada, retorna em andamento por padrão
        return None


class EscavadorClient:
    """Cliente para a API do Escavador usando o SDK oficial."""

    def __init__(self, api_key: str):
        if not api_key:
            raise ValueError("API Key do Escavador não fornecida.")
        try:
            escavador.config(api_key)
            self.api_key = api_key
        except ApiKeyNotFoundException:
            raise ValueError(
                "Chave da API do Escavador inválida ou não encontrada no .env")

        self.classifier = OutcomeClassifier()

    async def request_process_update(self, cnj: str, download_docs: bool = False) -> Dict[str, Any]:
        """
        Solicita a atualização de um processo nos sistemas dos Tribunais.
        Usa o SDK oficial V2 do Escavador.
        """
        logger.info(f"Solicitando atualização do processo CNJ: {cnj}")
        
        def _call_sdk():
            """Função síncrona para chamar o SDK."""
            try:
                resultado = ProcessoV2.solicitar_atualizacao(
                    numero_cnj=cnj,
                    enviar_callback=0,  # Para este fluxo, vamos gerenciar por status check
                    documentos_publicos=1 if download_docs else 0
                )
                # Converter o objeto do SDK para dict
                return {
                    "id": resultado.id,
                    "status": resultado.status,
                    "criado_em": resultado.criado_em.isoformat() if resultado.criado_em else None,
                    "concluido_em": resultado.concluido_em.isoformat() if resultado.concluido_em else None
                }
            except FailedRequest as e:
                logger.error(f"Erro na requisição ao solicitar atualização do CNJ {cnj}: {e}")
                raise HTTPException(status_code=400, detail=str(e))
            except Exception as e:
                logger.error(f"Erro inesperado ao solicitar atualização do CNJ {cnj}: {e}")
                raise HTTPException(status_code=500, detail="Erro interno ao processar a solicitação.")
        
        # Executar em thread separada para não bloquear o event loop
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(None, _call_sdk)

    async def get_process_update_status(self, cnj: str) -> Dict[str, Any]:
        """
        Retorna o status de uma solicitação de atualização de um processo.
        Usa o SDK oficial V2 do Escavador.
        """
        logger.info(f"Consultando status de atualização do processo CNJ: {cnj}")
        
        def _call_sdk():
            """Função síncrona para chamar o SDK."""
            try:
                resultado = ProcessoV2.status_atualizacao(numero_cnj=cnj)
                # Converter o objeto do SDK para dict
                response_data = {
                    "numero_cnj": resultado.numero_cnj,
                    "data_ultima_verificacao": resultado.data_ultima_verificacao.isoformat() if resultado.data_ultima_verificacao else None,
                    "tempo_desde_ultima_verificacao": resultado.tempo_desde_ultima_verificacao,
                    "ultima_verificacao": None
                }
                
                # Se houver uma verificação em andamento/concluída
                if hasattr(resultado, 'ultima_verificacao') and resultado.ultima_verificacao:
                    response_data["ultima_verificacao"] = {
                        "id": resultado.ultima_verificacao.id,
                        "status": resultado.ultima_verificacao.status,
                        "criado_em": resultado.ultima_verificacao.criado_em.isoformat() if resultado.ultima_verificacao.criado_em else None,
                        "concluido_em": resultado.ultima_verificacao.concluido_em.isoformat() if resultado.ultima_verificacao.concluido_em else None
                    }
                
                return response_data
            except FailedRequest as e:
                logger.error(f"Erro na requisição ao consultar status do CNJ {cnj}: {e}")
                raise HTTPException(status_code=400, detail=str(e))
            except Exception as e:
                logger.error(f"Erro inesperado ao consultar status do CNJ {cnj}: {e}")
                raise HTTPException(status_code=500, detail="Erro interno ao processar a solicitação.")
        
        # Executar em thread separada para não bloquear o event loop
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(None, _call_sdk)

    async def request_case_files_with_certificate(
        self, cnj: str, certificate_id: Optional[int] = None, 
        send_callback: bool = True
    ) -> Dict[str, Any]:
        """
        Solicita acesso aos autos de um processo utilizando certificado digital.
        Usa o SDK oficial V1 do Escavador.
        
        Esta funcionalidade permite que advogados com certificados digitais cadastrados
        no painel do Escavador acessem os autos completos dos processos diretamente
        dos sistemas dos tribunais.
        
        Args:
            cnj: Número CNJ do processo
            certificate_id: ID do certificado específico (opcional - usa o padrão se None)
            send_callback: Se deve enviar callback quando concluído
            
        Returns:
            Dict com informações da solicitação assíncrona
            
        Raises:
            ValueError: Se os parâmetros estão inválidos
            HTTPException: Se houve erro na API
        """
        if not cnj or not cnj.strip():
            raise ValueError("CNJ é obrigatório")
        
        logger.info(f"Solicitando autos com certificado digital para CNJ: {cnj}")
        
        def _call_sdk():
            """Função síncrona para chamar o SDK."""
            try:
                processo_v1 = ProcessoV1()
                resultado = processo_v1.informacoes_no_tribunal(
                    numero_unico=cnj.strip(),
                    send_callback=send_callback,
                    utilizar_certificado=True,  # Sempre usar certificado digital
                    certificado_id=certificate_id,  # Certificado específico (opcional)
                    documentos_publicos=True,  # Incluir documentos públicos
                    wait=False  # Não esperar, retornar ID assíncrono
                )
                
                logger.info(f"Solicitação de autos com certificado enviada para CNJ {cnj}")
                return resultado
                
            except FailedRequest as e:
                logger.error(f"Erro na requisição ao solicitar autos do CNJ {cnj}: {e}")
                # Mapear códigos de erro comuns
                error_message = str(e)
                if "401" in error_message or "unauthorized" in error_message.lower():
                    raise HTTPException(status_code=401, detail="API Key inválida ou certificado não autorizado")
                elif "404" in error_message or "not found" in error_message.lower():
                    raise HTTPException(status_code=404, detail=f"Processo {cnj} não encontrado")
                elif "403" in error_message or "forbidden" in error_message.lower():
                    raise HTTPException(status_code=403, detail="Acesso negado - verifique se o certificado está válido e cadastrado")
                else:
                    raise HTTPException(status_code=400, detail=str(e))
            except Exception as e:
                logger.error(f"Erro inesperado ao solicitar autos do CNJ {cnj}: {e}")
                raise HTTPException(status_code=500, detail="Erro interno ao processar a solicitação.")
        
        # Executar em thread separada para não bloquear o event loop
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(None, _call_sdk)

    async def get_case_files_status(self, async_id: str) -> Dict[str, Any]:
        """
        Consulta o status de uma solicitação assíncrona de autos.
        Usa o SDK oficial V1 do Escavador.
        
        Args:
            async_id: ID da solicitação assíncrona retornado pelo request_case_files_with_certificate
            
        Returns:
            Dict com status da solicitação e dados (se concluída)
        """
        if not async_id or not async_id.strip():
            raise ValueError("ID da solicitação assíncrona é obrigatório")
        
        logger.info(f"Consultando status da solicitação assíncrona: {async_id}")
        
        def _call_sdk():
            """Função síncrona para chamar o SDK."""
            try:
                # Converter async_id para int se necessário
                async_id_int = int(async_id.strip()) if async_id.strip().isdigit() else async_id.strip()
                
                busca_assincrona = BuscaAssincrona()
                result = busca_assincrona.por_id(id=async_id_int)
                
                # Log do status atual
                status = result.get('resposta', {}).get('status', 'DESCONHECIDO')
                logger.info(f"Status da solicitação {async_id}: {status}")
                
                return result
                
            except FailedRequest as e:
                logger.error(f"Erro na requisição ao consultar status da solicitação {async_id}: {e}")
                raise HTTPException(status_code=400, detail=str(e))
            except ValueError as e:
                logger.error(f"ID da solicitação inválido {async_id}: {e}")
                raise HTTPException(status_code=400, detail=f"ID da solicitação inválido: {async_id}")
            except Exception as e:
                logger.error(f"Erro inesperado ao consultar status da solicitação {async_id}: {e}")
                raise HTTPException(status_code=500, detail="Erro interno ao processar a solicitação.")
        
        # Executar em thread separada para não bloquear o event loop
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(None, _call_sdk)

    async def download_case_files(
        self, cnj: str, async_id: str, output_directory: str = "./downloads"
    ) -> Dict[str, Any]:
        """
        Baixa os arquivos dos autos de um processo após a conclusão da solicitação.
        
        Args:
            cnj: Número CNJ do processo
            async_id: ID da solicitação assíncrona
            output_directory: Diretório onde salvar os arquivos
            
        Returns:
            Dict com informações dos arquivos baixados
        """
        # Primeiro, verificar se a solicitação foi concluída
        status_result = await self.get_case_files_status(async_id)
        
        if status_result.get('resposta', {}).get('status') != 'SUCESSO':
            raise ValueError(f"Solicitação ainda não foi concluída. Status: {status_result.get('resposta', {}).get('status')}")
        
        # Extrair informações dos documentos disponíveis
        resposta_data = status_result.get('resposta', {}).get('resposta', {})
        
        os.makedirs(output_directory, exist_ok=True)
        downloaded_files = []
        
        # Processar instâncias e documentos
        for instancia in resposta_data.get('instancias', []):
            for doc in instancia.get('documentos', []):
                if doc.get('url_download'):
                    try:
                        file_info = await self._download_document(
                            doc['url_download'], 
                            cnj, 
                            doc.get('nome', 'documento'), 
                            output_directory
                        )
                        downloaded_files.append(file_info)
                    except Exception as e:
                        logger.error(f"Erro ao baixar documento {doc.get('nome')}: {e}")
        
        return {
            "cnj": cnj,
            "async_id": async_id,
            "total_files": len(downloaded_files),
            "downloaded_files": downloaded_files,
            "output_directory": output_directory
        }

    async def _download_document(
        self, download_url: str, cnj: str, doc_name: str, output_dir: str
    ) -> Dict[str, Any]:
        """
        Baixa um documento específico.
        """
        # Sanitizar nome do arquivo
        safe_filename = re.sub(r'[<>:"/\\|?*]', '_', f"{cnj}_{doc_name}")
        if not safe_filename.endswith('.pdf'):
            safe_filename += '.pdf'
            
        file_path = os.path.join(output_dir, safe_filename)
        
        # Headers necessários para download de documentos
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "X-Requested-With": "XMLHttpRequest",
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(download_url, headers=headers, timeout=120)
            response.raise_for_status()
            
            with open(file_path, 'wb') as f:
                f.write(response.content)
                
            file_size = len(response.content)
            logger.info(f"Documento baixado: {safe_filename} ({file_size} bytes)")
            
            return {
                "filename": safe_filename,
                "file_path": file_path,
                "size_bytes": file_size,
                "document_name": doc_name
            }

    async def get_detailed_process_movements(self, cnj: str, limit: int = 50, force_refresh: bool = False) -> Dict[str, Any]:
        """
        Busca movimentações detalhadas de um processo específico.
        
        Usa cache inteligente para evitar reconsultas constantes:
        1. Primeiro tenta Redis (1h TTL)
        2. Depois tenta banco PostgreSQL (24h TTL)  
        3. Por último consulta API Escavador
        4. Funciona offline com dados do banco
        
        Args:
            cnj: Número CNJ do processo
            limit: Máximo de movimentações a retornar
            force_refresh: Se True, ignora cache e busca dados frescos da API
            
        Returns:
            Dados formatados para exibição em linha do tempo no frontend
        """
        logger.info(f"Buscando movimentações detalhadas do processo CNJ: {cnj} (cache={'disabled' if force_refresh else 'enabled'})")
        
        # Se cache está habilitado, usar o serviço de cache
        if CACHE_ENABLED and process_cache_service and not force_refresh:
            try:
                movements_data, source = await process_cache_service.get_process_movements_cached(
                    cnj, limit, force_refresh
                )
                logger.info(f"Movimentações obtidas do cache ({source}) para CNJ: {cnj}")
                return movements_data
            except Exception as e:
                logger.warning(f"Erro no cache para CNJ {cnj}, fallback para API: {e}")
        
        # Fallback direto para API (implementação original)
        return await self._get_movements_from_api_direct(cnj, limit)
    
    async def _get_movements_from_api_direct(self, cnj: str, limit: int = 50) -> Dict[str, Any]:
        """
        Implementação original que busca dados diretamente da API do Escavador.
        Usado como fallback quando cache não está disponível.
        """
        try:
            from routes.process_movements import MovementClassifier
            classifier = MovementClassifier()
            
            # Buscar movimentações via SDK V2
            all_movements = []
            
            def _sync_call():
                """Função síncrona para chamada do SDK."""
                try:
                    movs_result = ProcessoV2.movimentacoes(cnj)
                    movements_list = []
                    
                    while movs_result and len(movements_list) < limit:
                        movements_list.extend(movs_result)
                        if len(movements_list) >= limit:
                            break
                        try:
                            movs_result = movs_result.continuar_busca()
                        except:
                            break  # Não há mais páginas
                    
                    return movements_list[:limit]
                except Exception as e:
                    logger.error(f"Erro na chamada síncrona para CNJ {cnj}: {e}")
                    return []
            
            # Executar chamada síncrona em thread separada
            loop = asyncio.get_running_loop()
            movements = await loop.run_in_executor(None, _sync_call)
            
            if not movements:
                raise HTTPException(status_code=404, detail=f"Nenhuma movimentação encontrada para o processo {cnj}")
            
            # Processar e classificar movimentações
            processed_movements = []
            for i, movement in enumerate(movements):
                classification = classifier.classify_movement(movement.conteudo)
                
                processed_movement = {
                    "id": f"mov_{i+1}",
                    "name": classification["description"],
                    "description": movement.conteudo[:200] + "..." if len(movement.conteudo) > 200 else movement.conteudo,
                    "full_content": movement.conteudo,
                    "type": classification["type"],
                    "icon": classification["icon"],
                    "color": classification["color"],
                    "date": getattr(movement, 'data', None),
                    "source": {
                        "tribunal": getattr(movement.fonte, 'tribunal', {}).get('nome', 'N/A') if hasattr(movement, 'fonte') and movement.fonte else 'N/A',
                        "grau": getattr(movement.fonte, 'grau_formatado', 'N/A') if hasattr(movement, 'fonte') and movement.fonte else 'N/A'
                    },
                    "classification": getattr(movement, 'classificacao_predita', None),
                    "is_completed": True,  # Movimentações já ocorridas estão completas
                    "is_current": i == 0,  # Primeira movimentação é a mais recente
                    "completed_at": getattr(movement, 'data', None),
                    "documents": []  # Documentos específicos podem ser adicionados depois
                }
                
                processed_movements.append(processed_movement)
            
            # Calcular progresso baseado no outcome
            outcome = self.classifier.classify([m.conteudo for m in movements[:10]])  # Análise das 10 mais recentes
            
            if outcome == "vitoria":
                progress = 100.0
                current_phase = "Processo Finalizado - Resultado Favorável"
            elif outcome == "derrota":
                progress = 100.0
                current_phase = "Processo Finalizado - Resultado Desfavorável"
            else:
                # Em andamento - calcular progresso baseado nos tipos de movimentação
                phase_indicators = [m for m in processed_movements if m["type"] in ["DECISAO", "SENTENCA"]]
                if phase_indicators:
                    progress = 80.0
                    current_phase = "Aguardando Decisão Final"
                elif any(m["type"] == "AUDIENCIA" for m in processed_movements):
                    progress = 60.0
                    current_phase = "Fase de Instrução"
                else:
                    progress = 30.0
                    current_phase = "Fase Inicial"
            
            result = {
                "cnj": cnj,
                "total_movements": len(movements),
                "shown_movements": len(processed_movements),
                "current_phase": current_phase,
                "progress_percentage": progress,
                "outcome": outcome,
                "movements": processed_movements,
                "last_update": movements[0].data if movements and hasattr(movements[0], 'data') else None,
                "tribunal_info": {
                    "name": movements[0].fonte.tribunal.get('nome', 'N/A') if movements and hasattr(movements[0], 'fonte') and movements[0].fonte else 'N/A',
                    "grau": movements[0].fonte.grau_formatado if movements and hasattr(movements[0], 'fonte') and movements[0].fonte else 'N/A'
                } if movements else {"name": "N/A", "grau": "N/A"}
            }
            
            # Salvar no cache se habilitado
            if CACHE_ENABLED and process_cache_service:
                try:
                    await process_cache_service._save_to_database(cnj, result)
                    await process_cache_service._save_to_redis(cnj, result)
                    logger.info(f"Dados salvos no cache para CNJ: {cnj}")
                except Exception as e:
                    logger.warning(f"Erro ao salvar no cache para CNJ {cnj}: {e}")
            
            return result
            
        except FailedRequest as e:
            logger.error(f"Erro na API do Escavador ao buscar movimentações do CNJ {cnj}: {e}")
            raise HTTPException(status_code=e.response.status_code, detail=str(e))
        except Exception as e:
            logger.error(f"Erro inesperado ao buscar movimentações do CNJ {cnj}: {e}")
            raise HTTPException(status_code=500, detail="Erro interno ao processar movimentações.")

    async def get_process_status_summary(self, cnj: str, force_refresh: bool = False) -> Dict[str, Any]:
        """
        Retorna um resumo do status do processo formatado para o frontend.
        
        Usa cache inteligente - primeiro tenta cache de status, depois gera
        baseado nas movimentações cached. Funciona offline.
        
        Converte dados do Escavador para o formato EXATO esperado pelo ProcessStatusSection.
        """
        logger.info(f"Buscando resumo de status do processo CNJ: {cnj} (cache={'disabled' if force_refresh else 'enabled'})")
        
        # Se cache está habilitado, tentar obter status cached primeiro
        if CACHE_ENABLED and process_cache_service and not force_refresh:
            try:
                status_data, source = await process_cache_service.get_process_status_cached(
                    cnj, force_refresh
                )
                logger.info(f"Status obtido do cache ({source}) para CNJ: {cnj}")
                return status_data
            except Exception as e:
                logger.warning(f"Erro no cache de status para CNJ {cnj}, gerando novo: {e}")
        
        try:
            # Buscar dados detalhados (que já usa cache)
            detailed_data = await self.get_detailed_process_movements(cnj, limit=20, force_refresh=force_refresh)
            movements = detailed_data.get("movements", [])
            outcome = detailed_data.get("outcome", "andamento")
            
            # Mapear fases baseado nas movimentações reais do Escavador
            phases = []
            current_phase_name = "Em Andamento"
            progress = detailed_data.get("progress_percentage", 0.0)
            
            # Criar fases baseadas nas movimentações encontradas
            if movements:
                # Agrupar movimentações por tipo
                movement_groups = {}
                for movement in movements:
                    mov_type = movement["type"]
                    if mov_type not in movement_groups:
                        movement_groups[mov_type] = []
                    movement_groups[mov_type].append(movement)
                
                # Definir ordem cronológica de fases processuais (SEM documentos - são tratados em aba separada)
                phase_mapping = {
                    "PETICAO": {
                        "name": "Petição Inicial",
                        "description": "Apresentação formal da causa à justiça."
                    },
                    "CITACAO": {
                        "name": "Citação das Partes", 
                        "description": "Notificação das partes envolvidas no processo."
                    },
                    "JUNTADA": {
                        "name": "Juntada de Documentos",
                        "description": "Documentos anexados aos autos do processo."
                    },
                    "AUDIENCIA": {
                        "name": "Audiência de Conciliação",
                        "description": "Tentativa de acordo amigável entre as partes."
                    },
                    "CONCLUSAO": {
                        "name": "Conclusão para Decisão",
                        "description": "Processo concluso para julgamento."
                    },
                    "DECISAO": {
                        "name": "Decisão Judicial",
                        "description": "Sentença ou decisão proferida pelo juiz."
                    }
                }
                
                # Criar fases baseadas no que foi encontrado
                phase_order = ["PETICAO", "CITACAO", "JUNTADA", "AUDIENCIA", "CONCLUSAO", "DECISAO"]
                current_phase_index = -1
                
                for i, phase_type in enumerate(phase_order):
                    if phase_type in movement_groups:
                        current_phase_index = i
                        phase_info = phase_mapping[phase_type]
                        latest_movement = movement_groups[phase_type][0]  # Mais recente
                        
                        # Determinar se a fase está completa
                        is_completed = True
                        is_current = False
                        completed_at = latest_movement.get("completed_at")
                        
                        phases.append({
                            "name": phase_info["name"],
                            "description": phase_info["description"],
                            "is_completed": is_completed,
                            "is_current": is_current,
                            "completed_at": completed_at,
                            "documents": []  # Documentos são tratados em aba separada
                        })
                
                # Determinar fase atual e progresso baseado no outcome
                if outcome == "vitoria":
                    current_phase_name = "Processo Finalizado - Resultado Favorável"
                    progress = 100.0
                elif outcome == "derrota": 
                    current_phase_name = "Processo Finalizado - Resultado Desfavorável"
                    progress = 100.0
                else:
                    # Em andamento - determinar fase atual
                    if current_phase_index >= 0:
                        if current_phase_index < len(phases):
                            phases[current_phase_index]["is_current"] = True
                            current_phase_name = phases[current_phase_index]["name"]
                    
                    # Calcular progresso baseado na fase atual
                    if current_phase_index >= 0:
                        progress = min(90.0, (current_phase_index + 1) * 100.0 / len(phase_order))
                    else:
                        progress = 15.0  # Processo muito inicial
                        current_phase_name = "Processo Iniciado"
            
            # Se não há movimentações, criar fase padrão
            if not phases:
                phases.append({
                    "name": "Processo Iniciado", 
                    "description": "Processo protocolado no sistema judiciário",
                    "is_completed": True,
                    "is_current": True,
                    "completed_at": detailed_data.get("last_update"),
                    "documents": []
                })
                current_phase_name = "Aguardando Andamento"
                progress = 10.0
            
            # Criar descrição dinâmica baseada no outcome
            if outcome == "vitoria":
                description = f"Processo {cnj} finalizado com resultado FAVORÁVEL. Parabéns!"
            elif outcome == "derrota":
                description = f"Processo {cnj} finalizado. Consulte seu advogado sobre possíveis recursos."
            else:
                current_phase_desc = phases[-1]["name"] if phases else "andamento inicial"
                description = f"Seu processo está avançando conforme o planejado. A fase atual é {current_phase_desc.lower()}."
            
            return {
                "current_phase": current_phase_name,
                "description": description,
                "progress_percentage": progress,
                "phases": phases[:3],  # Frontend mostra máximo 3 fases
                "cnj": cnj,
                "tribunal": detailed_data.get("tribunal_info", {}),
                "total_movements": detailed_data.get("total_movements", 0),
                "last_update": detailed_data.get("last_update"),
                "outcome": outcome
            }
            
        except HTTPException as e:
            raise e
        except Exception as e:
            logger.error(f"Erro inesperado ao gerar resumo do processo {cnj}: {e}")
            raise HTTPException(status_code=500, detail="Erro interno ao gerar resumo do processo.")

    async def get_lawyer_processes(
            self, oab_number: str, state: str) -> Optional[Dict[str, Any]]:
        """
        Busca todos os processos de um advogado pela OAB, classifica-os
        e retorna estatísticas detalhadas, com paginação completa.
        """

        def search_and_classify() -> Optional[Dict[str, Any]]:
            """Função síncrona para ser executada em uma thread separada."""
            try:
                # API V2 para buscar processos por OAB
                advogado, processos = ProcessoV2.por_oab(
                    numero=oab_number,
                    estado=state,
                    ordena_por=CriterioOrdenacao.ULTIMA_MOVIMENTACAO,
                    ordem=Ordem.DESC
                )

                stats: Dict[str, Any] = {
                    "total_cases": 0, "victories": 0, "defeats": 0,
                    "ongoing": 0, "success_rate": 0.0,
                    "area_distribution": {}, "processed_cases": []
                }

                if not advogado or not processos:
                    return stats

                all_processes = []
                while processos:
                    all_processes.extend(processos)
                    processos = processos.continuar_busca()

                stats["total_cases"] = len(all_processes)

                for proc in all_processes:
                    # Obter movimentações com paginação
                    all_movements = []
                    movs_result = ProcessoV2.movimentacoes(proc.numero_cnj)
                    while movs_result:
                        all_movements.extend(movs_result)
                        movs_result = movs_result.continuar_busca()

                    movs_text = [m.conteudo for m in all_movements]

                    outcome = self.classifier.classify(movs_text)

                    area = proc.area or "Não informada"
                    stats["area_distribution"][area] = stats["area_distribution"].get(
                        area, 0) + 1

                    case_data = {
                        "cnj": proc.numero_cnj,
                        "area": area,
                        "outcome": outcome,
                        "last_update": proc.data_ultima_movimentacao,
                        "movements_count": len(all_movements)
                    }
                    stats["processed_cases"].append(case_data)

                    if outcome is True:
                        stats["victories"] += 1
                    elif outcome is False:
                        stats["defeats"] += 1
                    else:
                        stats["ongoing"] += 1

                # Calcular taxa de sucesso sobre casos concluídos
                concluded_cases = stats["victories"] + stats["defeats"]
                if concluded_cases > 0:
                    stats["success_rate"] = stats["victories"] / concluded_cases

                return stats

            except FailedRequest:
                logger.error("Credenciais da API do Escavador são inválidas.")
                raise
            except Exception as e:
                logger.error(f"Erro ao buscar dados no Escavador: {e}")
                return None

        loop = asyncio.get_running_loop()
        result = await loop.run_in_executor(None, search_and_classify)
        return result

    async def get_person_details(self, person_id: int) -> Optional[Dict[str, Any]]:
        """
        Busca os detalhes de uma pessoa, incluindo o Currículo Lattes.

        Args:
            person_id: ID da pessoa no Escavador.

        Returns:
            Dicionário com os dados da pessoa ou None em caso de erro.
        """
        logger.debug(f"Buscando detalhes da pessoa ID: {person_id}")
        try:
            loop = asyncio.get_running_loop()
            
            # A API V1 do SDK não é async, então executamos em um executor
            pessoa_result = await loop.run_in_executor(
                None,  # usa o executor padrão
                lambda: Pessoa.por_id(id_pessoa=person_id)
            )
            
            if not pessoa_result:
                logger.warning(f"Nenhum detalhe encontrado para a pessoa ID: {person_id}")
                return None
            
            # O SDK retorna um objeto, então convertemos para dicionário
            return pessoa_result.to_dict() if hasattr(pessoa_result, 'to_dict') else vars(pessoa_result)

        except FailedRequest as e:
            logger.error(f"Falha na requisição para detalhes da pessoa ID {person_id}: {e.message}")
            if e.message and 'not found' in e.message.lower():
                raise HTTPException(status_code=404, detail=f"Pessoa com ID {person_id} não encontrada.")
            raise HTTPException(status_code=502, detail=f"Erro na API do Escavador: {e.message}")
        except Exception as e:
            logger.error(f"Erro inesperado ao buscar detalhes da pessoa ID {person_id}: {e}")
            return None

    async def get_curriculum_data(self, person_name: str, oab_number: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        Busca dados de currículo completos de uma pessoa usando nome e OAB.
        
        Args:
            person_name: Nome completo da pessoa
            oab_number: Número da OAB (opcional, melhora precisão)
            
        Returns:
            Dicionário estruturado com dados do currículo ou None se não encontrado
        """
        logger.info(f"Buscando currículo para: {person_name}")
        
        try:
            loop = asyncio.get_running_loop()
            
            # Primeira etapa: buscar a pessoa por nome
            pessoas = await loop.run_in_executor(
                None,
                lambda: Pessoa.buscar(termo=person_name, limit=5)
            )
            
            if not pessoas or not pessoas.get('items'):
                logger.warning(f"Nenhuma pessoa encontrada com nome: {person_name}")
                return None
            
            # Filtrar por OAB se fornecido
            target_person = None
            for pessoa in pessoas['items']:
                if oab_number:
                    # Verificar se a OAB coincide
                    oab_numeros = pessoa.get('oab_numero', [])
                    if any(oab_number in str(oab) for oab in oab_numeros):
                        target_person = pessoa
                        break
                else:
                    # Usar primeiro resultado se não há OAB
                    target_person = pessoa
                    break
            
            if not target_person:
                logger.warning(f"Pessoa não encontrada com critérios: {person_name}, OAB: {oab_number}")
                return None
            
            person_id = target_person.get('id')
            if not person_id:
                logger.warning(f"ID da pessoa não encontrado: {target_person}")
                return None
            
            # Segunda etapa: buscar detalhes completos incluindo currículo
            person_details = await self.get_person_details(person_id)
            
            if not person_details:
                return None
            
            # Estruturar dados de currículo para o algoritmo
            return self._structure_curriculum_data(person_details)
            
        except Exception as e:
            logger.error(f"Erro ao buscar currículo para {person_name}: {e}")
            return None
    
    def _structure_curriculum_data(self, person_details: Dict[str, Any]) -> Dict[str, Any]:
        """
        Estrutura os dados brutos do Escavador no formato esperado pelo algoritmo.
        
        Args:
            person_details: Dados brutos da API do Escavador
            
        Returns:
            Dicionário estruturado para o algoritmo de matching
        """
        curriculo_lattes = person_details.get('curriculo_lattes', {})
        
        if not curriculo_lattes:
            # Retornar estrutura básica se não há currículo Lattes
            return {
                'anos_experiencia': 0,
                'pos_graduacoes': [],
                'publicacoes': [],
                'num_publicacoes': 0,
                'areas_de_atuacao': person_details.get('areas_atuacao', ''),
                'fonte': 'escavador_basic',
                'tem_curriculo': False
            }
        
        # Extrair anos de experiência
        anos_exp = self._calculate_experience_years(curriculo_lattes)
        
        # Extrair pós-graduações
        pos_graduacoes = self._extract_postgraduate_degrees(curriculo_lattes)
        
        # Extrair publicações
        publicacoes = self._extract_publications(curriculo_lattes)
        
        # Extrair dados adicionais do currículo
        dados_adicionais = self._extract_additional_data(curriculo_lattes)
        
        # Estruturar resposta final
        structured_data = {
            'anos_experiencia': anos_exp,
            'pos_graduacoes': pos_graduacoes,
            'publicacoes': publicacoes,
            'num_publicacoes': len(publicacoes),
            'areas_de_atuacao': curriculo_lattes.get('areas_de_atuacao', ''),
            'resumo': curriculo_lattes.get('resumo', ''),
            'nome_em_citacoes': curriculo_lattes.get('nome_em_citacoes', ''),
            'ultima_atualizacao': curriculo_lattes.get('ultima_atualizacao', ''),
            'lattes_id': curriculo_lattes.get('lattes_id', ''),
            'fonte': 'escavador_lattes',
            'tem_curriculo': True,
            # Dados adicionais do Escavador
            'oab_numero': person_details.get('oab_numero', []),
            'quantidade_processos': person_details.get('quantidade_processos', 0),
            'tem_processo': person_details.get('tem_processo', 0) == 1,
            # 🆕 Dados adicionais do currículo Lattes
            'projetos_pesquisa': dados_adicionais.get('projetos_pesquisa', []),
            'premios': dados_adicionais.get('premios', []),
            'idiomas': dados_adicionais.get('idiomas', []),
            'eventos': dados_adicionais.get('eventos', [])
        }
        
        logger.info(f"Currículo estruturado - {anos_exp} anos exp, {len(pos_graduacoes)} títulos, {len(publicacoes)} publicações")
        
        return structured_data
    
    def _calculate_experience_years(self, curriculo_lattes: Dict[str, Any]) -> int:
        """Calcula anos de experiência baseado no currículo Lattes."""
        try:
            # Tentar buscar em atuações profissionais
            atuacoes = curriculo_lattes.get('atuacoes_profissionais', [])
            if atuacoes:
                anos_min = float('inf')
                for atuacao in atuacoes:
                    ano_inicio = atuacao.get('ano_inicio')
                    if ano_inicio:
                        anos_min = min(anos_min, int(ano_inicio))
                
                if anos_min != float('inf'):
                    from datetime import datetime
                    return max(0, datetime.now().year - anos_min)
            
            # Fallback: usar formações
            formacoes = curriculo_lattes.get('formacoes', [])
            if formacoes:
                # Buscar primeira graduação
                for formacao in formacoes:
                    if formacao.get('tipo', '').lower() in ['graduacao', 'bacharelado']:
                        ano_fim = formacao.get('ano_fim')
                        if ano_fim:
                            from datetime import datetime
                            return max(0, datetime.now().year - int(ano_fim))
            
            return 0
            
        except (ValueError, TypeError):
            return 0
    
    def _extract_postgraduate_degrees(self, curriculo_lattes: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Extrai títulos de pós-graduação do currículo Lattes."""
        pos_graduacoes = []
        
        try:
            formacoes = curriculo_lattes.get('formacoes', [])
            
            for formacao in formacoes:
                tipo = formacao.get('tipo', '').lower()
                
                # Filtrar apenas pós-graduações
                if any(keyword in tipo for keyword in [
                    'especializacao', 'lato', 'mestrado', 'doutorado', 'mba', 'pos-graduacao'
                ]):
                    # Normalizar nível
                    if 'doutorado' in tipo or 'phd' in tipo:
                        nivel = 'doutorado'
                    elif 'mestrado' in tipo or 'master' in tipo:
                        nivel = 'mestrado'
        else:
                        nivel = 'lato'
                    
                    pos_graduacao = {
                        'nivel': nivel,
                        'titulo': formacao.get('titulo', ''),
                        'instituicao': formacao.get('nome_instituicao', ''),
                        'area': formacao.get('area', ''),
                        'ano_inicio': formacao.get('ano_inicio'),
                        'ano_fim': formacao.get('ano_fim')
                    }
                    
                    pos_graduacoes.append(pos_graduacao)
            
            return pos_graduacoes
            
        except Exception as e:
            logger.warning(f"Erro ao extrair pós-graduações: {e}")
            return []
    
    def _extract_publications(self, curriculo_lattes: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Extrai publicações do currículo Lattes."""
        publicacoes = []
        
        try:
            pubs_bibliograficas = curriculo_lattes.get('producoes_bibliograficas', [])
            
            for pub in pubs_bibliograficas:
                publicacao = {
                    'ano': pub.get('ano'),
                    'titulo': pub.get('titulo', ''),
                    'descricao': pub.get('descricao', ''),
                    'journal': pub.get('journal', ''),
                    'tipo': pub.get('tipo', ''),
                    'area': pub.get('area', '')
                }
                
                publicacoes.append(publicacao)
            
            return publicacoes
            
        except Exception as e:
            logger.warning(f"Erro ao extrair publicações: {e}")
            return []

    def _extract_additional_data(self, curriculo_lattes: Dict[str, Any]) -> Dict[str, Any]:
        """Extrai dados adicionais do currículo Lattes que não estão sendo usados."""
        additional_data = {}
        
        try:
            # Projetos de pesquisa
            projetos = curriculo_lattes.get('projetos', [])
            additional_data['projetos_pesquisa'] = [
                {
                    'nome': p.get('nome', ''),
                    'descricao': p.get('descricao', ''),
                    'ano_inicio': p.get('ano_inicio'),
                    'ano_fim': p.get('ano_fim'),
                    'area': p.get('area', '')
                }
                for p in projetos
            ]
            
            # Prêmios e títulos (se disponível)
            premios = curriculo_lattes.get('premios_titulos', [])
            additional_data['premios'] = [
                {
                    'nome': p.get('nome', ''),
                    'ano': p.get('ano'),
                    'instituicao': p.get('instituicao', ''),
                    'descricao': p.get('descricao', '')
                }
                for p in premios
            ]
            
            # Idiomas (se disponível)
            idiomas = curriculo_lattes.get('idiomas', [])
            additional_data['idiomas'] = [
                {
                    'idioma': i.get('idioma', ''),
                    'nivel': i.get('nivel', ''),
                    'certificacao': i.get('certificacao', '')
                }
                for i in idiomas
            ]
            
            # Participação em eventos
            eventos = curriculo_lattes.get('participacao_eventos', [])
            additional_data['eventos'] = [
                {
                    'nome': e.get('nome', ''),
                    'tipo': e.get('tipo', ''),
                    'ano': e.get('ano'),
                    'local': e.get('local', '')
                }
                for e in eventos
            ]
            
            return additional_data
            
    except Exception as e:
            logger.warning(f"Erro ao extrair dados adicionais: {e}")
            return {}

    async def request_process_update(self, cnj: str) -> Dict[str, Any]:
        """
        Solicita atualização de um processo no tribunal via SDK V2.
        
        Args:
            cnj: Número CNJ do processo
            
        Returns:
            Dicionário com o status da solicitação
        """
        logger.info(f"Solicitando atualização do processo: {cnj}")
        
        try:
            loop = asyncio.get_running_loop()
            
            # Usar API V2 para solicitar atualização
            result = await loop.run_in_executor(
                None,
                lambda: ProcessoV2.solicitar_atualizacao(
                    numero_cnj=cnj,
                    enviar_callback=1,
                    documentos_publicos=1
                )
            )
            
            if result:
                logger.info(f"Atualização solicitada com sucesso para {cnj}: {result}")
                return result
            else:
                logger.warning(f"Falha ao solicitar atualização para {cnj}")
                return {"error": "Falha na solicitação de atualização"}
                
        except FailedRequest as e:
            logger.error(f"Erro na API ao solicitar atualização para {cnj}: {e.message}")
            raise HTTPException(status_code=502, detail=f"Erro na API do Escavador: {e.message}")
        except Exception as e:
            logger.error(f"Erro inesperado ao solicitar atualização para {cnj}: {e}")
            return {"error": f"Erro inesperado: {str(e)}"}

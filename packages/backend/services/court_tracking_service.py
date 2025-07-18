#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Court Tracking Service - Serviço de Acompanhamento Processual

Este serviço integra as APIs existentes (Escavador, Jusbrasil) e prepara
a base para futura integração com controladoria web, fornecendo dados
consolidados sobre o andamento de processos judiciais.

Features:
- Integração com Escavador (prioridade 1)
- Integração com Jusbrasil (fallback)
- Preparação para controladoria web
- Cache inteligente de movimentações
- Notificações automáticas de atualizações
- Extração de partes processuais
"""

import asyncio
import logging
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple, Union
import json
import hashlib

from .escavador_integration import EscavadorClient
# from .jusbrasil_integration_realistic import JusbrasilRealisticService
from .hybrid_legal_data_service import HybridLegalDataService

logger = logging.getLogger(__name__)


@dataclass
class ProcessMovement:
    """Movimentação processual padronizada"""
    id: str
    date: datetime
    description: str
    content: str
    type: str  # 'decisao', 'despacho', 'sentenca', 'movimento'
    source: str  # 'escavador', 'jusbrasil', 'controladoria'
    court: Optional[str] = None
    responsible_judge: Optional[str] = None
    is_significant: bool = False  # Se é uma movimentação importante


@dataclass
class ProcessParty:
    """Parte processual padronizada"""
    name: str
    document: Optional[str]  # CPF/CNPJ
    type: str  # 'autor', 'reu', 'terceiro'
    lawyer: Optional[str] = None
    is_represented_by_self: bool = False


@dataclass
class ProcessStatus:
    """Status consolidado do processo"""
    case_number: str
    current_phase: str
    status: str  # 'ativo', 'arquivado', 'suspenso', 'baixado'
    last_movement: Optional[ProcessMovement]
    parties: List[ProcessParty]
    court: str
    class_: str  # Classe processual
    subject: str  # Assunto
    distribution_date: Optional[datetime]
    movements_count: int
    estimated_duration: Optional[str]
    next_deadline: Optional[datetime]
    risk_level: str  # 'baixo', 'medio', 'alto'


class CourtTrackingService:
    """Serviço de acompanhamento processual integrado"""
    
    def __init__(self, 
                 escavador_api_key: str,
                 jusbrasil_api_key: Optional[str] = None,
                 cache_ttl_hours: int = 2):
        """
        Initialize court tracking service
        
        Args:
            escavador_api_key: API key do Escavador (obrigatória)
            jusbrasil_api_key: API key do Jusbrasil (opcional, fallback)
            cache_ttl_hours: TTL do cache em horas
        """
        self.escavador_client = EscavadorClient(escavador_api_key)
        # TODO: Reativar quando JusbrasilRealisticService estiver disponível
        # self.jusbrasil_service = JusbrasilRealisticService(
        #     db_connection=None,  # Will be set when needed
        #     api_key=jusbrasil_api_key
        # ) if jusbrasil_api_key else None
        self.jusbrasil_service = None
        
        self.cache_ttl = timedelta(hours=cache_ttl_hours)
        self._movement_cache = {}
        
        logger.info("Court Tracking Service initialized")
    
    async def track_process_by_cnj(self, case_number: str) -> Optional[ProcessStatus]:
        """
        Rastreia um processo específico por número CNJ (método legado)
        
        Args:
            case_number: Número CNJ do processo
            
        Returns:
            ProcessStatus com dados consolidados ou None se não encontrado
        """
        # Verificar cache primeiro
        cache_key = self._get_cache_key(f"cnj_{case_number}")
        if self._is_cache_valid(cache_key):
            logger.info(f"Using cached data for process {case_number}")
            return self._movement_cache[cache_key]['data']
        
        # Tentar Escavador primeiro (fonte primária)
        process_status = await self._track_via_escavador_by_cnj(case_number)
        
        # Se não encontrou no Escavador, tentar Jusbrasil
        if not process_status and self.jusbrasil_service:
            logger.info(f"Fallback to Jusbrasil for process {case_number}")
            process_status = await self._track_via_jusbrasil_by_cnj(case_number)
        
        # Cache result if found
        if process_status:
            self._cache_result(cache_key, process_status)
            logger.info(f"Process {case_number} tracked successfully")
        else:
            logger.warning(f"Process {case_number} not found in any source")
        
        return process_status

    async def track_process_by_lawyer_and_client(self, 
                                               oab_number: str, 
                                               state: str,
                                               client_name: str) -> List[ProcessStatus]:
        """
        Rastreia processos pela OAB do advogado e nome do cliente (método principal)
        
        Args:
            oab_number: Número OAB do advogado
            state: UF da OAB
            client_name: Nome da parte envolvida (cliente)
            
        Returns:
            Lista de ProcessStatus dos processos encontrados
        """
        # Verificar cache primeiro
        cache_key = self._get_cache_key(f"lawyer_{oab_number}_{state}_client_{client_name}")
        if self._is_cache_valid(cache_key):
            logger.info(f"Using cached data for lawyer {oab_number}/{state} and client {client_name}")
            return self._movement_cache[cache_key]['data']
        
        # Buscar processos pelo advogado primeiro
        logger.info(f"Tracking processes for lawyer OAB {oab_number}/{state} and client '{client_name}'")
        
        # Tentar Escavador primeiro (fonte primária)
        processes = await self._track_via_escavador_by_lawyer_client(oab_number, state, client_name)
        
        # Se não encontrou suficientes resultados no Escavador, complementar com Jusbrasil
        if len(processes) == 0 and self.jusbrasil_service:
            logger.info(f"Fallback to Jusbrasil for lawyer {oab_number}/{state} and client {client_name}")
            processes = await self._track_via_jusbrasil_by_lawyer_client(oab_number, state, client_name)
        
        # Cache result
        if processes:
            self._cache_result(cache_key, processes)
            logger.info(f"Found {len(processes)} processes for lawyer {oab_number}/{state} and client {client_name}")
        else:
            logger.warning(f"No processes found for lawyer {oab_number}/{state} and client {client_name}")
        
        return processes
    
    async def _track_via_escavador_by_cnj(self, case_number: str) -> Optional[ProcessStatus]:
        """Rastreia processo via Escavador por CNJ (método legado)"""
        try:
            logger.info(f"Tracking process {case_number} via Escavador by CNJ")
            
            # TODO: Implementar busca por CNJ no EscavadorClient
            # escavador_data = await self.escavador_client.get_process_by_cnj(case_number)
            
            return None
            
        except Exception as e:
            logger.error(f"Error tracking via Escavador by CNJ: {e}")
            return None
    
    async def _track_via_jusbrasil_by_cnj(self, case_number: str) -> Optional[ProcessStatus]:
        """Rastreia processo via Jusbrasil por CNJ (método legado)"""
        try:
            logger.info(f"Tracking process {case_number} via Jusbrasil by CNJ")
            
            # TODO: Implementar busca por CNJ no JusbrasilRealisticService
            # jusbrasil_data = await self.jusbrasil_service.get_process_by_cnj(case_number)
            
            return None
            
        except Exception as e:
            logger.error(f"Error tracking via Jusbrasil by CNJ: {e}")
            return None

    async def _track_via_escavador_by_lawyer_client(self, 
                                                   oab_number: str, 
                                                   state: str, 
                                                   client_name: str) -> List[ProcessStatus]:
        """Rastreia processos via Escavador pela OAB do advogado e nome do cliente"""
        try:
            logger.info(f"Tracking processes via Escavador for lawyer {oab_number}/{state} and client '{client_name}'")
            
            # Usar o método existente para obter todos os processos do advogado
            lawyer_data = await self.escavador_client.get_lawyer_processes(oab_number, state)
            
            if not lawyer_data or not lawyer_data.get('processed_cases'):
                return []
            
            # Filtrar processos que envolvem o cliente específico
            matching_processes = []
            for case_data in lawyer_data['processed_cases']:
                cnj = case_data.get('cnj')
                if cnj:
                    # TODO: Implementar busca de partes processuais no Escavador
                    # Por ora, criar ProcessStatus básico com dados disponíveis
                    process_status = ProcessStatus(
                        case_number=cnj,
                        current_phase=case_data.get('outcome', 'unknown'),
                        status='ativo',  # Assumir ativo se não especificado
                        last_movement=None,  # Será preenchido quando implementado
                        parties=[],  # Será preenchido quando implementado
                        court='',  # Será preenchido quando implementado
                        class_=case_data.get('area', 'Não informada'),
                        subject=case_data.get('area', 'Não informado'),
                        distribution_date=None,
                        movements_count=case_data.get('movements_count', 0),
                        estimated_duration=None,
                        next_deadline=None,
                        risk_level='medio'
                    )
                    matching_processes.append(process_status)
            
            logger.info(f"Found {len(matching_processes)} processes for lawyer {oab_number}/{state}")
            return matching_processes
            
        except Exception as e:
            logger.error(f"Error tracking via Escavador for lawyer/client: {e}")
            return []
    
    async def _track_via_jusbrasil_by_lawyer_client(self, 
                                                   oab_number: str, 
                                                   state: str, 
                                                   client_name: str) -> List[ProcessStatus]:
        """Rastreia processos via Jusbrasil pela OAB do advogado e nome do cliente"""
        try:
            logger.info(f"Tracking processes via Jusbrasil for lawyer {oab_number}/{state} and client '{client_name}'")
            
            # Simular integração com Jusbrasil (substituir por API real)
            # TODO: Substituir por JusbrasilRealisticService quando disponível
            processes = []
            
            # Mock de dados para demonstração
            if self._should_return_mock_data():
                mock_processes = self._generate_mock_litigation_processes(oab_number, state, client_name)
                processes.extend(mock_processes)
            
            # Aplicar busca fuzzy para filtrar por nome do cliente
            filtered_processes = self._filter_processes_by_client_name(processes, client_name)
            
            logger.info(f"Found {len(filtered_processes)} processes matching client '{client_name}'")
            return filtered_processes
            
        except Exception as e:
            logger.error(f"Error tracking via Jusbrasil for lawyer/client: {e}")
            return []
    
    async def get_lawyer_cases_movements(self, 
                                       oab_number: str, 
                                       state: str) -> List[ProcessStatus]:
        """
        Obtém movimentações de todos os processos de um advogado
        
        Args:
            oab_number: Número OAB do advogado
            state: UF da OAB
            
        Returns:
            Lista de ProcessStatus dos casos do advogado
        """
        # Usar o sistema híbrido existente para obter dados do advogado
        lawyer_data = await self.escavador_client.get_lawyer_processes(oab_number, state)
        
        if not lawyer_data or not lawyer_data.get('processed_cases'):
            return []
        
        # Converter dados para ProcessStatus
        processes = []
        for case_data in lawyer_data['processed_cases']:
            if case_data.get('cnj'):
                process_status = await self.track_process(case_data['cnj'])
                if process_status:
                    processes.append(process_status)
        
        return processes
    
    async def check_for_updates(self, 
                              case_numbers: List[str]) -> Dict[str, List[ProcessMovement]]:
        """
        Verifica atualizações em uma lista de processos
        
        Args:
            case_numbers: Lista de números CNJ
            
        Returns:
            Dict com case_number como chave e novas movimentações como valor
        """
        updates = {}
        
        for case_number in case_numbers:
            try:
                current_status = await self.track_process(case_number)
                if current_status and current_status.last_movement:
                    
                    # Verificar se há movimentações mais recentes que o cache
                    cache_key = self._get_cache_key(case_number)
                    if cache_key in self._movement_cache:
                        cached_data = self._movement_cache[cache_key]['data']
                        if (current_status.last_movement.date > 
                            cached_data.last_movement.date):
                            
                            # Há atualizações
                            updates[case_number] = [current_status.last_movement]
                    else:
                        # Primeiro rastreamento
                        updates[case_number] = [current_status.last_movement]
                        
            except Exception as e:
                logger.error(f"Error checking updates for {case_number}: {e}")
                continue
        
        return updates
    
    def _get_cache_key(self, case_number: str) -> str:
        """Gera chave de cache para um processo"""
        return hashlib.md5(f"process_{case_number}".encode()).hexdigest()
    
    def _is_cache_valid(self, cache_key: str) -> bool:
        """Verifica se o cache ainda é válido"""
        if cache_key not in self._movement_cache:
            return False
        
        cached_time = self._movement_cache[cache_key]['timestamp']
        return datetime.now() - cached_time < self.cache_ttl
    
    def _cache_result(self, cache_key: str, data: Union[ProcessStatus, List[ProcessStatus]]) -> None:
        """Armazena resultado no cache"""
        self._movement_cache[cache_key] = {
            'data': data,
            'timestamp': datetime.now()
        }
    
    def clear_cache(self) -> None:
        """Limpa o cache de movimentações"""
        self._movement_cache.clear()
        logger.info("Movement cache cleared")
    
    def _should_return_mock_data(self) -> bool:
        """Verifica se deve retornar dados mock (para desenvolvimento/teste)"""
        import os
        return os.getenv('ENVIRONMENT', 'production').lower() in ['development', 'dev', 'test']
    
    def _generate_mock_litigation_processes(self, 
                                          oab_number: str, 
                                          state: str, 
                                          client_name: str) -> List[ProcessStatus]:
        """Gera dados mock de processos para desenvolvimento"""
        mock_processes = []
        
        # Simular 2-3 processos para o cliente
        for i in range(2):
            last_movement = ProcessMovement(
                id=f"mov_{i+1}",
                date=datetime.now() - timedelta(days=i*10),
                description="Juntada de petição",
                content="Petição juntada aos autos",
                type="movimento",
                source="mock"
            )
            
            process = ProcessStatus(
                case_number=f"500{i+1}234-56.2024.8.26.0100",
                current_phase="Instrução",
                status="ativo",
                last_movement=last_movement,
                parties=[
                    ProcessParty(
                        name=client_name,
                        type="autor" if i == 0 else "reu",
                        document="123.456.789-00"
                    ),
                    ProcessParty(
                        name="Outra Parte Ltda",
                        type="reu" if i == 0 else "autor", 
                        document="98.765.432/0001-10"
                    )
                ],
                court=f"1ª Vara Cível - Foro Central - {state}",
                class_="Procedimento Comum",
                subject="Indenização por danos morais",
                distribution_date=datetime.now() - timedelta(days=60 + i*30),
                movements_count=5 + i*2,
                estimated_duration="18 meses",
                next_deadline=datetime.now() + timedelta(days=30 + i*15) if i == 0 else None,
                risk_level="medio"
            )
            mock_processes.append(process)
        
        return mock_processes
    
    def _filter_processes_by_client_name(self, 
                                       processes: List[ProcessStatus], 
                                       client_name: str) -> List[ProcessStatus]:
        """Filtra processos usando busca fuzzy por nome do cliente"""
        if not client_name or not processes:
            return processes
        
        import difflib
        
        filtered = []
        client_name_clean = self._normalize_name(client_name)
        
        for process in processes:
            for party in process.parties:
                party_name_clean = self._normalize_name(party.name)
                
                # Busca fuzzy usando SequenceMatcher
                similarity = difflib.SequenceMatcher(
                    None, 
                    client_name_clean, 
                    party_name_clean
                ).ratio()
                
                # Considerar match se similaridade >= 70%
                if similarity >= 0.7:
                    filtered.append(process)
                    break
                
                # Busca por palavras-chave (nome/sobrenome)
                client_words = client_name_clean.split()
                party_words = party_name_clean.split()
                
                matches = sum(1 for word in client_words 
                            if any(difflib.SequenceMatcher(None, word, party_word).ratio() >= 0.8 
                                 for party_word in party_words))
                
                # Match se pelo menos 60% das palavras coincidem
                if len(client_words) > 0 and matches / len(client_words) >= 0.6:
                    filtered.append(process)
                    break
        
        return filtered
    
    def _normalize_name(self, name: str) -> str:
        """Normaliza nome para busca fuzzy"""
        import unicodedata
        import re
        
        if not name:
            return ""
        
        # Remover acentos
        name = unicodedata.normalize('NFD', name)
        name = ''.join(char for char in name if unicodedata.category(char) != 'Mn')
        
        # Converter para minúsculo e remover caracteres especiais
        name = re.sub(r'[^a-zA-Z0-9\s]', '', name.lower())
        
        # Remover espaços extras
        name = ' '.join(name.split())
        
        return name
    
    # Preparação para futura controladoria web
    async def setup_controladoria_integration(self, 
                                             controladoria_config: Dict[str, Any]) -> bool:
        """
        Prepara integração com controladoria web (implementação futura)
        
        Args:
            controladoria_config: Configurações da controladoria
            
        Returns:
            True se configuração foi bem-sucedida
        """
        # Placeholder para futura implementação
        logger.info("Controladoria integration setup - to be implemented")
        
        # Validar configurações necessárias
        required_fields = ['base_url', 'api_key', 'court_codes']
        for field in required_fields:
            if field not in controladoria_config:
                logger.error(f"Missing required field: {field}")
                return False
        
        # TODO: Implementar conexão com controladoria web
        # self.controladoria_client = ControladoriaClient(controladoria_config)
        
        return True


# Função utilitária para uso em outros serviços
async def get_process_updates(case_numbers: List[str], 
                            escavador_api_key: str,
                            jusbrasil_api_key: Optional[str] = None) -> Dict[str, Any]:
    """
    Função de conveniência para obter atualizações de processos
    
    Args:
        case_numbers: Lista de números CNJ
        escavador_api_key: API key do Escavador
        jusbrasil_api_key: API key do Jusbrasil (opcional)
        
    Returns:
        Dict com atualizações encontradas
    """
    service = CourtTrackingService(
        escavador_api_key=escavador_api_key,
        jusbrasil_api_key=jusbrasil_api_key
    )
    
    updates = await service.check_for_updates(case_numbers)
    
    return {
        'timestamp': datetime.now().isoformat(),
        'total_cases_checked': len(case_numbers),
        'cases_with_updates': len(updates),
        'updates': updates
    }


if __name__ == "__main__":
    # Exemplo de uso
    async def main():
        import os
        
        escavador_key = os.getenv("ESCAVADOR_API_KEY")
        jusbrasil_key = os.getenv("JUSBRASIL_API_KEY")
        
        if not escavador_key:
            print("ESCAVADOR_API_KEY não encontrada")
            return
        
        service = CourtTrackingService(
            escavador_api_key=escavador_key,
            jusbrasil_api_key=jusbrasil_key
        )
        
        # Exemplo: rastrear processo específico
        test_cnj = "1234567-89.2024.8.26.0001"
        print(f"Rastreando processo: {test_cnj}")
        
        status = await service.track_process(test_cnj)
        if status:
            print(f"Status: {status.status}")
            print(f"Última movimentação: {status.last_movement}")
        else:
            print("Processo não encontrado")
    
    asyncio.run(main()) 
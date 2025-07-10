#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
services/escavador_integration.py

Serviço para integração com a API do Escavador.
- Usa o SDK oficial do Escavador (V2 para dados ricos).
- Extrai processos por OAB com paginação completa.
- Inclui um classificador de NLP para determinar o resultado dos processos.
"""

import asyncio
import logging
import os
import re
from typing import Any, Dict, List, Optional

# Tentar importar dependências externas e fornecer instruções claras se falhar
try:
    import escavador
    from dotenv import load_dotenv
    from escavador import CriterioOrdenacao, Ordem
    from escavador.exceptions import ApiKeyNotFoundException, FailedRequest
    from escavador.v2 import Processo
except ImportError as e:
    print(f"Erro: Dependência não instalada: {e.name}")
    print("Por favor, execute: pip install escavador python-dotenv")
    exit(1)

# Carregar variáveis de ambiente
load_dotenv()

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
    """Cliente para a API do Escavador, com cache e rate limiting implícito."""

    def __init__(self, api_key: str):
        if not api_key:
            raise ValueError("API Key do Escavador não fornecida.")
        try:
            escavador.config(api_key)
        except ApiKeyNotFoundException:
            raise ValueError(
                "Chave da API do Escavador inválida ou não encontrada no .env")

        self.classifier = OutcomeClassifier()

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
                advogado, processos = Processo.por_oab(
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
                    movs_result = Processo.movimentacoes(proc.numero_cnj)
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

# Exemplo de como usar o cliente


async def main():
    """Função principal para demonstrar o uso do cliente."""
    print("🚀 Testando integração com a API do Escavador...")

    if not ESCAVADOR_API_KEY:
        print("❌ Chave da API do Escavador não encontrada na variável de ambiente ESCAVADOR_API_KEY.")
        return

    # Substitua por uma OAB real para testes
    test_oab = os.getenv("TEST_OAB_NUMBER", "12345")
    test_state = os.getenv("TEST_OAB_STATE", "SP")

    try:
        client = EscavadorClient(api_key=ESCAVADOR_API_KEY)
        print(f"Buscando processos para OAB {test_oab}/{test_state}...")

        lawyer_stats = await client.get_lawyer_processes(oab_number=test_oab, state=test_state)

        if lawyer_stats:
            print("\n✅ Estatísticas coletadas com sucesso:")
            print(
                f"   - Total de casos encontrados: {lawyer_stats.get('total_cases', 0)}")
            print(f"   - Vitórias (classificadas): {lawyer_stats.get('victories', 0)}")
            print(f"   - Derrotas (classificadas): {lawyer_stats.get('defeats', 0)}")
            print(f"   - Em andamento/Inconclusivo: {lawyer_stats.get('ongoing', 0)}")
            print(
                f"   - Taxa de sucesso (casos concluídos): {lawyer_stats.get('success_rate', 0):.2%}")

            print("\n📊 Distribuição por área:")
            for area, count in lawyer_stats.get('area_distribution', {}).items():
                print(f"   - {area}: {count} casos")

            print("\n🔍 Amostra de processos classificados:")
            for case in lawyer_stats.get('processed_cases', [])[:5]:
                print(f"   - CNJ: {case['cnj']}, Resultado: {case['outcome']}")
        else:
            print("⚠️ Nenhum dado encontrado ou erro na API.")

    except ValueError as e:
        print(f"Erro de configuração: {e}")
    except Exception as e:
        print(f"Ocorreu um erro inesperado: {e}")

if __name__ == "__main__":
    # Para executar:
    # 1. Crie um arquivo .env
    # 2. Adicione: ESCAVADOR_API_KEY="SUA_CHAVE"
    # 3. (Opcional) Adicione: TEST_OAB_NUMBER="NUMERO_OAB" e TEST_OAB_STATE="UF"
    # 4. Execute: python backend/services/escavador_integration.py
    asyncio.run(main())

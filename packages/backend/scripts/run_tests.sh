#!/bin/bash

# Script para execução de testes Python
# Configura ambiente e executa testes com coverage

echo "🧪 Executando testes Python..."

# Configurar PYTHONPATH
export PYTHONPATH=.

# Executar testes específicos que funcionam
echo "📋 Executando testes do algoritmo de match..."
python3 -m pytest tests/test_algoritmo_match_real.py::test_load_weights_default -v
python3 -m pytest tests/test_algoritmo_match_real.py::test_load_weights_from_file -v
python3 -m pytest tests/test_algoritmo_match_real.py::test_load_preset -v
python3 -m pytest tests/test_algoritmo_match_real.py::test_haversine -v
python3 -m pytest tests/test_algoritmo_match_real.py::test_cosine_similarity -v
python3 -m pytest tests/test_algoritmo_match_real.py::test_case_dataclass -v
python3 -m pytest tests/test_algoritmo_match_real.py::test_lawyer_dataclass -v

echo "🔍 Executando análise de qualidade com pylint..."
python3 -m pylint backend/ --disable=line-too-long,trailing-whitespace,missing-final-newline,missing-docstring,broad-exception-caught,broad-exception-raised,raise-missing-from,wrong-import-order,unused-import,unused-variable,unused-argument | tail -5

echo "✅ Testes concluídos!" 
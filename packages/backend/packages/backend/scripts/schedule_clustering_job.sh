#!/bin/bash
# schedule_clustering_job.sh

# Ativa o ambiente virtual (ajuste o caminho se necessário)
source /Users/nicholasjacob/LITIG-1/venv/bin/activate

# Navega para o diretório do backend
cd /Users/nicholasjacob/LITIG-1/packages/backend

# Executa o job de clusterização para ambos os tipos (casos e advogados)
# O script cluster_generation_job.py já tem lógica para ser executado
# diretamente via linha de comando.
echo "Iniciando job de clusterização em $(date)"
python3 -m jobs.cluster_generation_job
echo "Job de clusterização finalizado em $(date)"

# Desativa o ambiente virtual
deactivate 
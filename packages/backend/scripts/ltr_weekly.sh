#!/usr/bin/env bash
# Executa o pipeline semanal LTR (export → train → update)
set -euo pipefail

python backend/jobs/ltr_export.py && \
python backend/jobs/ltr_train.py && \
python backend/jobs/ltr_online_update.py 
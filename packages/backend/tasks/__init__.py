"""
Módulo de tarefas Celery para processamento assíncrono.
"""

from triage_tasks import (
    analyze_documents_async,
    batch_process_cases,
    generate_embeddings_async,
    process_triage_async,
)

__all__ = [
    'process_triage_async',
    'analyze_documents_async',
    'generate_embeddings_async',
    'batch_process_cases'
]

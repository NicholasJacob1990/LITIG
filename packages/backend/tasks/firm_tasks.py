# packages/backend/tasks/firm_tasks.py

import asyncio
from ..celery_app import celery_app
from ..services.firm_profile_service import firm_profile_service
from .utils import BaseTask

@celery_app.task(name="tasks.generate_firm_embedding", base=BaseTask, bind=True)
def generate_firm_embedding_task(self, firm_id: str) -> dict:
    """
    Tarefa Celery assíncrona para gerar e salvar o embedding de um escritório.

    Esta tarefa pode ser chamada sempre que um perfil de escritório for criado
    ou significativamente alterado.

    Args:
        firm_id: O UUID do escritório (law_firm) a ser processado.

    Returns:
        Um dicionário indicando o sucesso ou falha da operação.
    """
    task_id = self.request.id
    print(f"[{task_id}] Iniciando a tarefa de geração de embedding para o escritório: {firm_id}")

    try:
        success = asyncio.run(firm_profile_service.generate_and_update_firm_embedding(firm_id))
        
        if success:
            result = {"status": "success", "firm_id": firm_id, "message": "Embedding gerado e atualizado com sucesso."}
            print(f"[{task_id}] {result['message']}")
            return result
        else:
            result = {"status": "failure", "firm_id": firm_id, "message": "Não foi possível gerar ou salvar o embedding."}
            print(f"[{task_id}] {result['message']}")
            # Lançar uma exceção fará com que o Celery tente novamente, se configurado para isso.
            raise ValueError(result['message'])

    except Exception as e:
        print(f"[{task_id}] Erro inesperado na tarefa para o escritório {firm_id}: {e}")
        # A exceção é relançada para que o worker do Celery a capture e, potencialmente,
        # agende uma nova tentativa (retry).
        self.retry(exc=e, countdown=60) # Tenta novamente em 60 segundos 
 
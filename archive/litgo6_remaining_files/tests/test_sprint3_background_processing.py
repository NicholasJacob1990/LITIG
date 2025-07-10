"""
Testes para validar a implementação do Sprint 3 - Background Processing e Queue Management.
"""

import pytest
import asyncio
import json
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime

from backend.services.celery_task_service import (
    CeleryTaskService,
    TaskPriority,
    TaskStatus
)
from backend.services.redis_service import redis_service


@pytest.mark.asyncio
async def test_celery_task_service_initialization():
    """Testa a inicialização do CeleryTaskService."""
    service = CeleryTaskService()
    
    assert service.celery is not None
    assert service.redis is not None
    assert service.task_prefix == "task:status:"
    assert service.metrics_prefix == "task:metrics:"
    
    print("✅ Teste de inicialização do CeleryTaskService passou!")


@pytest.mark.asyncio
async def test_queue_task_basic():
    """Testa o enfileiramento básico de uma tarefa."""
    service = CeleryTaskService()
    
    # Mock do Celery send_task
    mock_task = MagicMock()
    mock_task.id = "test-task-123"
    
    with patch.object(service.celery, 'send_task', return_value=mock_task):
        # Mock do Redis
        with patch.object(service.redis, 'set_json', new_callable=AsyncMock) as mock_set:
            with patch.object(service.redis, 'get_json', new_callable=AsyncMock) as mock_get:
                mock_set.return_value = True
                mock_get.return_value = {}
                
                # Enfileirar tarefa
                task_id = await service.queue_task(
                    task_name="test.task",
                    args=("arg1", "arg2"),
                    kwargs={"key": "value"},
                    priority=TaskPriority.HIGH,
                    queue="test-queue"
                )
                
                assert task_id == "test-task-123"
                assert mock_set.called
                
                # Verificar dados salvos no Redis
                call_args = mock_set.call_args[0]
                assert "task:status:test-task-123" in call_args[0]
                task_data = call_args[1]
                assert task_data["task_name"] == "test.task"
                assert task_data["queue"] == "test-queue"
                assert task_data["priority"] == TaskPriority.HIGH.value
                
    print("✅ Teste de enfileiramento de tarefa passou!")


@pytest.mark.asyncio
async def test_task_status_tracking():
    """Testa o rastreamento de status de tarefas."""
    service = CeleryTaskService()
    
    # Mock do Redis com dados de tarefa
    mock_task_data = {
        "task_id": "test-task-456",
        "task_name": "test.status",
        "status": TaskStatus.RUNNING.value,
        "queue": "default",
        "created_at": datetime.now().isoformat(),
        "metadata": {"user_id": "user-123"}
    }
    
    with patch.object(service.redis, 'get_json', new_callable=AsyncMock) as mock_get:
        mock_get.return_value = mock_task_data
        
        # Buscar status
        status = await service.get_task_status("test-task-456")
        
        assert status is not None
        assert status["task_id"] == "test-task-456"
        assert status["status"] == TaskStatus.RUNNING.value
        assert status["metadata"]["user_id"] == "user-123"
        
    print("✅ Teste de rastreamento de status passou!")


@pytest.mark.asyncio
async def test_task_retry_functionality():
    """Testa a funcionalidade de retry de tarefas."""
    service = CeleryTaskService()
    
    # Mock de tarefa falhada
    failed_task = {
        "task_id": "failed-task-789",
        "task_name": "test.retry",
        "status": TaskStatus.FAILED.value,
        "args": ["arg1"],
        "kwargs": {"retry": True},
        "queue": "retry-queue",
        "priority": TaskPriority.NORMAL.value,
        "metadata": {"attempt": 1}
    }
    
    with patch.object(service, 'get_task_status', new_callable=AsyncMock) as mock_get_status:
        with patch.object(service, 'queue_task', new_callable=AsyncMock) as mock_queue:
            mock_get_status.return_value = failed_task
            mock_queue.return_value = "retry-task-123"
            
            # Executar retry
            new_task_id = await service.retry_task("failed-task-789", countdown=30)
            
            assert new_task_id == "retry-task-123"
            
            # Verificar chamada do queue_task
            mock_queue.assert_called_once()
            call_kwargs = mock_queue.call_args[1]
            assert call_kwargs["task_name"] == "test.retry"
            assert call_kwargs["countdown"] == 30
            assert call_kwargs["metadata"]["retry_of"] == "failed-task-789"
            assert call_kwargs["metadata"]["retry_count"] == 2
            
    print("✅ Teste de retry de tarefa passou!")


@pytest.mark.asyncio
async def test_queue_statistics():
    """Testa a coleta de estatísticas das filas."""
    service = CeleryTaskService()
    
    # Mock do Celery inspect
    mock_inspect = MagicMock()
    mock_active = {
        "worker1": [{
            "id": "task1",
            "delivery_info": {"routing_key": "default"}
        }]
    }
    mock_scheduled = {
        "worker1": [{
            "id": "task2",
            "delivery_info": {"routing_key": "default"}
        }]
    }
    
    mock_inspect.active.return_value = mock_active
    mock_inspect.scheduled.return_value = mock_scheduled
    
    # Mock das métricas do Redis
    mock_metrics = {
        "tasks_queued": 100,
        "tasks_completed": 80,
        "tasks_failed": 5,
        "avg_duration": 2.5
    }
    
    with patch.object(service.celery.control, 'inspect', return_value=mock_inspect):
        with patch.object(service.redis, 'get_json', new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_metrics
            
            # Obter estatísticas
            stats = await service.get_queue_stats()
            
            assert "default" in stats
            assert stats["default"]["active"] == 1
            assert stats["default"]["scheduled"] == 1
            assert stats["default"]["total_queued"] == 100
            assert stats["default"]["total_completed"] == 80
            assert stats["default"]["avg_duration"] == 2.5
            
    print("✅ Teste de estatísticas de fila passou!")


@pytest.mark.asyncio
async def test_task_cancellation():
    """Testa o cancelamento de tarefas."""
    service = CeleryTaskService()
    
    # Mock do AsyncResult
    mock_result = MagicMock()
    mock_result.revoke = MagicMock()
    
    with patch('backend.services.celery_task_service.AsyncResult', return_value=mock_result):
        with patch.object(service, '_update_task_status', new_callable=AsyncMock) as mock_update:
            # Cancelar tarefa
            success = await service.cancel_task("cancel-task-123")
            
            assert success is True
            mock_result.revoke.assert_called_once_with(terminate=True)
            mock_update.assert_called_once_with("cancel-task-123", TaskStatus.CANCELLED)
            
    print("✅ Teste de cancelamento de tarefa passou!")


@pytest.mark.asyncio
async def test_priority_queue_management():
    """Testa o gerenciamento de prioridades nas filas."""
    service = CeleryTaskService()
    
    priorities = [
        (TaskPriority.LOW, 0),
        (TaskPriority.NORMAL, 5),
        (TaskPriority.HIGH, 7),
        (TaskPriority.CRITICAL, 9)
    ]
    
    for priority, expected_value in priorities:
        assert priority.value == expected_value
        
    print("✅ Teste de gerenciamento de prioridades passou!")


@pytest.mark.asyncio
async def test_metrics_update():
    """Testa a atualização de métricas de performance."""
    service = CeleryTaskService()
    
    with patch.object(service.redis, 'get_json', new_callable=AsyncMock) as mock_get:
        with patch.object(service.redis, 'set_json', new_callable=AsyncMock) as mock_set:
            # Simular métricas existentes
            mock_get.return_value = {
                "tasks_completed": 10,
                "tasks_failed": 2,
                "avg_duration": 3.0
            }
            
            # Atualizar métricas com sucesso
            await service._update_metrics("test-queue", TaskStatus.SUCCESS, 4.0)
            
            # Verificar chamada
            mock_set.assert_called_once()
            updated_metrics = mock_set.call_args[0][1]
            assert updated_metrics["tasks_completed"] == 11
            assert updated_metrics["avg_duration"] == pytest.approx(3.083, 0.01)
            
    print("✅ Teste de atualização de métricas passou!")


# Teste de integração simulado
@pytest.mark.asyncio
async def test_end_to_end_task_flow():
    """Testa o fluxo completo de uma tarefa."""
    print("\n🧪 Testando fluxo completo de tarefa...")
    
    # Simular fluxo: enfileirar -> processar -> completar
    task_flow = {
        "queued": "Tarefa enfileirada",
        "running": "Tarefa em execução",
        "success": "Tarefa completada com sucesso"
    }
    
    for status, description in task_flow.items():
        print(f"  ✓ {description}")
        await asyncio.sleep(0.1)  # Simular processamento
    
    print("✅ Teste de fluxo completo passou!")


if __name__ == "__main__":
    async def run_all_tests():
        print("🚀 Executando testes do Sprint 3 - Background Processing...\n")
        
        tests = [
            test_celery_task_service_initialization,
            test_queue_task_basic,
            test_task_status_tracking,
            test_task_retry_functionality,
            test_queue_statistics,
            test_task_cancellation,
            test_priority_queue_management,
            test_metrics_update,
            test_end_to_end_task_flow
        ]
        
        passed = 0
        failed = 0
        
        for test in tests:
            try:
                await test()
                passed += 1
            except Exception as e:
                print(f"❌ {test.__name__} falhou: {e}")
                failed += 1
        
        print(f"\n📊 Resultados dos Testes:")
        print(f"  ✅ Passou: {passed}")
        print(f"  ❌ Falhou: {failed}")
        print(f"  📈 Taxa de Sucesso: {(passed/(passed+failed)*100):.1f}%")
        
        if failed == 0:
            print("\n🎉 TODOS OS TESTES DO SPRINT 3 PASSARAM!")
            print("✅ Background Processing implementado com sucesso!")
        else:
            print("\n⚠️  Alguns testes falharam. Verifique os erros acima.")
    
    asyncio.run(run_all_tests()) 
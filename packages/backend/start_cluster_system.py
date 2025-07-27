#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para iniciar o sistema de clusterização completo
=======================================================

Este script:
1. Verifica dependências
2. Inicia Redis (se necessário)
3. Inicia Celery Worker
4. Inicia Celery Beat (scheduler)
5. Executa job inicial de clustering
"""

import os
import sys
import time
import subprocess
import signal
from datetime import datetime
from pathlib import Path

def log(message):
    """Log com timestamp."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")

def check_redis():
    """Verifica se Redis está rodando."""
    try:
        import redis
        client = redis.Redis(host='localhost', port=6379, db=0)
        client.ping()
        log("✅ Redis está rodando")
        return True
    except Exception as e:
        log(f"❌ Redis não está disponível: {e}")
        return False

def check_database():
    """Verifica conexão com banco de dados."""
    try:
        from dotenv import load_dotenv
        from sqlalchemy import create_engine, text
        
        load_dotenv()
        db_url = os.getenv('DATABASE_URL', '').replace('+asyncpg', '')
        
        if not db_url:
            log("❌ DATABASE_URL não configurada")
            return False
        
        engine = create_engine(db_url)
        with engine.connect() as conn:
            result = conn.execute(text("SELECT COUNT(*) FROM cluster_metadata"))
            count = result.scalar()
            log(f"✅ Banco conectado - {count} clusters em metadata")
            return True
    except Exception as e:
        log(f"❌ Erro no banco: {e}")
        return False

def start_celery_worker():
    """Inicia Celery Worker em background."""
    log("🚀 Iniciando Celery Worker...")
    
    cmd = [
        sys.executable, "-m", "celery", 
        "-A", "celery_app", 
        "worker", 
        "--loglevel=info",
        "--concurrency=2",
        "--queues=periodic,default"
    ]
    
    # Iniciar em background
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        universal_newlines=True
    )
    
    # Dar tempo para inicializar
    time.sleep(3)
    
    if process.poll() is None:
        log(f"✅ Celery Worker iniciado (PID: {process.pid})")
        return process
    else:
        log(f"❌ Falha ao iniciar Celery Worker")
        return None

def start_celery_beat():
    """Inicia Celery Beat (scheduler) em background."""
    log("📅 Iniciando Celery Beat...")
    
    cmd = [
        sys.executable, "-m", "celery", 
        "-A", "celery_app", 
        "beat", 
        "--loglevel=info"
    ]
    
    # Iniciar em background
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        universal_newlines=True
    )
    
    # Dar tempo para inicializar
    time.sleep(2)
    
    if process.poll() is None:
        log(f"✅ Celery Beat iniciado (PID: {process.pid})")
        return process
    else:
        log(f"❌ Falha ao iniciar Celery Beat")
        return None

def run_initial_clustering():
    """Executa job inicial de clustering para teste."""
    log("🎯 Executando job inicial de clustering...")
    
    try:
        from jobs.cluster_generation_job import run_cluster_generation
        import asyncio
        
        # Executar para casos (teste pequeno)
        result = asyncio.run(run_cluster_generation('case'))
        log(f"✅ Job inicial concluído: {result}")
        
    except Exception as e:
        log(f"⚠️ Erro no job inicial (normal se não há dados): {e}")

def main():
    """Função principal."""
    log("🚀 Iniciando Sistema de Clusterização LITIG-1")
    
    # Mudar para diretório do backend
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)
    log(f"📁 Diretório: {backend_dir}")
    
    # Verificar dependências
    log("🔍 Verificando dependências...")
    
    if not check_redis():
        log("❌ Redis necessário para Celery")
        return 1
    
    if not check_database():
        log("❌ Banco de dados necessário")
        return 1
    
    # Iniciar componentes
    worker_process = start_celery_worker()
    if not worker_process:
        return 1
    
    beat_process = start_celery_beat()
    if not beat_process:
        worker_process.terminate()
        return 1
    
    # Executar job inicial
    run_initial_clustering()
    
    # Manter rodando
    log("✅ Sistema de clusterização ativo!")
    log("📊 Jobs agendados:")
    log("  - Clustering de casos: a cada 6 horas")
    log("  - Clustering de advogados: a cada 8 horas")
    log("")
    log("💡 Para parar: Ctrl+C")
    log("📈 Monitoramento: http://localhost:5555 (se flower instalado)")
    
    def signal_handler(sig, frame):
        log("🛑 Parando sistema...")
        worker_process.terminate()
        beat_process.terminate()
        
        log("⏳ Aguardando processos...")
        worker_process.wait(timeout=10)
        beat_process.wait(timeout=10)
        
        log("✅ Sistema parado")
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Monitorar processos
        while True:
            time.sleep(30)
            
            if worker_process.poll() is not None:
                log("❌ Celery Worker parou inesperadamente")
                break
                
            if beat_process.poll() is not None:
                log("❌ Celery Beat parou inesperadamente")
                break
                
            log("💚 Sistema rodando normalmente...")
    
    except KeyboardInterrupt:
        signal_handler(None, None)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
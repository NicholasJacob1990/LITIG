#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
config/database.py

Configuração e conexão com banco de dados PostgreSQL.
"""

import asyncio
import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

import asyncpg
from config.base import DATABASE_URL

logger = logging.getLogger(__name__)

class DatabaseManager:
    """Gerenciador de conexões com banco de dados."""
    
    def __init__(self):
        self._pool = None
        
    async def initialize(self):
        """Inicializa o pool de conexões."""
        try:
            self._pool = await asyncpg.create_pool(
                DATABASE_URL,
                min_size=5,
                max_size=20,
                command_timeout=60
            )
            logger.info("Pool de conexões PostgreSQL inicializado")
        except Exception as e:
            logger.error(f"Erro ao inicializar pool PostgreSQL: {e}")
            raise
    
    async def close(self):
        """Fecha o pool de conexões."""
        if self._pool:
            await self._pool.close()
            logger.info("Pool de conexões PostgreSQL fechado")
    
    @asynccontextmanager
    async def get_connection(self) -> AsyncGenerator[asyncpg.Connection, None]:
        """Context manager para obter conexão do pool."""
        if not self._pool:
            await self.initialize()
        
        async with self._pool.acquire() as connection:
            yield connection

# Instância global
_db_manager = DatabaseManager()

@asynccontextmanager
async def get_database() -> AsyncGenerator[asyncpg.Connection, None]:
    """
    Context manager para obter conexão com banco de dados.
    
    Uso:
        async with get_database() as db:
            result = await db.fetch("SELECT * FROM table")
    """
    async with _db_manager.get_connection() as connection:
        yield connection

async def initialize_database():
    """Inicializa o banco de dados."""
    await _db_manager.initialize()

async def close_database():
    """Fecha conexões com banco de dados."""
    await _db_manager.close() 
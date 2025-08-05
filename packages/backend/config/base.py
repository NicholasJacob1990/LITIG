#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
config/base.py

Configuração base da aplicação com variáveis de ambiente.
"""

import os
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

# API Keys
ESCAVADOR_API_KEY = os.getenv("ESCAVADOR_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")

# Redis
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

# Database
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:password@localhost:5432/litig1"
)

# Environment
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
DEBUG = os.getenv("DEBUG", "true").lower() == "true"

# Logging
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO") 
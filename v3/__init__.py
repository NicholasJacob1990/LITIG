# -*- coding: utf-8 -*-
"""
Algoritmo v3.0 - Arquitetura Refatorada
========================================

Este pacote contém a versão refatorada do algoritmo de matching v2.11,
organizado em módulos com separação clara de responsabilidades.

Estrutura:
- models/: Modelos de domínio (Case, Lawyer, KPI)
- features/: Cálculo de features isolado em strategies
- services/: Integração com APIs externas e cache
- core/: Orquestração do algoritmo principal
- utils/: Funções utilitárias genéricas

Compatibilidade:
- Mantém API pública compatível com v2.11
- Permite migração gradual dos componentes
- Suporte a dependency injection
"""

__version__ = "3.0.0"
__author__ = "LITIG-1 Team"

# Imports principais para compatibilidade
from .models import Case, Lawyer, KPI
from .config import get_config, FEATURE_NAMES

__all__ = [
    "Case",
    "Lawyer", 
    "KPI",
    "get_config",
    "FEATURE_NAMES"
] 
"""
Algoritmo v3.0 - Arquitetura Refatorada
========================================

Este pacote contém a versão refatorada do algoritmo de matching v2.11,
organizado em módulos com separação clara de responsabilidades.

Estrutura:
- models/: Modelos de domínio (Case, Lawyer, KPI)
- features/: Cálculo de features isolado em strategies
- services/: Integração com APIs externas e cache
- core/: Orquestração do algoritmo principal
- utils/: Funções utilitárias genéricas

Compatibilidade:
- Mantém API pública compatível com v2.11
- Permite migração gradual dos componentes
- Suporte a dependency injection
"""

__version__ = "3.0.0"
__author__ = "LITIG-1 Team"

# Imports principais para compatibilidade
from .models import Case, Lawyer, KPI
from .config import get_config, FEATURE_NAMES

__all__ = [
    "Case",
    "Lawyer", 
    "KPI",
    "get_config",
    "FEATURE_NAMES"
] 
"""
Algoritmo v3.0 - Arquitetura Refatorada
========================================

Este pacote contém a versão refatorada do algoritmo de matching v2.11,
organizado em módulos com separação clara de responsabilidades.

Estrutura:
- models/: Modelos de domínio (Case, Lawyer, KPI)
- features/: Cálculo de features isolado em strategies
- services/: Integração com APIs externas e cache
- core/: Orquestração do algoritmo principal
- utils/: Funções utilitárias genéricas

Compatibilidade:
- Mantém API pública compatível com v2.11
- Permite migração gradual dos componentes
- Suporte a dependency injection
"""

__version__ = "3.0.0"
__author__ = "LITIG-1 Team"

# Imports principais para compatibilidade
from .models import Case, Lawyer, KPI
from .config import get_config, FEATURE_NAMES

__all__ = [
    "Case",
    "Lawyer", 
    "KPI",
    "get_config",
    "FEATURE_NAMES"
] 
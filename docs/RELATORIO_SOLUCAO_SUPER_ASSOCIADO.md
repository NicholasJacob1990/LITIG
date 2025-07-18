# 🎯 RELATÓRIO DE ANÁLISE E SOLUÇÃO - Sistema de Permissões Super Associado

**Versão:** 1.0  
**Data:** Janeiro 2025  
**Status:** Análise Técnica Completa

---

## 📋 RESUMO EXECUTIVO

### Problema Identificado
O sistema LITIG-1 apresenta **ambiguidade crítica de permissões** para usuários Super Associados (`lawyer_platform_associate`), que podem atuar em **3 contextos distintos**:
- **Funcionário da plataforma LITIG-1** (todas as atividades profissionais)
- **Pessoa física como cliente** (casos pessoais próprios)
- **Representante da plataforma** (parcerias e contratações em nome da LITIG-1)

**IMPORTANTE**: Super Associados **SEMPRE** agem em nome da plataforma LITIG-1 em atividades profissionais, incluindo formação de parcerias. A única exceção é quando contratam serviços como pessoa física para casos pessoais.

### Impacto Atual
- **Médio**: Confusão operacional na atuação dual
- **Baixo**: Interface congestionada com funcionalidades sobrepostas
- **Risco**: Logs de auditoria insuficientes para ações sensíveis

---

## 🔍 ANÁLISE TÉCNICA DETALHADA

### Estado Atual do Sistema

#### 1. **Arquitetura de Permissões Existente**
```41:76:packages/backend/supabase/migrations/20250131000000_create_permissions_system.sql
-- Tabela de Permissões (todas as capacidades possíveis do sistema)
CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE, -- Ex: 'nav.view.dashboard', 'cases.can.create'
    description TEXT,
    category TEXT, -- Ex: 'navigation', 'cases', 'partnerships'
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabela de Junção: Associar permissões a perfis
CREATE TABLE IF NOT EXISTS public.profile_permissions (
    profile_type TEXT NOT NULL, -- Referência ao user_role
    permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (profile_type, permission_id),
    CONSTRAINT valid_profile_type CHECK (
        profile_type IN ('client', 'lawyer_associated', 'lawyer_individual', 'lawyer_office', 'lawyer_platform_associate')
    )
);
```

#### 2. **Identificação do Super Associado**
```64:82:apps/app_flutter/lib/src/features/auth/domain/entities/user.dart
/// Verifica se o usuário é super associado
bool get isPlatformAssociate => effectiveUserRole == 'lawyer_platform_associate';

/// Verifica se o usuário é qualquer tipo de advogado
bool get isLawyer => 
  isAssociatedLawyer || 
  isIndividualLawyer || 
  isLawOffice || 
  isPlatformAssociate;
```

#### 3. **Navegação Híbrida Atual**
```370:371:apps/app_flutter/lib/src/shared/widgets/organisms/main_tabs_shell.dart
case 'lawyer_platform_associate': // NOVO: Super Associado - usa mesma navegação de captação
```

### Problemas Específicos Identificados

#### **❌ Problema 1: Ambiguidade de Contexto**
**Localização:** Interface de navegação e ações de usuário  
**Descrição:** O sistema não diferencia quando o Super Associado está:
- Atuando como funcionário da plataforma (recebendo ofertas)
- Atuando como contratante (contratando outros advogados)

#### **❌ Problema 2: Sobreposição de Funcionalidades**
**Localização:** `main_tabs_shell.dart` - Navegação principal  
**Descrição:** Acesso simultâneo a funcionalidades conflitantes:
- Aba "Ofertas" (como receptor)
- Aba "Ofertas" (como criador via parcerias)

#### **❌ Problema 3: Logs de Auditoria Insuficientes**
**Localização:** Sistema de backend - Ausência de rastreamento contextual  
**Descrição:** Não há diferenciação nos logs quando ações são executadas em contextos diferentes.

---

## 🚀 PROPOSTA DE SOLUÇÃO TÉCNICA

### **Solução 1: Sistema de Modo de Operação Explícito**

#### A. **Backend - Nova Tabela de Contexto**
```sql
-- Nova tabela para gerenciar contexto de operação
CREATE TABLE IF NOT EXISTS public.user_operation_context (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    current_mode TEXT NOT NULL CHECK (current_mode IN ('platform_employee', 'lawyer_contractor')),
    session_id TEXT,
    switched_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_user_operation_context_user_id ON public.user_operation_context(user_id);
CREATE INDEX idx_user_operation_context_session ON public.user_operation_context(session_id);
```

#### B. **Backend - Serviço de Contexto**
```python
# packages/backend/services/operation_context_service.py
from typing import Optional
from datetime import datetime

class OperationContextService:
    
    async def switch_context(
        self, 
        user_id: str, 
        target_mode: str,
        session_id: str,
        ip_address: str,
        user_agent: str
    ) -> dict:
        """
        Alterna o contexto de operação do Super Associado
        """
        # Validar se usuário é Super Associado
        if not await self._is_super_associate(user_id):
            raise PermissionError("Only Super Associates can switch context")
        
        # Registrar a mudança de contexto
        context_record = {
            "user_id": user_id,
            "current_mode": target_mode,
            "session_id": session_id,
            "ip_address": ip_address,
            "user_agent": user_agent,
            "switched_at": datetime.utcnow()
        }
        
        # Salvar no banco
        await self._save_context_switch(context_record)
        
        # Retornar permissões contextuais
        return await self._get_contextual_permissions(user_id, target_mode)
    
    async def get_current_context(self, user_id: str) -> dict:
        """
        Obtém o contexto atual do usuário
        """
        context = await supabase.table("user_operation_context")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("switched_at", desc=True)\
            .limit(1)\
            .execute()
        
        if context.data:
            return context.data[0]
        
        # Contexto padrão para Super Associados
        return {
            "current_mode": "platform_employee",
            "user_id": user_id,
            "switched_at": datetime.utcnow()
        }
```

#### C. **Frontend - Widget de Toggle Contextual**
```dart
// apps/app_flutter/lib/src/shared/widgets/context_toggle_widget.dart
class ContextToggleWidget extends StatefulWidget {
  const ContextToggleWidget({Key? key}) : super(key: key);

  @override
  State<ContextToggleWidget> createState() => _ContextToggleWidgetState();
}

class _ContextToggleWidgetState extends State<ContextToggleWidget> {
  OperationMode _currentMode = OperationMode.platformProfessional;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _getModeColor(), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getModeIcon(),
            size: 18,
            color: _getModeColor(),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getModeLabel(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _getModeColor(),
                ),
              ),
              Text(
                _getModeSubtitle(),
                style: TextStyle(
                  fontSize: 10,
                  color: _getModeColor().withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_getModeColor()),
              ),
            )
          else
            GestureDetector(
              onTap: _toggleMode,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getModeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  LucideIcons.repeat2,
                  size: 16,
                  color: _getModeColor(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getModeColor() {
    switch (_currentMode) {
      case OperationMode.platformProfessional:
        return AppColors.primary; // Azul corporativo LITIG-1
      case OperationMode.personalClient:
        return AppColors.success; // Verde para pessoal
    }
  }

  IconData _getModeIcon() {
    switch (_currentMode) {
      case OperationMode.platformProfessional:
        return LucideIcons.building2;
      case OperationMode.personalClient:
        return LucideIcons.user;
    }
  }

  String _getModeLabel() {
    switch (_currentMode) {
      case OperationMode.platformProfessional:
        return 'LITIG-1';
      case OperationMode.personalClient:
        return 'PESSOAL';
    }
  }

  String _getModeSubtitle() {
    switch (_currentMode) {
      case OperationMode.platformProfessional:
        return 'Em nome da plataforma';
      case OperationMode.personalClient:
        return 'Como pessoa física';
    }
  }

  Future<void> _toggleMode() async {
    if (_isLoading) return;

    // Mostrar modal de confirmação para troca de contexto
    final confirmed = await _showContextChangeDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final targetMode = _currentMode == OperationMode.platformProfessional 
        ? OperationMode.personalClient 
        : OperationMode.platformProfessional;

      await context.read<OperationContextBloc>().add(
        SwitchOperationMode(targetMode: targetMode),
      );

      setState(() {
        _currentMode = targetMode;
      });

      // Mostrar feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_getModeIcon(), color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Contexto alterado: ${_getModeLabel()} - ${_getModeSubtitle()}'),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: _getModeColor(),
          behavior: SnackBarBehavior.floating,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alternar contexto: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showContextChangeDialog() async {
    final targetMode = _currentMode == OperationMode.platformProfessional 
      ? OperationMode.personalClient 
      : OperationMode.platformProfessional;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Contexto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Você está prestes a alterar de:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getModeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getModeIcon(), color: _getModeColor()),
                  const SizedBox(width: 8),
                  Text('${_getModeLabel()} - ${_getModeSubtitle()}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Para:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (targetMode == OperationMode.platformProfessional 
                  ? AppColors.primary 
                  : AppColors.success).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    targetMode == OperationMode.platformProfessional 
                      ? LucideIcons.building2 
                      : LucideIcons.user,
                    color: targetMode == OperationMode.platformProfessional 
                      ? AppColors.primary 
                      : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    targetMode == OperationMode.platformProfessional 
                      ? 'LITIG-1 - Em nome da plataforma'
                      : 'PESSOAL - Como pessoa física',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ?? false;
  }
}

enum OperationMode {
  platformProfessional,  // Atividades profissionais em nome da LITIG-1
  personalClient,        // Contratação de serviços como pessoa física
}
```

### **Solução 2: Segregação de Permissões por Contexto**

#### A. **Matriz de Permissões Contextuais Revisada**
```python
# packages/backend/config/contextual_permissions.py
CONTEXTUAL_PERMISSIONS = {
    "lawyer_platform_associate": {
        "platform_professional": [
            # Atividades profissionais EM NOME DA LITIG-1
            "nav.view.offers",              # Receber ofertas da plataforma
            "offers.receive",               # Aceitar/rejeitar ofertas
            "nav.view.cases",               # Ver casos da plataforma
            "nav.view.dashboard",           # Dashboard de performance
            "quality.submit_feedback",      # Feedback de qualidade
            "platform.view_metrics",       # Métricas da plataforma
            "nav.view.partners",            # Buscar parceiros PARA A PLATAFORMA
            "nav.view.partnerships",        # Gerenciar parcerias DA PLATAFORMA
            "partnerships.create_platform", # Criar parcerias EM NOME DA LITIG-1
            "partnerships.manage_platform", # Gerenciar parcerias DA PLATAFORMA
            "offers.create_platform",       # Criar ofertas EM NOME DA LITIG-1
            "search.advanced.platform",     # Busca avançada para plataforma
            "platform.administrative",      # Funções administrativas
        ],
        "personal_client": [
            # Quando atua como PESSOA FÍSICA contratando serviços
            "nav.view.client_home",         # Dashboard de cliente
            "nav.view.find_lawyers",        # Buscar advogados para si
            "nav.view.client_cases",        # Ver casos pessoais
            "nav.view.client_messages",     # Mensagens pessoais
            "nav.view.client_profile",      # Perfil como cliente
            "cases.create_personal",        # Criar casos pessoais
            "lawyers.hire_personal",        # Contratar advogados para si
            "contracts.manage_personal",    # Gerenciar contratos pessoais
            "payments.personal",            # Pagamentos pessoais
        ]
    }
}
```

#### B. **Navegação Dinâmica Contextual**
```dart
// apps/app_flutter/lib/src/shared/config/contextual_navigation_config.dart
class ContextualNavigationConfig {
  static List<NavigationTab> getTabsForContext({
    required String userRole,
    required OperationMode currentMode,
    required List<String> permissions,
  }) {
    if (userRole != 'lawyer_platform_associate') {
      return NavigationConfig.getTabsForRole(userRole);
    }

    // Navegação específica para Super Associados baseada no contexto
    switch (currentMode) {
      case OperationMode.platformProfessional:
        return [
          NavigationTab(
            navItem: NavItem(
              label: 'Dashboard LITIG-1',
              icon: LucideIcons.building2,
              branchIndex: 0,
              badge: 'PLATAFORMA',
            ),
            requiredPermission: 'nav.view.dashboard',
          ),
          NavigationTab(
            navItem: NavItem(
              label: 'Ofertas',
              icon: LucideIcons.mailbox,
              branchIndex: 1,
            ),
            requiredPermission: 'nav.view.offers',
          ),
          NavigationTab(
            navItem: NavItem(
              label: 'Casos LITIG-1',
              icon: LucideIcons.briefcase,
              branchIndex: 2,
            ),
            requiredPermission: 'nav.view.cases',
          ),
          NavigationTab(
            navItem: NavItem(
              label: 'Parceiros',
              icon: LucideIcons.users,
              branchIndex: 3,
              badge: 'PLATAFORMA',
            ),
            requiredPermission: 'nav.view.partners',
          ),
          NavigationTab(
            navItem: NavItem(
              label: 'Parcerias',
              icon: LucideIcons.handshake,
              branchIndex: 4,
              badge: 'PLATAFORMA',
            ),
            requiredPermission: 'nav.view.partnerships',
          ),
          NavigationTab(
            navItem: NavItem(
              label: 'Mensagens',
              icon: LucideIcons.messageCircle,
              branchIndex: 5,
            ),
            requiredPermission: 'nav.view.messages',
          ),
          NavigationTab(
            navItem: NavItem(
              label: 'Perfil',
              icon: LucideIcons.user,
              branchIndex: 6,
            ),
            requiredPermission: 'nav.view.profile',
          ),
        ];

      case OperationMode.personalClient:
        return [
          NavigationTab(
            navItem: NavItem(
              label: 'Meu Painel',
              icon: LucideIcons.home,
              branchIndex: 0,
              badge: 'PESSOAL',
            ),
            requiredPermission: 'nav.view.client_home',
          ),
          NavigationTab(
            navItem: NavItem(
              label: 'Buscar Advogados',
              icon: LucideIcons.search,
              branchIndex: 1,
            ),
            requiredPermission: 'nav.view.find_lawyers',
          ),
          NavigationTab(
            navItem: NavItem(
              label: 'Meus Casos',
              icon: LucideIcons.fileText,
              branchIndex: 2,
              badge: 'PESSOAL',
            ),
            requiredPermission: 'nav.view.client_cases',
          ),
          NavigationTab(
            navItem: NavItem(
              label: 'Mensagens',
              icon: LucideIcons.messageCircle,
              branchIndex: 3,
            ),
            requiredPermission: 'nav.view.client_messages',
          ),
          NavigationTab(
            navItem: NavItem(
              label: 'Perfil',
              icon: LucideIcons.user,
              branchIndex: 4,
            ),
            requiredPermission: 'nav.view.client_profile',
          ),
        ];
    }
  }
}
```

### **Solução 3: Sistema de Auditoria Contextual**

#### A. **Backend - Logs Contextuais Revisados**
```python
# packages/backend/services/audit_service.py
from enum import Enum
from typing import Optional, Dict, Any
import json

class ContextualAuditService:
    
    async def log_contextual_action(
        self,
        user_id: str,
        action: str,
        context_mode: str,
        entity_type: str,
        entity_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        session_id: Optional[str] = None,
        on_behalf_of: str = "LITIG-1",  # SEMPRE registrar em nome de quem
    ) -> None:
        """
        Registra ação com contexto operacional específico
        SUPER ASSOCIADOS: Sempre identificar se ação é em nome da plataforma ou pessoal
        """
        
        # Enriquecer metadata com informações contextuais
        enriched_metadata = {
            **(metadata or {}),
            "on_behalf_of": on_behalf_of,
            "is_platform_action": context_mode == "platform_professional",
            "is_personal_action": context_mode == "personal_client",
        }
        
        audit_record = {
            "user_id": user_id,
            "action": action,
            "context_mode": context_mode,  # 'platform_professional' ou 'personal_client'
            "entity_type": entity_type,
            "entity_id": entity_id,
            "metadata": json.dumps(enriched_metadata),
            "session_id": session_id,
            "ip_address": self._get_request_ip(),
            "user_agent": self._get_user_agent(),
            "timestamp": datetime.utcnow(),
            "on_behalf_of": on_behalf_of,  # Campo explícito
        }
        
        await supabase.table("contextual_audit_logs").insert(audit_record).execute()
        
        # Log crítico: Alertar para ações sensíveis
        if self._is_sensitive_action(action, context_mode):
            await self._alert_sensitive_action(audit_record)
    
    def _is_sensitive_action(self, action: str, context_mode: str) -> bool:
        """
        Define ações que requerem atenção especial
        REVISADO: Separar ações da plataforma vs pessoais
        """
        sensitive_actions = {
            "platform_professional": [
                # Ações sensíveis EM NOME DA LITIG-1
                "offer.accept_high_value",         # Aceitar ofertas alto valor para plataforma
                "partnership.create_platform",     # Criar parcerias em nome da LITIG-1
                "contract.sign_platform",          # Assinar contratos pela plataforma
                "lawyer.onboard_platform",         # Cadastrar advogados na plataforma
                "quality.standards_enforce",       # Aplicar padrões de qualidade
                "platform.admin_access",           # Acessar dados administrativos
                "payments.authorize_platform",     # Autorizar pagamentos da plataforma
            ],
            "personal_client": [
                # Ações sensíveis COMO PESSOA FÍSICA
                "lawyer.hire_personal_high_value", # Contratar advogado caro pessoalmente
                "case.create_conflict_interest",   # Criar caso com conflito de interesse
                "payment.personal_high_amount",    # Pagamento pessoal alto valor
                "contract.personal_unusual_terms", # Contrato pessoal com termos incomuns
            ]
        }
        
        return action in sensitive_actions.get(context_mode, [])
    
    async def _alert_sensitive_action(self, audit_record: Dict[str, Any]) -> None:
        """
        Envia alerta para administradores sobre ações sensíveis
        REVISADO: Incluir contexto no alerta
        """
        context_description = {
            "platform_professional": "EM NOME DA LITIG-1",
            "personal_client": "COMO PESSOA FÍSICA"
        }.get(audit_record["context_mode"], "CONTEXTO DESCONHECIDO")
        
        alert_data = {
            "type": "SENSITIVE_CONTEXTUAL_ACTION",
            "severity": "MEDIUM",
            "user_id": audit_record["user_id"],
            "action": audit_record["action"],
            "context": audit_record["context_mode"],
            "context_description": context_description,
            "on_behalf_of": audit_record["on_behalf_of"],
            "timestamp": audit_record["timestamp"],
            "metadata": audit_record["metadata"],
            "alert_message": f"Super Associado executou ação sensível '{audit_record['action']}' {context_description}"
        }
        
        # Enviar para sistema de alertas
        await self.notification_service.send_admin_alert(alert_data)
        
        # Log adicional para compliance
        await self._log_compliance_record(audit_record, context_description)
    
    async def _log_compliance_record(self, audit_record: Dict[str, Any], context_description: str) -> None:
        """
        Log específico para compliance e auditoria externa
        """
        compliance_record = {
            "audit_log_id": audit_record.get("id"),
            "compliance_category": "SUPER_ASSOCIATE_SENSITIVE_ACTION",
            "user_identification": audit_record["user_id"],
            "action_performed": audit_record["action"],
            "execution_context": context_description,
            "business_justification": audit_record.get("metadata", {}).get("business_justification"),
            "supervisor_approval": audit_record.get("metadata", {}).get("supervisor_approval"),
            "timestamp": audit_record["timestamp"],
            "requires_review": True,
        }
        
        await supabase.table("compliance_audit_logs").insert(compliance_record).execute()
```

#### B. **Tabela de Auditoria Contextual**
```sql
-- Nova tabela para logs contextuais (REVISADA)
CREATE TABLE IF NOT EXISTS public.contextual_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    context_mode TEXT NOT NULL CHECK (context_mode IN ('platform_professional', 'personal_client')),
    entity_type TEXT,
    entity_id UUID,
    metadata JSONB,
    session_id TEXT,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    on_behalf_of TEXT DEFAULT 'LITIG-1', -- Campo explícito para identificar em nome de quem
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Nova tabela para compliance e auditoria externa
CREATE TABLE IF NOT EXISTS public.compliance_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    audit_log_id UUID REFERENCES public.contextual_audit_logs(id),
    compliance_category TEXT NOT NULL,
    user_identification UUID NOT NULL,
    action_performed TEXT NOT NULL,
    execution_context TEXT NOT NULL, -- "EM NOME DA LITIG-1" ou "COMO PESSOA FÍSICA"
    business_justification TEXT,
    supervisor_approval UUID REFERENCES auth.users(id),
    timestamp TIMESTAMPTZ NOT NULL,
    requires_review BOOLEAN DEFAULT TRUE,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES auth.users(id),
    review_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para consultas eficientes
CREATE INDEX idx_contextual_audit_user_id ON public.contextual_audit_logs(user_id);
CREATE INDEX idx_contextual_audit_action ON public.contextual_audit_logs(action);
CREATE INDEX idx_contextual_audit_context ON public.contextual_audit_logs(context_mode);
CREATE INDEX idx_contextual_audit_timestamp ON public.contextual_audit_logs(timestamp);

-- Índice composto para relatórios
CREATE INDEX idx_contextual_audit_user_context_time 
    ON public.contextual_audit_logs(user_id, context_mode, timestamp);
```

---

## 🎯 IMPLEMENTAÇÃO FASEADA

### **Fase 1: Base Técnica (Sprint 1 - 2 semanas)**
- ✅ Criação da tabela `user_operation_context`
- ✅ Implementação do `OperationContextService`
- ✅ Criação do enum `OperationMode` no frontend
- ✅ Implementação básica do `ContextToggleWidget`

### **Fase 2: Integração de Permissões (Sprint 2 - 2 semanas)**
- ✅ Configuração da matriz de permissões contextuais
- ✅ Integração com sistema de permissões existente
- ✅ Atualização do `AuthBloc` para suporte contextual
- ✅ Testes de navegação contextual

### **Fase 3: Sistema de Auditoria (Sprint 3 - 1 semana)**
- ✅ Implementação da tabela `contextual_audit_logs`
- ✅ Integração do `ContextualAuditService`
- ✅ Configuração de alertas para ações sensíveis
- ✅ Dashboard de auditoria para administradores

### **Fase 4: Interface e UX (Sprint 4 - 1 semana)**
- ✅ Refinamento do design do toggle contextual
- ✅ Implementação de indicadores visuais
- ✅ Testes de usabilidade
- ✅ Documentação do usuário

---

## 📊 MÉTRICAS DE SUCESSO

### **Métricas Operacionais**
- **Redução de 90%** em tickets de suporte relacionados à confusão de contexto
- **Aumento de 25%** na satisfação do usuário Super Associado
- **100%** de rastreabilidade em ações contextuais

### **Métricas Técnicas**
- **Zero** conflitos de permissão após implementação
- **< 200ms** tempo de resposta para troca de contexto
- **100%** cobertura de testes para funcionalidades contextuais

### **Métricas de Segurança**
- **100%** de ações sensíveis logadas e auditadas
- **< 5 minutos** tempo de detecção para ações suspeitas
- **Zero** vazamentos de dados entre contextos

---

## 🚀 PRÓXIMOS PASSOS

### **Imediato (Esta Sprint)**
1. **Aprovação da proposta técnica** pelo time de arquitetura
2. **Criação das tabelas de base** no ambiente de desenvolvimento
3. **Implementação do serviço de contexto** básico

### **Curto Prazo (Próximas 2 Sprints)**
1. **Desenvolvimento do toggle contextual** no frontend
2. **Integração com sistema de permissões** existente
3. **Testes de integração** completos

### **Médio Prazo (1-2 Meses)**
1. **Deploy em produção** com feature flag
2. **Monitoramento de métricas** de sucesso
3. **Refinamentos** baseados em feedback real

---

## 🔒 CONSIDERAÇÕES DE SEGURANÇA

### **Validações Obrigatórias**
- ✅ Verificar se usuário é Super Associado antes de permitir troca
- ✅ Registrar todas as trocas de contexto com timestamp
- ✅ Invalidar sessões ativas ao trocar contexto
- ✅ Limitar frequência de troca de contexto (rate limiting)

### **Auditoria Reforçada**
- ✅ Log detalhado de todas as ações em cada contexto
- ✅ Alertas automáticos para padrões suspeitos
- ✅ Relatórios mensais de uso contextual
- ✅ Revisão trimestral de permissões contextuais

---

**Relatório elaborado em conformidade com as diretrizes técnicas do LITIG-1**  
**Responsável:** Sistema de Análise Técnica  
**Próxima revisão:** Após implementação da Fase 1 
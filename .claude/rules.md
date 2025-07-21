

# Princípios de Desenvolvimento Flutter

## Base Arquitetural
- **Siga rigorosamente os princípios SOLID** em toda implementação
- **Análise holística obrigatória**: Leia todo diretório antes de alterações
- **ZERO simplificações**: Corrija problemas na raiz, não contorne

## Verificação Ativa (Confie, mas Verifique)
Antes de codificar, **SEMPRE** verifique:
- Backend: `packages/backend/routes/` e implementações completas
- Frontend: `apps/app_flutter/lib/src/features/` e BLoCs registrados
- Navegação: `app_router.dart` e `injection_container.dart` atualizados

## Implementação Holística
Nova funcionalidade deve abranger:
- **Backend**: API + banco + lógica de negócio
- **Frontend**: BLoC + UI + serviços
- **Navegação**: Rotas + menus contextuais

## Documentação Obrigatória
Arquivo `@status.md` **DEVE** ser atualizado após qualquer alteração:
```markdown
## [YYYY-MM-DD] - [Funcionalidade]
- Backend/Frontend/Navegação: [implementações]
- Arquivos: [criados/alterados]
- Status: [CONCLUÍDO/PARCIAL/PENDENTE]
---
```

## To-Dos e Rastreabilidade
- **Documente todos os TO-DOs** com complexidade proporcional
- **NUNCA delete** histórico do @status.md
- Mantenha rastreabilidade total de alterações




2.  **Princípio da Verificação (Confie, mas Verifique):** Nunca presuma que um plano foi implementado. Antes de codificar, **SEMPRE** verifique o estado atual do código para determinar o que já foi concluído. A verificação deve incluir:
    *   Existência de arquivos de rotas no **backend** (`packages/backend/routes/`).
    *   Existência de diretórios de `features` no **frontend** (`apps/app_flutter/lib/src/features/`).
    *   Registro de BLoCs e serviços no `injection_container.dart`.
    *   Configuração de rotas no `app_router.dart`.

3.  **Implementação Holística:** Ao implementar uma nova funcionalidade de um plano, garanta que ela seja consistente com as `features` já existentes. Qualquer implementação deve considerar e, se necessário, modificar de forma coesa:
    *   O **Backend** (API e banco de dados).
    *   O **Frontend** (lógica de estado, UI e serviços).
    *   A **Navegação** (rotas e menus contextuais).

4.  **Dever de Documentação:** Após **qualquer** criação ou alteração de código baseada em um plano, o arquivo `@status.md` **deve** ser atualizado com um resumo claro da implementação, referenciando qual documento de planejamento foi seguido e o que foi concluído.


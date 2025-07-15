
### **Regra de Implementação: Guia Mestre de Arquitetura e Desenvolvimento**

O desenvolvimento deste projeto é estritamente guiado pelos documentos de planejamento encontrados em `docs/`. Antes de iniciar **qualquer** implementação, modificação ou análise de código, siga estas diretrizes:

1.  **Ordem de Dependência Lógica:** As funcionalidades devem ser entendidas e implementadas na seguinte ordem de prioridade, pois uma depende da outra. Sempre valide o estado da dependência anterior antes de prosseguir.
    *   **1º (Fundação): Entidades B2B (`Firms`)**
        *   *Documento de Referência:* `docs/system/B2B_IMPLEMENTATION_PLAN.md`
    *   **2º (Motor): Busca Avançada (`Search`)**
        *   *Documento de Referência:* `PLANO_SISTEMA_BUSCA_AVANCADA.md`
    *   **3º (Transação): Sistema de Ofertas (`Offers`)**
        *   *Documento de Referência:* `PLANO_SISTEMA_OFERTAS.md`
    *   **4º (Colaboração): Parcerias (`Partnerships`)**
        *   *Documentos de Referência:* `docs/FLUTTER_PARTNERSHIPS_PLAN.md` e `docs/system/parcerias.md`
    *   **5º (Interface): Navegação e Contexto Duplo**
        *   *Documentos de Referência:* `docs/system/ANALISE_NAVEGACAO_FLUTTER.md` e `docs/system/DUAL_CONTEXT_IMPLEMENTATION_PLAN.md`

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


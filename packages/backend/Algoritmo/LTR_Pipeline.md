# Pipeline de Learning-to-Rank (LTR)

Este documento descreve o pipeline de *Learning-to-Rank* (LTR), implementado para mover o algoritmo de match de um modelo com pesos estáticos para um sistema que aprende e se otimiza continuamente com base no feedback real dos usuários.

## 1. Visão Geral

O objetivo do LTR é ajustar dinamicamente os pesos (`W_A`, `W_S`, `W_T`, etc.) das sete features do algoritmo de match. Em vez de pesos fixos (ex: `A: 0.30`, `S: 0.25`), o sistema aprende quais features são mais preditivas de um "match de sucesso" (ex: um contrato assinado e concluído).

O fluxo funciona como um ciclo de feedback:
1.  **Servir Recomendações**: A API recomenda advogados para um caso usando os pesos atuais.
2.  **Coletar Feedback**: O sistema registra as interações do usuário (advogado aceitou/recusou a oferta, contrato foi ganho/perdido) como *labels* de relevância.
3.  **Treinar Modelo**: Um job periódico executa um processo de ETL sobre os logs, treina um modelo `LGBMRanker` com os dados coletados e extrai novos pesos.
4.  **Atualizar Pesos**: O algoritmo de match recarrega os novos pesos, melhorando a qualidade das futuras recomendações.

## 2. Componentes do Pipeline

O pipeline é composto por três scripts principais:

### a) `algoritmo_match_v2_1_stable_readable.py` (Instrumentação)
-   **Responsabilidade**: Gerar os dados brutos.
-   **Funcionamento**: A cada recomendação de match, o `AUDIT_LOGGER` registra um evento em JSON contendo o `case_id`, `lawyer_id` e todas as `features` calculadas. Os serviços de ofertas e contratos também logam os eventos de feedback (`accepted`, `declined`, `won`, `lost`).

### b) `backend/jobs/ltr_export.py` (ETL)
-   **Responsabilidade**: Transformar logs brutos em um dataset de treino.
-   **Funcionamento**:
    1.  Lê o arquivo de log (`logs/audit.log`).
    2.  Filtra apenas os eventos relevantes (`match` e `feedback`).
    3.  Mapeia os labels categóricos (ex: "won") para scores de relevância numérica (ex: 3).
    4.  Agrupa os dados por "query" (o `case_id`).
    5.  Salva o dataset limpo e estruturado em `data/ltr_dataset.parquet`.

### c) `backend/jobs/ltr_train.py` (Treinador)
-   **Responsabilidade**: Treinar o modelo de ranking e gerar novos pesos.
-   **Funcionamento**:
    1.  Carrega o dataset `data/ltr_dataset.parquet`.
    2.  Treina um modelo `lightgbm.LGBMRanker`. Este modelo é projetado especificamente para aprender a ordenar listas de itens.
    3.  Salva o artefato do modelo treinado em `backend/models/ltr_model.txt`.
    4.  Extrai a "importância" de cada feature do modelo treinado.
    5.  Normaliza essas importâncias para que somem 1 e as salva como os novos pesos em `backend/models/ltr_weights.json`.

## 3. Carregamento Dinâmico de Pesos

O `algoritmo_match_v2_1_stable_readable.py` foi modificado para carregar os pesos dinamicamente:
-   Na inicialização, ele tenta carregar os pesos de `backend/models/ltr_weights.json`.
-   Se o arquivo não existir ou for inválido, ele utiliza os `DEFAULT_WEIGHTS` como fallback seguro.
-   O endpoint de API `/internal/reload_weights` permite forçar o recarregamento dos pesos sem a necessidade de reiniciar a aplicação, facilitando o deploy de novos modelos. 
### **Plano de Ação: Evolução do Motor de Match v2.4+**

**Objetivo Geral:** Transformar o motor de match de um sistema baseado em heurísticas para uma plataforma data-driven, auditável e escalável, implementando as recomendações de curto, médio e longo prazo.

---

### **Sprint 4: Robustez e Configurabilidade (Quick Wins)**

*   **Duração:** 2 semanas
*   **Meta Principal:** Implementar melhorias de alto impacto e baixo esforço para aumentar a confiabilidade, a precisão e a auditabilidade do algoritmo.

| User Story | Tarefas Técnicas | Documentação Associada |
| :--- | :--- | :--- |
| **Como desenvolvedor, quero que o cache de um advogado seja invalidado automaticamente quando seus dados-chave mudam, para garantir que o matching sempre use dados frescos.** | **1. Invalidação Ativa do Cache:** <br> • Identificar todos os endpoints que atualizam dados de um advogado (ex: `update_equity_data`). <br> • Após uma atualização bem-sucedida no banco, adicionar a chamada `await cache.delete(f"match:cache:{lawyer_id}")`. <br> • **Importante:** A chave do cache deve ser consistente entre a criação e a invalidação. | • Adicionar uma seção no `README_TECNICO.md` sobre a estratégia de cache e o processo de invalidação. |
| **Como administrador, quero configurar os parâmetros de diversidade (τ e λ) via variáveis de ambiente para poder ajustar o algoritmo sem deploy.** | **2. Parâmetros de Diversidade Configuráveis:** <br> • No `algoritmo_match.py`, alterar a definição das constantes `DIVERSITY_TAU` e `DIVERSITY_LAMBDA` para lerem de variáveis de ambiente com um fallback. <br> Ex: `DIVERSITY_TAU = float(os.getenv("DIVERSITY_TAU", 0.30))` | • Documentar as novas variáveis de ambiente no arquivo `.env.example`. |
| **Como usuário de um caso simples, quero que o match priorize o tempo real de deslocamento em vez da distância em linha reta.** | **3. Distância Real para Casos Simples:** <br> • Em `FeatureCalculator.geo_score()`, adicionar uma condição: `if self.case.complexity == "LOW"`. <br> • Dentro da condição, fazer uma chamada a um novo serviço (ex: `map_service.get_route_time()`) que consultaria uma API de rotas. <br> • Manter o cálculo de Haversine como fallback ou para outros níveis de complexidade. | • Documentar a nova dependência de uma API de rotas (Google Maps, OSRM, etc.) na arquitetura. |
| **Como plataforma, quero filtrar reviews de baixa qualidade para garantir que a métrica de avaliação seja mais confiável.** | **4. Limpeza de Reviews (Anti-Spam):** <br> • Antes do cálculo do `review_score`, criar uma função `_clean_reviews` que filtre a lista de reviews, removendo textos muito curtos ou com alta repetição de palavras. <br> • Aplicar essa limpeza antes de calcular a média das avaliações. | • Descrever a heurística de anti-spam na documentação do algoritmo. |

---

### **Sprint 5: Rumo ao LTR e Fairness Multi-Eixo**

*   **Duração:** 3 semanas (maior complexidade)
*   **Meta Principal:** Iniciar a transição para um modelo supervisionado (LTR) e implementar uma abordagem de fairness mais sofisticada e completa.

| User Story | Tarefas Técnicas | Documentação Associada |
| :--- | :--- | :--- |
| **Como cientista de dados, quero usar dados históricos para treinar os pesos do algoritmo de match e melhorar a relevância.** | **1. Pipeline de Treinamento LTR (Prova de Conceito):** <br> • Criar um script para extrair dados de log (indicações vs. aceites) e formatá-los para um modelo LTR. <br> • Treinar um modelo base (ex: LightGBM Ranker) localmente. <br> • Exportar os pesos aprendidos para o arquivo `ltr_weights.json`. <br> • O `algoritmo_match.py` já lê este arquivo, então a integração é direta. | • Criar um `README_LTR.md` explicando o processo de treinamento, o formato dos dados e como atualizar os pesos em produção. |
| **Como plataforma, quero garantir o equilíbrio de oportunidades em múltiplos eixos de diversidade simultaneamente.** | **2. Fairness Multi-Eixo Sequencial:** <br> • Refatorar a lógica de `rank()` no `algoritmo_match.py`. <br> • Em vez de somar todos os boosts, aplicar o `_calculate_dimension_boost` de forma sequencial para cada dimensão (`gender`, `ethnicity`, `pcd`). <br> • **Após cada passe**, reordenar a lista `elite` antes de aplicar o próximo boost. Isso garante que a correção de um eixo não desfaça a outra. | • Atualizar a documentação do `EQUITY_MODULE.md` para descrever a nova abordagem de fairness sequencial. |
| **Como engenheiro, quero que a busca por similaridade de casos seja performática para escalar o sistema.** | **3. Implementar Busca por Similaridade com ANN:** <br> • Alterar a consulta em `algoritmo_match.py` que busca `casos_historicos_embeddings` para usar o índice IVFFlat do `pgvector`, fazendo a busca por similaridade de cosseno diretamente no banco. <br> • Isso substitui o cálculo da similaridade em memória e é muito mais escalável. | • Atualizar a documentação da arquitetura para refletir o uso de índices ANN. |

---

### **Roadmap de Longo Prazo (v3.0+)**

| Ação Sugerida | Objetivo Estratégico |
| :--- | :--- |
| **Confiança Estatística (Intervalo Beta):** | Aumentar a robustez do score de "Taxa de Êxito", tornando-o mais confiável e resistente a manipulações com baixo volume de dados. |
| **Avaliação Online A/B:** | Tomar decisões sobre o algoritmo e pesos de fairness com base em evidências empíricas (CTR, NPS) em vez de heurísticas. |
| **Explain-back Simplificado (XAI):** | Aumentar a confiança do cliente final no sistema, gerando explicações em linguagem natural sobre por que um profissional foi recomendado. |
| **Certificação Externa de IA Responsável:** | Obter um selo de mercado que valide as práticas de IA responsável da plataforma, reduzindo riscos reputacionais e abrindo portas para clientes corporativos e governamentais. | 
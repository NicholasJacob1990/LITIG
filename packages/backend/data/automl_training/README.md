# AutoML Training Datasets

Este diretório armazena os datasets usados para treinar o modelo de ranqueamento (LTR - Learning-to-Rank) de forma automática usando AutoML.

## Formato dos Dados

O job de AutoML (`run_automl_ranking.py`) espera um arquivo CSV (`matches_history.csv`) neste diretório com a seguinte estrutura:

| case_id | lawyer_id | feature_S_qualis | feature_T_titulacao | feature_E_experiencia | feature_M_multidisciplinar | feature_C_complexidade | feature_P_honorarios | feature_R_reputacao | feature_Q_qualificacao | similarity_score | offer_accepted |
|---|---|---|---|---|---|---|---|---|---|---|---|
| uuid | uuid | float | float | float | float | float | float | float | float | float | int (1 ou 0) |

### Descrição das Colunas:
- **case_id**: Identificador único do caso.
- **lawyer_id**: Identificador único do advogado que recebeu a oferta.
- **feature_...**: Os valores normalizados (0 a 1) para cada uma das 8 features calculadas pelo `algoritmo_match`.
- **similarity_score**: O score de similaridade de cosseno do embedding do caso com o do advogado.
- **offer_accepted**: A nossa variável alvo. **1** se o cliente aceitou a oferta, **0** caso contrário.

## Geração do Dataset

Um script ou query no banco de dados deve ser executado periodicamente para gerar este arquivo a partir das tabelas `cases`, `lawyers` e `offers`, consolidando o histórico de interações para o re-treinamento do modelo de pesos. 
 
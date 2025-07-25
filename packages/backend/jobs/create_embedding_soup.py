#!/usr/bin/env python3
# backend/jobs/create_embedding_soup.py
"""
Job para criar uma "Sopa de Modelos" (Model Soup) de embeddings.
Esta técnica consiste em fazer a média dos pesos de vários modelos
fine-tuned para criar um único modelo mais robusto e performático.

Referência: https://jina.ai/news/model-soups-recipe-for-embeddings/
"""
import os
import torch
from sentence_transformers import SentenceTransformer
from collections import OrderedDict

# --- Configuração ---
# Modelo base que foi usado para o fine-tuning
BASE_MODEL = 'all-MiniLM-L6-v2'

# Diretório onde os modelos fine-tuned (hipotéticos) estariam salvos
# Em um cenário real, cada um seria o resultado de um processo de fine-tuning.
FINETUNED_MODELS_DIR = 'models/finetuned/'

# Paths para os modelos (simulando 3 modelos fine-tuned)
MODEL_PATHS = {
    'model_A_case_similarity': os.path.join(FINETUNED_MODELS_DIR, 'model_A'),
    'model_B_cv_matching': os.path.join(FINETUNED_MODELS_DIR, 'model_B'),
    'model_C_doc_search': os.path.join(FINETUNED_MODELS_DIR, 'model_C'),
}

# Path de saída para o nosso novo modelo "sopa"
OUTPUT_PATH = 'models/litig-embedding-soup-v1'

# --- Simulação: Preparar modelos fine-tuned ---
def prepare_finetuned_models():
    """
    Simula a existência de modelos fine-tuned.
    Em um cenário real, esta função não seria necessária, pois os modelos
    seriam o resultado de jobs de treinamento separados.
    Para este exemplo, apenas salvamos o modelo base em cada diretório.
    """
    print("Simulando a preparação de modelos fine-tuned...")
    if not os.path.exists(BASE_MODEL):
        print(f"Baixando modelo base '{BASE_MODEL}'...")
        model = SentenceTransformer(BASE_MODEL)
    else:
        model = SentenceTransformer(BASE_MODEL)

    for name, path in MODEL_PATHS.items():
        if not os.path.exists(path):
            print(f"Salvando modelo de simulação em '{path}'...")
            model.save(path)
    print("Modelos de simulação prontos.")


# --- Lógica da Sopa de Modelos ---
def create_model_soup():
    """
    Carrega vários modelos e cria uma "sopa" fazendo a média de seus pesos.
    """
    print("\nIniciando a criação da Sopa de Modelos...")
    
    # Carregar todos os modelos fine-tuned
    models = [SentenceTransformer(path) for path in MODEL_PATHS.values()]
    print(f"{len(models)} modelos carregados para a sopa.")

    # Pegar o state_dict do primeiro modelo como referência
    avg_state_dict = models[0].state_dict()

    # Somar os pesos dos outros modelos
    for model in models[1:]:
        for key in avg_state_dict:
            if avg_state_dict[key].data.dtype == torch.int64:
                continue # não fazemos média em pesos int64
            avg_state_dict[key].data += model.state_dict()[key].data

    # Fazer a média dos pesos
    for key in avg_state_dict:
         if avg_state_dict[key].data.dtype == torch.int64:
            continue
         avg_state_dict[key].data /= len(models)
    
    print("Média dos pesos calculada com sucesso.")

    # Criar um novo modelo a partir do modelo base e carregar os pesos médios
    soup_model = SentenceTransformer(BASE_MODEL)
    soup_model.load_state_dict(avg_state_dict)
    
    # Salvar o novo modelo "sopa"
    print(f"Salvando o novo modelo 'sopa' em '{OUTPUT_PATH}'...")
    soup_model.save(OUTPUT_PATH)
    print(f"Sopa de Modelos salva com sucesso em '{OUTPUT_PATH}'!")


if __name__ == "__main__":
    prepare_finetuned_models()
    create_model_soup() 
 
import sys
import os

# Adiciona o diretório raiz do projeto ao PYTHONPATH
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.database import engine
from app.models import Base
from app.models.user import User
from app.models.case import Case
from app.models.premium_criteria import PremiumCriteria

def sync_database():
    print("Iniciando a criação de tabelas...")
    try:
        # Garante que todos os modelos sejam "conhecidos" pela Base antes de criar
        # A importação acima já faz isso
        Base.metadata.create_all(bind=engine)
        print("Tabelas criadas com sucesso (se ainda não existiam).")
    except Exception as e:
        print(f"Ocorreu um erro ao criar as tabelas: {e}")

if __name__ == "__main__":
    sync_database() 
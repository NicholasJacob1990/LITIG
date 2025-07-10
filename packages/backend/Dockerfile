# Use uma imagem Python oficial como imagem base
FROM python:3.10-slim

# Define o diretório de trabalho no container
WORKDIR /app

# Copia os arquivos de dependências
COPY backend/requirements.txt .

# Instala as dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copia o resto do código da aplicação para o diretório de trabalho
COPY backend/ ./backend/

# Expõe a porta que o Gunicorn irá rodar
EXPOSE 8000

# Comando para rodar a aplicação usando Gunicorn
# Isso é mais robusto para produção do que o uvicorn --reload
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "backend.main:app", "--bind", "0.0.0.0:8000"] 
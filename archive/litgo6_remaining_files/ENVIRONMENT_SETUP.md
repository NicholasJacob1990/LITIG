# 🔧 Guia de Configuração de Ambiente - LITGO

Este guia fornece instruções detalhadas para configurar o ambiente de desenvolvimento do Sistema de Match Jurídico Inteligente LITGO.

## 📋 Pré-requisitos

### Sistema Operacional
- **macOS**: Versão 10.15 ou superior
- **Windows**: Windows 10/11 com WSL2
- **Linux**: Ubuntu 20.04 LTS ou superior

### Ferramentas Necessárias
- **Node.js**: v18.x ou superior
- **Python**: v3.11 ou superior
- **Flutter**: v3.22.0 ou superior
- **Git**: Versão mais recente
- **Docker**: Para serviços auxiliares (Redis, PostgreSQL)

## 🚀 Configuração Inicial

### 1. Clone do Repositório
```bash
git clone https://github.com/NicholasJacob1990/LITIG.git
cd LITIG
```

### 2. Configuração das Variáveis de Ambiente

#### Backend Python
```bash
cd LITGO6
cp env.example .env
```

Edite o arquivo `.env` com suas configurações:

```env
# Supabase (Desenvolvimento Local)
EXPO_PUBLIC_SUPABASE_URL=http://localhost:54321
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
SUPABASE_SERVICE_KEY=sua_chave_de_servico_aqui
EXPO_PUBLIC_SUPABASE_ANON_KEY=sua_chave_anonima_aqui

# APIs de IA
ANTHROPIC_API_KEY=sk-ant-sua-chave-aqui
OPENAI_API_KEY=sk-sua-chave-openai-aqui

# Redis
REDIS_URL=redis://localhost:6379/0

# API Backend
EXPO_PUBLIC_API_URL=http://127.0.0.1:8000/api
API_BASE_URL=http://127.0.0.1:8000

# Ambiente
ENVIRONMENT=development
DEBUG_MODE=true
LOG_LEVEL=debug
```

#### Frontend React Native
```bash
# As variáveis com prefixo EXPO_PUBLIC_ são automaticamente disponibilizadas
# no frontend através do arquivo .env na raiz do projeto
```

#### Flutter
```bash
cd meu_app
# Criar arquivo de configuração do Flutter
cat > .env << EOF
API_BASE_URL=http://127.0.0.1:8000/api
ENVIRONMENT=development
DEBUG_MODE=true
EOF
```

### 3. Instalação de Dependências

#### Backend Python
```bash
cd LITGO6
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
# ou
venv\Scripts\activate     # Windows

pip install -r backend/requirements.txt
```

#### Frontend React Native/Expo
```bash
cd LITGO6
npm install
```

#### Flutter
```bash
cd meu_app
flutter pub get
```

### 4. Configuração de Serviços

#### Supabase Local
```bash
# Instalar Supabase CLI
npm install -g @supabase/cli

# Inicializar Supabase local
cd LITGO6
supabase start

# Executar migrações
supabase migration up
```

#### Redis Local
```bash
# macOS
brew install redis
brew services start redis

# Ubuntu
sudo apt update
sudo apt install redis-server
sudo systemctl start redis-server

# Windows (WSL2)
sudo apt install redis-server
sudo service redis-server start
```

#### PostgreSQL (se não usar Supabase)
```bash
# macOS
brew install postgresql
brew services start postgresql

# Ubuntu
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

## 🔐 Configuração de APIs Externas

### Google Calendar API
1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione existente
3. Ative a Google Calendar API
4. Configure OAuth consent screen
5. Crie credenciais OAuth 2.0:
   - **iOS**: Bundle ID: `com.anonymous.boltexponativewind`
   - **Android**: Package name: `com.anonymous.boltexponativewind`
   - **Web**: Redirect URIs: `https://auth.expo.io/@seu_username/litgo`

### Anthropic Claude API
1. Registre-se em [Anthropic Console](https://console.anthropic.com/)
2. Obtenha sua API key
3. Configure limites de uso apropriados

### OpenAI API
1. Registre-se em [OpenAI Platform](https://platform.openai.com/)
2. Obtenha sua API key
3. Configure billing se necessário

## 🧪 Verificação da Configuração

### Teste Backend
```bash
cd LITGO6
source venv/bin/activate
cd backend
python -m pytest tests/ -v
```

### Teste Frontend
```bash
cd LITGO6
npm test
```

### Teste Flutter
```bash
cd meu_app
flutter test
```

## 🚀 Executar o Sistema

### Backend
```bash
cd LITGO6
source venv/bin/activate
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend React Native
```bash
cd LITGO6
npm start
# ou
npx expo start
```

### Flutter
```bash
cd meu_app
flutter run
```

## 🔧 Configurações Avançadas

### Configuração de CI/CD
O projeto já possui configuração de CI/CD no arquivo `.github/workflows/ci.yml`. Configure os seguintes secrets no GitHub:

```yaml
# GitHub Secrets necessários
CODECOV_TOKEN: Token do Codecov
SNYK_TOKEN: Token do Snyk para análise de segurança
SUPABASE_ACCESS_TOKEN: Token de acesso do Supabase
ANTHROPIC_API_KEY: Chave da API Anthropic
OPENAI_API_KEY: Chave da API OpenAI
```

### Configuração de Monitoramento
```bash
# Prometheus (opcional)
docker run -d -p 9090:9090 prom/prometheus

# Grafana (opcional)
docker run -d -p 3000:3000 grafana/grafana
```

## 📱 Configuração Mobile

### iOS
```bash
cd LITGO6
npx pod-install ios
```

### Android
```bash
cd LITGO6
npx react-native run-android
```

### Flutter Mobile
```bash
cd meu_app
flutter build apk --debug      # Android
flutter build ios --debug      # iOS
```

## 🐳 Docker (Opcional)

### Executar com Docker Compose
```bash
cd LITGO6
docker-compose up -d
```

### Configuração Docker
```yaml
# docker-compose.yml já configurado no projeto
# Inclui: PostgreSQL, Redis, Backend, Frontend
```

## 🔍 Troubleshooting

### Problemas Comuns

1. **Erro de dependências Python**
   ```bash
   pip install --upgrade pip
   pip install -r backend/requirements.txt --force-reinstall
   ```

2. **Erro de Metro/Expo**
   ```bash
   npx expo install --fix
   npx expo start --clear
   ```

3. **Erro Flutter**
   ```bash
   flutter clean
   flutter pub get
   flutter doctor
   ```

4. **Erro de conexão com banco**
   ```bash
   # Verificar se Supabase está rodando
   supabase status
   
   # Reiniciar serviços
   supabase stop
   supabase start
   ```

## 📚 Recursos Adicionais

- [Documentação Supabase](https://supabase.com/docs)
- [Documentação Expo](https://docs.expo.dev/)
- [Documentação Flutter](https://flutter.dev/docs)
- [Documentação FastAPI](https://fastapi.tiangolo.com/)

## 🆘 Suporte

Se encontrar problemas:
1. Verifique os logs do sistema
2. Consulte a documentação específica
3. Abra uma issue no repositório
4. Entre em contato com a equipe de desenvolvimento

---

**Nota**: Este guia é atualizado regularmente. Sempre verifique a versão mais recente no repositório. 
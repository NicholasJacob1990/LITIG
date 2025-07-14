# Testes E2E (End-to-End) - Sistema B2B Law Firms

Este diretório contém testes de integração end-to-end para validar o fluxo completo do sistema B2B Law Firms.

## 📋 Estrutura dos Testes

### 1. `b2b_flow_test.dart`
Testa o fluxo completo B2B do ponto de vista do cliente:

- **Fluxo Principal**: Cliente cria caso corporativo → visualiza ranking com escritórios → contrata escritório
- **Visualização de Detalhes**: Cliente visualiza detalhes do escritório antes de contratar
- **Comparação**: Cliente compara múltiplos escritórios
- **Tratamento de Erros**: Cenários sem escritórios disponíveis
- **Filtros e Busca**: Funcionalidades de filtro e busca de escritórios

### 2. `partnership_flow_test.dart`
Testa o fluxo de parcerias entre advogados e escritórios:

- **Busca de Parcerias**: Advogado busca e seleciona escritórios para parceria
- **Dashboard de Parcerias**: Visualização de parcerias ativas, enviadas e recebidas
- **Advogado Associado**: Visualização de informações do escritório no dashboard e perfil

## 🚀 Como Executar

### Pré-requisitos
1. Flutter SDK instalado
2. Dependência `integration_test` no `pubspec.yaml`
3. Backend rodando na porta 8080 (ou configurar URL no teste)

### Comandos

```bash
# Executar todos os testes E2E
flutter test integration_test/

# Executar teste específico
flutter test integration_test/b2b_flow_test.dart
flutter test integration_test/partnership_flow_test.dart

# Executar com dispositivo específico
flutter test integration_test/ -d <device_id>

# Executar com logs detalhados
flutter test integration_test/ --verbose
```

### Executar no Emulador/Dispositivo
```bash
# Android
flutter test integration_test/ -d android

# iOS
flutter test integration_test/ -d ios

# Chrome (para testes web)
flutter test integration_test/ -d chrome
```

## 🧪 Cenários de Teste

### Fluxo B2B Completo
1. **Login do Cliente**
   - Autenticação com credenciais válidas
   - Verificação de redirecionamento para dashboard

2. **Criação de Caso Corporativo**
   - Preenchimento de formulário com dados corporativos
   - Valor estimado alto para acionar matching B2B
   - Verificação de caso criado com sucesso

3. **Visualização de Ranking**
   - Verificação de escritórios no ranking
   - Indicadores visuais de escritórios vs advogados individuais
   - Exibição de KPIs (taxa de sucesso, casos ativos)

4. **Contratação de Escritório**
   - Seleção de escritório do ranking
   - Visualização de detalhes
   - Processo de contratação
   - Verificação de contrato criado

### Fluxo de Parcerias
1. **Busca de Escritórios**
   - Listagem de escritórios disponíveis
   - Aplicação de filtros
   - Seleção de escritório

2. **Proposta de Parceria**
   - Envio de proposta
   - Verificação de sucesso

3. **Dashboard de Parcerias**
   - Visualização de parcerias ativas
   - Propostas enviadas e recebidas
   - Estados diferentes das parcerias

### Advogado Associado
1. **Dashboard com Informações do Escritório**
   - Seção "Meu Escritório"
   - KPIs do escritório
   - Informações da equipe

2. **Perfil com Vínculo**
   - Seção de escritório no perfil
   - Função do advogado
   - Ações contextuais

## 🔧 Configuração de Ambiente

### Dados de Teste
Os testes usam dados mockados ou de teste:

```dart
// Credenciais de teste
cliente@test.com / password123     // Cliente
advogado@test.com / password123    // Advogado de captação
associado@test.com / password123   // Advogado associado
```

### Backend Mock
Para testes isolados, configure mocks para:
- Endpoints de autenticação
- Endpoints de escritórios (/firms/*)
- Endpoints de casos (/cases/*)
- Endpoints de contratos (/contracts/*)

### Configuração CI/CD
```yaml
# .github/workflows/integration_tests.yml
name: Integration Tests
on: [push, pull_request]

jobs:
  integration_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v1
      - run: flutter pub get
      - run: flutter test integration_test/
```

## 📊 Métricas e Relatórios

### Cobertura de Testes
- ✅ Fluxo completo B2B cliente
- ✅ Fluxo de parcerias advogado
- ✅ Dashboard advogado associado
- ✅ Tratamento de erros
- ✅ Filtros e busca

### Tempo de Execução
- Fluxo B2B completo: ~2-3 minutos
- Fluxo de parcerias: ~1-2 minutos
- Total: ~5-7 minutos

## 🐛 Troubleshooting

### Problemas Comuns

1. **Timeout nos testes**
   ```bash
   # Aumentar timeout
   flutter test integration_test/ --timeout=10m
   ```

2. **Elementos não encontrados**
   - Verificar se o backend está rodando
   - Confirmar dados de teste no banco
   - Verificar seletores de UI

3. **Falhas de rede**
   - Configurar URLs corretas no código
   - Verificar conectividade com backend
   - Usar mocks para testes isolados

### Logs e Debug
```bash
# Logs detalhados
flutter test integration_test/ --verbose

# Debug específico
flutter test integration_test/b2b_flow_test.dart --verbose
```

## 🔄 Manutenção

### Atualização dos Testes
- Atualizar seletores quando UI mudar
- Adicionar novos cenários para novas funcionalidades
- Manter dados de teste atualizados

### Revisão Regular
- Executar testes em diferentes dispositivos
- Verificar performance dos testes
- Atualizar documentação conforme necessário 
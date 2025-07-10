# 🚀 Flutter Setup - LITGO5

Este README contém as instruções essenciais para configurar e executar o projeto Flutter do LITGO5.

## 📋 Pré-requisitos

### 1. Flutter SDK
```bash
# Instalar Flutter (via FVM - recomendado)
dart pub global activate fvm
fvm install 3.16.0
fvm use 3.16.0

# Ou instalação direta
# https://docs.flutter.dev/get-started/install
```

### 2. Ferramentas de Desenvolvimento
```bash
# Android Studio (para Android)
# Xcode (para iOS - apenas macOS)
# VS Code com extensões Flutter/Dart
```

## 🚀 Setup Rápido

### 1. Criar Projeto Flutter
```bash
# Na pasta LITGO
flutter create --org com.litgo litgo_flutter
cd litgo_flutter

# Copiar configuração
cp ../flutter_project_config.yaml pubspec.yaml
flutter pub get
```

### 2. Configurar Estrutura Clean Architecture
```bash
# Criar estrutura de pastas
mkdir -p lib/features/{auth,triage,matching,cases,profile}/{data,domain,presentation}
mkdir -p lib/shared/{widgets,services,utils}
mkdir -p lib/app

# Copiar arquivos base (quando disponíveis)
# cp -r ../flutter_templates/* lib/
```

### 3. Configurar Supabase
```bash
# Instalar Supabase CLI
npm install -g supabase

# Configurar projeto
supabase init
supabase link --project-ref your-project-ref
```

### 4. Configurar Variáveis de Ambiente
```bash
# Criar arquivo .env
cat > .env << EOF
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
API_BASE_URL=http://localhost:8000/api
EOF

# Configurar no pubspec.yaml
flutter pub add flutter_dotenv
```

## 📁 Estrutura de Arquivos

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── screens/
│   │       └── widgets/
│   ├── triage/
│   ├── matching/
│   ├── cases/
│   └── profile/
├── shared/
│   ├── widgets/
│   ├── services/
│   └── utils/
└── injection_container.dart
```

## 🎯 Comandos Úteis

### Desenvolvimento
```bash
# Executar app
flutter run

# Hot reload
r

# Hot restart
R

# Executar em dispositivo específico
flutter run -d chrome
flutter run -d emulator-5554
```

### Testes
```bash
# Executar todos os testes
flutter test

# Executar com cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Testes de integração
flutter drive --target=test_driver/app.dart
```

### Build
```bash
# Build para debug
flutter build apk --debug

# Build para release
flutter build apk --release
flutter build ios --release
```

### Geração de Código
```bash
# Gerar código (models, repositories, etc.)
flutter packages pub run build_runner build

# Gerar com watch
flutter packages pub run build_runner watch
```

## 🔧 Configuração do IDE

### VS Code
```json
// .vscode/settings.json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "dart.lineLength": 80,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

### Android Studio
```
# File → Settings → Languages & Frameworks → Flutter
# Flutter SDK path: .fvm/flutter_sdk
```

## 🏗️ Componentes Base

### 1. Configurar Dependency Injection
```dart
// injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection_container.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
```

### 2. Configurar Roteamento
```dart
// app/router.dart
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    // Definir rotas
  ],
);
```

### 3. Configurar Tema
```dart
// app/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: 'Inter',
      // Configurações do tema
    );
  }
}
```

## 🔄 Migração de Componentes (Navegação Consolidada - 5 Abas)

### Lista de Componentes a Migrar por Aba
- [ ] **Aba 1 - Início/Painel:**
  - [ ] `ClientDashboard` → `ClientDashboard` (Flutter)
  - [ ] `LawyerDashboard` → `LawyerDashboard` (Flutter)
- [ ] **Aba 2 - Meus Casos/Casos:**
  - [ ] `CaseCard` → `CaseCard` (Flutter)
  - [ ] `CaseList` → `CaseList` (Flutter)
- [ ] **Aba 3 - Triagem/Agenda:**
  - [ ] `TriageForm` → `TriageForm` (Flutter)
  - [ ] `CalendarWidget` → `CalendarWidget` (Flutter)
- [ ] **Aba 4 - Advogados/Mensagens:**
  - [ ] `LawyerMatchCard` → `LawyerMatchCard` (Flutter)
  - [ ] `MessageBubble` → `MessageBubble` (Flutter)
- [ ] **Aba 5 - Perfil:**
  - [ ] `ProfileCard` → `ProfileCard` (Flutter)
  - [ ] `FinancialCard` → `FinancialCard` (Flutter)
- [ ] **Componentes Gerais:**
  - [ ] `AuthContext` → `AuthBloc` (Flutter)
  - [ ] `useTaskPolling` → `TaskPollingService` (Flutter)
  - [ ] `MainTabsShell` → Navegação com 5 abas adaptativas

### Padrão de Migração
1. **Identificar componente** React Native
2. **Criar widget** Flutter equivalente
3. **Implementar lógica** com BLoC
4. **Adicionar testes** unitários
5. **Testar integração** com backend

## 🐛 Troubleshooting

### Problemas Comuns

#### 1. Dependências não encontradas
```bash
flutter clean
flutter pub get
```

#### 2. Problemas de build
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### 3. Problemas de emulador
```bash
# Listar devices
flutter devices

# Reiniciar emulador
flutter emulators --launch <emulator_id>
```

## 📚 Recursos Adicionais

### Documentação
- [Flutter Docs](https://docs.flutter.dev/)
- [Dart Docs](https://dart.dev/guides)
- [Supabase Flutter](https://supabase.com/docs/reference/dart/introduction)

### Tutoriais
- [Flutter BLoC Pattern](https://bloclibrary.dev/)
- [Clean Architecture Flutter](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [Go Router](https://pub.dev/packages/go_router)

### Ferramentas
- [Flutter Inspector](https://docs.flutter.dev/development/tools/flutter-inspector)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [FVM](https://fvm.app/) - Flutter Version Management

## 💰 Seção Financeira (Advogado)

### Estrutura de Honorários
A implementação financeira suporta três tipos distintos de honorários:

```dart
// Exemplo de uso
final financialData = FinancialData(
  contractualFees: [], // Honorários contratuais (fixed fee)
  successFees: [],     // Honorários de êxito (success fee)
  attorneyFees: [],    // Honorários sucumbenciais
  summary: FinancialSummary(),
);
```

### Cards Visuais
- **Contratuais**: Azul Marinho (`Color(0xFF1E3A8A)`)
- **Honorários de Êxito**: Verde-Teal (`Color(0xFF059669)`)
- **Sucumbenciais**: Dourado Metálico (`Color(0xFFD97706)`)

### Funcionalidades
- [ ] Visão geral com 3 cards principais
- [ ] Filtros por período e tipo
- [ ] Exportação de dados contratuais
- [ ] Marcar honorários de êxito como recebidos
- [ ] Solicitar repasse de sucumbenciais
- [ ] Timeline de trânsito em julgado

## 🔗 Links Úteis

- **Projeto Principal**: [README.md](./README.md)
- **Guia de Migração**: [FLUTTER_DEVELOPMENT.md](./FLUTTER_DEVELOPMENT.md)
- **Comparação Técnica**: [FLUTTER_COMPARACAO_TECNICA.md](./FLUTTER_COMPARACAO_TECNICA.md)
- **Roadmap**: [FLUTTER_ROADMAP.md](./FLUTTER_ROADMAP.md)
- **Implementação Financeira**: [FLUTTER_FINANCIAL_IMPLEMENTATION.md](./FLUTTER_FINANCIAL_IMPLEMENTATION.md)

---

**Status**: Preparação para migração  
**Última atualização**: Janeiro 2025 
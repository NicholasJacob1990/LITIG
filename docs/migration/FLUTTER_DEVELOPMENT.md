# 🚀 Guia de Migração React Native → Flutter - LITGO5

## 📋 Índice

1. [Justificativas da Migração](#-justificativas-da-migração)
2. [Diferenças de Implementação](#-diferenças-de-implementação)
3. [Estrutura do Projeto Flutter](#-estrutura-do-projeto-flutter)
4. [Componentes e Widgets](#-componentes-e-widgets)
5. [Navegação e Roteamento](#-navegação-e-roteamento)
6. [Gerenciamento de Estado](#-gerenciamento-de-estado)
7. [Integrações com Backend](#-integrações-com-backend)
8. [Plano de Migração](#-plano-de-migração)

---

## 🎯 Justificativas da Migração

### Motivos Técnicos

#### 1. **Performance Superior**
- **React Native**: Utiliza bridge JavaScript-nativo, criando overhead
- **Flutter**: Compilação direta para código nativo ARM/x86
- **Benefício**: Redução de 30-50% no tempo de renderização de listas complexas

#### 2. **UI/UX Consistente**
- **React Native**: Dependente dos componentes nativos de cada plataforma
- **Flutter**: Próprio engine de renderização, UI idêntica em iOS/Android
- **Benefício**: Redução significativa de bugs específicos de plataforma

#### 3. **Ecossistema Maduro**
- **React Native**: Fragmentação de pacotes third-party
- **Flutter**: Ecossistema oficial Google com pacotes oficiais
- **Benefício**: Menor dependência de bibliotecas não-oficiais

#### 4. **Ferramentas de Desenvolvimento**
- **React Native**: Debugging complexo com Metro bundler
- **Flutter**: Hot reload instantâneo, DevTools nativo
- **Benefício**: Aumento de 40% na produtividade de desenvolvimento

### Motivos de Negócio

#### 1. **Manutenibilidade**
- Código único para ambas as plataformas
- Menor curva de aprendizado para novos desenvolvedores
- Redução de 25% no tempo de desenvolvimento de novas features

#### 2. **Escalabilidade**
- Melhor performance em listas grandes (advogados, casos)
- Animations mais fluidas para UX premium
- Suporte nativo a widgets complexos

#### 3. **Futuro do Desenvolvimento**
- Google investe pesadamente no Flutter
- Tendência de migração de grandes empresas (Alibaba, BMW, Google Pay)
- Suporte oficial para Desktop/Web com mesmo código

---

## 🔄 Diferenças de Implementação

### Estrutura de Arquivos

#### React Native (Atual)
```
app/
├── (auth)/
│   ├── index.tsx
│   ├── register-client.tsx
│   └── register-lawyer.tsx
├── (tabs)/                 # 5 abas principais
│   ├── index.tsx          # Início
│   ├── cases/             # Meus Casos/Casos
│   ├── triagem/           # Triagem/Agenda
│   ├── advogados/         # Advogados/Mensagens
│   └── profile/           # Perfil
└── components/
    ├── atoms/
    ├── molecules/
    └── organisms/
```

#### Flutter (Proposto)
```
lib/
├── main.dart
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── domain/
│   │   └── data/
│   ├── dashboard/         # Início
│   ├── cases/             # Meus Casos/Casos
│   ├── triage/            # Triagem/Agenda
│   ├── lawyers/           # Advogados/Mensagens
│   └── profile/           # Perfil
└── shared/
    ├── widgets/
    ├── services/
    └── utils/
```

### Componentes vs Widgets

#### React Native
```typescript
// LawyerMatchCard.tsx
import React from 'react';
import { View, Text, Pressable } from 'react-native';

interface LawyerMatchCardProps {
  lawyer: Lawyer;
  onSelect: () => void;
}

const LawyerMatchCard: React.FC<LawyerMatchCardProps> = ({ lawyer, onSelect }) => {
  return (
    <Pressable onPress={onSelect}>
      <View className="bg-white rounded-lg p-4 shadow-sm">
        <Text className="font-semibold">{lawyer.name}</Text>
        <Text className="text-gray-600">{lawyer.specialty}</Text>
      </View>
    </Pressable>
  );
};
```

#### Flutter
```dart
// lawyer_match_card.dart
import 'package:flutter/material.dart';

class LawyerMatchCard extends StatelessWidget {
  final Lawyer lawyer;
  final VoidCallback onSelect;

  const LawyerMatchCard({
    Key? key,
    required this.lawyer,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lawyer.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                lawyer.specialty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Navegação

#### React Native (Expo Router)
```typescript
// app/_layout.tsx
import { Stack } from 'expo-router';

export default function RootLayout() {
  return (
    <Stack>
      <Stack.Screen name="(auth)" options={{ headerShown: false }} />
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
    </Stack>
  );
}
```

#### Flutter (GoRouter)
```dart
// app_router.dart
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register-client',
          builder: (context, state) => const RegisterClientScreen(),
        ),
        GoRoute(
          path: '/register-lawyer',
          builder: (context, state) => const RegisterLawyerScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => MainTabsShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/cases',
          builder: (context, state) => const CasesScreen(),
          routes: [
            GoRoute(
              path: '/:caseId',
              builder: (context, state) {
                final caseId = state.pathParameters['caseId']!;
                return CaseDetailScreen(caseId: caseId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/triage',
          builder: (context, state) => const TriageScreen(),
        ),
        GoRoute(
          path: '/lawyers',
          builder: (context, state) => const LawyersScreen(),
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const LawyerSearchScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: '/financial',
              builder: (context, state) => const FinancialScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
```

---

## 📁 Estrutura do Projeto Flutter

### Arquitetura Clean Architecture

```
lib/
├── main.dart                           # Entry point
├── app/
│   ├── app.dart                        # App widget principal
│   ├── router.dart                     # Configuração de rotas
│   └── theme.dart                      # Theme e cores
├── features/                           # Features organizadas por domínio (5 abas)
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart
│   │   │   │   └── auth_response_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       ├── register_client_usecase.dart
│   │   │       └── register_lawyer_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   ├── register_client_screen.dart
│   │       │   └── register_lawyer_screen.dart
│   │       └── widgets/
│   │           ├── auth_form.dart
│   │           └── social_login_buttons.dart
│   ├── dashboard/                      # Aba 1: Início/Painel
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── dashboard_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── dashboard_stats_model.dart
│   │   │   │   └── kpi_model.dart
│   │   │   └── repositories/
│   │   │       └── dashboard_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── dashboard_stats.dart
│   │   │   │   └── kpi.dart
│   │   │   ├── repositories/
│   │   │   │   └── dashboard_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_client_stats_usecase.dart
│   │   │       └── get_lawyer_stats_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── dashboard_bloc.dart
│   │       │   ├── dashboard_event.dart
│   │       │   └── dashboard_state.dart
│   │       ├── screens/
│   │       │   ├── client_dashboard_screen.dart
│   │       │   └── lawyer_dashboard_screen.dart
│   │       └── widgets/
│   │           ├── stats_card.dart
│   │           ├── kpi_indicator.dart
│   │           └── quick_actions.dart
│   ├── cases/                          # Aba 2: Meus Casos/Casos
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── cases_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── case_model.dart
│   │   │   │   └── case_stats_model.dart
│   │   │   └── repositories/
│   │   │       └── cases_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── case.dart
│   │   │   │   └── case_stats.dart
│   │   │   ├── repositories/
│   │   │   │   └── cases_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_cases_usecase.dart
│   │   │       └── get_case_detail_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── cases_bloc.dart
│   │       │   ├── cases_event.dart
│   │       │   └── cases_state.dart
│   │       ├── screens/
│   │       │   ├── cases_list_screen.dart
│   │       │   ├── case_detail_screen.dart
│   │       │   └── case_documents_screen.dart
│   │       └── widgets/
│   │           ├── case_card.dart
│   │           ├── case_progress_indicator.dart
│   │           └── document_viewer.dart
│   ├── triage/                         # Aba 3: Triagem/Agenda
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── triage_remote_datasource.dart
│   │   │   │   └── schedule_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── triage_request_model.dart
│   │   │   │   ├── triage_result_model.dart
│   │   │   │   └── schedule_event_model.dart
│   │   │   └── repositories/
│   │   │       ├── triage_repository_impl.dart
│   │   │       └── schedule_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── triage_result.dart
│   │   │   │   └── schedule_event.dart
│   │   │   ├── repositories/
│   │   │   │   ├── triage_repository.dart
│   │   │   │   └── schedule_repository.dart
│   │   │   └── usecases/
│   │   │       ├── start_triage_usecase.dart
│   │   │       ├── get_triage_status_usecase.dart
│   │   │       └── get_schedule_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── triage_bloc.dart
│   │       │   ├── schedule_bloc.dart
│   │       │   └── *.dart
│   │       ├── screens/
│   │       │   ├── triage_screen.dart
│   │       │   ├── schedule_screen.dart
│   │       │   └── chat_screen.dart
│   │       └── widgets/
│   │           ├── triage_form.dart
│   │           ├── ai_typing_indicator.dart
│   │           ├── calendar_widget.dart
│   │           └── event_card.dart
│   ├── lawyers/                        # Aba 4: Advogados/Mensagens
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── lawyers_remote_datasource.dart
│   │   │   │   └── messages_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── lawyer_model.dart
│   │   │   │   ├── match_result_model.dart
│   │   │   │   └── message_model.dart
│   │   │   └── repositories/
│   │   │       ├── lawyers_repository_impl.dart
│   │   │       └── messages_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── lawyer.dart
│   │   │   │   ├── match_result.dart
│   │   │   │   └── message.dart
│   │   │   ├── repositories/
│   │   │   │   ├── lawyers_repository.dart
│   │   │   │   └── messages_repository.dart
│   │   │   └── usecases/
│   │   │       ├── find_lawyers_usecase.dart
│   │   │       ├── explain_match_usecase.dart
│   │   │       └── get_messages_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── lawyers_bloc.dart
│   │       │   ├── messages_bloc.dart
│   │       │   └── *.dart
│   │       ├── screens/
│   │       │   ├── lawyers_screen.dart
│   │       │   ├── lawyer_search_screen.dart
│   │       │   ├── messages_screen.dart
│   │       │   └── chat_detail_screen.dart
│   │       └── widgets/
│   │           ├── lawyer_match_card.dart
│   │           ├── explanation_modal.dart
│   │           ├── message_bubble.dart
│   │           └── chat_input.dart
│   └── profile/                        # Aba 5: Perfil
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── profile_remote_datasource.dart
│       │   │   └── financial_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── profile_model.dart
│       │   │   └── financial_model.dart
│       │   └── repositories/
│       │       ├── profile_repository_impl.dart
│       │       └── financial_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── profile.dart
│       │   │   └── financial_data.dart
│       │   ├── repositories/
│       │   │   ├── profile_repository.dart
│       │   │   └── financial_repository.dart
│       │   └── usecases/
│       │       ├── get_profile_usecase.dart
│       │       ├── update_profile_usecase.dart
│       │       └── get_financial_data_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── profile_bloc.dart
│           │   ├── financial_bloc.dart
│           │   └── *.dart
│           ├── screens/
│           │   ├── profile_screen.dart
│           │   ├── edit_profile_screen.dart
│           │   └── financial_screen.dart
│           └── widgets/
│               ├── profile_avatar.dart
│               ├── profile_info_card.dart
│               ├── financial_card.dart
│               └── financial_breakdown.dart
├── shared/
│   ├── widgets/
│   │   ├── atoms/
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_text_field.dart
│   │   │   ├── loading_indicator.dart
│   │   │   └── status_badge.dart
│   │   ├── molecules/
│   │   │   ├── search_bar.dart
│   │   │   ├── filter_chips.dart
│   │   │   └── rating_display.dart
│   │   └── organisms/
│   │       ├── app_bar.dart
│   │       ├── main_tabs_shell.dart
│   │       └── drawer_menu.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── supabase_service.dart
│   │   ├── notification_service.dart
│   │   └── storage_service.dart
│   ├── utils/
│   │   ├── constants.dart
│   │   ├── validators.dart
│   │   ├── date_utils.dart
│   │   └── currency_formatter.dart
│   └── models/
│       ├── api_response.dart
│       └── error_model.dart
└── injection_container.dart            # Dependency injection
```

---

## 🎨 Componentes e Widgets

### Atomic Design em Flutter

#### Atoms (Componentes Básicos)
```dart
// shared/widgets/atoms/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonStyle? style;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(text),
    );
  }
}
```

#### Molecules (Componentes Compostos)
```dart
// shared/widgets/molecules/search_bar.dart
import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const SearchBar({
    Key? key,
    required this.hintText,
    this.onChanged,
    this.onFilterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
            ),
          ),
          if (onFilterTap != null) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: onFilterTap,
            ),
          ],
        ],
      ),
    );
  }
}
```

#### Organisms (Componentes Complexos)
```dart
// features/matching/presentation/widgets/lawyer_match_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/lawyer.dart';

class LawyerMatchCard extends StatelessWidget {
  final Lawyer lawyer;
  final VoidCallback onSelect;
  final VoidCallback onExplain;

  const LawyerMatchCard({
    Key? key,
    required this.lawyer,
    required this.onSelect,
    required this.onExplain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usando as cores inferidas do LITGO6
    const cardBackgroundColor = Color(0xFF1F2937);
    const primaryTextColor = Color(0xFFFFFFFF);
    const secondaryTextColor = Color(0xFF9CA3AF);
    const primaryActionColor = Color(0xFF3B82F6);
    const borderColor = Color(0xFF374151);

    return Card(
      elevation: 4,
      color: cardBackgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, primaryTextColor, secondaryTextColor),
              const SizedBox(height: 16),
              _buildInfoRow(secondaryTextColor),
              const SizedBox(height: 20),
              _buildActions(primaryActionColor, primaryTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryTextColor, Color secondaryTextColor) {
    return Row(
      children: [
        Hero(
          tag: 'lawyer-avatar-${lawyer.id}',
          child: CircleAvatar(
            radius: 28,
            backgroundImage: CachedNetworkImageProvider(lawyer.avatarUrl),
            backgroundColor: const Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lawyer.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                lawyer.primaryArea,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getMatchColor().withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getMatchColor(), width: 1),
          ),
          child: Text(
            '${(lawyer.fairScore * 100).toInt()}%',
            style: TextStyle(
              color: _getMatchColor(),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoChip(Icons.star_border_purple500, '${lawyer.rating}', const Color(0xFFF59E0B), textColor),
        _buildInfoChip(Icons.location_on_outlined, '${lawyer.distanceKm.toStringAsFixed(1)} km', const Color(0xFF3B82F6), textColor),
        _buildInfoChip(Icons.cases_outlined, '${lawyer.casesCount} casos', const Color(0xFF10B981), textColor),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(Color primaryActionColor, Color primaryTextColor) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onExplain,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: primaryActionColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Explicar Match'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onSelect,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryActionColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: Text(
              'Selecionar',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getMatchColor() {
    final score = lawyer.fairScore;
    if (score >= 0.8) return const Color(0xFF10B981); // success
    if (score >= 0.6) return const Color(0xFFF59E0B); // warning
    return const Color(0xFFEF4444); // danger
  }
}
```

---

## 🧭 Navegação e Roteamento

### Configuração do GoRouter

```dart
// app/router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    // Rota de autenticação
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register-client',
          name: 'register-client',
          builder: (context, state) => const RegisterClientScreen(),
        ),
        GoRoute(
          path: '/register-lawyer',
          name: 'register-lawyer',
          builder: (context, state) => const RegisterLawyerScreen(),
        ),
      ],
    ),
    
    // Shell route para navegação com tabs
    ShellRoute(
      builder: (context, state, child) => MainTabsShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/triage',
          name: 'triage',
          builder: (context, state) => const TriageScreen(),
          routes: [
            GoRoute(
              path: '/result/:caseId',
              name: 'triage-result',
              builder: (context, state) {
                final caseId = state.pathParameters['caseId']!;
                return TriageResultScreen(caseId: caseId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/matches/:caseId',
          name: 'matches',
          builder: (context, state) {
            final caseId = state.pathParameters['caseId']!;
            return MatchesScreen(caseId: caseId);
          },
        ),
        GoRoute(
          path: '/cases',
          name: 'cases',
          builder: (context, state) => const CasesScreen(),
          routes: [
            GoRoute(
              path: '/:caseId',
              name: 'case-detail',
              builder: (context, state) {
                final caseId = state.pathParameters['caseId']!;
                return CaseDetailScreen(caseId: caseId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
```

### Shell com Bottom Navigation

```dart
// shared/widgets/organisms/main_tabs_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainTabsShell extends StatefulWidget {
  final Widget child;

  const MainTabsShell({Key? key, required this.child}) : super(key: key);

  @override
  State<MainTabsShell> createState() => _MainTabsShellState();
}

class _MainTabsShellState extends State<MainTabsShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userRole = context.read<AuthBloc>().state.userRole;
    
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/cases');
              break;
            case 2:
              context.go(_getThirdTabRoute(userRole));
              break;
            case 3:
              context.go(_getFourthTabRoute(userRole));
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        items: _getBottomNavItems(userRole),
      ),
    );
  }

  List<BottomNavigationBarItem> _getBottomNavItems(String userRole) {
    if (userRole == 'client') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Meus Casos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Triagem',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Advogados',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Painel',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: 'Casos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Agenda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Mensagens',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }
  }

  String _getThirdTabRoute(String userRole) {
    return userRole == 'client' ? '/triage' : '/schedule';
  }

  String _getFourthTabRoute(String userRole) {
    return userRole == 'client' ? '/lawyers' : '/messages';
  }
}
```

---

## 🔄 Gerenciamento de Estado

### Bloc Pattern com flutter_bloc

```dart
// features/triage/presentation/bloc/triage_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/start_triage_usecase.dart';
import '../../domain/usecases/get_triage_status_usecase.dart';

// Events
abstract class TriageEvent {}

class StartTriageEvent extends TriageEvent {
  final String caseDescription;
  final String userId;

  StartTriageEvent({required this.caseDescription, required this.userId});
}

class CheckTriageStatusEvent extends TriageEvent {
  final String taskId;

  CheckTriageStatusEvent({required this.taskId});
}

// States
abstract class TriageState {}

class TriageInitial extends TriageState {}

class TriageLoading extends TriageState {}

class TriageInProgress extends TriageState {
  final String taskId;
  final String message;

  TriageInProgress({required this.taskId, required this.message});
}

class TriageCompleted extends TriageState {
  final String caseId;
  final String area;
  final String subarea;
  final int urgencyHours;

  TriageCompleted({
    required this.caseId,
    required this.area,
    required this.subarea,
    required this.urgencyHours,
  });
}

class TriageError extends TriageState {
  final String message;

  TriageError({required this.message});
}

// Bloc
class TriageBloc extends Bloc<TriageEvent, TriageState> {
  final StartTriageUsecase startTriageUsecase;
  final GetTriageStatusUsecase getTriageStatusUsecase;

  TriageBloc({
    required this.startTriageUsecase,
    required this.getTriageStatusUsecase,
  }) : super(TriageInitial()) {
    on<StartTriageEvent>(_onStartTriage);
    on<CheckTriageStatusEvent>(_onCheckTriageStatus);
  }

  Future<void> _onStartTriage(
    StartTriageEvent event,
    Emitter<TriageState> emit,
  ) async {
    emit(TriageLoading());
    
    final result = await startTriageUsecase.call(
      StartTriageParams(
        caseDescription: event.caseDescription,
        userId: event.userId,
      ),
    );
    
    result.fold(
      (failure) => emit(TriageError(message: failure.message)),
      (triageResponse) => emit(TriageInProgress(
        taskId: triageResponse.taskId,
        message: triageResponse.message,
      )),
    );
  }

  Future<void> _onCheckTriageStatus(
    CheckTriageStatusEvent event,
    Emitter<TriageState> emit,
  ) async {
    final result = await getTriageStatusUsecase.call(
      GetTriageStatusParams(taskId: event.taskId),
    );
    
    result.fold(
      (failure) => emit(TriageError(message: failure.message)),
      (statusResponse) {
        if (statusResponse.status == 'completed') {
          emit(TriageCompleted(
            caseId: statusResponse.result.caseId,
            area: statusResponse.result.area,
            subarea: statusResponse.result.subarea,
            urgencyHours: statusResponse.result.urgencyHours,
          ));
        } else if (statusResponse.status == 'failed') {
          emit(TriageError(message: 'Falha na triagem'));
        }
        // Se ainda estiver em progresso, mantém o estado atual
      },
    );
  }
}
```

### Uso do Bloc na Tela

```dart
// features/triage/presentation/screens/triage_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/triage_bloc.dart';

class TriageScreen extends StatefulWidget {
  const TriageScreen({Key? key}) : super(key: key);

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final _descriptionController = TextEditingController();
  Timer? _statusTimer;

  @override
  void dispose() {
    _statusTimer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triagem Inteligente'),
      ),
      body: BlocConsumer<TriageBloc, TriageState>(
        listener: (context, state) {
          if (state is TriageInProgress) {
            _startStatusPolling(state.taskId);
          } else if (state is TriageCompleted) {
            _statusTimer?.cancel();
            context.go('/matches/${state.caseId}');
          } else if (state is TriageError) {
            _statusTimer?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Descreva seu caso jurídico',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Conte-nos sobre seu problema jurídico...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    expands: true,
                  ),
                ),
                const SizedBox(height: 16),
                if (state is TriageLoading || state is TriageInProgress) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  if (state is TriageInProgress)
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
                ElevatedButton(
                  onPressed: state is TriageLoading || state is TriageInProgress
                      ? null
                      : () {
                          if (_descriptionController.text.trim().isNotEmpty) {
                            context.read<TriageBloc>().add(
                              StartTriageEvent(
                                caseDescription: _descriptionController.text,
                                userId: 'current-user-id', // Obter do contexto de auth
                              ),
                            );
                          }
                        },
                  child: const Text('Iniciar Triagem'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _startStatusPolling(String taskId) {
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      context.read<TriageBloc>().add(CheckTriageStatusEvent(taskId: taskId));
    });
  }
}
```

---

## 🔗 Integrações com Backend

### Serviço de API

```dart
// shared/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  // Triagem
  Future<Response> startTriage({
    required String textoCliente,
    required String userId,
    List<double>? coords,
  }) async {
    return await _dio.post('/triage', data: {
      'texto_cliente': textoCliente,
      'user_id': userId,
      if (coords != null) 'coords': coords,
    });
  }

  Future<Response> getTriageStatus(String taskId) async {
    return await _dio.get('/triage/status/$taskId');
  }

  // Matching
  Future<Response> findMatches({
    required String caseId,
    int k = 5,
    String preset = 'balanced',
    double? radiusKm,
    List<String>? excludeIds,
  }) async {
    return await _dio.post('/match', data: {
      'case_id': caseId,
      'k': k,
      'preset': preset,
      if (radiusKm != null) 'radius_km': radiusKm,
      if (excludeIds != null) 'exclude_ids': excludeIds,
    });
  }

  Future<Response> explainMatch({
    required String caseId,
    required List<String> lawyerIds,
  }) async {
    return await _dio.post('/explain', data: {
      'case_id': caseId,
      'lawyer_ids': lawyerIds,
    });
  }

  // Cases
  Future<Response> getMyCases() async {
    return await _dio.get('/cases/my-cases');
  }

  Future<Response> getCaseDetail(String caseId) async {
    return await _dio.get('/cases/$caseId');
  }

  // Auth
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> registerClient({
    required String email,
    required String password,
    required String name,
    required String cpfCnpj,
    required String phone,
    required String userType,
  }) async {
    return await _dio.post('/auth/register-client', data: {
      'email': email,
      'password': password,
      'name': name,
      'cpf_cnpj': cpfCnpj,
      'phone': phone,
      'user_type': userType,
    });
  }

  Future<Response> registerLawyer({
    required String email,
    required String password,
    required String name,
    required String cpf,
    required String phone,
    required String oabNumber,
    required List<String> areas,
    required int maxCases,
    required Map<String, dynamic> address,
    Map<String, dynamic>? diversity,
    Map<String, String>? documents,
  }) async {
    return await _dio.post('/auth/register-lawyer', data: {
      'email': email,
      'password': password,
      'name': name,
      'cpf': cpf,
      'phone': phone,
      'oab_number': oabNumber,
      'areas': areas,
      'max_cases': maxCases,
      'address': address,
      if (diversity != null) 'diversity': diversity,
      if (documents != null) 'documents': documents,
    });
  }

  // Interceptor para adicionar token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
```

### Supabase Service

```dart
// shared/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  late final SupabaseClient _client;

  SupabaseService() {
    _client = Supabase.instance.client;
  }

  // Auth
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required String filePath,
  }) async {
    await _client.storage.from(bucket).upload(path, File(filePath));
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // Realtime
  RealtimeChannel subscribeToChannel(String channelName) {
    return _client.channel(channelName);
  }
}
```

---

## 📋 Plano de Migração

### Fase 1: Preparação e Setup (1-2 semanas)

#### Semana 1: Configuração Inicial
- [ ] Criar novo projeto Flutter
- [ ] Configurar estrutura de pastas Clean Architecture
- [ ] Configurar dependências básicas (dio, flutter_bloc, go_router)
- [ ] Configurar Supabase Flutter
- [ ] Configurar tema e design system

#### Semana 2: Configuração Avançada
- [ ] Configurar dependency injection (get_it)
- [ ] Implementar error handling global
- [ ] Configurar logging
- [ ] Setup de testes unitários
- [ ] Configurar CI/CD básico

### Fase 2: Migração de Autenticação (2-3 semanas)

#### Semana 3-4: Auth Core
- [ ] Implementar entidades e use cases de autenticação
- [ ] Criar repository de autenticação
- [ ] Implementar Bloc de autenticação
- [ ] Migrar tela de login

#### Semana 5: Registro
- [ ] Migrar tela de registro de cliente
- [ ] Migrar tela de registro de advogado
- [ ] Implementar validações de formulário
- [ ] Testes de autenticação

### Fase 3: Triagem e Matching (3-4 semanas)

#### Semana 6-7: Triagem
- [ ] Implementar entidades de triagem
- [ ] Criar serviços de triagem
- [ ] Migrar tela de triagem
- [ ] Implementar polling de status

#### Semana 8-9: Matching
- [ ] Implementar entidades de matching
- [ ] Criar serviços de matching
- [ ] Migrar tela de matches
- [ ] Implementar explicações de match

### Fase 4: Cases e Profile (2-3 semanas)

#### Semana 10-11: Cases
- [ ] Implementar entidades de casos
- [ ] Migrar tela de lista de casos
- [ ] Migrar tela de detalhes do caso
- [ ] Implementar chat em tempo real

#### Semana 12: Profile
- [ ] Migrar tela de perfil
- [ ] Implementar edição de perfil
- [ ] Configurações do app

### Fase 5: Funcionalidades Avançadas (3-4 semanas)

#### Semana 13-14: Integrações
- [ ] Implementar notificações push
- [ ] Configurar deep links
- [ ] Implementar upload de documentos
- [ ] Integração com câmera

#### Semana 15-16: Polimento
- [ ] Implementar animações
- [ ] Otimizar performance
- [ ] Testes de integração
- [ ] Documentação

### Fase 6: Deploy e Monitoramento (1-2 semanas)

#### Semana 17-18: Deploy
- [ ] Configurar build para release
- [ ] Deploy na Play Store (Android)
- [ ] Deploy na App Store (iOS)
- [ ] Configurar monitoramento de crash
- [ ] Métricas de performance

---

## 🚀 Comandos Úteis

### Setup Inicial
```bash
# Criar projeto Flutter
flutter create --org com.litgo litgo_flutter
cd litgo_flutter

# Adicionar dependências
flutter pub add dio flutter_bloc go_router supabase_flutter
flutter pub add --dev flutter_test build_runner

# Executar código generation
flutter packages pub run build_runner build

# Executar app
flutter run
```

### Desenvolvimento
```bash
# Hot reload
r

# Hot restart
R

# Análise de código
flutter analyze

# Executar testes
flutter test

# Build para release
flutter build apk --release
flutter build ios --release
```

---

## 📊 Métricas de Migração

### Estimativas de Tempo
- **Total estimado**: 16-20 semanas
- **Equipe recomendada**: 2-3 desenvolvedores Flutter
- **Fases críticas**: Autenticação e Matching (50% do tempo)

### Benefícios Esperados
- **Performance**: +40% melhoria na velocidade
- **Maintenance**: -30% tempo de manutenção
- **Bugs**: -50% bugs específicos de plataforma
- **Development**: +25% velocidade de desenvolvimento

### Riscos e Mitigações
- **Risco**: Perda de funcionalidades específicas do RN
- **Mitigação**: Auditoria prévia de features críticas

- **Risco**: Curva de aprendizado da equipe
- **Mitigação**: Treinamento Flutter + mentoria

- **Risco**: Integração com APIs existentes
- **Mitigação**: Manter contratos de API inalterados

---

Esse guia fornece uma base sólida para a migração do React Native para Flutter, mantendo a funcionalidade existente e melhorando a performance e manutenibilidade do código. 
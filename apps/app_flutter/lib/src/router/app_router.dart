import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/register_client_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/register_lawyer_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/contract_signature_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/case_detail_screen.dart';
import 'package:meu_app/src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/cases_screen.dart';
import 'package:meu_app/src/features/lawyers/presentation/screens/partners_screen.dart';
import 'package:meu_app/src/features/messages/presentation/screens/messages_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/settings_screen.dart';
import 'package:meu_app/src/features/home/presentation/screens/home_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/screens/partnerships_screen.dart';
import 'package:meu_app/src/features/offers/presentation/screens/offers_screen.dart';
import 'package:meu_app/src/shared/widgets/organisms/main_tabs_shell.dart';
import 'package:meu_app/src/features/triage/presentation/screens/chat_triage_screen.dart';
import 'package:meu_app/src/features/services/presentation/screens/services_screen.dart';
import 'package:meu_app/src/features/firms/presentation/screens/firm_detail_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/case_documents_screen.dart';
import 'package:meu_app/src/features/sla_management/presentation/screens/sla_settings_screen.dart';
import 'package:meu_app/src/features/sla_management/presentation/bloc/sla_settings_bloc.dart';
import 'package:meu_app/src/features/sla_management/presentation/bloc/sla_analytics_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/screens/hiring_proposals_screen.dart';
import 'package:meu_app/src/features/clients/presentation/screens/client_proposals_screen.dart';
import 'package:meu_app/src/features/chat/presentation/screens/chat_rooms_screen.dart';
import 'package:meu_app/src/features/chat/presentation/screens/chat_screen.dart';
import 'package:meu_app/injection_container.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter appRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final loggedIn = authState is auth_states.Authenticated;
      final isAuthenticating = ['/login', '/register-client', '/register-lawyer'].contains(state.matchedLocation);
      final isSplash = state.matchedLocation == '/splash';

      if (!loggedIn && !isAuthenticating && !isSplash) {
        return '/login';
      }
      
      if (loggedIn && (isAuthenticating || isSplash)) {
        final userRole = authState.user.role;
        
        switch (userRole) {
          case 'lawyer_associated':
            return '/dashboard';
          case 'lawyer_individual':
          case 'lawyer_office':
          case 'lawyer_platform_associate':
            return '/home';
          default:
            return '/client-home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register-client', builder: (context, state) => const RegisterClientScreen()),
      GoRoute(
        path: '/register-lawyer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final role = extra?['role'] as String? ?? 'lawyer_individual';
          return RegisterLawyerScreen(role: role);
        },
      ),
      GoRoute(
        path: '/contract-signature',
        builder: (context, state) {
          return const ContractSignatureScreen();
        },
      ),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainTabsShell(navigationShell: navigationShell);
        },
        branches: [
          // 0: Advogado Associado - Painel
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen())]),
          // 1: Advogado Associado - Casos
          StatefulShellBranch(routes: [GoRoute(path: '/cases', builder: (context, state) => const CasesScreen())]),
          // 2: Advogado Associado - Agenda (Exemplo, rota não existente)
          // TODO: Adicionar rota /schedule quando a tela for criada
          StatefulShellBranch(routes: [GoRoute(path: '/schedule', builder: (context, state) => const Center(child: Text('Agenda')))]),
          // 3: Advogado Associado - Ofertas
          StatefulShellBranch(routes: [GoRoute(path: '/offers', builder: (context, state) => const OffersScreen())]),
          // 3.5: Advogado Associado - Propostas de Contratação
          StatefulShellBranch(routes: [GoRoute(path: '/hiring-proposals', builder: (context, state) => const HiringProposalsScreen())]),
          // 4: Advogado Associado - Mensagens
          StatefulShellBranch(routes: [GoRoute(path: '/messages', builder: (context, state) => const ChatRoomsScreen())]),
          // 5: Advogado Associado - Perfil
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
          
          // 6: Advogado Contratante - Início
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
          // 7: Advogado Contratante - Casos
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-cases', builder: (context, state) => const CasesScreen())]),
          // 8: Advogado Contratante - Ofertas
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-offers', builder: (context, state) => const OffersScreen())]),
          // 9: Advogado Contratante - Parceiros
          StatefulShellBranch(routes: [GoRoute(path: '/partners', builder: (context, state) => const LawyersScreen())]),
          // 10: Advogado Contratante - Parcerias
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/partnerships',
                builder: (context, state) => BlocProvider(
                  create: (context) => getIt<PartnershipsBloc>(),
                  child: const PartnershipsScreen(),
                ),
              ),
            ],
          ),
          // 11: Advogado Contratante - Mensagens
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-messages', builder: (context, state) => const ChatRoomsScreen())]),
          // 12: Advogado Contratante - Perfil
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-profile', builder: (context, state) => const ProfileScreen())]),

          // 13: Cliente - Início
          StatefulShellBranch(routes: [GoRoute(path: '/client-home', builder: (context, state) => const HomeScreen())]),
          // 14: Cliente - Casos
          StatefulShellBranch(routes: [GoRoute(path: '/client-cases', builder: (context, state) => const CasesScreen())]),
          // 14.5: Cliente - Propostas
          StatefulShellBranch(routes: [GoRoute(path: '/client-proposals', builder: (context, state) => const ClientProposalsScreen())]),
          // 15: Cliente - Advogados (Busca Híbrida)
          StatefulShellBranch(routes: [GoRoute(path: '/advogados', builder: (context, state) => const LawyersScreen())]),
          // 16: Cliente - Mensagens
          StatefulShellBranch(routes: [GoRoute(path: '/client-messages', builder: (context, state) => const ChatRoomsScreen())]),
          // 17: Cliente - Serviços
          StatefulShellBranch(routes: [GoRoute(path: '/services', builder: (context, state) => const ServicesScreen())]),
          // 18: Cliente - Perfil
          StatefulShellBranch(routes: [GoRoute(path: '/client-profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
      
      // Rotas fora da shell
      GoRoute(
        path: '/case-detail/:caseId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CaseDetailScreen(caseId: state.pathParameters['caseId']!),
      ),
      GoRoute(
        path: '/cases/:caseId/documents',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CaseDocumentsScreen(caseId: state.pathParameters['caseId']!),
      ),
      GoRoute(
        path: '/firm/:firmId',
        builder: (context, state) => FirmDetailScreen(firmId: state.pathParameters['firmId']!),
      ),
      GoRoute(
        path: '/firm-modal/:firmId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => FirmDetailScreen(firmId: state.pathParameters['firmId']!),
      ),
      GoRoute(
        path: '/triage',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChatTriageScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/sla-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider<SlaSettingsBloc>(
              create: (context) => getIt<SlaSettingsBloc>(),
            ),
            BlocProvider<SlaAnalyticsBloc>(
              create: (context) => getIt<SlaAnalyticsBloc>(),
            ),
          ],
          child: const SlaSettingsScreen(),
        ),
      ),
      
      // Chat routes
      GoRoute(
        path: '/chat/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final otherPartyName = state.uri.queryParameters['otherPartyName'];
          
          return ChatScreen(
            roomId: roomId,
            otherPartyName: otherPartyName,
          );
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
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
// import 'package:meu_app/src/features/auth/presentation/screens/contract_activation_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/case_detail_screen.dart';
import 'package:meu_app/src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/cases_screen.dart';
import 'package:meu_app/src/features/lawyers/presentation/screens/lawyers_screen.dart';
import 'package:meu_app/src/features/messages/presentation/screens/messages_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/settings_screen.dart';
// import 'package:meu_app/src/features/schedule/presentation/screens/agenda_screen.dart';
import 'package:meu_app/src/features/home/presentation/screens/home_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';
// import 'package:meu_app/src/features/partnerships/presentation/screens/offers_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/screens/partnerships_screen.dart';
import 'package:meu_app/src/features/offers/presentation/screens/offers_screen.dart';
import 'package:meu_app/src/shared/widgets/organisms/main_tabs_shell.dart';
import 'package:meu_app/src/features/triage/presentation/screens/chat_triage_screen.dart';
import 'package:meu_app/src/features/services/presentation/screens/services_screen.dart';
import 'package:meu_app/src/features/firms/presentation/screens/firm_detail_screen.dart';
import 'package:meu_app/injection_container.dart';

// import 'routes.dart';

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
        // Redirecionar baseado no tipo de usuário
        final userRole = authState.user.role;
        
        switch (userRole) {
          case 'lawyer_associated':
            return '/dashboard';
          case 'lawyer_individual':
          case 'lawyer_office':
          case 'lawyer_platform_associate': // NOVO: Super Associado - usa mesma rota de captação
            return '/contractor-offers'; // MUDANÇA: Direciona para ofertas
          default: // cliente
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
      // GoRoute(
      //   path: '/contract-activation',
      //   builder: (context, state) {
      //     final extra = state.extra as Map<String, dynamic>?;
      //     final userId = extra?['userId'] as String?;
      //     final contractId = extra?['contractId'] as String?;
      //     return ContractActivationScreen(userId: userId, contractId: contractId);
      //   },
      // ),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainTabsShell(navigationShell: navigationShell);
        },
        branches: [
          // Advogado Associado (índices 0-5)
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/cases', builder: (context, state) => const CasesScreen())]),
          // StatefulShellBranch(routes: [GoRoute(path: '/agenda', builder: (context, state) => const AgendaScreen())]),
          // StatefulShellBranch(routes: [GoRoute(path: '/offers', builder: (context, state) => const OffersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
          
          // Advogado Contratante (índices 6-12 AGORA)
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
          // ⬇️ ADICIONAR NOVA ROTA AQUI ⬇️
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-cases', builder: (context, state) => const CasesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-offers', builder: (context, state) => const OffersScreen())]), // NOVA ABA
          StatefulShellBranch(routes: [GoRoute(path: '/partners', builder: (context, state) => const LawyersScreen())]), // Alterado para reutilizar LawyersScreen
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
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-messages', builder: (context, state) => const MessagesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-profile', builder: (context, state) => const ProfileScreen())]),

          // Cliente (índices 12-17)
          StatefulShellBranch(routes: [GoRoute(path: '/client-home', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/client-cases', builder: (context, state) => const CasesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/find-lawyers', builder: (context, state) => const LawyersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/client-messages', builder: (context, state) => const MessagesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/services', builder: (context, state) => const ServicesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/client-profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
      
      // Rotas fora da shell
      GoRoute(
        path: '/case-detail/:caseId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CaseDetailScreen(caseId: state.pathParameters['caseId']!),
      ),
      
      // Rotas de Escritórios (navegação interna)
      GoRoute(
        path: '/firm/:firmId',
        builder: (context, state) => FirmDetailScreen(firmId: state.pathParameters['firmId']!),
      ),
      
      // Rotas de Escritórios (navegação externa/modal)
      GoRoute(
        path: '/firm-modal/:firmId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => FirmDetailScreen(firmId: state.pathParameters['firmId']!),
      ),
      GoRoute(
        path: '/firm/:firmId/lawyers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final firmId = state.pathParameters['firmId']!;
          return Scaffold(
            appBar: AppBar(title: const Text('Advogados do Escritório')),
            body: Center(
              child: Text('Lista de advogados do escritório $firmId - Em desenvolvimento'),
            ),
          );
        },
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
        path: '/cases/:caseId/documents',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final caseId = state.pathParameters['caseId']!;
          return Scaffold(
            appBar: AppBar(title: Text('Documentos do Caso $caseId')),
            body: const Center(child: Text('Documentos não implementados ainda')),
          );
        },
      ),
      GoRoute(
        path: '/cases/:caseId/process-status',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final caseId = state.pathParameters['caseId']!;
          return Scaffold(
            appBar: AppBar(title: Text('Status do Processo $caseId')),
            body: const Center(child: Text('Status do processo não implementado ainda')),
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
} 
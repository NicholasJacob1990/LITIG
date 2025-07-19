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
import 'package:meu_app/src/features/video_call/presentation/screens/video_call_screen.dart';
import 'package:meu_app/src/features/ratings/presentation/screens/case_rating_screen.dart';
import 'package:meu_app/src/features/firms/presentation/screens/firm_team_screen.dart';
import 'package:meu_app/src/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:meu_app/src/features/admin/presentation/screens/admin_metrics_screen.dart';
import 'package:meu_app/src/features/admin/presentation/screens/admin_audit_screen.dart';
import 'package:meu_app/src/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:meu_app/src/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:meu_app/src/features/admin/domain/services/admin_auth_service.dart';
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
          case 'lawyer_office':
            return '/firm-dashboard';  // Dashboard específico para sócios
          case 'lawyer_individual':
          case 'lawyer_platform_associate':
            return '/contractor-home';  // Dashboard específico para contratantes
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
          
          // 6: Advogado Contratante - Dashboard Específico
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-home', builder: (context, state) => const DashboardScreen())]),
          // 6.1: Sócio de Escritório - Dashboard da Firma
          StatefulShellBranch(routes: [GoRoute(path: '/firm-dashboard', builder: (context, state) => const DashboardScreen())]),
          // 6.2: Advogado Contratante - Início (legado)
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
      
      // ✅ NOVO: Rota crítica "Ver Equipe Completa"
      GoRoute(
        path: '/firm/:firmId/lawyers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final firmId = state.pathParameters['firmId']!;
          return FirmTeamScreen(firmId: firmId);
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
          child: const SlaSettingsScreen(firmId: 'temp-firm-id'),
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
      
      // Video Call routes
      GoRoute(
        path: '/video-call/:roomName',
        builder: (context, state) {
          final roomName = state.pathParameters['roomName']!;
          final extra = state.extra as Map<String, dynamic>?;
          
          return VideoCallScreen(
            roomName: roomName,
            roomUrl: extra?['roomUrl'] ?? 'https://litig.daily.co/$roomName',
            userId: extra?['userId'] ?? 'anonymous',
            otherPartyName: extra?['otherPartyName'],
          );
        },
      ),

      // Rating routes
      GoRoute(
        path: '/rate-case/:caseId',
        builder: (context, state) {
          final caseId = state.pathParameters['caseId']!;
          final lawyerId = state.uri.queryParameters['lawyerId']!;
          final clientId = state.uri.queryParameters['clientId']!;
          final userType = state.uri.queryParameters['userType'] ?? 'client';
          
          return CaseRatingScreen(
            caseId: caseId,
            lawyerId: lawyerId,
            clientId: clientId,
            userType: userType,
          );
        },
      ),

      // 🏛️ ADMIN ROUTES - Sistema de Controladoria
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          // Verificar permissões administrativas
          final authState = authBloc.state;
          if (authState is auth_states.Authenticated) {
            final userRole = authState.user.role;
            if (!AdminAuthService.canAccessRoute(userRole, '/admin')) {
              return _buildAccessDeniedScreen(context);
            }
          }
          
          return BlocProvider(
            create: (context) => getIt<AdminBloc>(),
            child: const AdminDashboardScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/metrics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          // Verificar permissões administrativas
          final authState = authBloc.state;
          if (authState is auth_states.Authenticated) {
            final userRole = authState.user.role;
            if (!AdminAuthService.canAccessRoute(userRole, '/admin/metrics')) {
              return _buildAccessDeniedScreen(context);
            }
          }
          
          return BlocProvider(
            create: (context) => getIt<AdminBloc>(),
            child: const AdminMetricsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/audit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          // Verificar permissões administrativas
          final authState = authBloc.state;
          if (authState is auth_states.Authenticated) {
            final userRole = authState.user.role;
            if (!AdminAuthService.canAccessRoute(userRole, '/admin/audit')) {
              return _buildAccessDeniedScreen(context);
            }
          }
          
          return BlocProvider(
            create: (context) => getIt<AdminBloc>(),
            child: const AdminAuditScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          // Verificar permissões administrativas
          final authState = authBloc.state;
          if (authState is auth_states.Authenticated) {
            final userRole = authState.user.role;
            if (!AdminAuthService.canAccessRoute(userRole, '/admin/reports')) {
              return _buildAccessDeniedScreen(context);
            }
          }
          
          return BlocProvider(
            create: (context) => getIt<AdminBloc>(),
            child: const AdminReportsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          // Verificar permissões administrativas
          final authState = authBloc.state;
          if (authState is auth_states.Authenticated) {
            final userRole = authState.user.role;
            if (!AdminAuthService.canAccessRoute(userRole, '/admin/settings')) {
              return _buildAccessDeniedScreen(context);
            }
          }
          
          return BlocProvider(
            create: (context) => getIt<AdminBloc>(),
            child: const AdminSettingsScreen(),
          );
        },
      ),
    ],
  );
}

/// Tela de Acesso Negado para rotas administrativas
Widget _buildAccessDeniedScreen(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Acesso Negado'),
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.shieldX,
            size: 64,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Acesso Negado',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Você não tem permissão para acessar esta área administrativa.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(LucideIcons.home),
            label: const Text('Voltar ao Início'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/register_client_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/register_lawyer_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/contract_signature_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/domain/entities/user.dart' as auth_user;
import 'package:meu_app/src/features/cases/presentation/screens/case_detail_screen.dart';
import 'package:meu_app/src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:meu_app/src/features/home/presentation/screens/home_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/cases_screen.dart';
import 'package:meu_app/src/features/lawyers/presentation/screens/partners_screen.dart';
import 'package:meu_app/src/features/lawyers/presentation/screens/lawyers_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/screens/partners_search_screen.dart';

import 'package:meu_app/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/settings_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/personal_data_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/documents_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/communication_preferences_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/privacy_settings_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/social_connections_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/hybrid_partnerships_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/screens/partnerships_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/screens/partnership_detail_screen.dart';
import 'package:meu_app/src/features/offers/presentation/screens/offers_screen.dart';
import 'package:meu_app/src/shared/widgets/organisms/main_tabs_shell.dart';
import 'package:meu_app/src/features/triage/presentation/screens/chat_triage_screen.dart';
import 'package:meu_app/src/features/services/presentation/screens/services_screen.dart';
import 'package:meu_app/src/features/firms/presentation/screens/firm_detail_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/case_documents_screen.dart';
import 'package:meu_app/src/features/sla_management/presentation/screens/sla_settings_screen.dart';
import 'package:meu_app/src/features/sla_management/presentation/bloc/sla_settings_bloc.dart';
import 'package:meu_app/src/features/sla_management/presentation/bloc/sla_analytics_bloc.dart';
import 'package:meu_app/src/features/chat/presentation/screens/chat_screen.dart';
import 'package:meu_app/src/features/chat/presentation/screens/chat_rooms_screen.dart';
// import removed: ChatRoomsScreen no longer used for main message tabs
import 'package:meu_app/src/features/video_call/presentation/screens/video_call_screen.dart';
import 'package:meu_app/src/features/lawyers/presentation/screens/claim_profile_screen.dart';import 'package:meu_app/src/features/ratings/presentation/screens/case_rating_screen.dart';
import 'package:meu_app/src/features/firms/presentation/screens/firm_team_screen.dart';
import 'package:meu_app/src/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:meu_app/src/features/admin/presentation/screens/admin_metrics_screen.dart';
import 'package:meu_app/src/features/admin/presentation/screens/admin_audit_screen.dart';
import 'package:meu_app/src/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:meu_app/src/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:meu_app/src/features/admin/domain/services/admin_auth_service.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/lawyer_detail_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/screens/lawyer_detail_screen.dart';
import 'package:meu_app/src/features/firms/presentation/bloc/firm_profile_bloc.dart';
import 'package:meu_app/src/features/firms/presentation/screens/firm_profile_screen.dart';
import 'package:meu_app/src/features/cluster_insights/presentation/screens/cluster_insights_screen.dart';
import 'package:meu_app/src/features/cluster_insights/presentation/screens/cluster_detail_screen.dart';
// injection_container já importado acima; remoção de import duplicado
// Importação correta das novas telas
import 'package:meu_app/src/features/admin/presentation/screens/premium_criteria_list.dart';
import 'package:meu_app/src/features/cases/presentation/pages/lawyer_cases_demo_page.dart';
import 'package:meu_app/src/features/cases/presentation/pages/enhanced_lawyer_cases_demo_page.dart';
import 'package:meu_app/src/features/messaging/presentation/screens/unified_chat_screen.dart';
import 'package:meu_app/src/features/messaging/presentation/screens/connect_accounts_screen.dart';
import 'package:meu_app/src/features/messaging/presentation/screens/internal_chat_screen.dart';
import 'package:meu_app/src/features/contracts/presentation/screens/contracts_screen.dart';
import 'package:meu_app/src/features/financial/presentation/screens/financial_dashboard_screen.dart';
import 'package:meu_app/src/features/financial/presentation/bloc/financial_bloc.dart';
import 'package:meu_app/src/features/messaging/presentation/screens/unified_chats_screen.dart';
// import 'package:meu_app/pages/admin/premium_criteria_form.dart';
import 'package:meu_app/src/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/my_accepted_cases_screen.dart';
import 'package:meu_app/injection_container.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/privacy_cases_bloc.dart';

// Definição da rota de perfil reutilizável com sub-rotas
final profileGoRoute = GoRoute(
  path: '/profile', // Usaremos um path base e o shell controlará o acesso
  builder: (context, state) => const ProfileScreen(),
  routes: [
    GoRoute(
      path: 'edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: 'personal-data',
      builder: (context, state) => const PersonalDataScreen(),
    ),
    GoRoute(
      path: 'documents',
      builder: (context, state) => const DocumentsScreen(),
    ),
    GoRoute(
      path: 'communication-preferences',
      builder: (context, state) => const CommunicationPreferencesScreen(),
    ),
    GoRoute(
      path: 'privacy-settings',
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: 'social-connections',
      builder: (context, state) => const SocialConnectionsScreen(),
    ),
  ],
);

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
        print('DEBUG: Redirect - userRole: $userRole');
        
        switch (userRole) {
          case 'lawyer_firm_member':  // Atualizado de lawyer_associated
            print('DEBUG: Redirecting to /dashboard');
            return '/dashboard';
          case 'firm':
            print('DEBUG: Redirecting to /home');
            return '/home';  // Dashboard específico para sócios (ContractorDashboard)
          case 'lawyer_individual':
          case 'super_associate':
            print('DEBUG: Redirecting to /home');
            return '/home';  // Dashboard específico para contratantes
          default:
            print('DEBUG: Redirecting to /client-home');
            return '/client-home';
        }
      }
      return null;
    },
    routes: [
              GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/demo-lawyer-cases', builder: (context, state) => const LawyerCasesDemoPage()),
        GoRoute(path: '/demo-enhanced-lawyer-cases', builder: (context, state) => const EnhancedLawyerCasesDemoPage()),
        GoRoute(path: '/contracts', builder: (context, state) => const ContractsScreen()),
        GoRoute(
          path: '/financial',
          builder: (context, state) => BlocProvider(
            create: (context) => getIt<FinancialBloc>(),
            child: const FinancialDashboardScreen(),
          ),
        ),
      GoRoute(path: '/register-client', builder: (context, state) => const RegisterClientScreen()),
      GoRoute(
        path: '/claim-profile',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? 'invalid';
          return ClaimProfileScreen(invitationToken: token);
        },
      ),
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
          // === ADVOGADO ASSOCIADO (branches 0-5) ===
          // 0: Advogado Associado - Painel
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen())]),
          // 1: Advogado Associado - Casos
          StatefulShellBranch(routes: [
            GoRoute(path: '/cases', builder: (context, state) => const CasesScreen()),
            GoRoute(
              path: '/cases/accepted',
              builder: (context, state) => BlocProvider(
                create: (context) => getIt<PrivacyCasesBloc>(),
                child: const MyAcceptedCasesScreen(),
              ),
            ),
          ]),
          // 2: Advogado Associado - Agenda
          StatefulShellBranch(routes: [GoRoute(path: '/schedule', builder: (context, state) => const ScheduleScreen())]),
          // 3: Advogado Associado - Ofertas
          StatefulShellBranch(routes: [GoRoute(path: '/offers', builder: (context, state) => const OffersScreen())]),
          // 4: Advogado Associado - Mensagens (Nativa)
          StatefulShellBranch(routes: [GoRoute(path: '/messages', builder: (context, state) => const ChatRoomsScreen())]),
          // 5: Advogado Associado - Perfil
          StatefulShellBranch(routes: [
             GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'personal-data',
                    builder: (context, state) => const PersonalDataScreen(),
                  ),
                  GoRoute(
                    path: 'documents',
                    builder: (context, state) => const DocumentsScreen(),
                  ),
                  GoRoute(
                    path: 'communication-preferences',
                    builder: (context, state) => const CommunicationPreferencesScreen(),
                  ),
                  GoRoute(
                    path: 'privacy-settings',
                    builder: (context, state) => const PrivacySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'social-connections',
                    builder: (context, state) => const SocialConnectionsScreen(),
                  ),
                ],
            ),
          ]),
          
          // === ADVOGADO CONTRATANTE (branches 6-12) ===
          // 6: Advogado Contratante - Início
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const DashboardScreen())]),
          // 7: Advogado Contratante - Casos
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-cases', builder: (context, state) => const CasesScreen())]),
          // 8: Advogado Contratante - Ofertas
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-offers', builder: (context, state) => const OffersScreen())]),
          // 9: Advogado Contratante - Parceiros
          StatefulShellBranch(routes: [GoRoute(path: '/partners', builder: (context, state) => const PartnersScreen())]),
          // 10: Advogado Contratante - Parcerias
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/partnerships',
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => getIt<HybridPartnershipsBloc>()),
                    BlocProvider(create: (_) => getIt<PartnershipsBloc>()),
                  ],
                  child: const PartnershipsScreen(),
                ),
              ),
              GoRoute(
                path: '/partnerships/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final extra = state.extra as Map<String, dynamic>?;
                  return PartnershipDetailScreen(
                    partnershipId: id,
                    initialData: extra != null ? extra['partnership'] : null,
                  );
                },
              ),
            ],
          ),
          // 11: Advogado Contratante - Mensagens (Nativa)
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-messages', builder: (context, state) => const ChatRoomsScreen())]),
          // 12: Advogado Contratante - Perfil
           StatefulShellBranch(routes: [
             GoRoute(
                path: '/contractor-profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'personal-data',
                    builder: (context, state) => const PersonalDataScreen(),
                  ),
                  GoRoute(
                    path: 'documents',
                    builder: (context, state) => const DocumentsScreen(),
                  ),
                  GoRoute(
                    path: 'communication-preferences',
                    builder: (context, state) => const CommunicationPreferencesScreen(),
                  ),
                  GoRoute(
                    path: 'privacy-settings',
                    builder: (context, state) => const PrivacySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'social-connections',
                    builder: (context, state) => const SocialConnectionsScreen(),
                  ),
                ],
            ),
          ]),

          // === CLIENTE (branches 13-18) ===
          // 13: Cliente - Início (Home com slogan)
          StatefulShellBranch(routes: [GoRoute(path: '/client-home', builder: (context, state) => const HomeScreen())]),
          // 14: Cliente - Casos
          StatefulShellBranch(routes: [GoRoute(path: '/client-cases', builder: (context, state) => const CasesScreen())]),
          // 15: Cliente - Advogados (Busca de Advogados)
          StatefulShellBranch(routes: [GoRoute(path: '/find-lawyers', builder: (context, state) => const LawyersScreen())]),
          // 16: Cliente - Mensagens (Nativa)
          StatefulShellBranch(routes: [GoRoute(path: '/client-messages', builder: (context, state) => const ChatRoomsScreen())]),
          // 17: Cliente - Serviços
          StatefulShellBranch(routes: [GoRoute(path: '/services', builder: (context, state) => const ServicesScreen())]),
          // 18: Cliente - Perfil
           StatefulShellBranch(routes: [
             GoRoute(
                path: '/client-profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'personal-data',
                    builder: (context, state) => const PersonalDataScreen(),
                  ),
                  GoRoute(
                    path: 'documents',
                    builder: (context, state) => const DocumentsScreen(),
                  ),
                  GoRoute(
                    path: 'communication-preferences',
                    builder: (context, state) => const CommunicationPreferencesScreen(),
                  ),
                  GoRoute(
                    path: 'privacy-settings',
                    builder: (context, state) => const PrivacySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'social-connections',
                    builder: (context, state) => const SocialConnectionsScreen(),
                  ),
                ],
            ),
          ]),
        ],
      ),
      
      // Rotas de mensagens unificadas
      GoRoute(
        path: '/unified-messages',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UnifiedChatsScreen(),
      ),
      // ===== DEBUG: alternar usuário rapidamente para testes (cliente/advogado) =====
      GoRoute(
        path: '/__debug/switch-user',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'lawyer_firm_member';
          final id = state.uri.queryParameters['id'] ?? 'debug-user';
          final fullName = state.uri.queryParameters['name'] ?? (role.startsWith('lawyer') ? 'Advogado Demo' : 'Cliente Demo');

          // Monta user de debug com o papel solicitado
          final user = auth_user.User(
            id: id,
            email: role.startsWith('lawyer') ? 'advogado@demo.com' : 'cliente@demo.com',
            fullName: fullName,
            role: role,
            userRole: role,
            permissions: const [
              'nav.view.client_home',
              'nav.view.client_cases',
              'nav.view.find_lawyers',
              'nav.view.client_messages',
              'nav.view.services',
              'nav.view.client_profile',
            ],
          );

          // Dispara troca de usuário
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthBloc>().add(AuthDebugUserSwitch(user));
            // Redireciona para casos do advogado ou do cliente conforme role
            if (role == 'lawyer_firm_member' || role == 'lawyer_individual' || role == 'lawyer_platform_associate' || role == 'firm') {
              context.go('/cases');
            } else {
              context.go('/client-cases');
            }
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      GoRoute(
        path: '/unified-chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final chatId = extra['chatId'] as String;
          final chatName = extra['chatName'] as String;
          final provider = extra['provider'] as String;
          
          return UnifiedChatScreen(
            chatId: chatId,
            chatName: chatName,
            provider: provider,
          );
        },
      ),
      GoRoute(
        path: '/connect-accounts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConnectAccountsScreen(),
      ),
      GoRoute(
        path: '/internal-chat/:recipientId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final recipientId = state.pathParameters['recipientId']!;
          final recipientName = state.uri.queryParameters['recipientName'];
          
          return InternalChatScreen(
            recipientId: recipientId,
            recipientName: recipientName,
          );
        },
      ),
      
      // Rotas fora da shell
      GoRoute(
        path: '/triage',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final auto = state.uri.queryParameters['auto'] == '1';
          return ChatTriageScreen(autoStart: auto);
        },
      ),
      GoRoute(
        path: '/partners-search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PartnersSearchScreen(),
      ),
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
      
      // Rotas de Perfil (aninhadas) - Esta é a rota PAI que contém as sub-rotas
      GoRoute(
        path: '/profile-details', // Renomeado para evitar conflito com shell routes
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(), // Rota pai
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'personal-data',
            builder: (context, state) => const PersonalDataScreen(),
          ),
          GoRoute(
            path: 'documents',
            builder: (context, state) => const DocumentsScreen(),
          ),
          GoRoute(
            path: 'communication-preferences',
            builder: (context, state) => const CommunicationPreferencesScreen(),
          ),
          GoRoute(
            path: 'privacy-settings',
            builder: (context, state) => const PrivacySettingsScreen(),
          ),
          GoRoute(
            path: 'social-connections',
            builder: (context, state) => const SocialConnectionsScreen(),
          ),
        ],
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

      // Cluster Insights Routes
      GoRoute(
        path: '/cluster-insights',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ClusterInsightsScreen(),
      ),
      GoRoute(
        path: '/cluster-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final clusterId = state.uri.queryParameters['clusterId'] ?? '';
          return ClusterDetailScreen(clusterId: clusterId);
        },
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
            roomId: roomName,
            userName: extra?['userName'],
            callConfig: {
              'roomUrl': extra?['roomUrl'] ?? 'https://litig.daily.co/$roomName',
              'userId': extra?['userId'] ?? 'anonymous',
              'otherPartyName': extra?['otherPartyName'],
            },
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
            if (!AdminAuthService.canAccessRoute(userRole ?? '', '/admin')) {
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
            if (!AdminAuthService.canAccessRoute(userRole ?? '', '/admin/metrics')) {
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
            if (!AdminAuthService.canAccessRoute(userRole ?? '', '/admin/audit')) {
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
            if (!AdminAuthService.canAccessRoute(userRole ?? '', '/admin/reports')) {
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
            if (!AdminAuthService.canAccessRoute(userRole ?? '', '/admin/settings')) {
              return _buildAccessDeniedScreen(context);
            }
          }
          
          return BlocProvider(
            create: (context) => getIt<AdminBloc>(),
            child: const AdminSettingsScreen(),
          );
        },
      ),

      // ✅ Rota para Critérios Premium
      GoRoute(
        path: '/admin/premium-criteria',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final authState = authBloc.state;
          if (authState is auth_states.Authenticated) {
            final userRole = authState.user.role;
            if (!AdminAuthService.canAccessRoute(userRole ?? '', '/admin/premium-criteria')) {
              return _buildAccessDeniedScreen(context);
            }
          }
          return const PremiumCriteriaListPage();
        },
      ),

      // ✅ Rota para Perfil Detalhado do Advogado
      GoRoute(
        path: '/lawyer/:lawyerId/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final lawyerId = state.pathParameters['lawyerId']!;
          return BlocProvider(
            create: (context) => getIt<LawyerDetailBloc>(),
            child: LawyerDetailScreen(lawyerId: lawyerId),
          );
        },
      ),

      // ✅ Rota para Perfil Detalhado do Escritório
      GoRoute(
        path: '/firm/:firmId/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final firmId = state.pathParameters['firmId']!;
          return BlocProvider(
            create: (context) => getIt<FirmProfileBloc>(),
            child: FirmProfileScreen(firmId: firmId),
          );
        },
      ),

      // Rotas de perfil independentes (fallback)
      GoRoute(
        path: '/profile-details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'personal-data',
            builder: (context, state) => const PersonalDataScreen(),
          ),
          GoRoute(
            path: 'documents',
            builder: (context, state) => const DocumentsScreen(),
          ),
          GoRoute(
            path: 'communication-preferences',
            builder: (context, state) => const CommunicationPreferencesScreen(),
          ),
          GoRoute(
            path: 'privacy-settings',
            builder: (context, state) => const PrivacySettingsScreen(),
          ),
          GoRoute(
            path: 'social-connections',
            builder: (context, state) => const SocialConnectionsScreen(),
          ),
        ],
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
            LucideIcons.shieldOff,
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
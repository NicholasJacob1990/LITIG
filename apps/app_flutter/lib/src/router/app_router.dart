import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/case_detail_screen.dart';
import 'package:meu_app/src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/cases_screen.dart';
import 'package:meu_app/src/features/lawyers/presentation/screens/lawyers_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/screens/lawyer_search_screen.dart';
import 'package:meu_app/src/features/messages/presentation/screens/messages_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:meu_app/src/features/schedule/presentation/screens/agenda_screen.dart';
import 'package:meu_app/src/features/home/presentation/screens/home_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/screens/offers_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/screens/partnerships_screen.dart';
import 'package:meu_app/src/shared/widgets/organisms/main_tabs_shell.dart';
import 'package:meu_app/src/features/triage/presentation/screens/chat_triage_screen.dart';
import 'package:meu_app/src/features/services/presentation/screens/services_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter appRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authBloc.state is auth_states.Authenticated;
      final isAuthenticating = ['/login', '/register-client', '/register-lawyer'].contains(state.matchedLocation);
      final isSplash = state.matchedLocation == '/splash';

      if (!loggedIn && !isAuthenticating && !isSplash) {
        return '/login';
      }
      if (loggedIn && (isAuthenticating || isSplash)) {
        // Redirecionamento genérico após login. A shell cuidará do resto.
        return '/home'; 
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainTabsShell(navigationShell: navigationShell);
        },
        branches: [
          // Advogado Associado
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/cases', builder: (context, state) => const CasesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/agenda', builder: (context, state) => const AgendaScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/offers', builder: (context, state) => const OffersScreen())]),
          
          // Advogado Contratante
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/partners', builder: (context, state) => const LawyerSearchScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/partnerships', builder: (context, state) => const PartnershipsScreen())]),

          // Cliente
          StatefulShellBranch(routes: [GoRoute(path: '/client-home', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/client-cases', builder: (context, state) => const CasesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/find-lawyers', builder: (context, state) => const LawyersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/client-messages', builder: (context, state) => const MessagesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/services', builder: (context, state) => const ServicesScreen())]),
          
          // Comum
          StatefulShellBranch(routes: [GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
      
      // Rotas fora da shell
      GoRoute(
        path: '/case-detail/:caseId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CaseDetailScreen(caseId: state.pathParameters['caseId']!),
      ),
      GoRoute(
        path: '/triage',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChatTriageScreen(),
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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/register_client_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/register_lawyer_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/case_detail_screen.dart';
import 'package:meu_app/src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:meu_app/src/features/cases/presentation/screens/cases_screen.dart';
import 'package:meu_app/src/features/lawyers/presentation/screens/lawyers_screen.dart';
import 'package:meu_app/src/features/messages/presentation/screens/client_messages_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:meu_app/src/features/profile/presentation/screens/settings_screen.dart';
import 'package:meu_app/src/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:meu_app/src/features/messages/presentation/screens/messages_screen.dart';
import 'package:meu_app/src/features/services/presentation/screens/services_screen.dart';
import 'package:meu_app/src/shared/widgets/organisms/main_tabs_shell.dart';

GoRouter appRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'root'),
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authBloc.state is auth_states.Authenticated;
      final isAuthenticating = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register-client' ||
          state.matchedLocation == '/register-lawyer';

      if (authBloc.state is auth_states.AuthInitial) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      if (!loggedIn && !isAuthenticating) {
        return '/login';
      }

      if (loggedIn && (isAuthenticating || state.matchedLocation == '/splash')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
      ShellRoute(
        navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'shell'),
        builder: (context, state, child) {
          return BlocBuilder<AuthBloc, auth_states.AuthState>(
            builder: (context, authState) {
              if (authState is auth_states.Authenticated) {
                return MainTabsShell(child: child);
              }
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            },
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
              path: '/cases',
              builder: (context, state) => const CasesScreen(),
              routes: [
                GoRoute(
                  path: ':caseId',
                  builder: (context, state) {
                    final caseId = state.pathParameters['caseId']!;
                    return CaseDetailScreen(caseId: caseId);
                  },
                ),
              ]),
          GoRoute(
            path: '/lawyers',
            builder: (context, state) => const LawyersScreen(),
          ),
          GoRoute(
            path: '/client-messages',
            builder: (context, state) => const ClientMessagesScreen(),
          ),
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServicesScreen(),
          ),
          GoRoute(
            path: '/schedule',
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
              path: '/profile',
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
              ]),
        ],
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
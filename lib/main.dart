import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/router/app_router.dart';
import 'package:meu_app/injection_container.dart' as di;
import 'package:meu_app/src/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => di.getIt<AuthBloc>()..add(AuthAppStarted()),
      child: Builder(
        builder: (context) {
          final authBloc = context.watch<AuthBloc>();
          final router = appRouter(authBloc);

          return MaterialApp.router(
            routerConfig: router,
            title: 'LITIG',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
} 

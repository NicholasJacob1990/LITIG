import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/router/app_router.dart';
import 'package:meu_app/injection_container.dart' as di;

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
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
          );
        },
      ),
    );
  }
} 

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/injection_container.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/router/app_router.dart';
import 'package:meu_app/src/core/theme/app_theme.dart';
import 'package:meu_app/src/core/theme/theme_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String get _supabaseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:54321';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:54321';
  }
  return 'http://127.0.0.1:54321';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando aplicação...');

  try {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQw54IsKbscS7Cs8_wnwU',
    );
    print('✅ Supabase inicializado com sucesso');
  } catch (e) {
    if (e.toString().contains('already initialized')) {
      print('✅ Supabase já estava inicializado (hot restart)');
    } else {
      print('❌ Erro ao inicializar Supabase: $e');
      print('⚠️  Continuando sem Supabase - usando modo offline');
    }
  }

  try {
    configureDependencies();
    print('✅ Dependências configuradas');
  } catch (e) {
    print('❌ Erro ao configurar dependências: $e');
  }

  final authBloc = getIt<AuthBloc>();
  authBloc.add(AuthCheckStatusRequested());
  final router = appRouter(authBloc);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider.value(value: authBloc),
      ],
      child: MyApp(router: router),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    print('🎨 Construindo MaterialApp...');
    
    return BlocListener<AuthBloc, auth_states.AuthState>(
      listener: (context, state) {
        print('🔄 AuthState mudou para: ${state.runtimeType}');
      },
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          print('🎨 Construindo com tema: $themeMode');
          return MaterialApp.router(
            routerConfig: router,
            title: 'LITGO Flutter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            builder: (context, widget) {
              print('🏗️ Builder chamado, widget: ${widget.runtimeType}');
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                print('❌ Erro capturado: ${errorDetails.exception}');
                return ErrorScreen(error: errorDetails.exception.toString());
              };
              return widget ?? const ErrorScreen(error: 'Widget nulo');
            },
          );
        },
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Ops! Algo deu errado',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: usar GoRouter para navegar
                },
                child: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

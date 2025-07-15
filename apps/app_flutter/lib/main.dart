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
import 'package:meu_app/injection_container.dart' as di;
import 'package:timeago/timeago.dart' as timeago;
import 'package:meu_app/src/core/utils/logger.dart';

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
  
  AppLogger.init('Iniciando aplicação...');

  try {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQw54IsKbscS7Cs8_wnwU',
    );
    AppLogger.success('Supabase inicializado com sucesso');
  } catch (e) {
    if (e.toString().contains('already initialized')) {
      AppLogger.info('Supabase já estava inicializado (hot restart)');
    } else {
      AppLogger.error('Erro ao inicializar Supabase', error: e);
      AppLogger.warning('Continuando sem Supabase - usando modo offline');
    }
  }

  try {
    configureDependencies();
    AppLogger.success('Dependências configuradas');
  } catch (e) {
    AppLogger.error('Erro ao configurar dependências', error: e);
  }

  // Initialize timeago locales
  timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  timeago.setDefaultLocale('pt_BR');

  runApp(
    BlocProvider(
      create: (context) => ThemeCubit(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    AppLogger.init('Inicializando MyApp...');
    
    try {
      _authBloc = getIt<AuthBloc>();
      AppLogger.success('AuthBloc criado');
      
      _authBloc.add(AuthCheckStatusRequested());
      AppLogger.success('AuthCheckStatusRequested enviado');
      
      _router = appRouter(_authBloc);
      AppLogger.success('Router configurado');
    } catch (e) {
      AppLogger.error('Erro na inicialização', error: e);
    }
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Construindo MaterialApp...');
    
    return BlocProvider.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, auth_states.AuthState>(
        listener: (context, state) {
          AppLogger.debug('AuthState mudou para: ${state.runtimeType}');
        },
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            AppLogger.debug('Construindo com tema: $themeMode');
            return MaterialApp.router(
              routerConfig: _router,
              title: 'LITGO Flutter',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              builder: (context, widget) {
                AppLogger.debug('Builder chamado, widget: ${widget.runtimeType}');
                ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                  AppLogger.error('Erro capturado', error: errorDetails.exception);
                  return ErrorScreen(error: errorDetails.exception.toString());
                };
                return widget ?? const ErrorScreen(error: 'Widget nulo');
              },
            );
          },
        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/injection/injection_container.dart';
import 'src/features/auth/presentation/bloc/auth_bloc.dart';
import 'src/features/auth/presentation/bloc/auth_event.dart';
import 'src/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      // Usando URL do projeto real conforme documentação
      url: 'https://cgmzvdfzzqrvlxqyowle.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnbXp2ZGZ6enFydmx4cXlvd2xlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4MTU3NzMsImV4cCI6MjA2NzM5MTc3M30.k-MKLJOGLlXKIlq4D4dMFSXYbOFLFrjm7EyHK7kPbNo',
    );
    print('✅ Supabase inicializado com sucesso');
  } catch (e) {
    if (e.toString().contains('already initialized')) {
      print('✅ Supabase já estava inicializado (hot restart)');
    } else {
      print('❌ Erro ao inicializar Supabase: $e');
    }
  }

  // Inicializar dependências
  await initializeDependencies();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthBloc _authBloc;
  late final router = appRouter(_authBloc);

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'LITGO5',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:meu_app/injection_container.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/router/app_router.dart';
import 'package:meu_app/src/core/theme/app_theme.dart';
import 'package:meu_app/src/core/theme/theme_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:meu_app/src/core/utils/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meu_app/src/core/services/notification_service.dart';
import 'package:meu_app/src/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:meu_app/src/shared/utils/development_helper.dart';
import 'package:meu_app/src/features/profile/presentation/bloc/profile_bloc.dart';

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
  
  // Firebase initialization
  try {
    await Firebase.initializeApp();
    AppLogger.success('Firebase inicializado com sucesso');
    
    // Configure Firebase Messaging for background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    AppLogger.error('Erro ao inicializar Firebase', error: e);
    AppLogger.warning('Continuando sem Firebase - notificações podem não funcionar');
  }
  
  // Setup dependency injection
  await setupInjection();
  
  // Initialize notification service
  await _initializeNotificationService();
  
  // Initialize development helpers (including mock server)
  if (kDebugMode) {
    await DevelopmentHelper.initializeForDevelopment();
  }
  
  runApp(const MyApp());
}

/// Handler para mensagens Firebase em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  AppLogger.info('Handling background message: ${message.messageId}');
  
  try {
    // Inicializar serviço de notificações locais
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Processar dados da notificação
    if (message.data.isNotEmpty) {
      AppLogger.info('Message data: ${message.data}');
      
      // Mostrar notificação local
      await notificationService.showLocalNotification(
        title: message.notification?.title ?? 'Nova notificação',
        body: message.notification?.body ?? 'Você tem uma nova mensagem',
        data: message.data,
      );
    }
  } catch (e) {
    AppLogger.error('Erro ao processar mensagem em background', error: e);
  }
}

/// Inicializa o serviço de notificações
Future<void> _initializeNotificationService() async {
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Configurar callbacks
    notificationService.setOnNotificationReceived((data) {
      AppLogger.info('Notificação recebida', tag: 'NotificationService');
      // Aqui você pode adicionar lógica para atualizar o BLoC
    });
    
    notificationService.setOnNotificationTapped((data) {
      AppLogger.info('Notificação tocada', tag: 'NotificationService');
      // Aqui você pode adicionar lógica de navegação
    });
    
  } catch (e) {
    AppLogger.error('Erro ao inicializar notificações', tag: 'NotificationService', error: e);
  }
}

/// Configura injeção de dependências integrando sistema antigo com notificações
Future<void> setupInjection() async {
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
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final ThemeCubit _themeCubit;
  late final NotificationBloc _notificationBloc;
  late final ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _themeCubit = ThemeCubit();
    _notificationBloc = getIt<NotificationBloc>();
    _profileBloc = getIt<ProfileBloc>();
    
    // Inicializar busca de notificações para usuários logados
    _authBloc.stream.listen((authState) {
      if (authState is auth_states.Authenticated) {
        // Buscar notificações quando usuário faz login
        _notificationBloc.add(const NotificationFetchRequested());
        _notificationBloc.add(const NotificationUnreadCountRequested());
      }
    });
  }

  @override
  void dispose() {
    _authBloc.close();
    _themeCubit.close();
    _notificationBloc.close();
    _profileBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<ThemeCubit>.value(value: _themeCubit),
        BlocProvider<NotificationBloc>.value(value: _notificationBloc),
        BlocProvider<ProfileBloc>.value(value: _profileBloc),
        // Outros BLoCs existentes...
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'LITGO',
            themeMode: themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            routerConfig: appRouter(_authBloc),
            debugShowCheckedModeBanner: false,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [
              Locale('pt', 'BR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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

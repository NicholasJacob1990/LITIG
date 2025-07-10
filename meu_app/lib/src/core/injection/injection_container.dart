import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Supabase Client
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // Auth BLoC
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(supabase: getIt<SupabaseClient>()),
  );
} 
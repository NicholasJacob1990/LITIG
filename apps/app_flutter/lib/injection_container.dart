import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth
import 'package:meu_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:meu_app/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:meu_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';

// Cases
import 'package:meu_app/src/features/cases/data/datasources/cases_remote_data_source.dart';
import 'package:meu_app/src/features/cases/data/repositories/cases_repository_impl.dart';
import 'package:meu_app/src/features/cases/domain/repositories/cases_repository.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_my_cases_usecase.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_case_detail_usecase.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/cases_bloc.dart';

// Services
import 'package:meu_app/src/core/services/dio_service.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // External
  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);
  getIt.registerSingleton<Dio>(DioService.dio);

  // Auth
  // Datasources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt()));

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: getIt()));

  // Blocs
  getIt.registerFactory(() => AuthBloc(authRepository: getIt()));

  // Cases
  // Datasources
  getIt.registerLazySingleton<CasesRemoteDataSource>(
      () => CasesRemoteDataSourceImpl(dio: getIt()));

  // Repositories
  getIt.registerLazySingleton<CasesRepository>(
      () => CasesRepositoryImpl(remoteDataSource: getIt()));

  // Use Cases
  getIt.registerLazySingleton<GetMyCasesUseCase>(
      () => GetMyCasesUseCase(getIt()));
  
  getIt.registerLazySingleton<GetCaseDetailUseCase>(
      () => GetCaseDetailUseCase(getIt()));

  // Blocs
  getIt.registerFactory(() => CasesBloc(getMyCasesUseCase: getIt()));
} 
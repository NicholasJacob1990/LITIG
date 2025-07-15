import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import 'package:meu_app/src/core/network/network_info.dart';

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
import 'package:meu_app/src/features/cases/data/services/case_firm_recommendation_service.dart';
import 'package:meu_app/src/features/dashboard/presentation/bloc/lawyer_firm_bloc.dart';

// Firms
import 'package:meu_app/src/features/firms/data/datasources/firm_remote_data_source.dart';
import 'package:meu_app/src/features/firms/data/repositories/firm_repository_impl.dart';
import 'package:meu_app/src/features/firms/domain/repositories/firm_repository.dart';
import 'package:meu_app/src/features/firms/domain/usecases/get_firms.dart';
import 'package:meu_app/src/features/firms/domain/usecases/get_firm_by_id.dart';
import 'package:meu_app/src/features/firms/domain/usecases/get_firm_kpis.dart';
import 'package:meu_app/src/features/firms/domain/usecases/get_firm_lawyers.dart';
import 'package:meu_app/src/features/firms/presentation/bloc/firm_bloc.dart';
import 'package:meu_app/src/features/firms/presentation/bloc/firm_detail_bloc.dart';

// Lawyers
import 'package:meu_app/src/features/lawyers/data/datasources/lawyers_remote_data_source.dart';
import 'package:meu_app/src/features/lawyers/domain/repositories/lawyers_repository.dart';
import 'package:meu_app/src/features/lawyers/data/repositories/lawyers_repository_impl.dart';
import 'package:meu_app/src/features/lawyers/domain/usecases/find_matches_usecase.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/matches_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/hybrid_match_bloc.dart';

// Partnerships
import 'package:meu_app/src/features/partnerships/data/datasources/partnership_remote_data_source.dart';
import 'package:meu_app/src/features/partnerships/data/datasources/partnership_remote_data_source_impl.dart';
import 'package:meu_app/src/features/partnerships/data/repositories/partnership_repository_impl.dart';
import 'package:meu_app/src/features/partnerships/domain/repositories/partnership_repository.dart';
import 'package:meu_app/src/features/partnerships/domain/usecases/get_partnerships.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';

// Search
import 'package:meu_app/src/features/search/data/datasources/search_remote_data_source.dart';
import 'package:meu_app/src/features/search/data/repositories/search_repository_impl.dart';
import 'package:meu_app/src/features/search/domain/repositories/search_repository.dart';
import 'package:meu_app/src/features/search/domain/usecases/perform_search.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_bloc.dart';

// Offers
import 'package:meu_app/src/features/offers/data/datasources/offers_remote_data_source.dart';
import 'package:meu_app/src/features/offers/data/datasources/offers_remote_data_source_impl.dart';
import 'package:meu_app/src/features/offers/data/repositories/offers_repository_impl.dart';
import 'package:meu_app/src/features/offers/domain/repositories/offers_repository.dart';
import 'package:meu_app/src/features/offers/domain/usecases/offers_usecases.dart';
import 'package:meu_app/src/features/offers/presentation/bloc/offers_bloc.dart';

// Services
import 'package:meu_app/src/core/services/dio_service.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // External
  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);
  getIt.registerSingleton<Dio>(DioService.dio);
  getIt.registerLazySingleton(() => Connectivity());

  // Core
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(getIt()));

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

  // Services
  getIt.registerLazySingleton<CaseFirmRecommendationService>(
      () => CaseFirmRecommendationService(getFirms: getIt()));

  // Blocs
  getIt.registerFactory(() => CasesBloc(getMyCasesUseCase: getIt()));

  // Firms
  // Datasources
  getIt.registerLazySingleton<FirmRemoteDataSource>(
      () => FirmRemoteDataSourceImpl(
        client: http.Client(),
        baseUrl: 'http://localhost:8080/api',
      ));

  // Repositories
  getIt.registerLazySingleton<FirmRepository>(
      () => FirmRepositoryImpl(remoteDataSource: getIt()));

  // Use Cases
  getIt.registerLazySingleton<GetFirms>(
      () => GetFirms(getIt()));
  
  getIt.registerLazySingleton<GetFirmById>(
      () => GetFirmById(getIt()));

  getIt.registerLazySingleton<GetFirmKpis>(
      () => GetFirmKpis(getIt()));

  getIt.registerLazySingleton<GetFirmLawyers>(
      () => GetFirmLawyers(getIt()));

  // Blocs
  getIt.registerFactory(() => FirmBloc(getFirms: getIt()));
  
  getIt.registerFactory(() => FirmDetailBloc(
    getFirmById: getIt(),
    getFirmKpis: getIt(),
    getFirmLawyers: getIt(),
  ));

  // Lawyers
  // Datasources
  getIt.registerLazySingleton<LawyersRemoteDataSource>(
      () => LawyersRemoteDataSourceImpl(dio: getIt()));
      
  // Repositories
  getIt.registerLazySingleton<LawyersRepository>(
      () => LawyersRepositoryImpl(remoteDataSource: getIt()));

  // Use Cases
  getIt.registerLazySingleton(() => FindMatchesUseCase(getIt()));

  // Blocs
  getIt.registerFactory(() => MatchesBloc(findMatchesUseCase: getIt()));
  
  getIt.registerFactory(() => HybridMatchBloc(
    lawyersRepository: getIt(),
    firmsRepository: getIt(),
  ));

  // Partnerships
  // Datasources
  getIt.registerLazySingleton<PartnershipRemoteDataSource>(
      () => PartnershipRemoteDataSourceImpl());
  // Repositories
  getIt.registerLazySingleton<PartnershipRepository>(
      () => PartnershipRepositoryImpl(
            remoteDataSource: getIt(),
            networkInfo: getIt(),
          ));
  // Use Cases
  getIt.registerLazySingleton(() => GetPartnerships(getIt()));
  // Blocs
  getIt.registerFactory(() => PartnershipsBloc(getPartnerships: getIt()));

  // Search
  // Datasources
  getIt.registerLazySingleton<SearchRemoteDataSource>(
      () => SearchRemoteDataSourceImpl());
  // Repositories
  getIt.registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(remoteDataSource: getIt()));
  // Use Cases
  getIt.registerLazySingleton(() => PerformSearch(getIt()));
  // Blocs
  getIt.registerFactory(() => SearchBloc(performSearch: getIt()));

  // Offers
  // Datasources
  getIt.registerLazySingleton<OffersRemoteDataSource>(
      () => OffersRemoteDataSourceImpl(dio: getIt()));
  // Repositories
  getIt.registerLazySingleton<OffersRepository>(
      () => OffersRepositoryImpl(remoteDataSource: getIt()));
  // Use Cases
  getIt.registerLazySingleton(() => GetPendingOffersUseCase(getIt()));
  getIt.registerLazySingleton(() => GetOfferHistoryUseCase(getIt()));
  getIt.registerLazySingleton(() => GetOfferStatsUseCase(getIt()));
  getIt.registerLazySingleton(() => AcceptOfferUseCase(getIt()));
  getIt.registerLazySingleton(() => RejectOfferUseCase(getIt()));
  // Blocs
  getIt.registerFactory(() => OffersBloc(
        getPendingOffersUseCase: getIt(),
        getOfferHistoryUseCase: getIt(),
        getOfferStatsUseCase: getIt(),
        acceptOfferUseCase: getIt(),
        rejectOfferUseCase: getIt(),
      ));

  getIt.registerFactory(() => LawyerFirmBloc(firmsRepository: getIt()));
} 
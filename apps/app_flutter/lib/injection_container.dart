import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import 'package:meu_app/src/core/network/network_info.dart';
import 'package:meu_app/src/core/services/simple_api_service.dart';
import 'package:meu_app/src/core/services/storage_service.dart';
import 'package:meu_app/src/core/services/ocr_service.dart';
import 'package:meu_app/src/core/services/calendar_service.dart';
import 'package:meu_app/src/core/services/social_auth_service.dart';

// Auth
import 'package:meu_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:meu_app/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:meu_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/src/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';

// Cases
import 'package:meu_app/src/features/cases/data/datasources/cases_remote_data_source.dart';
import 'package:meu_app/src/features/cases/data/repositories/cases_repository_impl.dart';
import 'package:meu_app/src/features/cases/domain/repositories/cases_repository.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_my_cases_usecase.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_case_detail_usecase.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/cases_bloc.dart';
import 'package:meu_app/src/features/cases/data/services/case_firm_recommendation_service.dart';

// Contextual Cases
import 'package:meu_app/src/features/cases/data/datasources/contextual_case_remote_data_source.dart';
import 'package:meu_app/src/features/cases/data/repositories/contextual_case_repository_impl.dart';
import 'package:meu_app/src/features/cases/domain/repositories/contextual_case_repository.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_contextual_case_data_usecase.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_contextual_kpis_usecase.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_contextual_actions_usecase.dart';
import 'package:meu_app/src/features/cases/domain/usecases/update_case_allocation.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/contextual_case_bloc.dart';

// Calendar
import 'package:meu_app/src/features/calendar/presentation/bloc/calendar_bloc.dart';

// Messaging
import 'package:meu_app/src/features/messaging/presentation/bloc/unified_messaging_bloc.dart';

// VIP
import 'src/features/vip/presentation/bloc/vip_status_bloc.dart';

// Documents
import 'package:meu_app/src/features/cases/data/datasources/documents_remote_data_source.dart';
import 'package:meu_app/src/features/cases/data/repositories/documents_repository_impl.dart';
import 'package:meu_app/src/features/cases/domain/repositories/documents_repository.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_case_documents_usecase.dart';
import 'package:meu_app/src/features/cases/domain/usecases/upload_document_usecase.dart';
import 'package:meu_app/src/features/cases/domain/usecases/delete_document_usecase.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/case_documents_bloc.dart';

import 'package:meu_app/src/features/dashboard/presentation/bloc/lawyer_firm_bloc.dart';

// Firms
import 'package:meu_app/src/features/firms/data/datasources/firm_remote_data_source.dart';

// SLA Management - TEMPORARIAMENTE COMENTADO PARA COMPILAÇÃO
// import 'package:meu_app/src/features/sla_management/data/datasources/sla_settings_remote_data_source.dart';
// import 'package:meu_app/src/features/sla_management/data/datasources/sla_settings_local_data_source.dart';
// import 'package:meu_app/src/features/sla_management/data/datasources/sla_escalation_remote_data_source.dart';
// import 'package:meu_app/src/features/sla_management/data/datasources/sla_escalation_local_data_source.dart';
// import 'package:meu_app/src/features/sla_management/data/datasources/sla_metrics_remote_data_source.dart';
// import 'package:meu_app/src/features/sla_management/data/datasources/sla_audit_remote_data_source.dart';
// import 'package:meu_app/src/features/sla_management/data/repositories/sla_settings_repository_impl.dart';
// import 'package:meu_app/src/features/sla_management/data/repositories/sla_escalation_repository_impl.dart';
// import 'package:meu_app/src/features/sla_management/domain/repositories/sla_settings_repository.dart';
// import 'package:meu_app/src/features/sla_management/domain/repositories/sla_escalation_repository.dart';
// import 'package:meu_app/src/features/sla_management/domain/usecases/get_sla_settings_usecase.dart';
// import 'package:meu_app/src/features/sla_management/domain/usecases/update_sla_settings_usecase.dart';
// import 'package:meu_app/src/features/sla_management/domain/usecases/get_sla_metrics_usecase.dart';
// import 'package:meu_app/src/features/sla_management/domain/usecases/get_sla_escalations_usecase.dart';
// import 'package:meu_app/src/features/sla_management/domain/usecases/get_sla_audit_usecase.dart';
// import 'package:meu_app/src/features/sla_management/domain/usecases/get_sla_presets_usecase.dart';
// import 'package:meu_app/src/features/sla_management/domain/usecases/calculate_sla_deadline.dart';
// import 'package:meu_app/src/features/sla_management/domain/usecases/validate_sla_settings.dart';
// import 'package:meu_app/src/features/sla_management/presentation/bloc/sla_settings_bloc.dart';
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
import 'package:meu_app/src/features/lawyers/presentation/bloc/lawyer_detail_bloc.dart';

// Lawyer Detail - Enriched Data
import 'package:meu_app/src/features/lawyers/data/datasources/enriched_lawyer_data_source.dart';
import 'package:meu_app/src/features/lawyers/data/repositories/enriched_lawyer_repository_impl.dart';
import 'package:meu_app/src/features/lawyers/domain/repositories/enriched_lawyer_repository.dart';
import 'package:meu_app/src/features/lawyers/domain/usecases/get_enriched_lawyer.dart';

// Firm Profile - Enriched Data
import 'package:meu_app/src/features/firms/data/datasources/enriched_firm_data_source.dart';
import 'package:meu_app/src/features/firms/data/repositories/enriched_firm_repository_impl.dart';
import 'package:meu_app/src/features/firms/domain/repositories/enriched_firm_repository.dart';
import 'package:meu_app/src/features/firms/domain/usecases/get_enriched_firm.dart';
import 'package:meu_app/src/features/firms/presentation/bloc/firm_profile_bloc.dart';

// Partnerships
import 'package:meu_app/src/features/partnerships/data/datasources/partnership_remote_data_source.dart';
import 'package:meu_app/src/features/partnerships/data/datasources/partnership_remote_data_source_impl.dart';
import 'package:meu_app/src/features/partnerships/data/repositories/partnership_repository_impl.dart';
import 'package:meu_app/src/features/partnerships/domain/repositories/partnership_repository.dart';
import 'package:meu_app/src/features/partnerships/domain/usecases/get_partnerships.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/hybrid_partnerships_bloc.dart';

// Search
import 'package:meu_app/src/features/search/data/datasources/search_remote_data_source.dart';

// Profile
import 'package:meu_app/src/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:meu_app/src/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:meu_app/src/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:meu_app/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:meu_app/src/features/profile/presentation/bloc/profile_bloc.dart';

// Contracts
import 'package:meu_app/src/features/contracts/data/datasources/contracts_remote_data_source.dart';
import 'package:meu_app/src/features/contracts/data/repositories/contracts_repository_impl.dart';
import 'package:meu_app/src/features/contracts/domain/repositories/contracts_repository.dart';
import 'package:meu_app/src/features/contracts/presentation/bloc/contracts_bloc.dart';

// Financial
import 'package:meu_app/src/features/financial/data/datasources/financial_remote_data_source.dart';
import 'package:meu_app/src/features/financial/data/repositories/financial_repository_impl.dart';
import 'package:meu_app/src/features/financial/domain/repositories/financial_repository.dart';
import 'package:meu_app/src/features/financial/domain/usecases/get_financial_data.dart';
import 'package:meu_app/src/features/financial/domain/usecases/export_financial_data.dart';
import 'package:meu_app/src/features/financial/domain/usecases/mark_payment_received.dart';
import 'package:meu_app/src/features/financial/domain/usecases/request_payment_repass.dart';
import 'package:meu_app/src/features/financial/presentation/bloc/financial_bloc.dart';
import 'package:meu_app/src/features/search/data/repositories/search_repository_impl.dart';
import 'package:meu_app/src/features/search/domain/repositories/search_repository.dart';
import 'package:meu_app/src/features/search/domain/usecases/perform_search.dart';
import 'package:meu_app/src/features/search/domain/usecases/perform_semantic_firm_search.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_bloc.dart';

// Offers
import 'package:meu_app/src/features/offers/data/datasources/offers_remote_data_source.dart';
import 'package:meu_app/src/features/offers/data/datasources/offers_remote_data_source_impl.dart';
import 'package:meu_app/src/features/offers/data/repositories/offers_repository_impl.dart';
import 'package:meu_app/src/features/offers/domain/repositories/offers_repository.dart';
import 'package:meu_app/src/features/offers/domain/usecases/offers_usecases.dart';
import 'package:meu_app/src/features/offers/presentation/bloc/offers_bloc.dart';

// Notifications
import 'package:meu_app/src/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:meu_app/src/features/notifications/domain/repositories/notification_repository.dart';
import 'package:meu_app/src/features/notifications/presentation/bloc/notification_bloc.dart';

// Chat
import 'package:meu_app/src/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:meu_app/src/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:meu_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:meu_app/src/features/chat/domain/usecases/get_chat_rooms.dart';
import 'package:meu_app/src/features/chat/domain/usecases/get_chat_messages.dart';
import 'package:meu_app/src/features/chat/domain/usecases/send_message.dart';
import 'package:meu_app/src/features/chat/presentation/bloc/chat_bloc.dart';

// Video Call imports
import 'package:meu_app/src/features/video_call/domain/repositories/video_call_repository.dart';
import 'package:meu_app/src/features/video_call/domain/usecases/create_video_call_room.dart';
import 'package:meu_app/src/features/video_call/domain/usecases/join_video_call_room.dart';
import 'package:meu_app/src/features/video_call/data/repositories/video_call_repository_impl.dart';
import 'package:meu_app/src/features/video_call/data/datasources/video_call_remote_data_source.dart';
import 'package:meu_app/src/features/video_call/presentation/bloc/video_call_bloc.dart';
import 'package:meu_app/src/core/services/video_call_service.dart';

// Lawyer Hiring
import 'package:meu_app/src/features/lawyers/data/datasources/lawyer_hiring_remote_data_source.dart';
import 'package:meu_app/src/features/lawyers/data/repositories/lawyer_hiring_repository_impl.dart';
import 'package:meu_app/src/features/lawyers/domain/repositories/lawyer_hiring_repository.dart';
import 'package:meu_app/src/features/lawyers/domain/usecases/hire_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/usecases/get_hiring_proposals.dart';
import 'package:meu_app/src/features/lawyers/domain/usecases/respond_to_proposal.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/lawyer_hiring_bloc.dart';

// Ratings
import 'package:meu_app/src/features/ratings/data/datasources/rating_remote_datasource.dart';
import 'package:meu_app/src/features/ratings/data/datasources/rating_remote_datasource_impl.dart';
import 'package:meu_app/src/features/ratings/data/repositories/rating_repository_impl.dart';
import 'package:meu_app/src/features/ratings/domain/repositories/rating_repository.dart';
import 'package:meu_app/src/features/ratings/domain/usecases/submit_rating_usecase.dart';
import 'package:meu_app/src/features/ratings/domain/usecases/get_lawyer_ratings_usecase.dart';
import 'package:meu_app/src/features/ratings/domain/usecases/check_can_rate_usecase.dart';
import 'package:meu_app/src/features/ratings/presentation/bloc/rating_bloc.dart';

// Cluster Insights
import 'package:meu_app/src/features/cluster_insights/data/datasources/cluster_remote_datasource.dart';
import 'package:meu_app/src/features/cluster_insights/data/repositories/cluster_repository_impl.dart';
import 'package:meu_app/src/features/cluster_insights/domain/repositories/cluster_repository.dart';
import 'package:meu_app/src/features/cluster_insights/presentation/bloc/trending_clusters_bloc.dart';
import 'package:meu_app/src/features/cluster_insights/presentation/bloc/all_clusters_bloc.dart';
import 'package:meu_app/src/features/cluster_insights/presentation/bloc/partnership_recommendations_bloc.dart';

// Removed duplicate SLA Settings imports - using sla_management structure

// OCR Service

// Admin
// Admin imports commented out until AdminBloc implementation is complete
// import 'package:meu_app/src/features/admin/domain/repositories/admin_repository.dart';
// import 'package:meu_app/src/features/admin/domain/usecases/get_admin_dashboard.dart';
// import 'package:meu_app/src/features/admin/domain/usecases/get_admin_metrics.dart';
// import 'package:meu_app/src/features/admin/domain/usecases/get_admin_audit_logs.dart';
// import 'package:meu_app/src/features/admin/domain/usecases/generate_executive_report.dart';
// import 'package:meu_app/src/features/admin/domain/usecases/force_global_sync.dart';
// import 'package:meu_app/src/features/admin/presentation/bloc/admin_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // External dependencies
  getIt.registerLazySingleton(() => http.Client());
  getIt.registerLazySingleton(() => Connectivity());
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton(() => Supabase.instance.client);
  
  // SharedPreferences  
  final prefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => prefs);

  // Core services
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(getIt()));
  getIt.registerLazySingleton<SimpleApiService>(() => SimpleApiService(getIt()));
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<CalendarService>(() => CalendarService());
  getIt.registerLazySingleton<SocialAuthService>(() => SocialAuthService());

  // Auth
  // Datasources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt()));

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: getIt()));

  // Use Cases
  getIt.registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(getIt()));

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
  getIt.registerFactory(() => CasesBloc(
    getMyCasesUseCase: getIt(),
    getCurrentUserUseCase: getIt(),
  ));

  // Contextual Cases
  // Datasources
  getIt.registerLazySingleton<ContextualCaseRemoteDataSource>(
      () => ContextualCaseRemoteDataSourceImpl(dio: getIt()));

  // Repositories
  getIt.registerLazySingleton<ContextualCaseRepository>(
      () => ContextualCaseRepositoryImpl(remoteDataSource: getIt()));

  // Use Cases
  getIt.registerLazySingleton<GetContextualCaseDataUseCase>(
      () => GetContextualCaseDataUseCase(getIt()));
  
  getIt.registerLazySingleton<GetContextualKPIsUseCase>(
      () => GetContextualKPIsUseCase(getIt()));
      
  getIt.registerLazySingleton<GetContextualActionsUseCase>(
      () => GetContextualActionsUseCase(getIt()));
      
  getIt.registerLazySingleton<UpdateCaseAllocation>(
      () => UpdateCaseAllocation(getIt()));

  // Blocs
  getIt.registerFactory(() => ContextualCaseBloc(
      getContextualCaseData: getIt(),
      getContextualKPIs: getIt(),
      getContextualActions: getIt(),
      updateCaseAllocation: getIt(),
      ));

  // Blocs
  getIt.registerFactory(() => CalendarBloc());
  
  // Messaging
  getIt.registerFactory(() => UnifiedMessagingBloc());
  getIt.registerFactory(() => VipStatusBloc());

  // Documents
  // Datasources
  getIt.registerLazySingleton<DocumentsRemoteDataSource>(
      () => DocumentsRemoteDataSourceImpl(dio: getIt()));

  // Repositories
  getIt.registerLazySingleton<DocumentsRepository>(
      () => DocumentsRepositoryImpl(remoteDataSource: getIt()));

  // Use Cases
  getIt.registerLazySingleton<GetCaseDocumentsUseCase>(
      () => GetCaseDocumentsUseCase(getIt()));
  
  getIt.registerLazySingleton<UploadDocumentUseCase>(
      () => UploadDocumentUseCase(getIt()));
      
  getIt.registerLazySingleton<DeleteDocumentUseCase>(
      () => DeleteDocumentUseCase(getIt()));

  // Blocs
  getIt.registerFactory(() => CaseDocumentsBloc(
    getCaseDocumentsUseCase: getIt(),
    uploadDocumentUseCase: getIt(),
    deleteDocumentUseCase: getIt(),
  ));

  // Firms
  // Datasources
  getIt.registerLazySingleton<FirmRemoteDataSource>(
      () => FirmRemoteDataSourceImpl(
        client: http.Client(),
        baseUrl: 'http://localhost:8080/api',
      ));

  
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
  getIt.registerFactory(() => HybridPartnershipsBloc(
    getPartnerships: getIt(),
  ));

  // Search
  // Datasources
  getIt.registerLazySingleton<SearchRemoteDataSource>(
      () => SearchRemoteDataSourceImpl(dio: getIt()));
  // Repositories
  getIt.registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(remoteDataSource: getIt()));
  
  // Use Cases
  getIt.registerLazySingleton(() => PerformSearch(getIt()));
  getIt.registerLazySingleton(() => PerformSemanticFirmSearch(getIt()));
  
  // Blocs
  getIt.registerFactory(() => SearchBloc(
    performSearch: getIt(),
    performSemanticFirmSearch: getIt(),
  ));

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

  // Notifications
  // Repository
  getIt.registerLazySingleton<NotificationRepository>(() => 
    NotificationRepositoryImpl(
      apiService: getIt(),
      storageService: getIt(),
    ));
  
  // Bloc
  getIt.registerFactory(() => NotificationBloc(repository: getIt()));

  // SLA Management System - TEMPORARIAMENTE COMENTADO PARA COMPILAÇÃO
  
  // SLA Local Data Sources
  // getIt.registerLazySingleton<SlaSettingsLocalDataSource>(
  //   () => SlaSettingsLocalDataSourceImpl(sharedPreferences: getIt()));
  // getIt.registerLazySingleton<SlaEscalationLocalDataSource>(
  //   () => SlaEscalationLocalDataSourceImpl(sharedPreferences: getIt()));

  // SLA Remote Data Sources
  // getIt.registerLazySingleton<SlaSettingsRemoteDataSource>(
  //   () => SlaSettingsRemoteDataSourceImpl(
  //     dio: getIt<Dio>(),
  //     baseUrl: getIt<String>(instanceName: 'baseUrl'),
  //   ));
  // getIt.registerLazySingleton<SlaEscalationRemoteDataSource>(
  //   () => SlaEscalationRemoteDataSourceImpl(
  //     dio: getIt<Dio>(),
  //     baseUrl: getIt<String>(instanceName: 'baseUrl'),
  //   ));
  // getIt.registerLazySingleton<SlaMetricsRemoteDataSource>(
  //   () => SlaMetricsRemoteDataSourceImpl(client: getIt<Dio>()));
  // getIt.registerLazySingleton<SlaAuditRemoteDataSource>(
  //   () => SlaAuditRemoteDataSourceImpl(dio: getIt<Dio>()));

  // SLA Repositories
  // getIt.registerLazySingleton<SlaSettingsRepository>(
  //   () => SlaSettingsRepositoryImpl(
  //     localDataSource: getIt<SlaSettingsLocalDataSource>(),
  //     remoteDataSource: getIt<SlaSettingsRemoteDataSource>(),
  //   ));
  // getIt.registerLazySingleton<SlaEscalationRepository>(
  //   () => SlaEscalationRepositoryImpl(
  //     remoteDataSource: getIt<SlaEscalationRemoteDataSource>(),
  //     localDataSource: getIt<SlaEscalationLocalDataSource>(),
  //     dio: getIt<Dio>(),
  //   ));
  // getIt.registerLazySingleton<SlaMetricsRepository>(
  //   () => SlaMetricsRepositoryImpl(
  //     remoteDataSource: getIt<SlaMetricsRemoteDataSource>(),
  //   ));
  // getIt.registerLazySingleton<SlaAuditRepository>(
  //   () => SlaAuditRepositoryImpl(
  //     remoteDataSource: getIt<SlaAuditRemoteDataSource>(),
  //   ));

  // SLA Use Cases
  // getIt.registerLazySingleton(() => GetSlaSettingsUseCase(getIt()));
  // getIt.registerLazySingleton(() => UpdateSlaSettingsUseCase(getIt()));
  // getIt.registerLazySingleton(() => GetSlaMetricsUseCase(getIt()));
  // getIt.registerLazySingleton(() => GetSlaEscalationsUseCase(getIt()));
  // getIt.registerLazySingleton(() => GetSlaAuditUseCase(getIt()));
  // getIt.registerLazySingleton(() => GetSlaPresetsUseCase(getIt()));
  // getIt.registerLazySingleton(() => CalculateSlaDeadlineUseCase(getIt()));
  // getIt.registerLazySingleton(() => ValidateSlaSettings());

  // SLA BLoCs
  // getIt.registerFactory(() => SlaSettingsBloc(
  //       validateSlaSettings: getIt<ValidateSlaSettings>(),
  //       calculateSlaDeadlineUseCase: getIt<CalculateSlaDeadlineUseCase>(),
  //     ));
  // TODO: Implement missing SLA Analytics use cases
  // getIt.registerFactory(() => SlaAnalyticsBloc(
  //       generateSlaReport: getIt<GenerateSlaReport>(),
  //       exportSlaData: getIt<ExportSlaData>(),
  //     ));

  // Chat
  // Datasources
  getIt.registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(apiService: getIt()));
  
  // Repositories
  getIt.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(
        remoteDataSource: getIt(),
        networkInfo: getIt(),
      ));
  
  // Use Cases
  getIt.registerLazySingleton(() => GetChatRooms(getIt()));
  getIt.registerLazySingleton(() => GetChatMessages(getIt()));
  getIt.registerLazySingleton(() => SendMessage(getIt()));
  
  // BLoCs
  getIt.registerFactory(() => ChatBloc(
        getChatRooms: getIt(),
        getChatMessages: getIt(),
        sendMessage: getIt(),
        chatRepository: getIt(),
      ));

  // Video Call
  // Service
  getIt.registerLazySingleton(() => VideoCallService());
  
  // Datasources
  getIt.registerLazySingleton<VideoCallRemoteDataSource>(
      () => VideoCallRemoteDataSourceImpl(dio: getIt()));
  
  // Repository
  getIt.registerLazySingleton<VideoCallRepository>(() => VideoCallRepositoryImpl(
        remoteDataSource: getIt(),
        networkInfo: getIt(),
      ));
  
  // Use Cases
  getIt.registerLazySingleton(() => CreateVideoCallRoom(getIt()));
  getIt.registerLazySingleton(() => JoinVideoCallRoom(getIt()));
  
  // BLoC
  getIt.registerFactory(() => VideoCallBloc(
        createVideoCallRoom: getIt(),
        joinVideoCallRoom: getIt(),
        videoCallService: getIt(),
      ));

  // Lawyer Hiring
  // Datasources
  getIt.registerLazySingleton<LawyerHiringRemoteDataSource>(
      () => LawyerHiringRemoteDataSourceImpl(apiService: getIt()));
  
  // Repositories
  getIt.registerLazySingleton<LawyerHiringRepository>(
      () => LawyerHiringRepositoryImpl(
          remoteDataSource: getIt(),
          networkInfo: getIt(),
      ));
  
  // Use Cases
  getIt.registerLazySingleton(() => HireLawyer(getIt()));
  getIt.registerLazySingleton(() => GetHiringProposals(getIt()));
  getIt.registerLazySingleton(() => RespondToProposal(getIt()));
  
  // Blocs
  getIt.registerFactory(() => LawyerHiringBloc(
      hireLawyer: getIt(),
      getHiringProposals: getIt(),
      respondToProposal: getIt(),
  ));

  getIt.registerFactory(() => LawyerFirmBloc(firmsRepository: getIt()));

  // Ratings System
  // Data Sources
  getIt.registerLazySingleton<RatingRemoteDataSource>(
    () => RatingRemoteDataSourceImpl(dio: getIt()),
  );

  // Repositories
  getIt.registerLazySingleton<RatingRepository>(
    () => RatingRepositoryImpl(
      remoteDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton(() => SubmitRatingUseCase(getIt()));
  getIt.registerLazySingleton(() => GetLawyerRatingsUseCase(getIt()));
  getIt.registerLazySingleton(() => CheckCanRateUseCase(getIt()));

  // BLoC
  getIt.registerFactory(
    () => RatingBloc(
      submitRatingUseCase: getIt(),
      getLawyerRatingsUseCase: getIt(),
      checkCanRateUseCase: getIt(),
      repository: getIt(),
    ),
  );

  // OCR Service
  getIt.registerLazySingleton<OCRService>(() => OCRService());

  // Profile
  // Data Sources
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(),
  );
  getIt.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
    ),
  );

  // BLoC
  getIt.registerFactory(
    () => ProfileBloc(
      profileRepository: getIt(),
      socialAuthService: getIt(),
    ),
  );

  // Contracts
  // Data Sources
  getIt.registerLazySingleton<ContractsRemoteDataSource>(
    () => ContractsRemoteDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<ContractsRepository>(
    () => ContractsRepositoryImpl(remoteDataSource: getIt()),
  );

  // BLoC
  getIt.registerFactory(() => ContractsBloc(repository: getIt()));

  // Financial
  // Data Sources
  getIt.registerLazySingleton<FinancialRemoteDataSource>(
    () => FinancialRemoteDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<FinancialRepository>(
    () => FinancialRepositoryImpl(remoteDataSource: getIt()),
  );

  // Use Cases
  getIt.registerLazySingleton(() => GetFinancialData(getIt()));
  getIt.registerLazySingleton(() => ExportFinancialData(getIt()));
  getIt.registerLazySingleton(() => MarkPaymentReceived(getIt()));
  getIt.registerLazySingleton(() => RequestPaymentRepass(getIt()));

  // BLoC
  getIt.registerFactory(() => FinancialBloc(
    getFinancialData: getIt(),
    exportFinancialData: getIt(),
    markPaymentReceived: getIt(),
    requestPaymentRepass: getIt(),
  ));

  // Admin System
  // TODO: Implement AdminRepository when data layer is created
  // getIt.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl());
  
  // Use Cases
  // getIt.registerLazySingleton(() => GetAdminDashboard(getIt()));
  // getIt.registerLazySingleton(() => GetAdminMetrics(getIt()));
  // getIt.registerLazySingleton(() => GetAdminAuditLogs(getIt()));
  // getIt.registerLazySingleton(() => GenerateExecutiveReport(getIt()));
  // getIt.registerLazySingleton(() => ForceGlobalSync(getIt()));
  
  // BLoC - Comentado temporariamente até implementação das use cases
  // getIt.registerFactory(() => AdminBloc(
  //   getAdminDashboard: getIt(),
  //   getAdminMetrics: getIt(),
  //   getAdminAuditLogs: getIt(),
  //   generateExecutiveReport: getIt(),
  //   forceGlobalSync: getIt(),
  // ));

  // Lawyer Detail - Data Sources
  getIt.registerLazySingleton<EnrichedLawyerDataSource>(() => 
    EnrichedLawyerRemoteDataSource(
      client: getIt(),
      baseUrl: 'http://localhost:8000', // TODO: Mover para configuração
    )
  );
  
  // Lawyer Detail - Repositories
  getIt.registerLazySingleton<EnrichedLawyerRepository>(() => 
    EnrichedLawyerRepositoryImpl(dataSource: getIt())
  );
  
  // Lawyer Detail - Use Cases
  getIt.registerLazySingleton<GetEnrichedLawyerUseCase>(() => 
    GetEnrichedLawyerUseCase(repository: getIt())
  );
  
  getIt.registerLazySingleton<RefreshEnrichedLawyerUseCase>(() => 
    RefreshEnrichedLawyerUseCase(repository: getIt())
  );
  
  // Lawyer Detail - BLoC
  getIt.registerFactory(() => LawyerDetailBloc(
    getEnrichedLawyer: getIt(),
    refreshEnrichedLawyer: getIt(),
  ));

  // ✅ Firm Profile Dependencies
  // Firm Profile - Data Source
  getIt.registerLazySingleton<EnrichedFirmDataSource>(() => 
    EnrichedFirmDataSourceImpl(
      client: getIt(),
      baseUrl: 'http://localhost:8000',
    )
  );
  
  // Firm Profile - Repository
  getIt.registerLazySingleton<EnrichedFirmRepository>(() => 
    EnrichedFirmRepositoryImpl(dataSource: getIt())
  );
  
  // Firm Profile - Use Cases
  getIt.registerLazySingleton<GetEnrichedFirmUseCase>(() => 
    GetEnrichedFirmUseCase(repository: getIt())
  );
  
  getIt.registerLazySingleton<RefreshEnrichedFirmUseCase>(() => 
    RefreshEnrichedFirmUseCase(repository: getIt())
  );
  
  // Firm Profile - BLoC
  getIt.registerFactory(() => FirmProfileBloc(
    getEnrichedFirm: getIt(),
    refreshEnrichedFirm: getIt(),
  ));

  // Cluster Insights Feature
  // Data Sources
  getIt.registerLazySingleton<ClusterRemoteDataSource>(
    () => ClusterRemoteDataSourceImpl(client: getIt()),
  );

  // Repositories
  getIt.registerLazySingleton<ClusterRepository>(
    () => ClusterRepositoryImpl(remoteDataSource: getIt()),
  );

  // BLoCs
  getIt.registerFactory(() => TrendingClustersBloc(repository: getIt()));
  
  // 💡 ADICIONADOS: Registro dos novos BLoCs para as abas do modal
  getIt.registerFactory(() => AllClustersBloc(repository: getIt()));
  getIt.registerFactory(() => PartnershipRecommendationsBloc(repository: getIt()));
}
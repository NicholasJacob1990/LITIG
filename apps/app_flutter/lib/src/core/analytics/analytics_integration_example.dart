import 'package:flutter/material.dart';
import 'analytics_service.dart';

/// Exemplos de como integrar o AnalyticsService nas telas existentes
/// 
/// Este arquivo demonstra como adicionar tracking de analytics
/// nas funcionalidades implementadas para perfis de advogados e escritórios

class AnalyticsIntegrationExamples {
  static final _analytics = AnalyticsService();

  /// Exemplo 1: Integração na tela de perfil de advogado
  /// 
  /// Adicione este código no LawyerDetailScreen:
  /// ```dart
  /// class LawyerDetailScreen extends StatefulWidget {
  ///   // ... existing code
  /// 
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     
  ///     // Track quando a tela é visualizada
  ///     AnalyticsService().trackLawyerProfileView(
  ///       widget.lawyerId,
  ///       metadata: {
  ///         'source': 'search_results', // ou 'recommendations', 'deep_link', etc.
  ///         'user_type': 'client', // ou 'admin', 'lawyer', etc.
  ///       },
  ///     );
  ///     
  ///     // Track tempo de carregamento
  ///     final stopwatch = Stopwatch()..start();
  ///     bloc.add(LoadLawyerDetail(widget.lawyerId));
  ///     
  ///     bloc.stream.listen((state) {
  ///       if (state is LawyerDetailLoaded) {
  ///         stopwatch.stop();
  ///         AnalyticsService().trackLoadingTime(
  ///           'lawyer_profile',
  ///           stopwatch.elapsed,
  ///         );
  ///       } else if (state is LawyerDetailError) {
  ///         AnalyticsService().trackError(
  ///           'lawyer_profile_load',
  ///           state.message,
  ///           metadata: {'lawyer_id': widget.lawyerId},
  ///         );
  ///       }
  ///     });
  ///   }
  /// }
  /// ```
  static void exampleLawyerProfileIntegration(String lawyerId) {
    // Simulação da integração
    _analytics.trackLawyerProfileView(
      lawyerId,
      metadata: {
        'source': 'search_results',
        'user_type': 'client',
      },
    );
  }

  /// Exemplo 2: Integração na tela de perfil de escritório
  /// 
  /// Adicione este código no FirmProfileScreen:
  /// ```dart
  /// class FirmProfileScreen extends StatefulWidget {
  ///   // ... existing code
  ///   
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     
  ///     AnalyticsService().trackFirmProfileView(
  ///       widget.firmId,
  ///       metadata: {
  ///         'source': 'firm_listing',
  ///         'user_type': 'potential_client',
  ///       },
  ///     );
  ///   }
  /// }
  /// ```
  static void exampleFirmProfileIntegration(String firmId) {
    _analytics.trackFirmProfileView(
      firmId,
      metadata: {
        'source': 'firm_listing',
        'user_type': 'potential_client',
      },
    );
  }

  /// Exemplo 3: Tracking de navegação entre abas
  /// 
  /// Adicione este código no TabController das telas de perfil:
  /// ```dart
  /// DefaultTabController(
  ///   length: 5,
  ///   child: Column(
  ///     children: [
  ///       TabBar(
  ///         onTap: (index) {
  ///           final tabNames = ['overview', 'linkedin', 'academic', 'curriculum', 'transparency'];
  ///           AnalyticsService().trackTabNavigation(
  ///             'lawyer', // ou 'firm'
  ///             tabNames[index],
  ///             metadata: {
  ///               'profile_id': widget.lawyerId,
  ///               'previous_tab': _currentTabIndex,
  ///             },
  ///           );
  ///           _currentTabIndex = index;
  ///         },
  ///         tabs: [...],
  ///       ),
  ///       // ... rest of the code
  ///     ],
  ///   ),
  /// ),
  /// ```
  static void exampleTabNavigationTracking(String profileType, String tabName, String profileId) {
    _analytics.trackTabNavigation(
      profileType,
      tabName,
      metadata: {
        'profile_id': profileId,
        'session_time': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Exemplo 4: Tracking de uso de filtros
  /// 
  /// Adicione este código nas abas de Casos e Parcerias:
  /// ```dart
  /// void _applyFilters() {
  ///   setState(() {
  ///     // ... existing filter logic
  ///   });
  ///   
  ///   AnalyticsService().trackFilterUsage(
  ///     'firm_cases_history',
  ///     {
  ///       'status_filter': _selectedFilter,
  ///       'area_filter': _selectedArea,
  ///     },
  ///     metadata: {
  ///       'firm_id': widget.firmId,
  ///       'results_count': _filteredCases.length,
  ///     },
  ///   );
  /// }
  /// ```
  static void exampleFilterTracking(String screen, Map<String, String> filters, int resultsCount) {
    _analytics.trackFilterUsage(
      screen,
      filters,
      metadata: {
        'results_count': resultsCount,
        'filter_combinations': filters.length,
      },
    );
  }

  /// Exemplo 5: Tracking de refresh de dados
  /// 
  /// Adicione este código nos botões de refresh:
  /// ```dart
  /// void _handleRefresh() {
  ///   AnalyticsService().trackDataRefresh(
  ///     'lawyer', // ou 'firm'
  ///     widget.lawyerId,
  ///     metadata: {
  ///       'trigger': 'user_action', // ou 'automatic', 'error_retry'
  ///       'current_tab': _getCurrentTabName(),
  ///     },
  ///   );
  ///   
  ///   bloc.add(RefreshLawyerDetail(widget.lawyerId));
  /// }
  /// ```
  static void exampleRefreshTracking(String profileType, String profileId) {
    _analytics.trackDataRefresh(
      profileType,
      profileId,
      metadata: {
        'trigger': 'user_action',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Exemplo 6: Tracking de compartilhamento
  /// 
  /// Adicione este código nos botões de share:
  /// ```dart
  /// void _shareProfile() {
  ///   AnalyticsService().trackProfileShare(
  ///     'lawyer', // ou 'firm'
  ///     widget.lawyerId,
  ///     'native_share', // ou 'copy_link', 'email', 'whatsapp'
  ///     metadata: {
  ///       'profile_name': lawyer.name,
  ///       'shared_from_tab': _getCurrentTabName(),
  ///     },
  ///   );
  ///   
  ///   Share.share('Check out this lawyer profile: ${generateProfileUrl()}');
  /// }
  /// ```
  static void exampleShareTracking(String profileType, String profileId, String shareMethod) {
    _analytics.trackProfileShare(
      profileType,
      profileId,
      shareMethod,
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Exemplo 7: Tracking de explicação do algoritmo
  /// 
  /// Adicione este código no modal de explicação:
  /// ```dart
  /// void _showMatchExplanation(BuildContext context) {
  ///   AnalyticsService().trackAlgorithmExplanationView(
  ///     'lawyer', // ou 'firm'
  ///     widget.lawyer.id,
  ///     metadata: {
  ///       'match_score': widget.lawyer.fair,
  ///       'explanation_trigger': 'help_button',
  ///     },
  ///   );
  ///   
  ///   showDialog(
  ///     context: context,
  ///     builder: (context) => MatchExplanationDialog(...),
  ///   );
  /// }
  /// ```
  static void exampleAlgorithmExplanationTracking(String profileType, String profileId) {
    _analytics.trackAlgorithmExplanationView(
      profileType,
      profileId,
      metadata: {
        'user_curiosity_level': 'high',
        'explanation_detail': 'full',
      },
    );
  }

  /// Exemplo 8: Tracking de download de currículo
  /// 
  /// Adicione este código na aba de currículo:
  /// ```dart
  /// void _downloadCurriculum(String format) {
  ///   AnalyticsService().trackCurriculumDownload(
  ///     widget.lawyerId,
  ///     format, // 'pdf', 'docx', 'txt'
  ///     metadata: {
  ///       'lawyer_name': lawyer.name,
  ///       'download_source': 'profile_tab',
  ///       'file_size_mb': estimatedFileSize,
  ///     },
  ///   );
  ///   
  ///   // Perform download logic
  /// }
  /// ```
  static void exampleCurriculumDownloadTracking(String lawyerId, String format) {
    _analytics.trackCurriculumDownload(
      lawyerId,
      format,
      metadata: {
        'download_source': 'profile_tab',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Exemplo 9: Tracking de interações genéricas com UI
  /// 
  /// Use este código para elementos específicos:
  /// ```dart
  /// GestureDetector(
  ///   onTap: () {
  ///     AnalyticsService().trackUIInteraction(
  ///       'linkedin_connection_count',
  ///       'tap',
  ///       metadata: {
  ///         'profile_id': widget.lawyerId,
  ///         'connection_count': linkedinProfile.connectionCount,
  ///       },
  ///     );
  ///     
  ///     _showConnectionDetails();
  ///   },
  ///   child: Text('${profile.connectionCount} conexões'),
  /// ),
  /// ```
  static void exampleUIInteractionTracking(String element, String action) {
    _analytics.trackUIInteraction(
      element,
      action,
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Exemplo 10: Gerando relatório de analytics
  /// 
  /// Use este código para gerar relatórios:
  /// ```dart
  /// void _generateAnalyticsReport() {
  ///   final report = AnalyticsService().generateReport(
  ///     startDate: DateTime.now().subtract(Duration(days: 30)),
  ///     endDate: DateTime.now(),
  ///   );
  ///   
  ///   print(report.toString());
  ///   
  ///   // Ou envie para um dashboard
  ///   _sendReportToDashboard(report);
  /// }
  /// ```
  static void exampleReportGeneration() {
    final report = _analytics.generateReport(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
    );
    
    print('Analytics Report Generated:');
    print(report.toString());
  }

  /// Exemplo 11: Middleware para tracking automático de erros no BLoC
  /// 
  /// Adicione este código nos BLoCs:
  /// ```dart
  /// class LawyerDetailBloc extends Bloc<LawyerDetailEvent, LawyerDetailState> {
  ///   LawyerDetailBloc(...) : super(LawyerDetailInitial()) {
  ///     // ... existing code
  ///     
  ///     on<LoadLawyerDetail>((event, emit) async {
  ///       try {
  ///         emit(LawyerDetailLoading());
  ///         
  ///         final result = await _getEnrichedLawyer(event.lawyerId);
  ///         
  ///         result.fold(
  ///           (failure) {
  ///             AnalyticsService().trackError(
  ///               'lawyer_detail_load_failure',
  ///               failure.message,
  ///               metadata: {
  ///                 'lawyer_id': event.lawyerId,
  ///                 'failure_type': failure.runtimeType.toString(),
  ///               },
  ///             );
  ///             emit(LawyerDetailError(message: failure.message));
  ///           },
  ///           (lawyer) => emit(LawyerDetailLoaded(enrichedLawyer: lawyer)),
  ///         );
  ///       } catch (e) {
  ///         AnalyticsService().trackError(
  ///           'lawyer_detail_unexpected_error',
  ///           e.toString(),
  ///           metadata: {'lawyer_id': event.lawyerId},
  ///         );
  ///         emit(LawyerDetailError(message: 'Unexpected error occurred'));
  ///       }
  ///     });
  ///   }
  /// }
  /// ```
  static void exampleBlocErrorTracking(String errorType, String message, Map<String, dynamic> metadata) {
    _analytics.trackError(errorType, message, metadata: metadata);
  }

  /// Exemplo 12: Widget wrapper para tracking automático
  /// 
  /// Crie este widget para tracking automático:
  /// ```dart
  /// class TrackedWidget extends StatelessWidget {
  ///   final Widget child;
  ///   final String elementName;
  ///   final VoidCallback? onTap;
  ///   final Map<String, dynamic>? metadata;
  ///   
  ///   const TrackedWidget({
  ///     Key? key,
  ///     required this.child,
  ///     required this.elementName,
  ///     this.onTap,
  ///     this.metadata,
  ///   }) : super(key: key);
  ///   
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return GestureDetector(
  ///       onTap: () {
  ///         AnalyticsService().trackUIInteraction(
  ///           elementName,
  ///           'tap',
  ///           metadata: metadata,
  ///         );
  ///         onTap?.call();
  ///       },
  ///       child: child,
  ///     );
  ///   }
  /// }
  /// 
  /// // Usage:
  /// TrackedWidget(
  ///   elementName: 'lawyer_contact_button',
  ///   metadata: {'lawyer_id': widget.lawyerId},
  ///   onTap: () => _contactLawyer(),
  ///   child: ElevatedButton(
  ///     onPressed: null, // handled by TrackedWidget
  ///     child: Text('Entrar em Contato'),
  ///   ),
  /// ),
  /// ```
  static Widget createTrackedWidget({
    required Widget child,
    required String elementName,
    VoidCallback? onTap,
    Map<String, dynamic>? metadata,
  }) {
    return GestureDetector(
      onTap: () {
        _analytics.trackUIInteraction(elementName, 'tap', metadata: metadata);
        onTap?.call();
      },
      child: child,
    );
  }
}

/// Mixin para facilitar o uso de analytics em StatefulWidgets
mixin AnalyticsTrackingMixin<T extends StatefulWidget> on State<T> {
  final AnalyticsService analytics = AnalyticsService();
  
  void trackScreenView(String screenName, {Map<String, dynamic>? metadata}) {
    analytics.trackUIInteraction(
      screenName,
      'view',
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
        ...?metadata,
      },
    );
  }
  
  void trackButtonTap(String buttonName, {Map<String, dynamic>? metadata}) {
    analytics.trackUIInteraction(
      buttonName,
      'tap',
      metadata: metadata,
    );
  }
  
  void trackLoadingTime(String operation, Duration duration) {
    analytics.trackLoadingTime(operation, duration);
  }
  
  void trackError(String operation, String error, {Map<String, dynamic>? metadata}) {
    analytics.trackError(operation, error, metadata: metadata);
  }
} 
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Serviço para gerenciar feature flags usando Firebase Remote Config
class RemoteConfigService {
  static RemoteConfigService? _instance;
  static RemoteConfigService get instance => _instance ??= RemoteConfigService._();
  
  RemoteConfigService._();

  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  /// Inicializa o Firebase Remote Config
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Configurações para desenvolvimento
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode 
            ? const Duration(seconds: 10) // Desenvolvimento: 10 segundos
            : const Duration(hours: 1),   // Produção: 1 hora
      ));

      // Valores padrão para feature flags
      await _remoteConfig!.setDefaults({
        'use_new_navigation_system': true,
        'enable_contextual_case_view': false,
        'enable_b2b_matching': false,
        'enable_partnership_ai_suggestions': false,
        'debug_mode': kDebugMode,
      });

      // Buscar configurações remotas
      await _remoteConfig!.fetchAndActivate();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ RemoteConfigService inicializado com sucesso');
        print('📱 Feature flags carregadas:');
        print('   - use_new_navigation_system: $useNewNavigationSystem');
        print('   - enable_contextual_case_view: $enableContextualCaseView');
        print('   - enable_b2b_matching: $enableB2BMatching');
        print('   - enable_partnership_ai_suggestions: $enablePartnershipAISuggestions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inicializar RemoteConfigService: $e');
        print('📱 Usando valores padrão locais');
      }
      _isInitialized = false;
    }
  }

  /// Força uma nova busca das configurações remotas
  Future<void> forceRefresh() async {
    if (_remoteConfig == null) return;
    
    try {
      await _remoteConfig!.fetchAndActivate();
      if (kDebugMode) {
        print('🔄 Feature flags atualizadas');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao atualizar feature flags: $e');
      }
    }
  }

  /// Retorna o valor de uma feature flag booleana
  bool _getBool(String key, {bool defaultValue = false}) {
    if (!_isInitialized || _remoteConfig == null) {
      return defaultValue;
    }
    
    try {
      return _remoteConfig!.getBool(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar feature flag "$key": $e');
      }
      return defaultValue;
    }
  }

  /// Retorna o valor de uma feature flag string
  String _getString(String key, {String defaultValue = ''}) {
    if (!_isInitialized || _remoteConfig == null) {
      return defaultValue;
    }
    
    try {
      return _remoteConfig!.getString(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar feature flag "$key": $e');
      }
      return defaultValue;
    }
  }

  /// Retorna o valor de uma feature flag inteira
  int _getInt(String key, {int defaultValue = 0}) {
    if (!_isInitialized || _remoteConfig == null) {
      return defaultValue;
    }
    
    try {
      return _remoteConfig!.getInt(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar feature flag "$key": $e');
      }
      return defaultValue;
    }
  }

  // === FEATURE FLAGS ESPECÍFICAS ===

  /// Controla se o novo sistema de navegação baseado em permissões está ativo
  bool get useNewNavigationSystem => _getBool('use_new_navigation_system', defaultValue: true);

  /// Controla se a visualização contextual de casos está ativa
  bool get enableContextualCaseView => _getBool('enable_contextual_case_view', defaultValue: false);

  /// Controla se o sistema de matching B2B está ativo
  bool get enableB2BMatching => _getBool('enable_b2b_matching', defaultValue: false);

  /// Controla se as sugestões de parceria por IA estão ativas
  bool get enablePartnershipAISuggestions => _getBool('enable_partnership_ai_suggestions', defaultValue: false);

  /// Controla se o modo debug está ativo
  bool get debugMode => _getBool('debug_mode', defaultValue: kDebugMode);

  /// Retorna o nível de log configurado remotamente
  String get logLevel => _getString('log_level', defaultValue: 'info');

  /// Retorna o timeout para requisições de API (em segundos)
  int get apiTimeout => _getInt('api_timeout', defaultValue: 30);

  /// Retorna informações sobre todas as feature flags para debug
  Map<String, dynamic> get allFeatureFlags {
    if (!_isInitialized || _remoteConfig == null) {
      return {
        'error': 'RemoteConfig não inicializado',
        'using_defaults': true,
      };
    }

    return {
      'use_new_navigation_system': useNewNavigationSystem,
      'enable_contextual_case_view': enableContextualCaseView,
      'enable_b2b_matching': enableB2BMatching,
      'enable_partnership_ai_suggestions': enablePartnershipAISuggestions,
      'debug_mode': debugMode,
      'log_level': logLevel,
      'api_timeout': apiTimeout,
      'last_fetch_time': _remoteConfig!.lastFetchTime,
      'last_fetch_status': _remoteConfig!.lastFetchStatus,
    };
  }
} 
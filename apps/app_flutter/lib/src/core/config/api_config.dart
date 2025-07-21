/// Configurações da API
/// 
/// Centraliza todas as configurações relacionadas à comunicação com APIs
class ApiConfig {
  /// URL base da API principal
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  /// URL base da API de desenvolvimento
  static const String devBaseUrl = 'http://127.0.0.1:8080/api';

  /// URL base da API de produção
  static const String prodBaseUrl = 'https://api.litig.app';

  /// Headers padrão para todas as requisições
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'LITIG-App/1.0',
  };

  /// Timeout padrão para requisições (em milissegundos)
  static const int defaultTimeout = 30000;

  /// Timeout para upload de arquivos (em milissegundos)
  static const int uploadTimeout = 120000;

  /// Timeout para download de arquivos (em milissegundos)
  static const int downloadTimeout = 180000;

  /// Máximo de tentativas para requisições
  static const int maxRetries = 3;

  /// Intervalo entre tentativas (em milissegundos)
  static const int retryDelay = 1000;

  /// Versão da API
  static const String apiVersion = 'v1';

  /// Headers com autenticação (deve ser definido dinamicamente)
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  /// Obtém a URL completa baseada no ambiente
  static String get currentBaseUrl {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return prodBaseUrl;
    }
    return devBaseUrl;
  }

  /// Endpoints específicos
  static const String documentsEndpoint = '/documents';
  static const String casesEndpoint = '/cases';
  static const String usersEndpoint = '/users';
  static const String firmsEndpoint = '/firms';
  static const String notificationsEndpoint = '/notifications';
  static const String slaEndpoint = '/sla';
  static const String offersEndpoint = '/offers';
  static const String partnershipsEndpoint = '/partnerships';

  /// Endpoints para validação de documentos
  static const String documentValidationEndpoint = '/documents/validation';
  static const String documentSuggestionsEndpoint = '/documents/suggestions';
  static const String documentEnhancedEndpoint = '/documents/enhanced';

  /// Configurações de upload
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const List<String> allowedFileTypes = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'jpg',
    'jpeg',
    'png',
  ];
}
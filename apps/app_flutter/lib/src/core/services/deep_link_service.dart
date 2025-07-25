import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:meu_app/src/core/utils/logger.dart';

/// Serviço para gerenciar deep links da aplicação
/// Especialmente importante para URLs de retorno do Stripe
class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance => _instance ??= DeepLinkService._();
  
  DeepLinkService._();

  static const MethodChannel _channel = MethodChannel('litig/deep_links');
  
  /// Callback para quando um deep link é recebido
  Function(String)? onDeepLinkReceived;

  /// Inicializa o serviço de deep links
  Future<void> initialize() async {
    try {
      // Configurar listener para deep links nativos
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // Verificar se app foi aberto por deep link
      await _checkInitialLink();
      
      AppLogger.init('DeepLinkService inicializado');
    } catch (e) {
      AppLogger.error('Erro ao inicializar DeepLinkService', error: e);
    }
  }

  /// Handler para chamadas nativas
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeepLink':
        final link = call.arguments as String?;
        if (link != null) {
          await _processDeepLink(link);
        }
        break;
      default:
        AppLogger.warning('Método não reconhecido: ${call.method}');
    }
  }

  /// Verifica se app foi aberto por deep link
  Future<void> _checkInitialLink() async {
    try {
      final initialLink = await _channel.invokeMethod<String>('getInitialLink');
      if (initialLink != null && initialLink.isNotEmpty) {
        AppLogger.info('App aberto por deep link: $initialLink');
        await _processDeepLink(initialLink);
      }
    } catch (e) {
      AppLogger.warning('Erro ao verificar link inicial: $e');
    }
  }

  /// Processa um deep link recebido
  Future<void> _processDeepLink(String link) async {
    try {
      AppLogger.info('Processando deep link: $link');
      
      final uri = Uri.parse(link);
      
      // Processar diferentes tipos de deep links
      switch (uri.host) {
        case 'billing':
          await _handleBillingDeepLink(uri);
          break;
        
        case 'case':
          await _handleCaseDeepLink(uri);
          break;
          
        case 'chat':
          await _handleChatDeepLink(uri);
          break;
          
        default:
          AppLogger.warning('Deep link não reconhecido: $link');
          // Callback genérico se configurado
          onDeepLinkReceived?.call(link);
      }
    } catch (e) {
      AppLogger.error('Erro ao processar deep link', error: e);
    }
  }

  /// Trata deep links relacionados a billing/pagamentos
  Future<void> _handleBillingDeepLink(Uri uri) async {
    final path = uri.path;
    final queryParams = uri.queryParameters;
    
    AppLogger.info('Processando billing deep link: $path');
    
    switch (path) {
      case '/success':
        await _handleBillingSuccess(queryParams);
        break;
        
      case '/cancel':
        await _handleBillingCancel(queryParams);
        break;
        
      default:
        AppLogger.warning('Billing path não reconhecido: $path');
    }
  }

  /// Trata sucesso no pagamento Stripe
  Future<void> _handleBillingSuccess(Map<String, String> params) async {
    final sessionId = params['session_id'];
    final planId = params['plan_id'];
    
    AppLogger.success('Pagamento bem-sucedido - Session: $sessionId, Plan: $planId');
    
    // Navegar para tela de sucesso com dados
    // Note: Usar contexto global ou callback para navegação
    _navigateToRoute('/billing/success', extra: {
      'session_id': sessionId,
      'plan_id': planId,
      'success': true,
    });
  }

  /// Trata cancelamento do pagamento Stripe
  Future<void> _handleBillingCancel(Map<String, String> params) async {
    final sessionId = params['session_id'];
    
    AppLogger.warning('Pagamento cancelado - Session: $sessionId');
    
    // Navegar para tela de cancelamento
    _navigateToRoute('/billing/cancel', extra: {
      'session_id': sessionId,
      'cancelled': true,
    });
  }

  /// Trata deep links de casos
  Future<void> _handleCaseDeepLink(Uri uri) async {
    final path = uri.path;
    final caseId = path.split('/').last;
    
    AppLogger.info('Abrindo caso: $caseId');
    
    _navigateToRoute('/case-detail/$caseId');
  }

  /// Trata deep links de chat
  Future<void> _handleChatDeepLink(Uri uri) async {
    final path = uri.path;
    final chatId = path.split('/').last;
    
    AppLogger.info('Abrindo chat: $chatId');
    
    _navigateToRoute('/chat/$chatId');
  }

  /// Navega para uma rota específica
  void _navigateToRoute(String route, {Object? extra}) {
    // Em um contexto real, você precisaria de acesso ao GoRouter
    // Por enquanto, log a intenção
    AppLogger.info('Navegando para: $route');
    if (extra != null) {
      AppLogger.debug('Com dados extras: $extra');
    }
    
    // TODO: Implementar navegação real quando houver contexto
    // Exemplo: GoRouter.of(context).push(route, extra: extra);
  }

  /// Gera URL de deep link para billing
  static String getBillingSuccessUrl({String? sessionId, String? planId}) {
    final params = <String, String>{};
    if (sessionId != null) params['session_id'] = sessionId;
    if (planId != null) params['plan_id'] = planId;
    
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return 'litig://billing/success${query.isNotEmpty ? '?$query' : ''}';
  }

  /// Gera URL de deep link para billing cancelado
  static String getBillingCancelUrl({String? sessionId}) {
    final params = <String, String>{};
    if (sessionId != null) params['session_id'] = sessionId;
    
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return 'litig://billing/cancel${query.isNotEmpty ? '?$query' : ''}';
  }

  /// Gera URL de deep link para caso
  static String getCaseDeepLink(String caseId) {
    return 'litig://case/$caseId';
  }

  /// Gera URL de deep link para chat
  static String getChatDeepLink(String chatId) {
    return 'litig://chat/$chatId';
  }

  /// Define callback para deep links não tratados
  void setOnDeepLinkReceived(Function(String) callback) {
    onDeepLinkReceived = callback;
  }

  /// Registra handler para deep links específicos
  final Map<String, Function(Map<String, String>)> _customHandlers = {};
  
  void registerHandler(String path, Function(Map<String, String>) handler) {
    _customHandlers[path] = handler;
    AppLogger.debug('Handler registrado para: $path');
  }

  /// Remove handler personalizado
  void unregisterHandler(String path) {
    _customHandlers.remove(path);
    AppLogger.debug('Handler removido para: $path');
  }

  /// Simula um deep link (útil para desenvolvimento)
  Future<void> simulateDeepLink(String link) async {
    if (kDebugMode) {
      AppLogger.debug('Simulando deep link: $link');
      await _processDeepLink(link);
    }
  }
} 
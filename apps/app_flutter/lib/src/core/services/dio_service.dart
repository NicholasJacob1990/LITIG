import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

class DioService {
  static Dio? _dio;

  static String get _baseUrl {
    // Debug logs para verificar a detecção de plataforma
    print('🔍 DEBUG: kIsWeb = $kIsWeb');
    
    // Detecção mais robusta de plataforma
    if (kIsWeb) {
      print('🌐 DEBUG: Detectado Flutter Web - usando localhost:8080');
      return 'http://localhost:8080/api';
    }
    
    // Para plataformas nativas, verificar o Platform
    try {
      if (Platform.isAndroid) {
        print('🤖 DEBUG: Detectado Android - usando 10.0.2.2:8080');
        return 'http://10.0.2.2:8080/api'; // Emulador Android
      } else if (Platform.isIOS) {
        print('🍎 DEBUG: Detectado iOS - usando 127.0.0.1:8080');
        return 'http://127.0.0.1:8080/api'; // Simulador iOS
      } else {
        print('🖥️ DEBUG: Detectado Desktop - usando localhost:8080');
        return 'http://localhost:8080/api'; // Desktop
      }
    } catch (e) {
      // Se Platform não estiver disponível (ex: Web), usar localhost
      print('⚠️ DEBUG: Platform não disponível, fallback para localhost:8080');
      return 'http://localhost:8080/api';
    }
  }

  static Dio get dio {
    if (_dio == null) {
      final baseUrl = _baseUrl;
      print('🚀 DEBUG: Inicializando Dio com baseUrl: $baseUrl');
      
      _dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ));

      // Adicionar interceptor de autenticação
      _dio!.interceptors.add(AuthInterceptor());

      // Adicionar interceptor de logging (apenas em debug)
      _dio!.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print('DIO: $object'),
      ));
    }
    return _dio!;
  }

  // ========== TRIAGEM INTELIGENTE ==========
  
  /// Inicia triagem inteligente assíncrona
  static Future<Response> startTriage({
    required String textoCliente,
    required String userId,
    List<double>? coords,
  }) async {
    try {
      return await dio.post('/triage', data: {
        'texto_cliente': textoCliente,
        'user_id': userId,
        if (coords != null) 'coords': coords,
      });
    } catch (e) {
      print('Erro na triagem: $e');
      rethrow;
    }
  }

  /// Verifica status da triagem
  static Future<Response> getTriageStatus(String taskId) async {
    try {
      return await dio.get('/triage/status/$taskId');
    } catch (e) {
      print('Erro ao verificar status da triagem: $e');
      rethrow;
    }
  }

  // ========== MATCHING DE ADVOGADOS ==========
  
  /// Busca matches de advogados para um caso
  static Future<Response> findMatches({
    required String caseId,
    int k = 5,
    String preset = 'balanced',
    double? radiusKm,
    List<String>? excludeIds,
  }) async {
    try {
      return await dio.post('/match', data: {
        'case_id': caseId,
        'k': k,
        'preset': preset,
        if (radiusKm != null) 'radius_km': radiusKm,
        if (excludeIds != null) 'exclude_ids': excludeIds,
      });
    } catch (e) {
      print('Erro ao buscar matches: $e');
      rethrow;
    }
  }

  /// Gera explicações para matches
  static Future<Response> explainMatches({
    required String caseId,
    required List<String> lawyerIds,
  }) async {
    try {
      return await dio.post('/explain', data: {
        'case_id': caseId,
        'lawyer_ids': lawyerIds,
      });
    } catch (e) {
      print('Erro ao explicar matches: $e');
      rethrow;
    }
  }

  /// Busca manual de advogados com filtros
  static Future<Response> searchLawyers({
    String? query,
    String? area,
    String? uf,
    double? minRating,
    double? maxDistance,
    bool? onlyAvailable,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      Map<String, dynamic> params = {
        'limit': limit,
        'offset': offset,
      };
      
      if (query != null && query.isNotEmpty) params['q'] = query;
      if (area != null) params['area'] = area;
      if (uf != null) params['uf'] = uf;
      if (minRating != null) params['min_rating'] = minRating;
      if (maxDistance != null) params['max_distance'] = maxDistance;
      if (onlyAvailable != null) params['only_available'] = onlyAvailable;
      
      return await dio.get('/lawyers', queryParameters: params);
    } catch (e) {
      print('Erro na busca de advogados: $e');
      rethrow;
    }
  }

  // ========== GESTÃO DE CASOS ==========
  
  /// Busca casos do usuário
  static Future<Response> getMyCases() async {
    try {
      return await dio.get('/cases/my-cases');
    } catch (e) {
      print('Erro ao buscar casos: $e');
      rethrow;
    }
  }

  /// Busca detalhes de um caso específico
  static Future<Response> getCaseDetail(String caseId) async {
    try {
      return await dio.get('/cases/$caseId');
    } catch (e) {
      print('Erro ao buscar detalhes do caso: $e');
      rethrow;
    }
  }

  /// Atualiza status do caso
  static Future<Response> updateCaseStatus({
    required String caseId,
    required String newStatus,
    String? notes,
  }) async {
    try {
      return await dio.patch('/cases/$caseId/status', data: {
        'new_status': newStatus,
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      print('Erro ao atualizar status do caso: $e');
      rethrow;
    }
  }

  // ========== MENSAGENS/CHAT ==========
  
  /// Busca mensagens de um caso
  static Future<Response> getCaseMessages(String caseId) async {
    try {
      return await dio.get('/cases/$caseId/messages');
    } catch (e) {
      print('Erro ao buscar mensagens: $e');
      rethrow;
    }
  }

  /// Envia mensagem
  static Future<Response> sendMessage({
    required String caseId,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      return await dio.post('/cases/$caseId/messages', data: {
        'message': message,
        if (attachments != null) 'attachments': attachments,
      });
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      rethrow;
    }
  }

  // ========== DOCUMENTOS ==========
  
  /// Upload de documento
  static Future<Response> uploadDocument({
    required String caseId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      
      return await dio.post('/documents/upload/$caseId', data: formData);
    } catch (e) {
      print('Erro ao fazer upload de documento: $e');
      rethrow;
    }
  }

  /// Lista documentos de um caso
  static Future<Response> getCaseDocuments(String caseId) async {
    try {
      return await dio.get('/documents/case/$caseId');
    } catch (e) {
      print('Erro ao buscar documentos: $e');
      rethrow;
    }
  }

  /// Download de documento
  static Future<Response> downloadDocument(String documentId) async {
    try {
      return await dio.get('/documents/$documentId/download');
    } catch (e) {
      print('Erro ao baixar documento: $e');
      rethrow;
    }
  }

  // ========== GESTÃO DE TEMPO (ADVOGADOS) ==========
  
  /// Registra tempo trabalhado
  static Future<Response> recordTimeEntry({
    required String caseId,
    required String description,
    required String startTime,
    required String endTime,
    required double billableHours,
    required double hourlyRate,
    required String category,
  }) async {
    try {
      return await dio.post('/cases/$caseId/time_entries', data: {
        'description': description,
        'start_time': startTime,
        'end_time': endTime,
        'billable_hours': billableHours,
        'hourly_rate': hourlyRate,
        'category': category,
      });
    } catch (e) {
      print('Erro ao registrar tempo: $e');
      rethrow;
    }
  }

  /// Lista entradas de tempo
  static Future<Response> getTimeEntries(String caseId) async {
    try {
      return await dio.get('/cases/$caseId/time_entries');
    } catch (e) {
      print('Erro ao buscar entradas de tempo: $e');
      rethrow;
    }
  }

  /// Ajusta honorários
  static Future<Response> adjustFees({
    required String caseId,
    required String feeType,
    double? percentage,
    double? fixedAmount,
    double? hourlyRate,
    List<Map<String, dynamic>>? adjustments,
  }) async {
    try {
      return await dio.patch('/cases/$caseId/fees', data: {
        'fee_type': feeType,
        if (percentage != null) 'percentage': percentage,
        if (fixedAmount != null) 'fixed_amount': fixedAmount,
        if (hourlyRate != null) 'hourly_rate': hourlyRate,
        if (adjustments != null) 'adjustments': adjustments,
      });
    } catch (e) {
      print('Erro ao ajustar honorários: $e');
      rethrow;
    }
  }

  // ========== PAGAMENTOS ==========
  
  /// Cria intenção de pagamento
  static Future<Response> createPaymentIntent({
    required double amount,
    required String currency,
    required String caseId,
  }) async {
    try {
      return await dio.post('/payments/create-intent', data: {
        'amount': amount,
        'currency': currency,
        'case_id': caseId,
      });
    } catch (e) {
      print('Erro ao criar intenção de pagamento: $e');
      rethrow;
    }
  }

  /// Cria pagamento PIX
  static Future<Response> createPixPayment({
    required double amount,
    required String caseId,
  }) async {
    try {
      return await dio.post('/payments/pix', data: {
        'amount': amount,
        'case_id': caseId,
      });
    } catch (e) {
      print('Erro ao criar pagamento PIX: $e');
      rethrow;
    }
  }

  // ========== AVALIAÇÕES ==========
  
  /// Cria avaliação
  static Future<Response> createRating({
    required String lawyerId,
    required int rating,
    required String comment,
    required String caseId,
  }) async {
    try {
      return await dio.post('/ratings', data: {
        'lawyer_id': lawyerId,
        'rating': rating,
        'comment': comment,
        'case_id': caseId,
      });
    } catch (e) {
      print('Erro ao criar avaliação: $e');
      rethrow;
    }
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Adicionar token de autenticação automaticamente
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final accessToken = session?.accessToken;
      
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      } else {
        // Para testes, adicionar um token mockado quando não há autenticação
        print('⚠️  Sem token de autenticação - usando modo teste');
        options.headers['X-Test-Mode'] = 'true';
      }
    } catch (e) {
      print('⚠️  Erro ao obter token: $e - usando modo teste');
      options.headers['X-Test-Mode'] = 'true';
    }
    
    print('DEBUG: Request ${options.method} ${options.uri}');
    print('DEBUG: Headers: ${options.headers}');
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('DEBUG: Response ${response.statusCode} from ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('DEBUG: Error ${err.response?.statusCode} from ${err.requestOptions.uri}');
    print('DEBUG: Error message: ${err.message}');
    
    // Tratar erros de autenticação de forma mais flexível
    if (err.response?.statusCode == 401) {
      print('DEBUG: Token inválido ou expirado - mas continuando...');
    }
    
    // Tratar erros de conectividade específicos para Flutter Web
    if (err.type == DioExceptionType.connectionError) {
      print('⚠️  AVISO: Backend não está acessível em localhost:8080');
      print('💡 O app vai usar dados mock para demonstração');
      print('🔧 Para conectar ao backend real, certifique-se que ele está rodando');
    }
    
    handler.next(err);
  }
} 
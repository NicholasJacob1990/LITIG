import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

class DioService {
  static Dio? _dio;

  static Dio get dio {
    if (_dio == null) {
      _dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:8000/api',
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
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;
    
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
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
    
    // Tratar erros de autenticação
    if (err.response?.statusCode == 401) {
      // Token expirado ou inválido
      print('DEBUG: Token inválido ou expirado');
      // Aqui poderia implementar refresh token ou logout automático
    }
    
    // Tratar erros de conectividade específicos para Flutter Web
    if (err.type == DioExceptionType.connectionError) {
      print('⚠️  AVISO: Backend não está acessível em localhost:8000');
      print('💡 O app vai usar dados mock para demonstração');
      print('🔧 Para conectar ao backend real, certifique-se que ele está rodando');
    }
    
    handler.next(err);
  }
} 
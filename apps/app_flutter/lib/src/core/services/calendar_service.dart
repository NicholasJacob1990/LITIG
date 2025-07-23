import 'package:meu_app/src/core/services/dio_service.dart';
import 'package:meu_app/src/features/calendar/domain/entities/calendar_event.dart';

class CalendarService {
  static const String _baseUrl = '/api/v1/calendar';

  /// Busca eventos de um determinado período.
  Future<List<CalendarEvent>> getEvents({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await DioService.dio.get(
        '$_baseUrl/events',
        queryParameters: {'start_date': startDate, 'end_date': endDate},
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> eventList = response.data['events'];
        return eventList.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        throw Exception('API error: ${response.data['detail']}');
      }
    } catch (e) {
      // Adicionar log ou tratamento de erro mais específico
      throw Exception('Erro ao buscar eventos do calendário: $e');
    }
  }

  /// Cria um novo evento genérico no calendário.
  Future<CalendarEvent> createEvent({
    required String title,
    required String startTime,
    required String endTime,
    List<Map<String, String>>? participants,
    String? description,
    String? location,
  }) async {
    try {
       final response = await DioService.dio.post(
        '$_baseUrl/events',
        data: {
          'title': title,
          'start_time': startTime,
          'end_time': endTime,
          'participants': participants,
          'description': description,
          'location': location,
        },
      );
      
      if (response.data['success'] == true) {
         return CalendarEvent.fromJson(response.data['event']);
      } else {
        throw Exception('API error: ${response.data['detail']}');
      }
    } catch (e) {
      throw Exception('Erro ao criar evento: $e');
    }
  }

  /// Cria um novo evento jurídico (audiência, consulta, prazo).
  Future<CalendarEvent> createLegalEvent({
    required String title,
    required String startTime,
    required String endTime,
    required String caseId,
    required String caseType,
    required String eventCategory,
    List<Map<String, String>>? participants,
    String? description,
    String? location,
  }) async {
    try {
      final response = await DioService.dio.post(
        '$_baseUrl/legal-event',
        data: {
          'title': title,
          'start_time': startTime,
          'end_time': endTime,
          'case_id': caseId,
          'case_type': caseType,
          'event_category': eventCategory,
          'participants': participants,
          'description': description,
          'location': location,
        },
      );

      if (response.data['success'] == true) {
        return CalendarEvent.fromJson(response.data['event']);
      } else {
        throw Exception('API error: ${response.data['detail']}');
      }
    } catch (e) {
      throw Exception('Erro ao criar evento jurídico: $e');
    }
  }
} 
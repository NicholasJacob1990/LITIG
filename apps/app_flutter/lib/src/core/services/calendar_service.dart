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

  /// Obtém calendários disponíveis
  Future<List<Map<String, dynamic>>> getCalendars() async {
    try {
      final response = await DioService.dio.get('$_baseUrl/calendars');
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['calendars']);
      } else {
        throw Exception('API error: ${response.data['detail']}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar calendários: $e');
    }
  }

  /// Obtém eventos de calendário com parâmetros
  Future<List<CalendarEvent>> getCalendarEvents({
    String? calendarId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (calendarId != null) queryParams['calendar_id'] = calendarId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await DioService.dio.get(
        '$_baseUrl/events',
        queryParameters: queryParams,
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> eventList = response.data['events'];
        return eventList.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        throw Exception('API error: ${response.data['detail']}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar eventos do calendário: $e');
    }
  }

  /// Cria evento de calendário
  Future<CalendarEvent> createCalendarEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
    String? calendarId,
  }) async {
    try {
      final response = await DioService.dio.post(
        '$_baseUrl/events',
        data: {
          'title': title,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'description': description,
          'location': location,
          'calendar_id': calendarId,
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

  /// Atualiza evento de calendário
  Future<CalendarEvent> updateCalendarEvent({
    required String eventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    String? location,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (startTime != null) data['start_time'] = startTime.toIso8601String();
      if (endTime != null) data['end_time'] = endTime.toIso8601String();
      if (description != null) data['description'] = description;
      if (location != null) data['location'] = location;

      final response = await DioService.dio.put(
        '$_baseUrl/events/$eventId',
        data: data,
      );
      
      if (response.data['success'] == true) {
        return CalendarEvent.fromJson(response.data['event']);
      } else {
        throw Exception('API error: ${response.data['detail']}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar evento: $e');
    }
  }

  /// Deleta evento de calendário
  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      final response = await DioService.dio.delete('$_baseUrl/events/$eventId');
      
      if (response.data['success'] != true) {
        throw Exception('API error: ${response.data['detail']}');
      }
    } catch (e) {
      throw Exception('Erro ao deletar evento: $e');
    }
  }

  /// Sincroniza calendários
  Future<List<CalendarEvent>> syncCalendars() async {
    try {
      final response = await DioService.dio.post('$_baseUrl/sync');
      
      if (response.data['success'] == true) {
        final List<dynamic> eventList = response.data['events'];
        return eventList.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        throw Exception('API error: ${response.data['detail']}');
      }
    } catch (e) {
      throw Exception('Erro ao sincronizar calendários: $e');
    }
  }
} 
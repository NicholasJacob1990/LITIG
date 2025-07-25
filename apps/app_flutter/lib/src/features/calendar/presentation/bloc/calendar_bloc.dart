import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app/src/core/services/calendar_service.dart';
import 'package:meu_app/src/core/utils/logger.dart';
import 'package:meu_app/src/features/calendar/domain/entities/calendar_event.dart' as entities;

// ===== EVENTS =====

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

class LoadCalendarEvents extends CalendarEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool refresh;
  
  const LoadCalendarEvents({
    this.startDate,
    this.endDate,
    this.refresh = false,
  });
  
  @override
  List<Object?> get props => [startDate, endDate, refresh];
}

class CreateCalendarEvent extends CalendarEvent {
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> attendees;
  final String? location;
  
  const CreateCalendarEvent({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.attendees,
    this.location,
  });
  
  @override
  List<Object?> get props => [title, description, startTime, endTime, attendees, location];
}

class UpdateCalendarEvent extends CalendarEvent {
  final String eventId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> attendees;
  final String? location;
  
  const UpdateCalendarEvent({
    required this.eventId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.attendees,
    this.location,
  });
  
  @override
  List<Object?> get props => [eventId, title, description, startTime, endTime, attendees, location];
}

class DeleteCalendarEvent extends CalendarEvent {
  final String eventId;
  
  const DeleteCalendarEvent({required this.eventId});
  
  @override
  List<Object?> get props => [eventId];
}

class SyncCalendars extends CalendarEvent {
  const SyncCalendars();
}

// ===== STATES =====

abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<entities.CalendarEvent> events;
  final List<Map<String, dynamic>> calendars;
  final DateTime lastSync;
  
  const CalendarLoaded({
    required this.events,
    required this.calendars,
    required this.lastSync,
  });
  
  @override
  List<Object?> get props => [events, calendars, lastSync];
}

class CalendarError extends CalendarState {
  final String message;
  
  const CalendarError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class CalendarEventCreated extends CalendarState {
  final entities.CalendarEvent event;
  
  const CalendarEventCreated({required this.event});
  
  @override
  List<Object?> get props => [event];
}

class CalendarEventUpdated extends CalendarState {
  final entities.CalendarEvent event;
  
  const CalendarEventUpdated({required this.event});
  
  @override
  List<Object?> get props => [event];
}

class CalendarEventDeleted extends CalendarState {
  final String eventId;
  
  const CalendarEventDeleted({required this.eventId});
  
  @override
  List<Object?> get props => [eventId];
}

class CalendarSyncing extends CalendarState {}

class CalendarSynced extends CalendarState {
  final int syncedEvents;
  final DateTime syncTime;
  
  const CalendarSynced({
    required this.syncedEvents,
    required this.syncTime,
  });
  
  @override
  List<Object?> get props => [syncedEvents, syncTime];
}

// ===== BLOC =====

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarService _calendarService;
  
  CalendarBloc({CalendarService? calendarService})
      : _calendarService = calendarService ?? CalendarService(),
        super(CalendarInitial()) {
    
    on<LoadCalendarEvents>(_onLoadCalendarEvents);
    on<CreateCalendarEvent>(_onCreateCalendarEvent);
    on<UpdateCalendarEvent>(_onUpdateCalendarEvent);
    on<DeleteCalendarEvent>(_onDeleteCalendarEvent);
    on<SyncCalendars>(_onSyncCalendars);
  }

  Future<void> _onLoadCalendarEvents(
    LoadCalendarEvents event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      emit(CalendarLoading());
      
      AppLogger.info('Carregando eventos de calendário - ${event.startDate?.toIso8601String()} até ${event.endDate?.toIso8601String()}');

      // Buscar calendários disponíveis
      final calendars = await _calendarService.getCalendars();

      // Buscar eventos de todos os calendários
      final events = await _calendarService.getCalendarEvents(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      AppLogger.success('Eventos carregados com sucesso - ${events.length} eventos, ${calendars.length} calendários');

      emit(CalendarLoaded(
        events: events,
        calendars: calendars,
        lastSync: DateTime.now(),
      ));
    } catch (e) {
      AppLogger.error('Erro ao carregar eventos de calendário', error: e);
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onCreateCalendarEvent(
    CreateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      AppLogger.info('Criando evento de calendário: ${event.title}');

      final createdEvent = await _calendarService.createCalendarEvent(
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        location: event.location,
      );

      AppLogger.success('Evento criado com sucesso: ${createdEvent.id}');

      emit(CalendarEventCreated(event: createdEvent));
      
      // Recarregar eventos para mostrar o novo
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      AppLogger.error('Erro ao criar evento de calendário', error: e);
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCalendarEvent(
    UpdateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      AppLogger.info('Atualizando evento de calendário: ${event.eventId}');

      final updatedEvent = await _calendarService.updateCalendarEvent(
        eventId: event.eventId,
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        location: event.location,
      );

      AppLogger.success('Evento atualizado com sucesso');

      emit(CalendarEventUpdated(event: updatedEvent));
      
      // Recarregar eventos para mostrar a atualização
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      AppLogger.error('Erro ao atualizar evento de calendário', error: e);
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCalendarEvent(
    DeleteCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      AppLogger.info('Excluindo evento de calendário: ${event.eventId}');

      await _calendarService.deleteCalendarEvent(event.eventId);

      AppLogger.success('Evento excluído com sucesso');

      emit(CalendarEventDeleted(eventId: event.eventId));
      
      // Recarregar eventos para remover o excluído
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      AppLogger.error('Erro ao excluir evento de calendário', error: e);
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onSyncCalendars(
    SyncCalendars event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      emit(CalendarSyncing());
      
      AppLogger.info('Sincronizando calendários com Unipile V2');

      // Sincronizar todos os calendários conectados
      final syncedEvents = await _calendarService.syncCalendars();

      AppLogger.success('Sincronização concluída - $syncedEvents eventos sincronizados');

      emit(CalendarSynced(
        syncedEvents: syncedEvents.length,
        syncTime: DateTime.now(),
      ));
      
      // Recarregar eventos após sincronização
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      AppLogger.error('Erro na sincronização de calendários', error: e);
      emit(CalendarError(message: e.toString()));
    }
  }
} 
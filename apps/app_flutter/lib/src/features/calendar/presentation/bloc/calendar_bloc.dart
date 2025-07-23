import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app/src/core/services/unipile_service.dart';
import 'package:meu_app/src/core/utils/logger.dart';

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
  final List<Map<String, dynamic>> events;
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
  final Map<String, dynamic> event;
  
  const CalendarEventCreated({required this.event});
  
  @override
  List<Object?> get props => [event];
}

class CalendarEventUpdated extends CalendarState {
  final Map<String, dynamic> event;
  
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
  final UnipileService _unipileService;
  
  CalendarBloc({UnipileService? unipileService})
      : _unipileService = unipileService ?? UnipileService(),
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
      
      Logger.info('Carregando eventos de calendário', {
        'start_date': event.startDate?.toIso8601String(),
        'end_date': event.endDate?.toIso8601String(),
        'refresh': event.refresh,
      });

      // Buscar calendários disponíveis
      final calendarsResult = await _unipileService.getCalendars();
      if (calendarsResult['success'] != true) {
        throw Exception(calendarsResult['error'] ?? 'Falha ao carregar calendários');
      }

      final calendars = calendarsResult['data'] as List<dynamic>? ?? [];

      // Buscar eventos de todos os calendários
      final eventsResult = await _unipileService.getCalendarEvents(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      if (eventsResult['success'] != true) {
        throw Exception(eventsResult['error'] ?? 'Falha ao carregar eventos');
      }

      final events = eventsResult['data'] as List<dynamic>? ?? [];

      Logger.info('Eventos carregados com sucesso', {
        'events_count': events.length,
        'calendars_count': calendars.length,
      });

      emit(CalendarLoaded(
        events: events.cast<Map<String, dynamic>>(),
        calendars: calendars.cast<Map<String, dynamic>>(),
        lastSync: DateTime.now(),
      ));
    } catch (e) {
      Logger.error('Erro ao carregar eventos de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onCreateCalendarEvent(
    CreateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Criando evento de calendário', {
        'title': event.title,
        'start_time': event.startTime.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
      });

      final result = await _unipileService.createCalendarEvent(
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        attendees: event.attendees,
        location: event.location,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao criar evento');
      }

      final createdEvent = result['data'] as Map<String, dynamic>;

      Logger.info('Evento criado com sucesso', {
        'event_id': createdEvent['id'],
      });

      emit(CalendarEventCreated(event: createdEvent));
      
      // Recarregar eventos para mostrar o novo
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao criar evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCalendarEvent(
    UpdateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Atualizando evento de calendário', {
        'event_id': event.eventId,
        'title': event.title,
      });

      final result = await _unipileService.updateCalendarEvent(
        eventId: event.eventId,
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        attendees: event.attendees,
        location: event.location,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao atualizar evento');
      }

      final updatedEvent = result['data'] as Map<String, dynamic>;

      Logger.info('Evento atualizado com sucesso');

      emit(CalendarEventUpdated(event: updatedEvent));
      
      // Recarregar eventos para mostrar a atualização
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao atualizar evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCalendarEvent(
    DeleteCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Excluindo evento de calendário', {
        'event_id': event.eventId,
      });

      final result = await _unipileService.deleteCalendarEvent(event.eventId);

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao excluir evento');
      }

      Logger.info('Evento excluído com sucesso');

      emit(CalendarEventDeleted(eventId: event.eventId));
      
      // Recarregar eventos para remover o excluído
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao excluir evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onSyncCalendars(
    SyncCalendars event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      emit(CalendarSyncing());
      
      Logger.info('Sincronizando calendários com Unipile V2');

      // Sincronizar todos os calendários conectados
      final result = await _unipileService.syncCalendars();

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha na sincronização');
      }

      final syncData = result['data'] as Map<String, dynamic>? ?? {};
      final syncedEvents = syncData['synced_events'] as int? ?? 0;

      Logger.info('Sincronização concluída', {
        'synced_events': syncedEvents,
      });

      emit(CalendarSynced(
        syncedEvents: syncedEvents,
        syncTime: DateTime.now(),
      ));
      
      // Recarregar eventos após sincronização
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro na sincronização de calendários', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }
} 
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
  final List<Map<String, dynamic>> events;
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
  final Map<String, dynamic> event;
  
  const CalendarEventCreated({required this.event});
  
  @override
  List<Object?> get props => [event];
}

class CalendarEventUpdated extends CalendarState {
  final Map<String, dynamic> event;
  
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
  final UnipileService _unipileService;
  
  CalendarBloc({UnipileService? unipileService})
      : _unipileService = unipileService ?? UnipileService(),
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
      
      Logger.info('Carregando eventos de calendário', {
        'start_date': event.startDate?.toIso8601String(),
        'end_date': event.endDate?.toIso8601String(),
        'refresh': event.refresh,
      });

      // Buscar calendários disponíveis
      final calendarsResult = await _unipileService.getCalendars();
      if (calendarsResult['success'] != true) {
        throw Exception(calendarsResult['error'] ?? 'Falha ao carregar calendários');
      }

      final calendars = calendarsResult['data'] as List<dynamic>? ?? [];

      // Buscar eventos de todos os calendários
      final eventsResult = await _unipileService.getCalendarEvents(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      if (eventsResult['success'] != true) {
        throw Exception(eventsResult['error'] ?? 'Falha ao carregar eventos');
      }

      final events = eventsResult['data'] as List<dynamic>? ?? [];

      Logger.info('Eventos carregados com sucesso', {
        'events_count': events.length,
        'calendars_count': calendars.length,
      });

      emit(CalendarLoaded(
        events: events.cast<Map<String, dynamic>>(),
        calendars: calendars.cast<Map<String, dynamic>>(),
        lastSync: DateTime.now(),
      ));
    } catch (e) {
      Logger.error('Erro ao carregar eventos de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onCreateCalendarEvent(
    CreateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Criando evento de calendário', {
        'title': event.title,
        'start_time': event.startTime.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
      });

      final result = await _unipileService.createCalendarEvent(
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        attendees: event.attendees,
        location: event.location,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao criar evento');
      }

      final createdEvent = result['data'] as Map<String, dynamic>;

      Logger.info('Evento criado com sucesso', {
        'event_id': createdEvent['id'],
      });

      emit(CalendarEventCreated(event: createdEvent));
      
      // Recarregar eventos para mostrar o novo
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao criar evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCalendarEvent(
    UpdateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Atualizando evento de calendário', {
        'event_id': event.eventId,
        'title': event.title,
      });

      final result = await _unipileService.updateCalendarEvent(
        eventId: event.eventId,
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        attendees: event.attendees,
        location: event.location,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao atualizar evento');
      }

      final updatedEvent = result['data'] as Map<String, dynamic>;

      Logger.info('Evento atualizado com sucesso');

      emit(CalendarEventUpdated(event: updatedEvent));
      
      // Recarregar eventos para mostrar a atualização
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao atualizar evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCalendarEvent(
    DeleteCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Excluindo evento de calendário', {
        'event_id': event.eventId,
      });

      final result = await _unipileService.deleteCalendarEvent(event.eventId);

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao excluir evento');
      }

      Logger.info('Evento excluído com sucesso');

      emit(CalendarEventDeleted(eventId: event.eventId));
      
      // Recarregar eventos para remover o excluído
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao excluir evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onSyncCalendars(
    SyncCalendars event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      emit(CalendarSyncing());
      
      Logger.info('Sincronizando calendários com Unipile V2');

      // Sincronizar todos os calendários conectados
      final result = await _unipileService.syncCalendars();

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha na sincronização');
      }

      final syncData = result['data'] as Map<String, dynamic>? ?? {};
      final syncedEvents = syncData['synced_events'] as int? ?? 0;

      Logger.info('Sincronização concluída', {
        'synced_events': syncedEvents,
      });

      emit(CalendarSynced(
        syncedEvents: syncedEvents,
        syncTime: DateTime.now(),
      ));
      
      // Recarregar eventos após sincronização
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro na sincronização de calendários', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }
} 
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
  final List<Map<String, dynamic>> events;
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
  final Map<String, dynamic> event;
  
  const CalendarEventCreated({required this.event});
  
  @override
  List<Object?> get props => [event];
}

class CalendarEventUpdated extends CalendarState {
  final Map<String, dynamic> event;
  
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
  final UnipileService _unipileService;
  
  CalendarBloc({UnipileService? unipileService})
      : _unipileService = unipileService ?? UnipileService(),
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
      
      Logger.info('Carregando eventos de calendário', {
        'start_date': event.startDate?.toIso8601String(),
        'end_date': event.endDate?.toIso8601String(),
        'refresh': event.refresh,
      });

      // Buscar calendários disponíveis
      final calendarsResult = await _unipileService.getCalendars();
      if (calendarsResult['success'] != true) {
        throw Exception(calendarsResult['error'] ?? 'Falha ao carregar calendários');
      }

      final calendars = calendarsResult['data'] as List<dynamic>? ?? [];

      // Buscar eventos de todos os calendários
      final eventsResult = await _unipileService.getCalendarEvents(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      if (eventsResult['success'] != true) {
        throw Exception(eventsResult['error'] ?? 'Falha ao carregar eventos');
      }

      final events = eventsResult['data'] as List<dynamic>? ?? [];

      Logger.info('Eventos carregados com sucesso', {
        'events_count': events.length,
        'calendars_count': calendars.length,
      });

      emit(CalendarLoaded(
        events: events.cast<Map<String, dynamic>>(),
        calendars: calendars.cast<Map<String, dynamic>>(),
        lastSync: DateTime.now(),
      ));
    } catch (e) {
      Logger.error('Erro ao carregar eventos de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onCreateCalendarEvent(
    CreateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Criando evento de calendário', {
        'title': event.title,
        'start_time': event.startTime.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
      });

      final result = await _unipileService.createCalendarEvent(
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        attendees: event.attendees,
        location: event.location,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao criar evento');
      }

      final createdEvent = result['data'] as Map<String, dynamic>;

      Logger.info('Evento criado com sucesso', {
        'event_id': createdEvent['id'],
      });

      emit(CalendarEventCreated(event: createdEvent));
      
      // Recarregar eventos para mostrar o novo
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao criar evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCalendarEvent(
    UpdateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Atualizando evento de calendário', {
        'event_id': event.eventId,
        'title': event.title,
      });

      final result = await _unipileService.updateCalendarEvent(
        eventId: event.eventId,
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        attendees: event.attendees,
        location: event.location,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao atualizar evento');
      }

      final updatedEvent = result['data'] as Map<String, dynamic>;

      Logger.info('Evento atualizado com sucesso');

      emit(CalendarEventUpdated(event: updatedEvent));
      
      // Recarregar eventos para mostrar a atualização
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao atualizar evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCalendarEvent(
    DeleteCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Excluindo evento de calendário', {
        'event_id': event.eventId,
      });

      final result = await _unipileService.deleteCalendarEvent(event.eventId);

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao excluir evento');
      }

      Logger.info('Evento excluído com sucesso');

      emit(CalendarEventDeleted(eventId: event.eventId));
      
      // Recarregar eventos para remover o excluído
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao excluir evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onSyncCalendars(
    SyncCalendars event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      emit(CalendarSyncing());
      
      Logger.info('Sincronizando calendários com Unipile V2');

      // Sincronizar todos os calendários conectados
      final result = await _unipileService.syncCalendars();

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha na sincronização');
      }

      final syncData = result['data'] as Map<String, dynamic>? ?? {};
      final syncedEvents = syncData['synced_events'] as int? ?? 0;

      Logger.info('Sincronização concluída', {
        'synced_events': syncedEvents,
      });

      emit(CalendarSynced(
        syncedEvents: syncedEvents,
        syncTime: DateTime.now(),
      ));
      
      // Recarregar eventos após sincronização
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro na sincronização de calendários', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }
} 
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
  final List<Map<String, dynamic>> events;
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
  final Map<String, dynamic> event;
  
  const CalendarEventCreated({required this.event});
  
  @override
  List<Object?> get props => [event];
}

class CalendarEventUpdated extends CalendarState {
  final Map<String, dynamic> event;
  
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
  final UnipileService _unipileService;
  
  CalendarBloc({UnipileService? unipileService})
      : _unipileService = unipileService ?? UnipileService(),
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
      
      Logger.info('Carregando eventos de calendário', {
        'start_date': event.startDate?.toIso8601String(),
        'end_date': event.endDate?.toIso8601String(),
        'refresh': event.refresh,
      });

      // Buscar calendários disponíveis
      final calendarsResult = await _unipileService.getCalendars();
      if (calendarsResult['success'] != true) {
        throw Exception(calendarsResult['error'] ?? 'Falha ao carregar calendários');
      }

      final calendars = calendarsResult['data'] as List<dynamic>? ?? [];

      // Buscar eventos de todos os calendários
      final eventsResult = await _unipileService.getCalendarEvents(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      if (eventsResult['success'] != true) {
        throw Exception(eventsResult['error'] ?? 'Falha ao carregar eventos');
      }

      final events = eventsResult['data'] as List<dynamic>? ?? [];

      Logger.info('Eventos carregados com sucesso', {
        'events_count': events.length,
        'calendars_count': calendars.length,
      });

      emit(CalendarLoaded(
        events: events.cast<Map<String, dynamic>>(),
        calendars: calendars.cast<Map<String, dynamic>>(),
        lastSync: DateTime.now(),
      ));
    } catch (e) {
      Logger.error('Erro ao carregar eventos de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onCreateCalendarEvent(
    CreateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Criando evento de calendário', {
        'title': event.title,
        'start_time': event.startTime.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
      });

      final result = await _unipileService.createCalendarEvent(
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        attendees: event.attendees,
        location: event.location,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao criar evento');
      }

      final createdEvent = result['data'] as Map<String, dynamic>;

      Logger.info('Evento criado com sucesso', {
        'event_id': createdEvent['id'],
      });

      emit(CalendarEventCreated(event: createdEvent));
      
      // Recarregar eventos para mostrar o novo
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao criar evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCalendarEvent(
    UpdateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Atualizando evento de calendário', {
        'event_id': event.eventId,
        'title': event.title,
      });

      final result = await _unipileService.updateCalendarEvent(
        eventId: event.eventId,
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        attendees: event.attendees,
        location: event.location,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao atualizar evento');
      }

      final updatedEvent = result['data'] as Map<String, dynamic>;

      Logger.info('Evento atualizado com sucesso');

      emit(CalendarEventUpdated(event: updatedEvent));
      
      // Recarregar eventos para mostrar a atualização
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao atualizar evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCalendarEvent(
    DeleteCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      Logger.info('Excluindo evento de calendário', {
        'event_id': event.eventId,
      });

      final result = await _unipileService.deleteCalendarEvent(event.eventId);

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha ao excluir evento');
      }

      Logger.info('Evento excluído com sucesso');

      emit(CalendarEventDeleted(eventId: event.eventId));
      
      // Recarregar eventos para remover o excluído
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro ao excluir evento de calendário', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }

  Future<void> _onSyncCalendars(
    SyncCalendars event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      emit(CalendarSyncing());
      
      Logger.info('Sincronizando calendários com Unipile V2');

      // Sincronizar todos os calendários conectados
      final result = await _unipileService.syncCalendars();

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Falha na sincronização');
      }

      final syncData = result['data'] as Map<String, dynamic>? ?? {};
      final syncedEvents = syncData['synced_events'] as int? ?? 0;

      Logger.info('Sincronização concluída', {
        'synced_events': syncedEvents,
      });

      emit(CalendarSynced(
        syncedEvents: syncedEvents,
        syncTime: DateTime.now(),
      ));
      
      // Recarregar eventos após sincronização
      add(const LoadCalendarEvents(refresh: true));
    } catch (e) {
      Logger.error('Erro na sincronização de calendários', {
        'error': e.toString(),
      });
      emit(CalendarError(message: e.toString()));
    }
  }
} 
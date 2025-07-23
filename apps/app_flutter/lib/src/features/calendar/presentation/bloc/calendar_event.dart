import 'package:equatable/equatable.dart';

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
  final String? location;
  final String? accountId;
  
  const CreateCalendarEvent({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.accountId,
  });
  
  @override
  List<Object?> get props => [title, description, startTime, endTime, location, accountId];
}

class UpdateCalendarEvent extends CalendarEvent {
  final String eventId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  
  const UpdateCalendarEvent({
    required this.eventId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
  });
  
  @override
  List<Object?> get props => [eventId, title, description, startTime, endTime, location];
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
part of 'calendar_bloc.dart';

abstract class CalendarBlocEvent extends Equatable {
  const CalendarBlocEvent();

  @override
  List<Object> get props => [];
}

/// Evento para carregar os eventos do calendário para um determinado período.
class LoadCalendarEvents extends CalendarBlocEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadCalendarEvents({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}

/// Evento para criar um novo evento no calendário.
class CreateCalendarEvent extends CalendarBlocEvent {
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final String? location;
  final List<Map<String, String>>? participants;

  const CreateCalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
    this.participants,
  });

  @override
  List<Object> get props => [title, startTime, endTime];
} 
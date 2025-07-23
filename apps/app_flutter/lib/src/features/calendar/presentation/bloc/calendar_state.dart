part of 'calendar_bloc.dart';

abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object> get props => [];
}

/// Estado inicial, nada aconteceu ainda.
class CalendarInitial extends CalendarState {}

/// Estado de carregamento, indica que os eventos estão sendo buscados.
class CalendarLoading extends CalendarState {}

/// Estado de sucesso, os eventos foram carregados.
class CalendarLoaded extends CalendarState {
  final List<CalendarEvent> events;

  const CalendarLoaded({required this.events});

  @override
  List<Object> get props => [events];
}

/// Estado de erro, indica que ocorreu um problema.
class CalendarError extends CalendarState {
  final String message;

  const CalendarError({required this.message});

  @override
  List<Object> get props => [message];
} 
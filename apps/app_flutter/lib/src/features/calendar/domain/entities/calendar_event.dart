import 'package:equatable/equatable.dart';

class CalendarEvent extends Equatable {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final String? location;
  final List<CalendarEventParticipant> participants;
  final bool isAllDay;
  final String provider; // 'google', 'outlook', etc.

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
    this.participants = const [],
    required this.isAllDay,
    required this.provider,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'] ?? 'Evento sem título',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      description: json['description'],
      location: json['location'],
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => CalendarEventParticipant.fromJson(p))
              .toList() ??
          [],
      isAllDay: json['is_all_day'] ?? false,
      provider: json['provider'] ?? 'unknown',
    );
  }

  @override
  List<Object?> get props => [id, title, startTime, endTime, provider];
}

class CalendarEventParticipant extends Equatable {
  final String email;
  final String? name;
  final String status; // 'accepted', 'declined', 'needsAction'

  const CalendarEventParticipant({
    required this.email,
    this.name,
    required this.status,
  });

  factory CalendarEventParticipant.fromJson(Map<String, dynamic> json) {
    return CalendarEventParticipant(
      email: json['email'],
      name: json['name'],
      status: json['status'] ?? 'needsAction',
    );
  }

  @override
  List<Object?> get props => [email];
} 
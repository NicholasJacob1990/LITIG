class BusinessHours {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final List<int> workingDays; // 1-7 (Monday-Sunday)
  final List<DateTime> holidays;
  final String timezone;

  const BusinessHours({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.workingDays,
    required this.holidays,
    required this.timezone,
  });

  // Default business hours: 9:00 AM to 6:00 PM, Monday to Friday, Brazil timezone
  static BusinessHours defaultBusiness() {
    return const BusinessHours(
      startHour: 9,
      startMinute: 0,
      endHour: 18,
      endMinute: 0,
      workingDays: [1, 2, 3, 4, 5], // Monday to Friday
      holidays: [],
      timezone: 'America/Sao_Paulo',
    );
  }

  // Extended business hours: 8:00 AM to 8:00 PM, Monday to Saturday
  static BusinessHours extended() {
    return const BusinessHours(
      startHour: 8,
      startMinute: 0,
      endHour: 20,
      endMinute: 0,
      workingDays: [1, 2, 3, 4, 5, 6], // Monday to Saturday
      holidays: [],
      timezone: 'America/Sao_Paulo',
    );
  }

  // 24/7 availability
  static BusinessHours fullTime() {
    return const BusinessHours(
      startHour: 0,
      startMinute: 0,
      endHour: 23,
      endMinute: 59,
      workingDays: [1, 2, 3, 4, 5, 6, 7], // All days
      holidays: [],
      timezone: 'America/Sao_Paulo',
    );
  }

  // Check if a given DateTime falls within business hours
  bool isWithinBusinessHours(DateTime dateTime) {
    // Check if it's a working day
    if (!workingDays.contains(dateTime.weekday)) {
      return false;
    }

    // Check if it's a holiday
    for (final holiday in holidays) {
      if (dateTime.year == holiday.year &&
          dateTime.month == holiday.month &&
          dateTime.day == holiday.day) {
        return false;
      }
    }

    // Check if it's within working hours
    final timeOfDay = dateTime.hour * 60 + dateTime.minute;
    final startTime = startHour * 60 + startMinute;
    final endTime = endHour * 60 + endMinute;

    return timeOfDay >= startTime && timeOfDay <= endTime;
  }

  // Calculate business hours between two dates
  Duration calculateBusinessHoursBetween(DateTime start, DateTime end) {
    if (start.isAfter(end)) {
      return Duration.zero;
    }

    Duration totalBusinessTime = Duration.zero;
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDate)) {
      if (isWithinBusinessHours(current)) {
        // Calculate business hours for this day
        final startOfBusinessDay = DateTime(
          current.year,
          current.month,
          current.day,
          startHour,
          startMinute,
        );
        final endOfBusinessDay = DateTime(
          current.year,
          current.month,
          current.day,
          endHour,
          endMinute,
        );

        DateTime dayStart = current.isBefore(startOfBusinessDay) 
            ? startOfBusinessDay 
            : current;
        DateTime dayEnd = current.isAtSameMomentAs(endDate) && end.isBefore(endOfBusinessDay) 
            ? end 
            : endOfBusinessDay;

        if (dayStart.isBefore(dayEnd)) {
          totalBusinessTime += dayEnd.difference(dayStart);
        }
      }
      current = current.add(const Duration(days: 1));
    }

    return totalBusinessTime;
  }

  // Add business hours to a given date
  DateTime addBusinessHours(DateTime startDate, int hoursToAdd) {
    if (hoursToAdd <= 0) return startDate;

    DateTime current = startDate;
    int remainingHours = hoursToAdd;

    while (remainingHours > 0) {
      if (isWithinBusinessHours(current)) {
        // Calculate how many business hours are left in this day
        final endOfBusinessDay = DateTime(
          current.year,
          current.month,
          current.day,
          endHour,
          endMinute,
        );

        final hoursLeftInDay = endOfBusinessDay.difference(current).inHours;
        
        if (remainingHours <= hoursLeftInDay) {
          // We can finish within this business day
          return current.add(Duration(hours: remainingHours));
        } else {
          // Move to start of next business day
          remainingHours -= hoursLeftInDay;
          current = _getNextBusinessDay(current);
        }
      } else {
        // Move to start of next business day
        current = _getNextBusinessDay(current);
      }
    }

    return current;
  }

  DateTime _getNextBusinessDay(DateTime date) {
    DateTime nextDay = DateTime(date.year, date.month, date.day + 1, startHour, startMinute);
    
    while (!isWithinBusinessHours(nextDay)) {
      nextDay = nextDay.add(const Duration(days: 1));
      nextDay = DateTime(nextDay.year, nextDay.month, nextDay.day, startHour, startMinute);
    }
    
    return nextDay;
  }

  // Get formatted time string
  String get startTimeString => '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  String get endTimeString => '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  // Copy with method
  BusinessHours copyWith({
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<int>? workingDays,
    List<DateTime>? holidays,
    String? timezone,
  }) {
    return BusinessHours(
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      workingDays: workingDays ?? this.workingDays,
      holidays: holidays ?? this.holidays,
      timezone: timezone ?? this.timezone,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'workingDays': workingDays,
      'holidays': holidays.map((h) => h.toIso8601String()).toList(),
      'timezone': timezone,
    };
  }

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
      workingDays: List<int>.from(json['workingDays']),
      holidays: (json['holidays'] as List)
          .map((h) => DateTime.parse(h as String))
          .toList(),
      timezone: json['timezone'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessHours &&
        other.startHour == startHour &&
        other.startMinute == startMinute &&
        other.endHour == endHour &&
        other.endMinute == endMinute &&
        _listEquals(other.workingDays, workingDays) &&
        _listEquals(other.holidays, holidays) &&
        other.timezone == timezone;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      startHour,
      startMinute,
      endHour,
      endMinute,
      Object.hashAll(workingDays),
      Object.hashAll(holidays),
      timezone,
    );
  }

  @override
  String toString() {
    return 'BusinessHours($startTimeString-$endTimeString, Days: $workingDays, Timezone: $timezone)';
  }
} 
 
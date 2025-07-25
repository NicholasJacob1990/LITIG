import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:meu_app/src/features/calendar/domain/entities/calendar_event.dart' as entities;
import 'package:meu_app/src/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:meu_app/injection_container.dart'; // Para getIt

class UnifiedCalendarScreen extends StatelessWidget {
  const UnifiedCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CalendarBloc>()
        ..add(LoadCalendarEvents(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 30)),
        )),
      child: const UnifiedCalendarView(),
    );
  }
}

class UnifiedCalendarView extends StatefulWidget {
  const UnifiedCalendarView({super.key});

  @override
  State<UnifiedCalendarView> createState() => _UnifiedCalendarViewState();
}

class _UnifiedCalendarViewState extends State<UnifiedCalendarView> {
  late final ValueNotifier<List<entities.CalendarEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<entities.CalendarEvent> _getEventsForDay(DateTime day) {
    final state = context.read<CalendarBloc>().state;
    if (state is CalendarLoaded) {
      return state.events.where((event) {
        return isSameDay(event.startTime, day);
      }).toList();
    }
    return [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário Unificado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implementar diálogo para adicionar evento
            },
          ),
        ],
      ),
      body: BlocConsumer<CalendarBloc, CalendarState>(
        listener: (context, state) {
          if (state is CalendarLoaded) {
            _selectedEvents.value = _getEventsForDay(_selectedDay!);
          }
        },
        builder: (context, state) {
          if (state is CalendarLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CalendarError) {
            return Center(child: Text('Erro: ${state.message}'));
          }
          if (state is CalendarLoaded) {
            return Column(
              children: [
                TableCalendar<entities.CalendarEvent>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    context.read<CalendarBloc>().add(LoadCalendarEvents(
                        startDate: focusedDay.subtract(const Duration(days: 30)),
                        endDate: focusedDay.add(const Duration(days: 30)),
                      ));
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: ValueListenableBuilder<List<entities.CalendarEvent>>(
                    valueListenable: _selectedEvents,
                    builder: (context, value, _) {
                      return ListView.builder(
                        itemCount: value.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: ListTile(
                              onTap: () => print('${value[index]}'),
                              title: Text(value[index].title),
                              subtitle: Text(
                                '${DateFormat.jm().format(value[index].startTime)} - ${DateFormat.jm().format(value[index].endTime)}',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('Iniciando Calendário...'));
        },
      ),
    );
  }
} 
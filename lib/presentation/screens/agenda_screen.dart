import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/event_provider.dart';
import '../../domain/entities/event.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  late DateTime _selectedDate;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _pageController = PageController(initialPage: 1000);
  }

  List<DateTime> _getWeek(int weekOffset) {
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final targetMonday = currentMonday.add(Duration(days: weekOffset * 7));
    return List.generate(7, (index) {
      final d = targetMonday.add(Duration(days: index));
      return DateTime(d.year, d.month, d.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Agenda & Events', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E1E8B),
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Column(
        children: [
          // Horizontal Date Picker (Swipable Weeks)
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, pageIndex) {
                final weekOffset = pageIndex - 1000;
                final weekDays = _getWeek(weekOffset);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDays.map((date) {
                      final isSelected = date == _selectedDate;
                      final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: Container(
                          width: 45, // Smaller width to fit 7 perfectly across the screen
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? Colors.white70 : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          // Events List
          Expanded(
            child: eventsAsync.when(
              data: (allEvents) {
                final events = allEvents.where((e) {
                  return e.eventDate.year == _selectedDate.year &&
                         e.eventDate.month == _selectedDate.month &&
                         e.eventDate.day == _selectedDate.day;
                }).toList();

                if (events.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No events scheduled for this day.\nRemember: Q1 events will auto-suspend conflicting habits.', 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        onTap: () => _showEventModal(context, ref, event),
                        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${event.startTime} - ${event.endTime}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: event.quadrant == Quadrant.q1 ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.quadrant.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              color: event.quadrant == Quadrant.q1 ? Colors.red : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        shape: const StadiumBorder(),
        onPressed: () {
          _showEventModal(context, ref);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showEventModal(BuildContext context, WidgetRef ref, [Event? existingEvent]) {
    final isUpdate = existingEvent != null;
    final titleController = TextEditingController(text: existingEvent?.title ?? '');
    DateTime selectedDate = existingEvent?.eventDate ?? DateTime.now();
    
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    if (existingEvent != null) {
      final startParts = existingEvent.startTime.split(':');
      if (startParts.length == 2) startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
    }
    
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    if (existingEvent != null) {
      final endParts = existingEvent.endTime.split(':');
      if (endParts.length == 2) endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
    }
    
    Quadrant selectedQuadrant = existingEvent?.quadrant ?? Quadrant.q1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24, left: 24, right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isUpdate ? 'Update Event' : 'Create New Event', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E1E8B))),
                      if (isUpdate)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Event?'),
                                content: const Text('Are you sure you want to delete this event?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref.read(eventsProvider.notifier).deleteEvent(existingEvent.id);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Event Title',
                      filled: true,
                      fillColor: const Color(0xFFF5F7FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Date'),
                    trailing: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => selectedDate = date);
                    },
                  ),
                  ListTile(
                    title: const Text('Start Time'),
                    trailing: Text(startTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: startTime);
                      if (time != null) setState(() => startTime = time);
                    },
                  ),
                  ListTile(
                    title: const Text('End Time'),
                    trailing: Text(endTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: endTime);
                      if (time != null) setState(() => endTime = time);
                    },
                  ),
                  ListTile(
                    title: const Text('Quadrant'),
                    trailing: DropdownButton<Quadrant>(
                      value: selectedQuadrant,
                      items: Quadrant.values.map((q) {
                        return DropdownMenuItem(value: q, child: Text(q.toString().split('.').last.toUpperCase()));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedQuadrant = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E1E8B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          final event = existingEvent ?? Event();
                          event.title = titleController.text;
                          event.eventDate = selectedDate;
                          event.startTime = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
                          event.endTime = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
                          event.quadrant = selectedQuadrant;
                          
                          if (!isUpdate) {
                            event.status = EventStatus.upcoming;
                          }
                          
                          ref.read(eventsProvider.notifier).addEvent(event);
                          Navigator.pop(context);
                        }
                      },
                      child: Text(isUpdate ? 'Update Event' : 'Save Event', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }
}

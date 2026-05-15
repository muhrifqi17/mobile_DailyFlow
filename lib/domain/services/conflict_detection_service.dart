import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../infrastructure/services/isar_service.dart';
import '../entities/event.dart';
import '../entities/habit.dart';
import '../entities/habit_log.dart';
import '../../application/providers/habit_provider.dart';

final conflictDetectionServiceProvider = Provider<ConflictDetectionService>((ref) {
  return ConflictDetectionService(ref.read(isarServiceProvider));
});

class ConflictDetectionService {
  final IsarService _isarService;

  ConflictDetectionService(this._isarService);

  /// Checks if a Q1 Event overlaps with any active habits.
  /// If an overlap occurs, the habit is suspended for that day.
  Future<void> detectAndSuspendConflicts(Event event) async {
    if (event.quadrant != Quadrant.q1) return; // Only Q1 events trigger suspension

    final isar = await _isarService.db;
    
    // Get all active habits
    final activeHabits = await isar.habits.filter().isActiveEqualTo(true).findAll();
    
    // Parse event times
    final eventStartParts = event.startTime.split(':');
    final eventEndParts = event.endTime.split(':');
    
    if (eventStartParts.length != 2 || eventEndParts.length != 2) return;
    
    final eventStartMinutes = int.parse(eventStartParts[0]) * 60 + int.parse(eventStartParts[1]);
    final eventEndMinutes = int.parse(eventEndParts[0]) * 60 + int.parse(eventEndParts[1]);

    await isar.writeTxn(() async {
      for (final habit in activeHabits) {
        final habitTimeParts = habit.targetTime.split(':');
        if (habitTimeParts.length != 2) continue;
        
        final habitMinutes = int.parse(habitTimeParts[0]) * 60 + int.parse(habitTimeParts[1]);
        
        // If habit time falls within the event duration, it's a conflict
        if (habitMinutes >= eventStartMinutes && habitMinutes <= eventEndMinutes) {
          // Suspend the habit for the day of the event
          final targetDateStart = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
          final targetDateEnd = targetDateStart.add(const Duration(days: 1));
          
          final existingLog = await isar.habitLogs.filter()
            .habit((q) => q.idEqualTo(habit.id))
            .targetDateBetween(targetDateStart, targetDateEnd)
            .findFirst();
            
          if (existingLog != null) {
            existingLog.status = LogStatus.suspended;
            await isar.habitLogs.put(existingLog);
          } else {
            final newLog = HabitLog()
              ..targetDate = targetDateStart
              ..status = LogStatus.suspended;
            
            await isar.habitLogs.put(newLog);
            newLog.habit.value = habit;
            await newLog.habit.save();
          }
        }
      }
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../../infrastructure/services/isar_service.dart';
import '../../infrastructure/services/notification_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

final notificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

final habitsProvider = StateNotifierProvider<HabitNotifier, AsyncValue<List<Habit>>>((ref) {
  return HabitNotifier(ref.read(isarServiceProvider), ref.read(notificationServiceProvider));
});

class HabitNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final IsarService _isarService;
  final LocalNotificationService _notificationService;

  HabitNotifier(this._isarService, this._notificationService) : super(const AsyncValue.loading()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    try {
      final isar = await _isarService.db;
      final habits = await isar.habits.where().findAll();
      state = AsyncValue.data(habits);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addHabit(Habit habit) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.habits.put(habit);
    });
      
    // Schedule Notification
    try {
      final timeParts = habit.targetTime.split(':');
      if (timeParts.length == 2) {
        final now = DateTime.now();
        var targetTime = DateTime(now.year, now.month, now.day, int.parse(timeParts[0]), int.parse(timeParts[1]));
        
        // If time has already passed today, schedule for tomorrow
        if (targetTime.isBefore(now)) {
          targetTime = targetTime.add(const Duration(days: 1));
        }
        await _notificationService.scheduleTwoStageNotification(
          id: habit.id,
          title: habit.title,
          scheduledTime: targetTime,
        );
      }
    } catch (e) {
      // Ignore notification errors so it doesn't break the UI auto-render
      print("Failed to schedule notification: $e");
    }
    // FIRE IMMEDIATE TEST NOTIFICATION
    try {
      await _notificationService.showImmediateTestNotification();
    } catch (e) {
      print("Immediate test failed: $e");
    }

    await loadHabits();
  }

  Future<void> deleteHabit(int id) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.habits.delete(id);
      await isar.habitLogs.filter().habit((q) => q.idEqualTo(id)).deleteAll();
    });
    await loadHabits();
  }

  Future<void> markHabitDone(Habit habit) async {
    final isar = await _isarService.db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await isar.writeTxn(() async {
      // Check if already logged today
      final existingLog = await isar.habitLogs.filter()
          .habit((q) => q.idEqualTo(habit.id))
          .targetDateEqualTo(today)
          .findFirst();

      if (existingLog == null) {
        final newLog = HabitLog()
          ..targetDate = today
          ..status = LogStatus.done
          ..completedAt = now;

        await isar.habitLogs.put(newLog);
        newLog.habit.value = habit;
        await newLog.habit.save();

        // Increment streak
        habit.currentStreak += 1;
        if (habit.currentStreak > habit.longestStreak) {
          habit.longestStreak = habit.currentStreak;
        }
        await isar.habits.put(habit);
      }
    });
    await loadHabits();
  }

  Future<LogStatus?> getHabitStatusToday(Habit habit) async {
    final isar = await _isarService.db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final existingLog = await isar.habitLogs.filter()
        .habit((q) => q.idEqualTo(habit.id))
        .targetDateEqualTo(today)
        .findFirst();
        
    return existingLog?.status;
  }
}

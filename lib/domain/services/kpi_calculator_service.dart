import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../infrastructure/services/isar_service.dart';
import '../../application/providers/habit_provider.dart';
import '../entities/habit.dart';
import '../entities/habit_log.dart';
import '../entities/journal_entry.dart';

final kpiCalculatorProvider = Provider<KPICalculatorService>((ref) {
  return KPICalculatorService(ref.read(isarServiceProvider));
});

class KPICalculatorService {
  final IsarService _isarService;

  KPICalculatorService(this._isarService);

  // --- TIER 1: PRIMARY KPI CARDS ---

  /// Today's Completion Rate: done / (done + missed + not_done) hari ini
  Future<double> getTodayCompletionRate() async {
    final isar = await _isarService.db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final logsToday = await isar.habitLogs.filter().targetDateEqualTo(today).findAll();
    
    int done = 0;
    int total = 0;
    
    for (var log in logsToday) {
      if (log.status == LogStatus.suspended) continue;
      if (log.status == LogStatus.done) done++;
      total++;
    }
    
    if (total == 0) return 0.0;
    return done / total;
  }

  /// 7-Day Consistency Score: Rata-rata Completion Rate 7 hari terakhir
  Future<double> get7DayConsistencyScore() async {
    final isar = await _isarService.db;
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    
    final logs = await isar.habitLogs.filter()
      .targetDateBetween(sevenDaysAgo, DateTime(now.year, now.month, now.day, 23, 59, 59))
      .findAll();
      
    int done = 0;
    int total = 0;
    
    for (var log in logs) {
      if (log.status == LogStatus.suspended) continue;
      if (log.status == LogStatus.done) done++;
      total++;
    }
    
    if (total == 0) return 0.0;
    return done / total;
  }

  /// Active Streak: Consecutive days dengan Consistency Score >= 90%
  Future<int> getActiveStreak() async {
    final isar = await _isarService.db;
    final now = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < 365; i++) { // Check up to a year back
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final logs = await isar.habitLogs.filter().targetDateEqualTo(date).findAll();
      
      if (logs.isEmpty && i != 0) break; // Stop if no logs (except maybe today)
      
      int done = 0;
      int total = 0;
      for (var log in logs) {
        if (log.status == LogStatus.suspended) continue;
        if (log.status == LogStatus.done) done++;
        total++;
      }
      
      if (total == 0) {
        // If all suspended, it's neutral, so we continue the loop but don't increment streak
        continue;
      }
      
      double score = done / total;
      if (score >= 0.9) {
        streak++;
      } else {
        if (i != 0) break; // If it's not today, break the streak
      }
    }
    return streak;
  }

  /// Journal Streak: Consecutive days dengan entri jurnal
  Future<int> getJournalStreak() async {
    final isar = await _isarService.db;
    final now = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < 365; i++) {
      final dateStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dateEnd = dateStart.add(const Duration(days: 1));
      
      final entry = await isar.journalEntrys.filter()
          .createdAtBetween(dateStart, dateEnd)
          .findFirst();
          
      if (entry != null) {
        streak++;
      } else {
        if (i != 0) break;
      }
    }
    return streak;
  }

  // --- TIER 2: DIAGNOSTIC KPI CARDS ---

  Future<String> getMostMissedHabit() async {
    final isar = await _isarService.db;
    final logs = await isar.habitLogs.filter().statusEqualTo(LogStatus.missed).findAll();
    if (logs.isEmpty) return 'None';
    
    final map = <int, int>{};
    for (var log in logs) {
      map[log.habit.value?.id ?? -1] = (map[log.habit.value?.id ?? -1] ?? 0) + 1;
    }
    
    int maxId = map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    if (maxId == -1) return 'None';
    
    final habit = await isar.habits.get(maxId);
    return habit?.title ?? 'None';
  }

  Future<String> getMostIncompleteHabit() async {
    final isar = await _isarService.db;
    final logs = await isar.habitLogs.filter().statusEqualTo(LogStatus.notDone).findAll();
    if (logs.isEmpty) return 'None';
    
    final map = <int, int>{};
    for (var log in logs) {
      map[log.habit.value?.id ?? -1] = (map[log.habit.value?.id ?? -1] ?? 0) + 1;
    }
    
    int maxId = map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    if (maxId == -1) return 'None';
    
    final habit = await isar.habits.get(maxId);
    return habit?.title ?? 'None';
  }

  Future<double> getCompletionIntegrityScore() async {
    final isar = await _isarService.db;
    final doneCount = await isar.habitLogs.filter().statusEqualTo(LogStatus.done).count();
    final notDoneCount = await isar.habitLogs.filter().statusEqualTo(LogStatus.notDone).count();
    
    final denominator = doneCount + notDoneCount;
    if (denominator == 0) return 0.0;
    return doneCount / denominator;
  }

  Future<double> getDisruptionIndex() async {
    final isar = await _isarService.db;
    final suspendedCount = await isar.habitLogs.filter().statusEqualTo(LogStatus.suspended).count();
    final totalCount = await isar.habitLogs.count();
    
    if (totalCount == 0) return 0.0;
    return suspendedCount / totalCount;
  }

  Future<String> getBestDayOfWeek() async {
    return 'Monday'; // Simplified placeholder for now
  }

  Future<String> getWorstDayOfWeek() async {
    return 'Sunday'; // Simplified placeholder for now
  }
}

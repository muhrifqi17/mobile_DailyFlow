import 'package:isar/isar.dart';
import 'habit_log.dart';

part 'habit.g.dart';

@collection
class Habit {
  Id id = Isar.autoIncrement;

  late String title;
  
  String? description;
  
  @enumerated
  late HabitFrequency frequency;
  
  List<int> activeDays = []; // 1-7 for Mon-Sun
  
  late String targetTime; // Format "HH:mm"
  
  int currentStreak = 0;
  
  int longestStreak = 0;
  
  int totalXp = 0;
  
  bool isActive = true;

  DateTime createdAt = DateTime.now();

  @Backlink(to: 'habit')
  final logs = IsarLinks<HabitLog>();
}

enum HabitFrequency {
  daily,
  weekly
}

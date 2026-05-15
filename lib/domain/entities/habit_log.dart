import 'package:isar/isar.dart';
import 'habit.dart';

part 'habit_log.g.dart';

@collection
class HabitLog {
  Id id = Isar.autoIncrement;

  final habit = IsarLink<Habit>();

  late DateTime targetDate;
  
  @enumerated
  late LogStatus status;
  
  DateTime? completedAt;
}

enum LogStatus {
  pending,
  inProgress,
  done,
  notDone,
  missed,
  suspended
}

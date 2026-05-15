import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/journal_entry.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [
          UserSchema,
          HabitSchema,
          HabitLogSchema,
          EventSchema,
          JournalEntrySchema
        ],
        directory: dir.path,
      );
    }
    return Future.value(Isar.getInstance());
  }
}

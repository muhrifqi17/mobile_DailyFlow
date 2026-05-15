import 'package:isar/isar.dart';

part 'journal_entry.g.dart';

@collection
class JournalEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late DateTime entryDate; // 1 entry per day
  
  late String cipherText; // AES-256-GCM encrypted
  
  late String iv; // Initialization Vector
  
  late String mac; // Message Authentication Code
  
  @enumerated
  late JournalMood mood;
  
  int wordCount = 0;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

enum JournalMood {
  good,
  neutral,
  tough,
  none
}

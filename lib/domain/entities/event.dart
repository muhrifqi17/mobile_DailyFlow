import 'package:isar/isar.dart';

part 'event.g.dart';

@collection
class Event {
  Id id = Isar.autoIncrement;

  late String title;
  
  String? description;
  
  late DateTime eventDate;
  
  late String startTime; // "HH:mm"
  
  late String endTime; // "HH:mm"
  
  @enumerated
  late Quadrant quadrant;
  
  @enumerated
  late EventStatus status;

  DateTime createdAt = DateTime.now();
}

enum Quadrant {
  q1, // Urgent & Important
  q2, // Not Urgent & Important
  q3, // Urgent & Not Important
  q4  // Not Urgent & Not Important
}

enum EventStatus {
  upcoming,
  completed,
  notCompleted
}

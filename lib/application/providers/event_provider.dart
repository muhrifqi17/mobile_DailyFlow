import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../domain/entities/event.dart';
import '../../infrastructure/services/isar_service.dart';
import '../../domain/services/conflict_detection_service.dart';
import 'habit_provider.dart'; // To access isarServiceProvider

final eventsProvider = StateNotifierProvider<EventNotifier, AsyncValue<List<Event>>>((ref) {
  return EventNotifier(
    ref.read(isarServiceProvider),
    ref.read(conflictDetectionServiceProvider),
  );
});

class EventNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  final IsarService _isarService;
  final ConflictDetectionService _conflictService;

  EventNotifier(this._isarService, this._conflictService) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      final isar = await _isarService.db;
      final events = await isar.events.where().sortByEventDate().findAll();
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addEvent(Event event) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.events.put(event);
    });
    
    // Call the domain service to check for conflicts
    await _conflictService.detectAndSuspendConflicts(event);
    
    await loadEvents();
  }

  Future<void> deleteEvent(int id) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.events.delete(id);
    });
    await loadEvents();
  }
}

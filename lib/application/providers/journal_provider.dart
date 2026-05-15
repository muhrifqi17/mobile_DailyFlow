import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../domain/entities/journal_entry.dart';
import '../../infrastructure/services/crypto_service.dart';
import '../../infrastructure/services/isar_service.dart';
import 'habit_provider.dart'; // to access isarServiceProvider

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

final journalsProvider = StateNotifierProvider<JournalNotifier, AsyncValue<List<JournalEntry>>>((ref) {
  return JournalNotifier(
    ref.read(isarServiceProvider),
    ref.read(cryptoServiceProvider),
  );
});

class JournalNotifier extends StateNotifier<AsyncValue<List<JournalEntry>>> {
  final IsarService _isarService;
  final CryptoService _cryptoService;

  JournalNotifier(this._isarService, this._cryptoService) : super(const AsyncValue.loading()) {
    loadJournals();
  }

  Future<void> loadJournals() async {
    try {
      final isar = await _isarService.db;
      final journals = await isar.journalEntrys.where().sortByCreatedAtDesc().findAll();
      
      // Decrypt the content
      final decryptedJournals = <JournalEntry>[];
      for (final j in journals) {
        final decryptedContent = await _cryptoService.decrypt(j.cipherText, j.iv, j.mac);
        final unencryptedJournal = JournalEntry()
          ..id = j.id
          ..createdAt = j.createdAt
          ..cipherText = decryptedContent; // Storing decrypted temporarily for UI
        decryptedJournals.add(unencryptedJournal);
      }
      
      state = AsyncValue.data(decryptedJournals);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addJournal(String rawText) async {
    final isar = await _isarService.db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final existingJournal = await isar.journalEntrys.filter().entryDateEqualTo(today).findFirst();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    if (existingJournal != null) {
      // Append to existing entry
      final decryptedContent = await _cryptoService.decrypt(existingJournal.cipherText, existingJournal.iv, existingJournal.mac);
      final appendedText = "$decryptedContent\n\n[$timeString]\n$rawText";
      
      final encryptedData = await _cryptoService.encrypt(appendedText);
      existingJournal.cipherText = encryptedData['cipherText']!;
      existingJournal.iv = encryptedData['iv']!;
      existingJournal.mac = encryptedData['mac']!;
      existingJournal.updatedAt = now;

      await isar.writeTxn(() async {
        await isar.journalEntrys.put(existingJournal);
      });
    } else {
      // Create new entry
      final initialText = "[$timeString]\n$rawText";
      final encryptedData = await _cryptoService.encrypt(initialText);
      
      final newJournal = JournalEntry()
        ..entryDate = today
        ..createdAt = now
        ..cipherText = encryptedData['cipherText']!
        ..iv = encryptedData['iv']!
        ..mac = encryptedData['mac']!
        ..mood = JournalMood.none;

      await isar.writeTxn(() async {
        await isar.journalEntrys.put(newJournal);
      });
    }
    
    await loadJournals();
  }
}

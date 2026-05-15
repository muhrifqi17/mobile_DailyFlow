import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../application/providers/journal_provider.dart';
import '../../domain/entities/journal_entry.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalsAsync = ref.watch(journalsProvider);
    final textController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Secure Journal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E1E8B),
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How are you feeling today?', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E1E8B)),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: textController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your private thoughts here... Everything is AES-256 encrypted.',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              onPressed: () async {
                if (textController.text.trim().isNotEmpty) {
                  await ref.read(journalsProvider.notifier).addJournal(textController.text.trim());
                  textController.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Journal encrypted and saved!')),
                    );
                  }
                }
              },
              child: const Text('Lock & Save', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Past Entries', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E1E8B)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: journalsAsync.when(
                data: (journals) {
                  if (journals.isEmpty) {
                    return const Center(child: Text('No previous entries found.', style: TextStyle(color: Colors.black54)));
                  }
                  return ListView.builder(
                    itemCount: journals.length,
                    itemBuilder: (context, index) {
                      final journal = journals[index];
                      return _JournalEntryCard(journal: journal);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalEntryCard extends ConsumerStatefulWidget {
  final JournalEntry journal;

  const _JournalEntryCard({required this.journal});

  @override
  ConsumerState<_JournalEntryCard> createState() => _JournalEntryCardState();
}

class _JournalEntryCardState extends ConsumerState<_JournalEntryCard> {
  bool _isUnlocked = false;
  final _storage = const FlutterSecureStorage();

  Future<void> _authenticate() async {
    if (_isUnlocked) return;
    
    // Check if PIN exists
    String? storedPin = await _storage.read(key: 'journal_pin');
    
    if (!mounted) return;

    if (storedPin == null) {
      // First time setup
      final newPin = await _showPinDialog('Create 4-digit PIN for Journals');
      if (newPin != null && newPin.length == 4) {
        await _storage.write(key: 'journal_pin', value: newPin);
        setState(() => _isUnlocked = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN successfully set!')));
        }
      }
    } else {
      // Prompt for PIN
      final enteredPin = await _showPinDialog('Enter 4-digit PIN');
      if (enteredPin == storedPin) {
        setState(() => _isUnlocked = true);
      } else if (enteredPin != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect PIN!')));
        }
      }
    }
  }

  Future<String?> _showPinDialog(String title) async {
    String pin = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: '****'),
          onChanged: (val) => pin = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, pin), child: const Text('Submit')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _authenticate,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.journal.createdAt.toLocal()}'.split('.')[0], 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF), fontSize: 12),
                  ),
                  if (!_isUnlocked) const Icon(Icons.lock, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              if (_isUnlocked) 
                Text(widget.journal.cipherText)
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Tap to unlock this entry', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


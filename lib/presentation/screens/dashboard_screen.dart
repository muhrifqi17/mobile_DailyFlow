import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/habit_provider.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF), // Light Blue-Grey Background
      appBar: AppBar(
        title: const Text('My Goals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E1E8B), // Navy Blue
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(
              child: Text('No habits found. Start by creating one!', style: TextStyle(color: Colors.black54)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return _buildHabitCard(context, ref, habit);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF), // Indigo
        shape: const StadiumBorder(),
        onPressed: () {
          // Open Modal to create new habit
          _showHabitModal(context, ref);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, WidgetRef ref, Habit habit) {
    return FutureBuilder<LogStatus?>(
      future: ref.read(habitsProvider.notifier).getHabitStatusToday(habit),
      builder: (context, snapshot) {
        final status = snapshot.data;
        
        final now = DateTime.now();
        final habitTimeParts = habit.targetTime.split(':');
        final isTimePassed = habitTimeParts.length == 2 && 
            (now.hour > int.parse(habitTimeParts[0]) || 
            (now.hour == int.parse(habitTimeParts[0]) && now.minute >= int.parse(habitTimeParts[1])));
        
        final isDone = status == LogStatus.done;
        final isSuspended = status == LogStatus.suspended;
        final canMarkDone = isTimePassed && !isDone && !isSuspended;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 2,
          shadowColor: Colors.black12,
          child: ListTile(
            onTap: () => _showHabitModal(context, ref, habit),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            title: Text(
              habit.title, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isSuspended ? Colors.grey : const Color(0xFF2E1E8B), 
                fontSize: 16,
                decoration: isDone || isSuspended ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              isSuspended ? 'Suspended (Q1 Conflict)' : 'Time: ${habit.targetTime} • Streak: ${habit.currentStreak}', 
              style: TextStyle(color: isSuspended ? Colors.red.shade300 : Colors.black54)
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canMarkDone ? const Color(0xFF6C63FF) : Colors.grey.shade400, // Pill shaped button
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: canMarkDone ? () async {
                await ref.read(habitsProvider.notifier).markHabitDone(habit);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${habit.title} marked as Done!')),
                  );
                }
              } : null,
              child: Text(isDone ? 'Completed' : 'Done', style: const TextStyle(color: Colors.white)),
            ),
          ),
        );
      }
    );
  }

  void _showHabitModal(BuildContext context, WidgetRef ref, [Habit? existingHabit]) {
    final isUpdate = existingHabit != null;
    final titleController = TextEditingController(text: existingHabit?.title ?? '');
    
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    if (existingHabit != null) {
      final parts = existingHabit.targetTime.split(':');
      if (parts.length == 2) {
        selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24, left: 24, right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isUpdate ? 'Update Goal' : 'Create New Goal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E1E8B))),
                      if (isUpdate)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Goal?'),
                                content: const Text('Are you sure you want to delete this goal and its history?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref.read(habitsProvider.notifier).deleteHabit(existingHabit.id);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Goal Title',
                      filled: true,
                      fillColor: const Color(0xFFF5F7FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Target Time'),
                    trailing: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: const Color(0xFFF5F7FF),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E1E8B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          final formattedHour = selectedTime.hour.toString().padLeft(2, '0');
                          final formattedMinute = selectedTime.minute.toString().padLeft(2, '0');
                          
                          final habit = existingHabit ?? Habit();
                          habit.title = titleController.text;
                          habit.targetTime = "$formattedHour:$formattedMinute";
                          
                          if (!isUpdate) {
                            habit.frequency = HabitFrequency.daily;
                          }
                          
                          ref.read(habitsProvider.notifier).addHabit(habit);
                          Navigator.pop(context);
                        }
                      },
                      child: Text(isUpdate ? 'Update' : 'Save', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }
}

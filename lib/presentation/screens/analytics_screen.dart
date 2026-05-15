import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/kpi_calculator_service.dart';

final todayCompletionProvider = FutureProvider<double>((ref) => ref.read(kpiCalculatorProvider).getTodayCompletionRate());
final sevenDayConsistencyProvider = FutureProvider<double>((ref) => ref.read(kpiCalculatorProvider).get7DayConsistencyScore());
final activeStreakProvider = FutureProvider<int>((ref) => ref.read(kpiCalculatorProvider).getActiveStreak());
final journalStreakProvider = FutureProvider<int>((ref) => ref.read(kpiCalculatorProvider).getJournalStreak());

final mostMissedHabitProvider = FutureProvider<String>((ref) => ref.read(kpiCalculatorProvider).getMostMissedHabit());
final mostIncompleteHabitProvider = FutureProvider<String>((ref) => ref.read(kpiCalculatorProvider).getMostIncompleteHabit());
final integrityProvider = FutureProvider<double>((ref) => ref.read(kpiCalculatorProvider).getCompletionIntegrityScore());
final disruptionProvider = FutureProvider<double>((ref) => ref.read(kpiCalculatorProvider).getDisruptionIndex());

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Performance Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E1E8B),
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader('Tier 1: Vital Signs'),
            Row(
              children: [
                Expanded(child: _buildMetricCard(title: "Today's Rate", provider: todayCompletionProvider, ref: ref, isPercent: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(title: "7-Day Score", provider: sevenDayConsistencyProvider, ref: ref, isPercent: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard(title: "Active Streak", provider: activeStreakProvider, ref: ref, suffix: ' Days')),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(title: "Journal Streak", provider: journalStreakProvider, ref: ref, suffix: ' Days')),
              ],
            ),

            const SizedBox(height: 24),
            const _SectionHeader('Tier 2: Diagnostic Insights'),
            _buildInfoCard("Most Missed Habit", mostMissedHabitProvider, ref),
            const SizedBox(height: 12),
            _buildInfoCard("Most Incomplete Habit", mostIncompleteHabitProvider, ref),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard(title: "Completion Integrity", provider: integrityProvider, ref: ref, isPercent: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(title: "Disruption Index", provider: disruptionProvider, ref: ref, isPercent: true)),
              ],
            ),
            const SizedBox(height: 12),
            _buildPlaceholderCard('Disruption Pattern Heatmap will be rendered here.'),

            const SizedBox(height: 24),
            const _SectionHeader('Tier 3: Trend & Historical'),
            _buildPlaceholderCard('Weekly Habit Heatmap'),
            const SizedBox(height: 12),
            _buildPlaceholderCard('Monthly Calendar View'),
            const SizedBox(height: 12),
            _buildPlaceholderCard('Monthly Consistency Trend Chart'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required FutureProvider provider, required WidgetRef ref, bool isPercent = false, String suffix = ''}) {
    final asyncVal = ref.watch(provider);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            asyncVal.when(
              data: (val) {
                if (isPercent) {
                  return Text('${(val * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)));
                } else {
                  return Text('$val$suffix', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)));
                }
              },
              loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const Text('Err', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, FutureProvider<String> provider, WidgetRef ref) {
    final asyncVal = ref.watch(provider);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        trailing: asyncVal.when(
          data: (val) => Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          loading: () => const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => const Text('Error'),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(String text) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade200,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(child: Text(text, style: const TextStyle(color: Colors.black45, fontStyle: FontStyle.italic), textAlign: TextAlign.center)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E1E8B))),
    );
  }
}

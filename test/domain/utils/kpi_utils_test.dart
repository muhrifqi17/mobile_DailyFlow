import 'package:flutter_test/flutter_test.dart';
import 'package:dailyflow/domain/utils/kpi_utils.dart';

void main() {
  group('KPIUtils - Business Logic Tests', () {
    
    group('calculateCompletionRate (High Priority)', () {
      test('Should calculate correct rate for normal values', () {
        // 5 done out of 10 total = 50%
        final rate = KPIUtils.calculateCompletionRate(done: 5, missed: 3, notDone: 2);
        expect(rate, 0.5);
      });

      test('Should return 1.0 if everything is done', () {
        final rate = KPIUtils.calculateCompletionRate(done: 10, missed: 0, notDone: 0);
        expect(rate, 1.0);
      });

      test('Should return 0.0 if nothing is done', () {
        final rate = KPIUtils.calculateCompletionRate(done: 0, missed: 5, notDone: 5);
        expect(rate, 0.0);
      });
      
      // EDGE CASES (Medium Priority)
      test('Edge Case: Should return 0.0 if all inputs are 0', () {
        final rate = KPIUtils.calculateCompletionRate(done: 0, missed: 0, notDone: 0);
        expect(rate, 0.0);
      });

      test('Edge Case: Should handle negative values gracefully (return 0.0)', () {
        final rate = KPIUtils.calculateCompletionRate(done: -5, missed: 2, notDone: 1);
        expect(rate, 0.0);
      });
    });

    group('calculateConsistencyScore (High Priority)', () {
      test('Should calculate average of valid days', () {
        final score = KPIUtils.calculateConsistencyScore([1.0, 0.5, 0.0]);
        // Average of 1.0, 0.5, 0.0 is 0.5
        expect(score, 0.5);
      });

      test('Should ignore suspended days (-1.0)', () {
        final score = KPIUtils.calculateConsistencyScore([1.0, -1.0, 0.5]);
        // Average of 1.0 and 0.5 (ignoring -1.0) is 0.75
        expect(score, 0.75);
      });

      // EDGE CASES (Medium Priority)
      test('Edge Case: Should return 0.0 for empty list', () {
        final score = KPIUtils.calculateConsistencyScore([]);
        expect(score, 0.0);
      });

      test('Edge Case: Should return 0.0 if all days are suspended', () {
        final score = KPIUtils.calculateConsistencyScore([-1.0, -1.0, -1.0]);
        expect(score, 0.0);
      });
    });

    group('hasTimeConflict (High Priority / Fatal if wrong)', () {
      test('Should return true if habit time is exactly on event start time', () {
        final conflict = KPIUtils.hasTimeConflict('09:00', '09:00', '10:00');
        expect(conflict, true);
      });

      test('Should return true if habit time is inside event duration', () {
        final conflict = KPIUtils.hasTimeConflict('09:30', '09:00', '10:00');
        expect(conflict, true);
      });

      test('Should return false if habit time is outside event duration', () {
        final conflict = KPIUtils.hasTimeConflict('08:59', '09:00', '10:00');
        expect(conflict, false);
      });

      // EDGE CASES (Medium Priority)
      test('Edge Case: Should return false for malformed time strings', () {
        final conflict = KPIUtils.hasTimeConflict('invalid', '09:00', '10:00');
        expect(conflict, false);
      });

      test('Edge Case: Should return false for empty strings', () {
        final conflict = KPIUtils.hasTimeConflict('', '', '');
        expect(conflict, false);
      });
    });
  });
}

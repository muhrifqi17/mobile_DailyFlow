import 'package:flutter_test/flutter_test.dart';
import 'package:dailyflow/domain/utils/validators.dart';

void main() {
  group('Input Validators Tests', () {
    
    group('Habit Title Validation', () {
      test('Should return null for valid title', () {
        expect(Validators.validateHabitTitle('Morning Run'), null);
        expect(Validators.validateHabitTitle('Read 10 pages!'), null);
      });

      test('Should return error for empty title', () {
        expect(Validators.validateHabitTitle(''), 'Title cannot be empty');
        expect(Validators.validateHabitTitle('   '), 'Title cannot be empty');
        expect(Validators.validateHabitTitle(null), 'Title cannot be empty');
      });

      test('Should return error for title exceeding 50 chars', () {
        final longTitle = 'a' * 51;
        expect(Validators.validateHabitTitle(longTitle), 'Title must be less than 50 characters');
      });

      test('Should return error for invalid characters', () {
        expect(Validators.validateHabitTitle('Coding <script>'), 'Title contains invalid characters');
        expect(Validators.validateHabitTitle('Read @night'), 'Title contains invalid characters');
      });
    });

    group('Target Time Validation', () {
      test('Should return null for valid HH:MM time', () {
        expect(Validators.validateTargetTime('09:00'), null);
        expect(Validators.validateTargetTime('23:59'), null);
        expect(Validators.validateTargetTime('00:00'), null);
      });

      test('Should return error for invalid time format', () {
        expect(Validators.validateTargetTime('9:00'), 'Invalid time format. Use HH:MM');
        expect(Validators.validateTargetTime('24:00'), 'Invalid time format. Use HH:MM');
        expect(Validators.validateTargetTime('12:60'), 'Invalid time format. Use HH:MM');
        expect(Validators.validateTargetTime('12-30'), 'Invalid time format. Use HH:MM');
      });

      test('Should return error for empty time', () {
        expect(Validators.validateTargetTime(''), 'Time is required');
        expect(Validators.validateTargetTime(null), 'Time is required');
      });
    });

    group('Journal PIN Validation', () {
      test('Should return null for valid 4-digit PIN', () {
        expect(Validators.validatePinCode('1234'), null);
        expect(Validators.validatePinCode('0000'), null);
      });

      test('Should return error for non-4 digit lengths', () {
        expect(Validators.validatePinCode('123'), 'PIN must be exactly 4 digits');
        expect(Validators.validatePinCode('12345'), 'PIN must be exactly 4 digits');
      });

      test('Should return error for non-numeric PIN', () {
        expect(Validators.validatePinCode('123a'), 'PIN must contain only numbers');
        expect(Validators.validatePinCode('12 4'), 'PIN must contain only numbers');
      });
    });

    group('Journal Entry Validation', () {
      test('Should return null for valid entry', () {
        expect(Validators.validateJournalEntry('Feeling great today!'), null);
      });

      test('Should return error for empty entry', () {
        expect(Validators.validateJournalEntry(''), 'Journal entry cannot be empty');
        expect(Validators.validateJournalEntry(null), 'Journal entry cannot be empty');
      });

      test('Should return error for overly large entry', () {
        final hugeEntry = 'a' * 10001;
        expect(Validators.validateJournalEntry(hugeEntry), 'Journal entry is too long');
      });
    });
  });
}

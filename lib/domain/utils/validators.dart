class Validators {
  /// Validates Habit Title
  static String? validateHabitTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title cannot be empty';
    }
    if (value.length > 50) {
      return 'Title must be less than 50 characters';
    }
    // Avoid special characters that might break UI or DB
    final regex = RegExp(r'^[a-zA-Z0-9\s.,!?_-]+$');
    if (!regex.hasMatch(value)) {
      return 'Title contains invalid characters';
    }
    return null; // Valid
  }

  /// Validates Target Time (Format: HH:MM)
  static String? validateTargetTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Time is required';
    }
    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (!regex.hasMatch(value)) {
      return 'Invalid time format. Use HH:MM';
    }
    return null;
  }

  /// Validates Journal Entry (Moment)
  static String? validateJournalEntry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Journal entry cannot be empty';
    }
    if (value.length > 10000) {
      return 'Journal entry is too long';
    }
    return null;
  }

  /// Validates 4-Digit PIN Code
  static String? validatePinCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN is required';
    }
    if (value.length != 4) {
      return 'PIN must be exactly 4 digits';
    }
    final regex = RegExp(r'^\d{4}$');
    if (!regex.hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    return null;
  }

  /// Validates Event Name
  static String? validateEventName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Event name cannot be empty';
    }
    if (value.length > 100) {
      return 'Event name is too long';
    }
    return null;
  }
}

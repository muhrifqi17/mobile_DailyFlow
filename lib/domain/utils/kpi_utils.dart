class KPIUtils {
  /// Calculate Completion Rate
  /// Formula: done / (done + missed + notDone)
  /// If input is invalid (negative) or total is 0, returns 0.0
  static double calculateCompletionRate({
    required int done,
    required int missed,
    required int notDone,
  }) {
    if (done < 0 || missed < 0 || notDone < 0) return 0.0;
    
    final total = done + missed + notDone;
    if (total == 0) return 0.0;
    
    return done / total;
  }

  /// Calculates consistency score average given a list of daily completion rates.
  /// Ignores days where the rate is -1.0 (suspended/neutral).
  static double calculateConsistencyScore(List<double> dailyRates) {
    if (dailyRates.isEmpty) return 0.0;

    double totalScore = 0;
    int validDays = 0;

    for (var rate in dailyRates) {
      if (rate >= 0.0) {
        totalScore += rate;
        validDays++;
      }
    }

    if (validDays == 0) return 0.0;
    return totalScore / validDays;
  }

  /// Check if two times conflict. Format: "HH:MM"
  static bool hasTimeConflict(String habitTime, String eventStartTime, String eventEndTime) {
    try {
      final hParts = habitTime.split(':');
      final esParts = eventStartTime.split(':');
      final eeParts = eventEndTime.split(':');

      if (hParts.length != 2 || esParts.length != 2 || eeParts.length != 2) return false;

      final hMin = int.parse(hParts[0]) * 60 + int.parse(hParts[1]);
      final esMin = int.parse(esParts[0]) * 60 + int.parse(esParts[1]);
      final eeMin = int.parse(eeParts[0]) * 60 + int.parse(eeParts[1]);

      return hMin >= esMin && hMin <= eeMin;
    } catch (e) {
      return false; // Handle malformed strings (null, empty, non-numeric) safely
    }
  }
}

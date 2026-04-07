/// Offsets the logical "today" for expiry checks and UI (time simulator / QA).
class SimulatedClock {
  SimulatedClock._();

  /// Added to [DateTime.now] wherever the app treats "current date" for food expiry.
  static Duration offset = Duration.zero;

  static DateTime get now => DateTime.now().add(offset);

  static void reset() => offset = Duration.zero;

  static void addDays(int days) {
    if (days == 0) return;
    offset += Duration(days: days);
  }

  static String describeOffset(String language) {
    if (offset == Duration.zero) {
      return language == 'ENG' ? 'Real time (no offset)' : 'Giờ thực (không cộng thêm)';
    }
    final days = offset.inDays;
    if (language == 'ENG') {
      return 'Simulated: +$days day(s) vs real clock';
    }
    return 'Mô phỏng: +$days ngày so với đồng hồ thật';
  }
}

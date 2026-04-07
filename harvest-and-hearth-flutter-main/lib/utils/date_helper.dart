import 'package:intl/intl.dart';

class DateHelper {
  DateHelper._();

  static final _fmt = DateFormat('dd/MM/yyyy');

  static String format(DateTime date) => _fmt.format(date);

  static String formatShort(DateTime date) =>
      DateFormat('dd/MM').format(date);

  static String relativeLabel(int? daysUntilExpiry, String language) {
    if (daysUntilExpiry == null) return '';
    final isVie = language == 'VIE';
    if (daysUntilExpiry < 0) {
      final d = daysUntilExpiry.abs();
      return isVie ? '$d ngày trước' : '$d days ago';
    }
    if (daysUntilExpiry == 0) return isVie ? 'Hôm nay' : 'Today';
    return isVie
        ? '$daysUntilExpiry ngày còn lại'
        : '$daysUntilExpiry days left';
  }
}

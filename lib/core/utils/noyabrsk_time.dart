import 'package:intl/intl.dart';

class NoyabrskTime {
  static const Duration offset = Duration(hours: 5);

  static DateTime now() => DateTime.now().toUtc().add(offset);

  static String formatAfishaDate(DateTime date) {
    final dayMonth = DateFormat('dd MMMM', 'ru').format(date);
    final weekday = DateFormat('EEEE', 'ru').format(date);
    return '$dayMonth, $weekday';
  }
}

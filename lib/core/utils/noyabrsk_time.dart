class NoyabrskTime {
  static DateTime now() => DateTime.now().toUtc().add(const Duration(hours: 5));

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static String formatAfishaDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    const weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    return '${date.day} ${months[date.month - 1]}, ${weekdays[date.weekday - 1]}';
  }

  static String formatShortDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}

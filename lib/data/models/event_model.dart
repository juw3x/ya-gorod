enum ScheduleType { single, multiple, period }

class EventSession {
  final DateTime date;
  final String? startTime;
  final String? endTime;

  const EventSession({
    required this.date,
    this.startTime,
    this.endTime,
  });

  bool isCompleted(DateTime noyabrskNow) {
    if (endTime != null && endTime!.contains(':')) {
      final parts = endTime!.split(':');
      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return noyabrskNow.isAfter(endDateTime);
    }
    final nextMidnight = DateTime(date.year, date.month, date.day + 1);
    return noyabrskNow.isAfter(nextMidnight) || noyabrskNow.isAtSameMomentAs(nextMidnight);
  }
}

class EventModel {
  final String id;
  final String title;
  final String category;
  final String ageRating;
  final String venueName;
  final String venueAddress;
  final String? mapUrl;
  final String? ticketUrl;
  final String description;
  final String? coverUrl;
  final List<String> galleryUrls;
  final bool isFree;
  final int? minPrice;
  final String? priceLabel;
  final ScheduleType scheduleType;
  final List<EventSession> sessions;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  const EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.ageRating,
    required this.venueName,
    required this.venueAddress,
    this.mapUrl,
    this.ticketUrl,
    required this.description,
    this.coverUrl,
    this.galleryUrls = const [],
    this.isFree = false,
    this.minPrice,
    this.priceLabel,
    required this.scheduleType,
    this.sessions = const [],
    this.periodStart,
    this.periodEnd,
  });

  String get formattedPrice {
    if (isFree) return 'Бесплатно';
    if (priceLabel != null) return priceLabel!;
    if (minPrice != null) return 'от $minPrice ₽';
    return 'Платный вход';
  }
}

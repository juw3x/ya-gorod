import '../../core/network/api_client.dart';

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

  factory EventSession.fromJson(Map<String, dynamic> json) => EventSession(
        date: DateTime.parse(json['date']),
        startTime: json['startTime'] ?? json['start_time'],
        endTime: json['endTime'] ?? json['end_time'],
      );

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
  final String? videoUrl;
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
    this.videoUrl,
    this.galleryUrls = const [],
    this.isFree = false,
    this.minPrice,
    this.priceLabel,
    required this.scheduleType,
    this.sessions = const [],
    this.periodStart,
    this.periodEnd,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['schedule_type'] ?? 'single').toString();
    final scheduleType = switch (typeStr) {
      'multiple' => ScheduleType.multiple,
      'period' => ScheduleType.period,
      _ => ScheduleType.single,
    };

    final rawSessions = (json['sessions'] as List?) ?? const [];
    final rawGallery = (json['gallery_urls'] as List?) ?? const [];

    return EventModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      category: json['category'] ?? 'Другое',
      ageRating: json['age_rating'] ?? '0+',
      venueName: json['venue_name'] ?? '',
      venueAddress: json['venue_address'] ?? '',
      mapUrl: json['map_url'],
      ticketUrl: json['ticket_url'],
      description: json['description'] ?? '',
      coverUrl: ApiClient.resolveMediaUrl(json['cover_url']),
      videoUrl: ApiClient.resolveMediaUrl(json['video_url']),
      galleryUrls: rawGallery
          .map((e) => ApiClient.resolveMediaUrl(e.toString()))
          .whereType<String>()
          .toList(),
      isFree: json['is_free'] == true,
      minPrice: json['min_price'] is int ? json['min_price'] : int.tryParse('${json['min_price']}'),
      scheduleType: scheduleType,
      sessions: rawSessions
          .where((e) => e is Map)
          .map((e) => EventSession.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      periodStart: json['period_start'] != null ? DateTime.tryParse(json['period_start']) : null,
      periodEnd: json['period_end'] != null ? DateTime.tryParse(json['period_end']) : null,
    );
  }

  String get formattedPrice {
    if (isFree) return 'Бесплатно';
    if (priceLabel != null) return priceLabel!;
    if (minPrice != null) return 'от $minPrice ₽';
    return 'Платный вход';
  }
}

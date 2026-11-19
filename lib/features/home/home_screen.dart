import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/noyabrsk_time.dart';
import '../../data/models/event_model.dart';
import '../../data/models/home_models.dart';
import '../../data/repositories/mock_home_repository.dart';
import 'widgets/banner_slider.dart';
import 'widgets/stories_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = MockHomeRepository();

  @override
  Widget build(BuildContext context) {
    final stories = _repo.getStories();
    final sliderBanners = _repo.getSliderBanners();
    final adBanners = _repo.getAfishaAdBanners();
    final events = _repo.getEvents();
    final now = NoyabrskTime.now();

    // Разворачиваем события в плоский список пар (Дата, Мероприятие, Время)
    final items = <_AfishaCardEntry>[];
    for (final event in events) {
      for (final session in event.sessions) {
        if (!session.isCompleted(now)) {
          items.add(_AfishaCardEntry(date: session.date, startTime: session.startTime, event: event));
        }
      }
    }

    // Сортировка: по дате, внутри даты по времени (без времени — в конце)[cite: 14]
    items.sort((a, b) {
      final dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;
      if (a.startTime == null && b.startTime == null) return 0;
      if (a.startTime == null) return 1;
      if (b.startTime == null) return -1;
      return a.startTime!.compareTo(b.startTime!);
    });

    // Формируем ленту с заголовками дат и рекламой (перед 1-й, после 4-й, 8-й...)[cite: 14, 16]
    final feedWidgets = <Widget>[];
    DateTime? lastDate;
    int cardCounter = 0;
    int adIndex = 0;

    for (final entry in items) {
      if (lastDate == null || lastDate != entry.date) {
        lastDate = entry.date;
        feedWidgets.add(_DateHeader(date: entry.date));
      }

      // Врезка рекламы перед 1-й (counter == 0) и далее каждые 4 карточки[cite: 16]
      if (cardCounter % 4 == 0 && adIndex < adBanners.length) {
        feedWidgets.add(_InlineAdCard(banner: adBanners[adIndex]));
        adIndex++;
      }

      feedWidgets.add(_EventCard(entry: entry));
      cardCounter++;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        StoriesSection(stories: stories),
        const SizedBox(height: 8),
        BannerSlider(banners: sliderBanners),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Афиша города', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        if (feedWidgets.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Нет мероприятий', style: TextStyle(color: Colors.grey))),
          )
        else
          ...feedWidgets,
      ],
    );
  }
}

class _AfishaCardEntry {
  final DateTime date;
  final String? startTime;
  final EventModel event;
  _AfishaCardEntry({required this.date, this.startTime, required this.event});
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        NoyabrskTime.formatAfishaDate(date),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InlineAdCard extends StatelessWidget {
  final BannerModel banner;
  const _InlineAdCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (banner.linkUrl != null) {
          launchUrl(Uri.parse(banner.linkUrl!), mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('РЕКЛАМА', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(banner.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (banner.subtitle != null)
                    Text(banner.subtitle!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _AfishaCardEntry entry;
  const _EventCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final event = entry.event;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            height: 100,
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.image_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                      child: Text(event.ageRating, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(event.venueName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${event.category} • ${event.formattedPrice}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      entry.startTime ?? 'Время уточняется',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
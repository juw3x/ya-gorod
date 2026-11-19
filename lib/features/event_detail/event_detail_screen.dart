import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/noyabrsk_time.dart';
import '../../data/models/event_model.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Мероприятие', style: TextStyle(color: Colors.black87, fontSize: 17)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Badge(text: event.category),
              const SizedBox(width: 8),
              _Badge(text: event.ageRating),
            ],
          ),
          const SizedBox(height: 12),
          Text(event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._buildScheduleWidgets(),
          const SizedBox(height: 20),
          const Text('О мероприятии', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(event.description, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
          const SizedBox(height: 20),
          const Text('Место проведения', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.venueName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(event.venueAddress, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                if (event.mapUrl != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(event.mapUrl!), mode: LaunchMode.externalApplication),
                    child: const Text(
                      'Открыть на карте ↗',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B3A67),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Стоимость билета', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(event.formattedPrice, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (event.ticketUrl != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B3A67),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => launchUrl(Uri.parse(event.ticketUrl!), mode: LaunchMode.externalApplication),
                  child: const Text('Купить билет ↗'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScheduleWidgets() {
    if (event.scheduleType == ScheduleType.period && event.periodStart != null && event.periodEnd != null) {
      final start = NoyabrskTime.formatAfishaDate(event.periodStart!);
      final end = NoyabrskTime.formatAfishaDate(event.periodEnd!);
      return [
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(child: Text('$start — $end', style: const TextStyle(fontSize: 14))),
          ],
        ),
      ];
    }

    return event.sessions.map((s) {
      final dateStr = NoyabrskTime.formatAfishaDate(s.date);
      final timeStr = s.startTime == null
          ? 'Время уточняется'
          : (s.endTime != null ? '${s.startTime} – ${s.endTime}' : s.startTime!);
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Text('$dateStr • $timeStr', style: const TextStyle(fontSize: 14)),
          ],
        ),
      );
    }).toList();
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

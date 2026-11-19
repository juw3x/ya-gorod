import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../core/utils/noyabrsk_time.dart';
import '../../data/models/event_model.dart';
import '../not_found/not_found_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.event.videoUrl != null) {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.event.videoUrl!));
      _videoController = ctrl;
      ctrl.initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  bool _isFinished() {
    final now = NoyabrskTime.now();
    final event = widget.event;
    if (event.scheduleType == ScheduleType.period && event.periodEnd != null) {
      return NoyabrskTime.dateOnly(now).isAfter(NoyabrskTime.dateOnly(event.periodEnd!));
    }
    if (event.sessions.isEmpty) return false;
    return event.sessions.every((s) => s.isCompleted(now));
  }

  void _openGalleryPreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 240,
                  child: Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished()) return const NotFoundScreen();
    final event = widget.event;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
              const Text('К афише', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 210,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(16)),
            child: event.coverUrl != null
                ? Image.network(
                    event.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                  )
                : const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
          ),
          if (_videoController != null && _videoController!.value.isInitialized) ...[
            const SizedBox(height: 16),
            const Text('Видео-анонс', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: Icon(
                        _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (event.galleryUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: event.galleryUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _openGalleryPreview(context, event.galleryUrls[i]),
                  child: Container(
                    width: 112,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: const Color(0xFFDCE1EA), borderRadius: BorderRadius.circular(10)),
                    child: Image.network(
                      event.galleryUrls[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.photo, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
          ..._buildScheduleWidgets(event),
          const SizedBox(height: 20),
          const Text('О мероприятии', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(12)),
            child: Text(event.description, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
          const SizedBox(height: 20),
          const Text('Место проведения', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(12)),
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
                      style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600, color: Color(0xFF2B3A67)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: Container(
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
    );
  }

  List<Widget> _buildScheduleWidgets(EventModel event) {
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

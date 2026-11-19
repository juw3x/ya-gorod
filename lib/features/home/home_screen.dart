import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/noyabrsk_time.dart';
import '../../core/utils/scroll_bus.dart';
import '../../data/models/event_model.dart';
import '../../data/models/home_models.dart';
import '../../data/repositories/api_repository.dart';
import 'widgets/banner_slider.dart';
import 'widgets/stories_section.dart';

class _AfishaEntry {
  final DateTime groupDate;
  final EventModel event;
  final String? timeLabel;
  final String? periodRangeLabel;

  const _AfishaEntry({
    required this.groupDate,
    required this.event,
    this.timeLabel,
    this.periodRangeLabel,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _afishaKey = GlobalKey();

  List<StoryItem> _stories = [];
  List<BannerItem> _banners = [];
  List<_AfishaEntry> _allEntries = [];

  int _visibleCount = 20;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    ScrollBus.homeTop.addListener(_onScrollToTop);
    ScrollBus.homeAfisha.addListener(_onScrollToAfisha);
    _loadHome();
  }

  void _onScrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _onScrollToAfisha() {
    final ctx = _afishaKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _loadHome() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await ApiRepository.fetchHome();
      if (!mounted) return;
      setState(() {
        _stories = data.stories;
        _banners = data.banners;
        _allEntries = _buildEntries(data.events);
        _visibleCount = 20;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Не удалось подключиться к API. Проверьте сеть и попробуйте снова.';
      });
    }
  }

  List<_AfishaEntry> _buildEntries(List<EventModel> events) {
    final now = NoyabrskTime.now();
    final today = NoyabrskTime.dateOnly(now);
    final entries = <_AfishaEntry>[];

    for (final event in events) {
      if (event.scheduleType == ScheduleType.period && event.periodStart != null && event.periodEnd != null) {
        final start = NoyabrskTime.dateOnly(event.periodStart!);
        final end = NoyabrskTime.dateOnly(event.periodEnd!);
        if (today.isAfter(end)) continue;
        final groupDate = today.isBefore(start) ? start : today;
        final rangeLabel = '${NoyabrskTime.formatShortDate(start)} — ${NoyabrskTime.formatShortDate(end)}';
        entries.add(_AfishaEntry(groupDate: groupDate, event: event, periodRangeLabel: rangeLabel));
      } else {
        for (final session in event.sessions) {
          if (session.isCompleted(now)) continue;
          entries.add(_AfishaEntry(
            groupDate: NoyabrskTime.dateOnly(session.date),
            event: event,
            timeLabel: session.startTime,
          ));
        }
      }
    }

    entries.sort((a, b) => a.groupDate.compareTo(b.groupDate));
    return entries;
  }

  @override
  void dispose() {
    ScrollBus.homeTop.removeListener(_onScrollToTop);
    ScrollBus.homeAfisha.removeListener(_onScrollToAfisha);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _allEntries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _allEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadHome, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    final displayed = _allEntries.take(_visibleCount).toList();
    final widgets = <Widget>[
      const SizedBox(height: 12),
      StoriesSection(stories: _stories),
      const SizedBox(height: 16),
      BannerSlider(banners: _banners),
      const SizedBox(height: 20),
      Padding(
        key: _afishaKey,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Text('Афиша мероприятий', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 12),
    ];

    DateTime? lastDate;
    for (var i = 0; i < displayed.length; i++) {
      final entry = displayed[i];
      if (i == 0) widgets.add(_buildAdBanner(1));
      if (lastDate == null || lastDate != entry.groupDate) {
        lastDate = entry.groupDate;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              NoyabrskTime.formatAfishaDate(entry.groupDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2B3A67)),
            ),
          ),
        );
      }
      widgets.add(_EventCard(entry: entry));
      if ((i + 1) % 4 == 0) widgets.add(_buildAdBanner(((i + 1) ~/ 4) + 1));
    }

    if (_visibleCount < _allEntries.length) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: OutlinedButton(
            onPressed: () => setState(() => _visibleCount += 20),
            child: const Text('Больше мероприятий'),
          ),
        ),
      );
    } else {
      widgets.add(const SizedBox(height: 24));
    }

    return RefreshIndicator(
      onRefresh: _loadHome,
      child: ListView(controller: _scrollController, children: widgets),
    );
  }

  Widget _buildAdBanner(int number) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0D9E6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined, color: Color(0xFF2B3A67)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Рекламный блок #$number — партнёры «Я-Город»', style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _AfishaEntry entry;
  const _EventCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final event = entry.event;
    return GestureDetector(
      onTap: () => context.push('/home/event', extra: event),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10)),
              child: event.coverUrl != null
                  ? Image.network(
                      event.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.event, color: Colors.grey),
                    )
                  : const Icon(Icons.event, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(event.venueName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 8),
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
                      const SizedBox(width: 8),
                      Text(
                        entry.periodRangeLabel ?? entry.timeLabel ?? 'Время уточняется',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2B3A67)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

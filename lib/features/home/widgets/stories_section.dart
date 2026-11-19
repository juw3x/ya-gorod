import 'package:flutter/material.dart';
import '../../../data/models/home_models.dart';

class StoriesSection extends StatelessWidget {
  final List<StoryModel> stories;

  const StoriesSection({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 118,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final story = stories[index];
          return GestureDetector(
            onTap: () => _openStoryViewer(context, index),
            child: SizedBox(
              width: 74,
              child: Column(
                children: [
                  Container(
                    width: 74,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: const Icon(Icons.image_outlined, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openStoryViewer(BuildContext context, int initialIndex) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false, // Закрывается только по кнопке закрытия[cite: 12]
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _StoryViewerScreen(
        stories: stories,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const _StoryViewerScreen({required this.stories, required this.initialIndex});

  @override
  State<_StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<_StoryViewerScreen> {
  late int _currentIndex;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _expanded = false;
      });
    }
  }

  void _next() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _expanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      body: SafeArea(
        child: Column(
          children: [
            // Сегментный индикатор[cite: 12]
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: List.generate(widget.stories.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i == _currentIndex ? const Color(0xFF2B3A67) : Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Область медиа с зонами нажатия назад/вперед[cite: 12]
            Expanded(
              child: Stack(
                children: [
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Фото или видео истории', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _prev)),
                      Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _next)),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Нижняя панель описания[cite: 12]
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.shortCaption, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                  if (_expanded && story.fullDescription != null) ...[
                    const SizedBox(height: 8),
                    Text(story.fullDescription!, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (story.fullDescription != null && !_expanded)
                        GestureDetector(
                          onTap: () => setState(() => _expanded = true),
                          child: const Text(
                            'Ещё',
                            style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w500),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Text('${_currentIndex + 1} / ${widget.stories.length}', style: const TextStyle(color: Colors.grey)),
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../data/models/home_models.dart';

class StoriesSection extends StatelessWidget {
  final List<StoryItem> stories;
  const StoriesSection({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final story = stories[index];
          return GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              PageRouteBuilder(
                opaque: false,
                transitionDuration: const Duration(milliseconds: 280),
                reverseTransitionDuration: const Duration(milliseconds: 220),
                pageBuilder: (_, __, ___) => _StoryViewer(stories: stories, initialIndex: index),
                transitionsBuilder: (_, animation, __, child) {
                  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
                      child: child,
                    ),
                  );
                },
              ),
            ),
            child: SizedBox(
              width: 78,
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2B3A67), width: 2),
                    ),
                    child: ClipOval(
                      child: story.previewUrl != null
                          ? CachedNetworkImage(
                              imageUrl: story.previewUrl!,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 180),
                              errorWidget: (_, __, ___) => _fallbackIcon(story.isVideo),
                            )
                          : _fallbackIcon(story.isVideo),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, height: 1.15),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackIcon(bool isVideo) => Container(
        color: const Color(0xFFDCE1EA),
        child: Icon(isVideo ? Icons.play_circle_outline : Icons.auto_awesome, color: const Color(0xFF2B3A67)),
      );
}

class _StoryViewer extends StatefulWidget {
  final List<StoryItem> stories;
  final int initialIndex;
  const _StoryViewer({required this.stories, required this.initialIndex});

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> {
  late int _index;
  bool _isExpanded = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _initMedia();
  }

  Future<void> _initMedia() async {
    await _videoController?.dispose();
    _videoController = null;
    final story = widget.stories[_index];
    if (story.isVideo && story.mediaUrl != null) {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl!));
      _videoController = ctrl;
      try {
        await ctrl.initialize();
        await ctrl.setLooping(false);
        await ctrl.play();
        if (mounted) setState(() {});
      } catch (_) {
        await ctrl.dispose();
        _videoController = null;
      }
    }
  }

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.stories.length) {
      return;
    }
    setState(() {
      _index = next;
      _isExpanded = false;
    });
    _initMedia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_index];
    final fullText = (story.description != null && story.description!.trim().isNotEmpty)
        ? story.description!.trim()
        : story.title;
    final hasLongText = fullText.length > 75 || fullText.contains('\n');

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Медиа (фото или видео)
            Center(
              child: story.isVideo && _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : (story.mediaUrl ?? story.previewUrl) != null
                      ? CachedNetworkImage(
                          imageUrl: (story.mediaUrl ?? story.previewUrl)!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          fadeInDuration: const Duration(milliseconds: 200),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                        )
                      : const Icon(Icons.auto_awesome, color: Colors.white54, size: 48),
            ),

            // Зоны нажатия влево / вправо (работают, когда текст свёрнут)
            if (!_isExpanded)
              Row(
                children: [
                  Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _step(-1))),
                  Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _step(1))),
                ],
              ),

            // Верхний сегментный индикатор и кнопка закрытия
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  Row(
                    children: List.generate(
                      widget.stories.length,
                      (i) => Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i == _index ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Нижний блок с мягким градиентом и плавно раскрывающимся текстом
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.fromLTRB(16, _isExpanded ? 56 : 36, 16, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: _isExpanded ? const [0.0, 0.25, 1.0] : const [0.0, 0.45, 1.0],
                    colors: _isExpanded
                        ? [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.72),
                            Colors.black.withValues(alpha: 0.90),
                          ]
                        : [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.58),
                            Colors.black.withValues(alpha: 0.82),
                          ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.bottomLeft,
                      child: _isExpanded
                          ? ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                              child: SingleChildScrollView(
                                child: Text(
                                  fullText,
                                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
                                ),
                              ),
                            )
                          : Text(
                              fullText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (hasLongText)
                          GestureDetector(
                            onTap: () => setState(() => _isExpanded = !_isExpanded),
                            child: Text(
                              _isExpanded ? 'Свернуть' : 'Ещё',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Text(
                          '${_index + 1} / ${widget.stories.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              MaterialPageRoute(builder: (_) => _StoryViewer(stories: stories, initialIndex: index)),
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
                          ? Image.network(
                              story.previewUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _fallbackIcon(story.isVideo),
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
      Navigator.pop(context);
      return;
    }
    setState(() => _index = next);
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
    Widget content;

    if (story.isVideo && _videoController != null && _videoController!.value.isInitialized) {
      content = AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else if (!story.isVideo && story.mediaUrl != null) {
      content = Image.network(
        story.mediaUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
      );
    } else {
      content = const CircularProgressIndicator(color: Colors.white);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: content),
            Row(
              children: [
                Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _step(-1))),
                Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _step(1))),
              ],
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                  (i) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      color: i <= _index ? Colors.white : Colors.white30,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: Text(story.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

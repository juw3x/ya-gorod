import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/home_models.dart';

class BannerSlider extends StatefulWidget {
  final List<BannerItem> banners;
  const BannerSlider({super.key, required this.banners});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.banners.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_current + 1) % widget.banners.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    });
  }

  void _goToPage(int index) {
    _controller.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 156,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) {
              setState(() => _current = i);
              _startTimer();
            },
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return GestureDetector(
                onTap: banner.targetUrl == null
                    ? null
                    : () => launchUrl(Uri.parse(banner.targetUrl!), mode: LaunchMode.externalApplication),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B3A67), Color(0xFF496A81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (banner.imageUrl != null)
                        Image.network(
                          banner.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(banner.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(banner.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            final active = index == _current;
            return GestureDetector(
              onTap: () => _goToPage(index),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF2B3A67) : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

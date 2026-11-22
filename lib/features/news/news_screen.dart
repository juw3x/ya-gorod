import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../core/utils/scroll_bus.dart';
import '../../data/models/news_model.dart';
import '../../data/repositories/api_repository.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ScrollController _scrollController = ScrollController();
  NewsCategory _selectedFilter = NewsCategory.all;
  int _total = 0;
  int _requestId = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorText;
  List<NewsItem> _loaded = [];

  @override
  void initState() {
    super.initState();
    ScrollBus.newsTop.addListener(_onScrollToTop);
    _fetchNews(reset: true);
  }

  void _onScrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _fetchNews({required bool reset}) async {
    final currentReq = ++_requestId;
    setState(() {
      _errorText = null;
      if (reset) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final page = await ApiRepository.fetchNews(
        category: _selectedFilter,
        offset: reset ? 0 : _loaded.length,
        limit: 20,
      );
      if (!mounted || currentReq != _requestId) return;
      setState(() {
        _total = page.total;
        _loaded = reset ? page.items : [..._loaded, ...page.items];
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || currentReq != _requestId) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorText = 'Ошибка загрузки новостей. Попробуйте ещё раз.';
      });
    }
  }

  @override
  void dispose() {
    ScrollBus.newsTop.removeListener(_onScrollToTop);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _fetchNews(reset: true),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Новости', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Показано ${_loaded.length} из $_total', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildChip(NewsCategory.all, 'Все'),
              _buildChip(NewsCategory.official, 'Официальные'),
              _buildChip(NewsCategory.city, 'Городские'),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_loaded.isEmpty && _errorText == null)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Новостей пока нет', style: TextStyle(color: Colors.grey))))
          else
            ..._loaded.map((item) => _NewsCard(item: item)),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: () => _fetchNews(reset: _loaded.isEmpty), child: const Text('Повторить')),
                ],
              ),
            )
          else if (!_isLoading && _loaded.length < _total)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton(
                onPressed: _isLoadingMore ? null : () => _fetchNews(reset: false),
                child: _isLoadingMore
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Показать еще'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(NewsCategory category, String label) {
    final isSelected = _selectedFilter == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF2B3A67),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onSelected: (_) {
        if (_selectedFilter == category) return;
        setState(() => _selectedFilter = category);
        _fetchNews(reset: true);
      },
    );
  }
}

class _InlineVideoBox extends StatefulWidget {
  final String videoUrl;
  final String? coverUrl;
  final double height;
  const _InlineVideoBox({required this.videoUrl, this.coverUrl, this.height = 200});

  @override
  State<_InlineVideoBox> createState() => _InlineVideoBoxState();
}

class _InlineVideoBoxState extends State<_InlineVideoBox> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized || _controller == null) return;
    setState(() {
      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      if (widget.coverUrl != null && widget.coverUrl!.isNotEmpty) {
        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Image.network(widget.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
        );
      }
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_initialized && _controller != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            else if (widget.coverUrl != null && widget.coverUrl!.isNotEmpty)
              Image.network(widget.coverUrl!, width: double.infinity, height: widget.height, fit: BoxFit.cover)
            else
              const CircularProgressIndicator(color: Colors.white),
            if (!_initialized || !(_controller?.value.isPlaying ?? false))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (item.videoUrl != null && item.videoUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _InlineVideoBox(videoUrl: item.videoUrl!, coverUrl: item.coverUrl, height: 220),
              ),
              const SizedBox(height: 16),
            ] else if (item.coverUrl != null && item.coverUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  item.coverUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                  child: Text(item.categoryLabel, style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Text(item.publishedAtLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (item.content.isNotEmpty && item.content != item.title) ...[
              const SizedBox(height: 12),
              Text(item.content, style: const TextStyle(fontSize: 15, height: 1.45, color: Colors.black87)),
            ],
            if (item.externalUrl.isNotEmpty) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(item.externalUrl), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Открыть в Telegram'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B3A67),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = item.videoUrl != null && item.videoUrl!.isNotEmpty;
    final hasCover = item.coverUrl != null && item.coverUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasVideo)
              _InlineVideoBox(videoUrl: item.videoUrl!, coverUrl: item.coverUrl, height: 190)
            else if (hasCover)
              Image.network(
                item.coverUrl!,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                        child: Text(item.categoryLabel, style: const TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 10),
                      Text(item.publishedAtLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

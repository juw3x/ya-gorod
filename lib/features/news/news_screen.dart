import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(item.externalUrl), mode: LaunchMode.externalApplication),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              color: const Color(0xFFDCE1EA),
              child: item.coverUrl != null
                  ? Image.network(
                      item.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.article_outlined, size: 40, color: Colors.grey),
                    )
                  : const Icon(Icons.article_outlined, size: 40, color: Colors.grey),
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

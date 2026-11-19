import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/news_model.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  NewsCategory _selectedFilter = NewsCategory.all;
  int _visibleCount = 20;

  static const List<NewsItem> _allNews = [
    NewsItem(
      id: 'n1',
      title: 'В городе готовят программу ноябрьских мероприятий',
      category: NewsCategory.official,
      publishedAtLabel: '3 ноября в 11:40',
      externalUrl: 'https://example.com/news/1',
    ),
    NewsItem(
      id: 'n2',
      title: 'В библиотеке пройдёт встреча для всей семьи',
      category: NewsCategory.city,
      publishedAtLabel: '3 ноября в 04:40',
      externalUrl: 'https://example.com/news/2',
    ),
    NewsItem(
      id: 'n3',
      title: 'График работы городских учреждений в праздничные дни',
      category: NewsCategory.official,
      publishedAtLabel: '2 ноября в 21:40',
      externalUrl: 'https://example.com/news/3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == NewsCategory.all
        ? _allNews
        : _allNews.where((n) => n.category == _selectedFilter).toList();
    final displayed = filtered.take(_visibleCount).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Новости', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Показано ${displayed.length} из ${filtered.length}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
        if (displayed.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Новостей пока нет', style: TextStyle(color: Colors.grey))),
          )
        else
          ...displayed.map((item) => _NewsCard(item: item)),
        if (displayed.length < filtered.length)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton(
              onPressed: () => setState(() => _visibleCount += 20),
              child: const Text('Показать еще'),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(NewsCategory category, String label) {
    final isSelected = _selectedFilter == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF2B3A67),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onSelected: (_) => setState(() {
        _selectedFilter = category;
        _visibleCount = 20;
      }),
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0xFFDCE1EA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Center(child: Icon(Icons.article_outlined, size: 40, color: Colors.grey)),
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

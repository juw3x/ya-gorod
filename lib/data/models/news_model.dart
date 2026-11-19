enum NewsCategory { all, official, city }

class NewsItem {
  final String id;
  final String title;
  final NewsCategory category;
  final String publishedAtLabel;
  final String externalUrl;
  final String? coverUrl;

  const NewsItem({
    required this.id,
    required this.title,
    required this.category,
    required this.publishedAtLabel,
    required this.externalUrl,
    this.coverUrl,
  });

  String get categoryLabel => category == NewsCategory.official ? 'Официальные' : 'Городские';
}

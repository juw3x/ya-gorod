import '../../core/network/api_client.dart';

enum NewsCategory { all, official, city }

class NewsItem {
  final String id;
  final String title;
  final String content;
  final NewsCategory category;
  final String publishedAtLabel;
  final String externalUrl;
  final String? coverUrl;
  final String? videoUrl;

  const NewsItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.publishedAtLabel,
    required this.externalUrl,
    this.coverUrl,
    this.videoUrl,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        content: (json['content'] ?? json['description'] ?? json['title'] ?? '').toString(),
        category: json['category'] == 'official' ? NewsCategory.official : NewsCategory.city,
        publishedAtLabel: json['published_at_label'] ?? '',
        externalUrl: json['external_url'] ?? '',
        coverUrl: ApiClient.resolveMediaUrl(json['cover_url']),
        videoUrl: ApiClient.resolveMediaUrl(json['video_url']),
      );

  String get categoryLabel => category == NewsCategory.official ? 'Официальные' : 'Городские';
}

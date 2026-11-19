import '../../core/network/api_client.dart';

class StoryItem {
  final String id;
  final String title;
  final String? previewUrl;
  final String? mediaUrl;
  final bool isVideo;

  const StoryItem({
    required this.id,
    required this.title,
    this.previewUrl,
    this.mediaUrl,
    this.isVideo = false,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) => StoryItem(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        previewUrl: ApiClient.resolveMediaUrl(json['preview_url']),
        mediaUrl: ApiClient.resolveMediaUrl(json['media_url']),
        isVideo: json['is_video'] == true,
      );
}

class BannerItem {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? targetUrl;

  const BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.targetUrl,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        subtitle: json['subtitle'] ?? '',
        imageUrl: ApiClient.resolveMediaUrl(json['image_url']),
        targetUrl: json['target_url'],
      );
}

enum BannerType { info, ad }

class StoryModel {
  final String id;
  final String title;
  final String? coverUrl;
  final String? mediaUrl;
  final bool isVideo;
  final String shortCaption;
  final String? fullDescription;
  final int sortOrder;

  const StoryModel({
    required this.id,
    required this.title,
    this.coverUrl,
    this.mediaUrl,
    this.isVideo = false,
    required this.shortCaption,
    this.fullDescription,
    required this.sortOrder,
  });
}

class BannerModel {
  final String id;
  final BannerType type;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String? linkUrl;
  final int sortOrder;

  const BannerModel({
    required this.id,
    required this.type,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.linkUrl,
    required this.sortOrder,
  });
}
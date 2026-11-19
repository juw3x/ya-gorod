import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/event_model.dart';
import '../models/home_models.dart';
import '../models/news_model.dart';

class HomeData {
  final List<StoryItem> stories;
  final List<BannerItem> banners;
  final List<EventModel> events;

  const HomeData({
    required this.stories,
    required this.banners,
    required this.events,
  });
}

class NewsPage {
  final int total;
  final List<NewsItem> items;

  const NewsPage({required this.total, required this.items});
}

class ApiRepository {
  static Future<HomeData> fetchHome() async {
    final res = await ApiClient.dio.get('/api/home');
    final data = res.data as Map<String, dynamic>;
    return HomeData(
      stories: ((data['stories'] as List?) ?? [])
          .map((e) => StoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      banners: ((data['banners'] as List?) ?? [])
          .map((e) => BannerItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      events: ((data['events'] as List?) ?? [])
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<NewsPage> fetchNews({
    required NewsCategory category,
    required int offset,
    int limit = 20,
  }) async {
    final res = await ApiClient.dio.get(
      '/api/news',
      queryParameters: {
        'category': category.name,
        'offset': offset,
        'limit': limit,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return NewsPage(
      total: (data['total'] as int?) ?? 0,
      items: ((data['items'] as List?) ?? [])
          .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<void> submitProposal({
    required Map<String, dynamic> payload,
    required List<PlatformFile> files,
  }) async {
    final multipartFiles = <MultipartFile>[];
    for (final f in files) {
      if (!kIsWeb && f.path != null) {
        multipartFiles.add(await MultipartFile.fromFile(f.path!, filename: f.name));
      }
    }

    final formData = FormData.fromMap({
      'payload': jsonEncode(payload),
      if (multipartFiles.isNotEmpty) 'files': multipartFiles,
    });

    await ApiClient.dio.post('/api/proposals', data: formData);
  }
}

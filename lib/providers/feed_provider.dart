import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../services/piped_api_service.dart';

class FeedProvider with ChangeNotifier {
  final PipedApiService _api = PipedApiService();

  List<VideoModel> _videos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Gaming',
    'Music',
    'Podcasts',
    'News',
    'Technology',
    'Comedy',
    'Animation',
  ];

  List<VideoModel> get videos => _videos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  FeedProvider() {
    loadFeed();
  }

  Future<void> selectCategory(String category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();

    if (category == 'All') {
      await loadFeed();
    } else {
      await searchCategory(category);
    }
  }

  Future<void> loadFeed() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _api.getTrending();
      _videos = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchCategory(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.search(query, filter: 'videos');
      _videos = List<VideoModel>.from(res['videos'] ?? []);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}


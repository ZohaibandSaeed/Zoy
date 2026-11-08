import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../services/piped_api_service.dart';

class SearchProvider with ChangeNotifier {
  final PipedApiService _api = PipedApiService();

  List<VideoModel> _videos = [];
  List<Map<String, dynamic>> _channels = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _activeFilter = 'all'; // 'all', 'videos', 'channels'

  List<VideoModel> get videos => _videos;
  List<Map<String, dynamic>> get channels => _channels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get activeFilter => _activeFilter;

  void setFilter(String filter, String query) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
    if (query.isNotEmpty) {
      search(query);
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.search(query, filter: _activeFilter);
      _videos = List<VideoModel>.from(res['videos'] ?? []);
      _channels = List<Map<String, dynamic>>.from(res['channels'] ?? []);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clear() {
    _videos = [];
    _channels = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}


import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Video orqa fon uchun Provider
/// Videolarni rotation qilish va vaqtga asoslangan o'zgartirish
class VideoBackgroundProvider extends ChangeNotifier {
  // Asset videolar ro'yxati (keyinchalik Firebase'dan olinadi)
  final List<String> _videoAssets = [
    'assets/videos/background.mp4',
    // Keyinchalik qo'shiladi:
    // 'assets/videos/video_2.mp4',
    // 'assets/videos/video_3.mp4',
  ];

  int _currentVideoIndex = 0;
  Timer? _rotationTimer;
  
  // Rotation sozlamalari
  static const Duration rotationInterval = Duration(hours: 2);
  static const String _lastRotationKey = 'video_last_rotation';
  static const String _currentIndexKey = 'video_current_index';

  int get currentVideoIndex => _currentVideoIndex;
  String get currentVideoPath => _videoAssets[_currentVideoIndex];
  int get totalVideos => _videoAssets.length;

  /// Providerni ishga tushirish
  Future<void> initialize() async {
    await _loadSavedState();
    await _checkAndRotate();
    _startRotationTimer();
  }

  /// Saqlangan holatni yuklash
  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentVideoIndex = prefs.getInt(_currentIndexKey) ?? 0;
      
      // Index chegarasini tekshirish
      if (_currentVideoIndex >= _videoAssets.length) {
        _currentVideoIndex = 0;
      }
    } catch (e) {
      debugPrint('Error loading video state: $e');
    }
  }

  /// Rotation vaqtini tekshirish va kerak bo'lsa o'zgartirish
  Future<void> _checkAndRotate() async {
    if (_videoAssets.length <= 1) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRotation = prefs.getInt(_lastRotationKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Agar vaqt o'tgan bo'lsa, keyingi videoga o'tish
      if (now - lastRotation > rotationInterval.inMilliseconds) {
        await _rotateToNext();
      }
    } catch (e) {
      debugPrint('Error checking rotation: $e');
    }
  }

  /// Keyingi videoga o'tish
  Future<void> _rotateToNext() async {
    _currentVideoIndex = (_currentVideoIndex + 1) % _videoAssets.length;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currentIndexKey, _currentVideoIndex);
      await prefs.setInt(_lastRotationKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving rotation state: $e');
    }
    
    notifyListeners();
  }

  /// Timer'ni boshlash
  void _startRotationTimer() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(rotationInterval, (_) {
      _rotateToNext();
    });
  }

  /// Kun vaqtiga qarab video tanlash (keyinchalik)
  String getVideoForTimeOfDay() {
    final hour = DateTime.now().hour;
    
    if (hour >= 6 && hour < 12) {
      // Ertalab - yorug' videolar
      return _videoAssets[0];
    } else if (hour >= 12 && hour < 18) {
      // Kunduz - faol videolar
      return _videoAssets[_videoAssets.length > 1 ? 1 : 0];
    } else {
      // Kechqurun - elegantlik
      return _videoAssets[_videoAssets.length > 2 ? 2 : 0];
    }
  }

  /// Qo'lda keyingi videoga o'tish (testing uchun)
  void skipToNext() {
    _rotateToNext();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }
}

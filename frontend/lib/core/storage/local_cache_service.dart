import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Ultra-fast local storage cache service for instant cold start (< 50ms)
/// and offline data persistence.
class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final Map<String, dynamic> _memoryCache = {};
  bool _isInitialized = false;

  /// Pre-warms in-memory cache on app launch for zero-latency synchronous reads
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final all = await _storage.readAll();
      for (final entry in all.entries) {
        try {
          _memoryCache[entry.key] = jsonDecode(entry.value);
        } catch (_) {
          _memoryCache[entry.key] = entry.value;
        }
      }
      _isInitialized = true;
      debugPrint('⚡ [LocalCacheService] In-memory cache hydrated with ${_memoryCache.length} keys');
    } catch (e) {
      debugPrint('⚠️ [LocalCacheService] Init warning: $e');
    }
  }

  /// Instant synchronous read from in-memory cache
  T? get<T>(String key) {
    final value = _memoryCache[key];
    if (value is T) return value;
    return null;
  }

  /// Saves data locally to both memory and encrypted disk storage
  Future<void> set(String key, dynamic value) async {
    _memoryCache[key] = value;
    try {
      final jsonStr = jsonEncode(value);
      await _storage.write(key: key, value: jsonStr);
    } catch (e) {
      debugPrint('⚠️ [LocalCacheService] Set write warning: $e');
    }
  }

  /// Removes a cached key
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  /// Clears all local cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  // ──── HELPER METHODS FOR COMMON ENTITIES ──────────────────────────

  /// Save bookmarked reels IDs
  Future<void> saveBookmarkedReel(String reelId, bool isSaved) async {
    final Map<String, dynamic> bookmarks = Map<String, dynamic>.from(get<Map>('bookmarked_reels') ?? {});
    bookmarks[reelId] = isSaved;
    await set('bookmarked_reels', bookmarks);
  }

  /// Get bookmarked reels
  Map<String, bool> getBookmarkedReels() {
    final raw = get<Map>('bookmarked_reels');
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v == true));
  }

  /// Save liked reels
  Future<void> saveLikedReel(String reelId, bool isLiked) async {
    final Map<String, dynamic> likes = Map<String, dynamic>.from(get<Map>('liked_reels') ?? {});
    likes[reelId] = isLiked;
    await set('liked_reels', likes);
  }

  /// Get liked reels
  Map<String, bool> getLikedReels() {
    final raw = get<Map>('liked_reels');
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v == true));
  }
}

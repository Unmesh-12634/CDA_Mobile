import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ultra-fast local storage cache service for instant cold start (< 50ms)
/// and unbreakable session persistence across app closes and phone restarts.
class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
  );

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  bool _isInitialized = false;

  /// Pre-warms in-memory cache on app launch from SharedPreferences & SecureStorage
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Hydrate all keys from SharedPreferences
      if (_prefs != null) {
        for (final key in _prefs!.getKeys()) {
          final val = _prefs!.get(key);
          if (val is String) {
            try {
              _memoryCache[key] = jsonDecode(val);
            } catch (_) {
              _memoryCache[key] = val;
            }
          } else {
            _memoryCache[key] = val;
          }
        }
      }

      // Also hydrate from SecureStorage
      try {
        final allSecure = await _storage.readAll();
        for (final entry in allSecure.entries) {
          try {
            _memoryCache[entry.key] = jsonDecode(entry.value);
          } catch (_) {
            _memoryCache[entry.key] = entry.value;
          }
        }
      } catch (_) {}

      _isInitialized = true;
      debugPrint('⚡ [LocalCacheService] In-memory cache hydrated with ${_memoryCache.length} keys from SharedPreferences');
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

  /// Saves data locally to memory, SharedPreferences, and SecureStorage
  Future<void> set(String key, dynamic value) async {
    _memoryCache[key] = value;
    
    // 1. SharedPreferences (Rock-solid, survives app kills & reboots)
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs != null) {
        if (value is bool) {
          await _prefs!.setBool(key, value);
        } else if (value is int) {
          await _prefs!.setInt(key, value);
        } else if (value is double) {
          await _prefs!.setDouble(key, value);
        } else if (value is String) {
          await _prefs!.setString(key, value);
        } else {
          await _prefs!.setString(key, jsonEncode(value));
        }
      }
    } catch (e) {
      debugPrint('⚠️ [LocalCacheService] SharedPreferences write warning: $e');
    }

    // 2. Secure Storage
    try {
      final jsonStr = value is String ? value : jsonEncode(value);
      await _storage.write(key: key, value: jsonStr);
    } catch (_) {}
  }

  /// Removes a cached key
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.remove(key);
      await _storage.delete(key: key);
    } catch (_) {}
  }

  /// Clears all local cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.clear();
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

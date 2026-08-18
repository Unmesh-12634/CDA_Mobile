import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseStorageService {
  static final SupabaseStorageService _instance = SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  SupabaseClient get _client => SupabaseConfig.client;

  /// Uploads user avatar image to 'avatars' bucket and returns the public URL
  Future<String?> uploadAvatar({
    required String filePath,
    required String userEmail,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('[Storage] Avatar file does not exist: $filePath');
        return null;
      }

      final ext = filePath.split('.').last.toLowerCase();
      final cleanEmail = userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final storagePath = 'avatar_$cleanEmail.$ext';

      debugPrint('[Storage] Uploading avatar to avatars/$storagePath ...');

      // Upload with upsert so subsequent uploads replace the old picture
      await _client.storage.from('avatars').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              cacheControl: '3600',
            ),
          );

      // Get public URL with timestamp cache-buster
      final publicUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
      final cacheBustedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('✅ [Storage] Avatar uploaded successfully: $cacheBustedUrl');
      return cacheBustedUrl;
    } catch (e) {
      debugPrint('❌ [Storage] Avatar upload error: $e');
      return null;
    }
  }

  /// Uploads user resume document (PDF/DOCX) to 'resumes' bucket and returns the public URL
  Future<String?> uploadResume({
    required String filePath,
    required String fileName,
    required String userEmail,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('[Storage] Resume file does not exist: $filePath');
        return null;
      }

      final cleanEmail = userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storagePath = '$cleanEmail/$cleanFileName';

      debugPrint('[Storage] Uploading resume to resumes/$storagePath ...');

      await _client.storage.from('resumes').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              cacheControl: '3600',
            ),
          );

      final publicUrl = _client.storage.from('resumes').getPublicUrl(storagePath);
      debugPrint('✅ [Storage] Resume uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ [Storage] Resume upload error: $e');
      return null;
    }
  }
}

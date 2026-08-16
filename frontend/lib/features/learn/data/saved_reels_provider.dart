import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/network/java_api_service.dart';

class SavedReelsNotifier extends StateNotifier<Set<String>> {
  SavedReelsNotifier() : super(<String>{}) {
    loadSavedReels();
  }

  Future<void> loadSavedReels() async {
    try {
      final res = await SupabaseConfig.client
          .from('saved_reels')
          .select('reel_id');

      if (res.isNotEmpty) {
        final set = res.map((e) => e['reel_id'].toString()).toSet();
        state = set;
        debugPrint('✅ Loaded ${set.length} saved reels from Supabase DB');
      } else {
        state = <String>{};
      }
    } catch (e) {
      debugPrint('Saved reels load notice: $e');
    }
  }

  Future<void> toggleSave(String reelId, {String? userId}) async {
    final effectiveUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : (SupabaseConfig.client.auth.currentUser?.id ?? '7e3f690f-38b7-4bfa-af4f-5afa4b79428f');
    final currentlySaved = state.contains(reelId);

    if (currentlySaved) {
      state = {...state}..remove(reelId);
    } else {
      state = {...state, reelId};
    }

    // 1. Sync with Java Backend
    JavaApiService.toggleSaveReel(reelId: reelId);

    // 2. Sync with Supabase Database
    try {
      if (currentlySaved) {
        await SupabaseConfig.client
            .from('saved_reels')
            .delete()
            .eq('reel_id', reelId);
      } else {
        await SupabaseConfig.client.from('saved_reels').insert({
          'user_id': effectiveUserId,
          'reel_id': reelId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      debugPrint('✅ Synced saved reel state ($reelId: ${!currentlySaved}) to Supabase DB');
    } catch (e) {
      debugPrint('Saved reel toggle error: $e');
    }
  }

  bool isSaved(String reelId) {
    return state.contains(reelId);
  }
}

final savedReelsProvider = StateNotifierProvider<SavedReelsNotifier, Set<String>>((ref) {
  return SavedReelsNotifier();
});

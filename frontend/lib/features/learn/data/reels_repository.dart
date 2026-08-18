import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/network/java_api_service.dart';

class ReelModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int durationSeconds;
  final String category;
  final List<String> tags;
  final String authorName;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;

  const ReelModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.category,
    required this.tags,
    required this.authorName,
    required this.viewsCount,
    required this.likesCount,
    this.commentsCount = 0,
  });

  factory ReelModel.fromMap(Map<String, dynamic> map) {
    final tagsList = (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? ['Tech'];
    return ReelModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Tech Concept in 60s',
      description: map['description']?.toString() ?? '',
      videoUrl: map['videoUrl']?.toString() ?? map['video_url']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? map['thumbnail_url']?.toString() ?? 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=600',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? (map['duration_seconds'] as num?)?.toInt() ?? 60,
      category: map['category']?.toString() ?? 'Engineering',
      tags: tagsList,
      authorName: map['authorName']?.toString() ?? map['author_name']?.toString() ?? 'Senior Mentor',
      viewsCount: (map['viewsCount'] as num?)?.toInt() ?? (map['views_count'] as num?)?.toInt() ?? 0,
      likesCount: (map['likesCount'] as num?)?.toInt() ?? (map['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? (map['comments_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReelCommentModel {
  final String id;
  final String reelId;
  final String userEmail;
  final String userName;
  final String? userAvatar;
  final String comment;
  final DateTime createdAt;

  const ReelCommentModel({
    required this.id,
    required this.reelId,
    required this.userEmail,
    required this.userName,
    this.userAvatar,
    required this.comment,
    required this.createdAt,
  });

  factory ReelCommentModel.fromMap(Map<String, dynamic> map) {
    return ReelCommentModel(
      id: map['id']?.toString() ?? '',
      reelId: map['reel_id']?.toString() ?? '',
      userEmail: map['user_email']?.toString() ?? '',
      userName: map['user_name']?.toString() ?? 'Learner',
      userAvatar: map['user_avatar']?.toString(),
      comment: map['comment']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ReelsRepository {
  /// Fetches Top reels from Java Backend or Supabase PostgreSQL
  Future<List<ReelModel>> fetchTopReels({int limit = 10, String? skill}) async {
    // 1. Try Java Enterprise Backend
    try {
      final javaReels = await JavaApiService.fetchTopReels(limit: limit, skill: skill);
      if (javaReels != null && javaReels.isNotEmpty) {
        debugPrint('✅ Fetched ${javaReels.length} top reels via Java Backend!');
        return javaReels.map((m) => ReelModel.fromMap(m)).take(limit).toList();
      }
    } catch (e) {
      debugPrint('Java backend reels notice: $e');
    }

    // 2. Direct Supabase DB Fallback
    try {
      var query = SupabaseConfig.client
          .from('reels')
          .select('*')
          .eq('is_active', true)
          .order('views_count', ascending: false)
          .limit(limit);

      final response = await query;
      if (response.isNotEmpty) {
        final list = response.map((m) => ReelModel.fromMap(Map<String, dynamic>.from(m))).toList();

        if (skill != null && skill != 'All' && skill.trim().isNotEmpty) {
          final target = skill.trim().toLowerCase();
          final List<ReelModel> filtered = list.where((ReelModel r) {
            final catMatch = r.category.toLowerCase().contains(target);
            final titleMatch = r.title.toLowerCase().contains(target);
            final tagMatch = r.tags.any((String t) => t.toLowerCase().contains(target));
            return catMatch || titleMatch || tagMatch;
          }).toList();
          return (filtered.isNotEmpty ? filtered : list).take(limit).toList();
        }

        return list.take(limit).toList();
      }
    } catch (e) {
      debugPrint('Supabase reels fetch notice: $e');
    }
    return [];
  }

  /// Toggle Like in Database
  Future<bool> toggleLike(String reelId, String userEmail) async {
    try {
      final existing = await SupabaseConfig.client
          .from('reel_likes')
          .select('id')
          .eq('reel_id', reelId)
          .eq('user_email', userEmail);

      if (existing.isNotEmpty) {
        await SupabaseConfig.client
            .from('reel_likes')
            .delete()
            .eq('reel_id', reelId)
            .eq('user_email', userEmail);

        try {
          final cur = await SupabaseConfig.client.from('reels').select('likes_count').eq('id', reelId).maybeSingle();
          final count = (cur?['likes_count'] as num?)?.toInt() ?? 1;
          await SupabaseConfig.client.from('reels').update({'likes_count': count > 0 ? count - 1 : 0}).eq('id', reelId);
        } catch (_) {}
        return false;
      } else {
        await SupabaseConfig.client.from('reel_likes').insert({
          'reel_id': reelId,
          'user_email': userEmail,
          'created_at': DateTime.now().toIso8601String(),
        });

        try {
          final cur = await SupabaseConfig.client.from('reels').select('likes_count').eq('id', reelId).maybeSingle();
          final count = (cur?['likes_count'] as num?)?.toInt() ?? 0;
          await SupabaseConfig.client.from('reels').update({'likes_count': count + 1}).eq('id', reelId);
        } catch (_) {}
        return true;
      }
    } catch (e) {
      debugPrint('toggleLike error: $e');
      return false;
    }
  }

  /// Fetch Comments for Reel
  Future<List<ReelCommentModel>> fetchComments(String reelId) async {
    try {
      final res = await SupabaseConfig.client
          .from('reel_comments')
          .select('*')
          .eq('reel_id', reelId)
          .order('created_at', ascending: false);

      if (res.isNotEmpty) {
        return res.map((m) => ReelCommentModel.fromMap(Map<String, dynamic>.from(m))).toList();
      }
    } catch (e) {
      debugPrint('fetchComments error: $e');
    }
    return [];
  }

  /// Post a new comment
  Future<ReelCommentModel?> postComment({
    required String reelId,
    required String userEmail,
    required String userName,
    String? userAvatar,
    required String comment,
  }) async {
    try {
      final data = {
        'reel_id': reelId,
        'user_email': userEmail,
        'user_name': userName,
        'user_avatar': userAvatar,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      };
      final res = await SupabaseConfig.client.from('reel_comments').insert(data).select().single();
      try {
        final cur = await SupabaseConfig.client.from('reels').select('comments_count').eq('id', reelId).maybeSingle();
        final count = (cur?['comments_count'] as num?)?.toInt() ?? 0;
        await SupabaseConfig.client.from('reels').update({'comments_count': count + 1}).eq('id', reelId);
      } catch (_) {}
      return ReelCommentModel.fromMap(Map<String, dynamic>.from(res));
    } catch (e) {
      debugPrint('postComment error: $e');
      return null;
    }
  }

  /// Delete a user's comment
  Future<bool> deleteComment({
    required String commentId,
    required String reelId,
  }) async {
    try {
      await SupabaseConfig.client
          .from('reel_comments')
          .delete()
          .eq('id', commentId);

      try {
        final cur = await SupabaseConfig.client.from('reels').select('comments_count').eq('id', reelId).maybeSingle();
        final count = (cur?['comments_count'] as num?)?.toInt() ?? 1;
        final newCount = (count > 0) ? count - 1 : 0;
        await SupabaseConfig.client.from('reels').update({'comments_count': newCount}).eq('id', reelId);
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('deleteComment error: $e');
      return false;
    }
  }
}

final reelsRepositoryProvider = Provider<ReelsRepository>((ref) {
  return ReelsRepository();
});

final topReelsProvider = FutureProvider.family<List<ReelModel>, String?>((ref, skill) async {
  final repo = ref.watch(reelsRepositoryProvider);
  return repo.fetchTopReels(limit: 10, skill: skill);
});

final allReelsFeedProvider = FutureProvider<List<ReelModel>>((ref) async {
  final repo = ref.watch(reelsRepositoryProvider);
  return repo.fetchTopReels(limit: 20, skill: null);
});

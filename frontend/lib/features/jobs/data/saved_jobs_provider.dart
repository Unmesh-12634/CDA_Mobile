import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import 'jobs_repository.dart';
import 'mock_jobs.dart';

class SavedJobsNotifier extends StateNotifier<Set<String>> {
  SavedJobsNotifier() : super(<String>{}) {
    loadSavedJobs();
  }

  Future<void> loadSavedJobs() async {
    try {
      final res = await SupabaseConfig.client
          .from('saved_jobs')
          .select('job_id');

      if (res.isNotEmpty) {
        final set = res.map((e) => e['job_id'].toString()).toSet();
        state = set;
        debugPrint('✅ Loaded ${set.length} saved jobs from Supabase DB');
      } else {
        state = <String>{};
      }
    } catch (e) {
      debugPrint('Saved jobs load notice: $e');
    }
  }

  Future<void> toggleSave(String jobId, {String? userId}) async {
    final effectiveUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : (SupabaseConfig.client.auth.currentUser?.id ?? '7e3f690f-38b7-4bfa-af4f-5afa4b79428f');
    final currentlySaved = state.contains(jobId);

    if (currentlySaved) {
      state = {...state}..remove(jobId);
    } else {
      state = {...state, jobId};
    }

    try {
      if (currentlySaved) {
        await SupabaseConfig.client
            .from('saved_jobs')
            .delete()
            .eq('job_id', jobId);
      } else {
        await SupabaseConfig.client.from('saved_jobs').insert({
          'user_id': effectiveUserId,
          'job_id': jobId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      debugPrint('✅ Synced saved job state ($jobId: ${!currentlySaved}) to Supabase DB');
    } catch (e) {
      debugPrint('Saved job toggle error: $e');
    }
  }

  bool isSaved(String jobId) {
    return state.contains(jobId);
  }
}

final savedJobsProvider = StateNotifierProvider<SavedJobsNotifier, Set<String>>((ref) {
  return SavedJobsNotifier();
});

final savedJobListProvider = FutureProvider<List<Job>>((ref) async {
  final savedIds = ref.watch(savedJobsProvider);
  if (savedIds.isEmpty) return <Job>[];

  final repo = ref.watch(jobsRepositoryProvider);
  final allJobs = await repo.fetchJobs();
  return allJobs.where((job) => savedIds.contains(job.id)).toList();
});

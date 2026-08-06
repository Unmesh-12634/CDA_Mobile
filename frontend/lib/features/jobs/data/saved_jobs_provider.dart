import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_jobs.dart';

class SavedJobsNotifier extends StateNotifier<Set<String>> {
  SavedJobsNotifier() : super({'job-101', 'job-103'}); // Default mock saved jobs

  void toggleSave(String jobId) {
    if (state.contains(jobId)) {
      state = {...state}..remove(jobId);
    } else {
      state = {...state, jobId};
    }
  }

  bool isSaved(String jobId) {
    return state.contains(jobId);
  }
}

final savedJobsProvider = StateNotifierProvider<SavedJobsNotifier, Set<String>>((ref) {
  return SavedJobsNotifier();
});

final savedJobListProvider = Provider<List<Job>>((ref) {
  final savedIds = ref.watch(savedJobsProvider);
  return sampleJobs.where((job) => savedIds.contains(job.id)).toList();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_interview_service.dart';
import '../../profile/data/user_profile_provider.dart';

final interviewReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(aiInterviewServiceProvider);
  final profile = ref.watch(userProfileProvider);
  final userEmail = profile.email.isNotEmpty ? profile.email : '';
  if (userEmail.isEmpty) return [];
  return api.fetchInterviewHistory(email: userEmail);
});

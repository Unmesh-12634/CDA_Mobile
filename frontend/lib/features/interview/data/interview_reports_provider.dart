import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_interview_service.dart';
import '../../profile/data/user_profile_provider.dart';

final interviewReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(aiInterviewServiceProvider);
  final profile = ref.watch(userProfileProvider);
  final userEmail = profile.email.isNotEmpty ? profile.email : 'unii12634@gmail.com';
  return api.fetchInterviewHistory(email: userEmail);
});

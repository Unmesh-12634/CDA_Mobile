import 'package:flutter_riverpod/flutter_riverpod.dart';

class InterviewSetupConfig {
  final String candidateName;
  final String jobRole;
  final String experienceLevel;
  final String interviewType;
  final String difficulty;
  final int targetQuestionCount;
  final String voicePersona;
  final double speechRate;
  final List<String> enrolledCourses;
  final List<String> skills;
  final String? resumePath;
  final String? resumeText;
  final String? primarySkillId;
  final String? primarySkillName;
  final String? jobId;
  final String? jobDescriptionText;
  final List<String> jobRequiredSkills;

  const InterviewSetupConfig({
    this.candidateName = '',
    this.jobRole = '',
    this.experienceLevel = 'Mid-Level',
    this.interviewType = 'Technical',
    this.difficulty = 'Intermediate',
    this.targetQuestionCount = 5,
    this.voicePersona = 'christopher',
    this.speechRate = 0.50,
    this.enrolledCourses = const [],
    this.skills = const [],
    this.resumePath,
    this.resumeText,
    this.primarySkillId,
    this.primarySkillName,
    this.jobId,
    this.jobDescriptionText,
    this.jobRequiredSkills = const [],
  });

  InterviewSetupConfig copyWith({
    String? candidateName,
    String? jobRole,
    String? experienceLevel,
    String? interviewType,
    String? difficulty,
    int? targetQuestionCount,
    String? voicePersona,
    double? speechRate,
    List<String>? enrolledCourses,
    List<String>? skills,
    String? resumePath,
    String? resumeText,
    String? primarySkillId,
    String? primarySkillName,
    String? jobId,
    String? jobDescriptionText,
    List<String>? jobRequiredSkills,
  }) {
    return InterviewSetupConfig(
      candidateName: candidateName ?? this.candidateName,
      jobRole: jobRole ?? this.jobRole,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      interviewType: interviewType ?? this.interviewType,
      difficulty: difficulty ?? this.difficulty,
      targetQuestionCount: targetQuestionCount ?? this.targetQuestionCount,
      voicePersona: voicePersona ?? this.voicePersona,
      speechRate: speechRate ?? this.speechRate,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      skills: skills ?? this.skills,
      resumePath: resumePath ?? this.resumePath,
      resumeText: resumeText ?? this.resumeText,
      primarySkillId: primarySkillId ?? this.primarySkillId,
      primarySkillName: primarySkillName ?? this.primarySkillName,
      jobId: jobId ?? this.jobId,
      jobDescriptionText: jobDescriptionText ?? this.jobDescriptionText,
      jobRequiredSkills: jobRequiredSkills ?? this.jobRequiredSkills,
    );
  }
}

class InterviewSetupNotifier extends StateNotifier<InterviewSetupConfig> {
  InterviewSetupNotifier() : super(const InterviewSetupConfig());

  void updateConfig({
    String? candidateName,
    String? jobRole,
    String? experienceLevel,
    String? interviewType,
    String? difficulty,
    int? targetQuestionCount,
    String? voicePersona,
    double? speechRate,
    List<String>? enrolledCourses,
    List<String>? skills,
    String? resumePath,
    String? resumeText,
    String? primarySkillId,
    String? primarySkillName,
    String? jobId,
    String? jobDescriptionText,
    List<String>? jobRequiredSkills,
  }) {
    state = state.copyWith(
      candidateName: candidateName,
      jobRole: jobRole,
      experienceLevel: experienceLevel,
      interviewType: interviewType,
      difficulty: difficulty,
      targetQuestionCount: targetQuestionCount,
      voicePersona: voicePersona,
      speechRate: speechRate,
      enrolledCourses: enrolledCourses,
      skills: skills,
      resumePath: resumePath,
      resumeText: resumeText,
      primarySkillId: primarySkillId,
      primarySkillName: primarySkillName,
      jobId: jobId,
      jobDescriptionText: jobDescriptionText,
      jobRequiredSkills: jobRequiredSkills,
    );
  }
}

final interviewSetupProvider =
    StateNotifierProvider<InterviewSetupNotifier, InterviewSetupConfig>((ref) {
  return InterviewSetupNotifier();
});


import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InterviewTrack {
  skillDrill,       // Focused Single-Skill Deep Dive (e.g. Java Concurrency, Flutter)
  roleMock,         // Standard Role & Seniority Mock (e.g. Full Stack Java Dev)
  customJd,         // Custom Job Description (paste any JD)
  resumeBased,      // Tailored to user profile & uploaded resume projects
  behavioralStar,   // HR / Leadership / Situational STAR format
}

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
  final InterviewTrack track;
  final String targetCompany;
  final String modeId;
  final String modeDisplayName;

  const InterviewSetupConfig({
    this.candidateName = '',
    this.jobRole = 'Full Stack Java Developer',
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
    this.track = InterviewTrack.roleMock,
    this.targetCompany = '',
    this.modeId = 'comprehensive',
    this.modeDisplayName = 'Comprehensive Technical Round',
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
    InterviewTrack? track,
    String? targetCompany,
    String? modeId,
    String? modeDisplayName,
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
      track: track ?? this.track,
      targetCompany: targetCompany ?? this.targetCompany,
      modeId: modeId ?? this.modeId,
      modeDisplayName: modeDisplayName ?? this.modeDisplayName,
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
    InterviewTrack? track,
    String? targetCompany,
    String? modeId,
    String? modeDisplayName,
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
      track: track,
      targetCompany: targetCompany,
      modeId: modeId,
      modeDisplayName: modeDisplayName,
    );
  }

  void reset() {
    state = const InterviewSetupConfig();
  }
}

final interviewSetupProvider =
    StateNotifierProvider<InterviewSetupNotifier, InterviewSetupConfig>((ref) {
  return InterviewSetupNotifier();
});

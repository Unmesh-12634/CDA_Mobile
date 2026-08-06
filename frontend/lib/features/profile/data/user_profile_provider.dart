import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  final String name;
  final String degree;
  final String college;
  final String targetRole;
  final String avatarInitials;
  final String cgpa;
  final int streakDays;
  final bool isCvVerified;
  final List<String> skills;
  final Map<String, double> domainScores;

  const UserProfile({
    required this.name,
    required this.degree,
    required this.college,
    required this.targetRole,
    required this.avatarInitials,
    required this.cgpa,
    required this.streakDays,
    required this.isCvVerified,
    required this.skills,
    required this.domainScores,
  });

  UserProfile copyWith({
    String? name,
    String? degree,
    String? college,
    String? targetRole,
    String? avatarInitials,
    String? cgpa,
    int? streakDays,
    bool? isCvVerified,
    List<String>? skills,
    Map<String, double>? domainScores,
  }) {
    return UserProfile(
      name: name ?? this.name,
      degree: degree ?? this.degree,
      college: college ?? this.college,
      targetRole: targetRole ?? this.targetRole,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      cgpa: cgpa ?? this.cgpa,
      streakDays: streakDays ?? this.streakDays,
      isCvVerified: isCvVerified ?? this.isCvVerified,
      skills: skills ?? this.skills,
      domainScores: domainScores ?? this.domainScores,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier()
      : super(
          const UserProfile(
            name: 'Arjun Verma',
            degree: 'B.Tech CS',
            college: 'IIT Delhi (2021-2025)',
            targetRole: 'Senior AI & Full-Stack Engineer',
            avatarInitials: 'AV',
            cgpa: '8.9',
            streakDays: 12,
            isCvVerified: true,
            skills: ['Python', 'Flutter', 'React', 'System Design', 'AI/ML', 'PostgreSQL'],
            domainScores: {
              'AI / ML Engineering': 0.92,
              'Full-Stack Tech': 0.85,
              'System Architecture': 0.78,
            },
          ),
        );

  void updateProfile({
    String? name,
    String? degree,
    String? college,
    String? targetRole,
    String? cgpa,
  }) {
    final initials = name != null && name.trim().isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .take(2)
            .join()
        : state.avatarInitials;

    state = state.copyWith(
      name: name,
      degree: degree,
      college: college,
      targetRole: targetRole,
      avatarInitials: initials.isEmpty ? 'AV' : initials,
      cgpa: cgpa,
    );
  }

  void addSkill(String skill) {
    if (skill.trim().isEmpty || state.skills.contains(skill.trim())) return;
    state = state.copyWith(skills: [...state.skills, skill.trim()]);
  }

  void removeSkill(String skill) {
    state = state.copyWith(
      skills: state.skills.where((s) => s != skill).toList(),
    );
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});

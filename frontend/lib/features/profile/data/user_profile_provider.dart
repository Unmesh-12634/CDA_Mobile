import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_service.dart';

class UserProfile {
  final String name;
  final String degree;
  final String college;
  final String targetRole;
  final String avatarInitials;
  final String? avatarImagePath;
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
    this.avatarImagePath,
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
    String? avatarImagePath,
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
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
      cgpa: cgpa ?? this.cgpa,
      streakDays: streakDays ?? this.streakDays,
      isCvVerified: isCvVerified ?? this.isCvVerified,
      skills: skills ?? this.skills,
      domainScores: domainScores ?? this.domainScores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'degree': degree,
      'college': college,
      'targetRole': targetRole,
      'avatarInitials': avatarInitials,
      'avatarImagePath': avatarImagePath,
      'cgpa': cgpa,
      'streakDays': streakDays,
      'isCvVerified': isCvVerified,
      'skills': skills,
      'domainScores': domainScores,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'Arjun Verma',
      degree: json['degree'] as String? ?? 'B.Tech CS',
      college: json['college'] as String? ?? 'IIT Delhi (2021-2025)',
      targetRole: json['targetRole'] as String? ?? 'Senior AI & Full-Stack Engineer',
      avatarInitials: json['avatarInitials'] as String? ?? 'AV',
      avatarImagePath: json['avatarImagePath'] as String?,
      cgpa: json['cgpa'] as String? ?? '8.9',
      streakDays: json['streakDays'] as int? ?? 12,
      isCvVerified: json['isCvVerified'] as bool? ?? true,
      skills: List<String>.from(json['skills'] as List? ?? ['Python', 'Flutter', 'React', 'System Design', 'AI/ML', 'PostgreSQL']),
      domainScores: Map<String, double>.from(
        (json['domainScores'] as Map? ?? {
          'AI / ML Engineering': 0.92,
          'Full-Stack Tech': 0.85,
          'System Architecture': 0.78,
        }).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      ),
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final Ref ref;

  UserProfileNotifier(this.ref) : super(_defaultProfile()) {
    _loadProfile();
  }

  static UserProfile _defaultProfile() {
    return const UserProfile(
      name: 'Arjun Verma',
      degree: 'B.Tech CS',
      college: 'IIT Delhi (2021-2025)',
      targetRole: 'Senior AI & Full-Stack Engineer',
      avatarInitials: 'AV',
      avatarImagePath: null,
      cgpa: '8.9',
      streakDays: 12,
      isCvVerified: true,
      skills: ['Python', 'Flutter', 'React', 'System Design', 'AI/ML', 'PostgreSQL'],
      domainScores: {
        'AI / ML Engineering': 0.92,
        'Full-Stack Tech': 0.85,
        'System Architecture': 0.78,
      },
    );
  }

  Future<void> _loadProfile() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.getUserProfile();
      if (raw != null) {
        final Map<String, dynamic> json = jsonDecode(raw);
        state = UserProfile.fromJson(json);
      }
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = jsonEncode(state.toJson());
      await storage.saveUserProfile(raw);
    } catch (_) {}
  }

  Future<void> updateProfile({
    String? name,
    String? degree,
    String? college,
    String? targetRole,
    String? avatarInitials,
    String? avatarImagePath,
    String? cgpa,
  }) async {
    final initials = name != null && name.trim().isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .take(2)
            .join()
        : state.avatarInitials;

    state = state.copyWith(
      name: name ?? state.name,
      degree: degree ?? state.degree,
      college: college ?? state.college,
      targetRole: targetRole ?? state.targetRole,
      avatarInitials: avatarInitials ?? (initials.isEmpty ? 'AV' : initials),
      avatarImagePath: avatarImagePath, // Allow passing null/updated path
      cgpa: cgpa ?? state.cgpa,
    );

    await _saveProfile();
  }

  Future<void> addSkill(String skill) async {
    if (skill.trim().isEmpty || state.skills.contains(skill.trim())) return;
    state = state.copyWith(skills: [...state.skills, skill.trim()]);
    await _saveProfile();
  }

  Future<void> removeSkill(String skill) async {
    state = state.copyWith(
      skills: state.skills.where((s) => s != skill).toList(),
    );
    await _saveProfile();
  }

  Future<void> updateSkills(List<String> newSkills) async {
    state = state.copyWith(
      skills: List<String>.from(newSkills.map((s) => s.trim()).where((s) => s.isNotEmpty)),
    );
    await _saveProfile();
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref);
});

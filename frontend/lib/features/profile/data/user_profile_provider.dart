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
  final String? resumeFileName;
  final String? resumeFilePath;
  final String? resumeUploadedAt;

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
    this.resumeFileName,
    this.resumeFilePath,
    this.resumeUploadedAt,
  });

  UserProfile copyWith({
    String? name,
    String? degree,
    String? college,
    String? targetRole,
    String? avatarInitials,
    String? avatarImagePath,
    bool clearAvatarImagePath = false,
    String? cgpa,
    int? streakDays,
    bool? isCvVerified,
    List<String>? skills,
    Map<String, double>? domainScores,
    String? resumeFileName,
    String? resumeFilePath,
    String? resumeUploadedAt,
    bool clearResume = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      degree: degree ?? this.degree,
      college: college ?? this.college,
      targetRole: targetRole ?? this.targetRole,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarImagePath: clearAvatarImagePath ? null : (avatarImagePath ?? this.avatarImagePath),
      cgpa: cgpa ?? this.cgpa,
      streakDays: streakDays ?? this.streakDays,
      isCvVerified: isCvVerified ?? this.isCvVerified,
      skills: skills ?? this.skills,
      domainScores: domainScores ?? this.domainScores,
      resumeFileName: clearResume ? null : (resumeFileName ?? this.resumeFileName),
      resumeFilePath: clearResume ? null : (resumeFilePath ?? this.resumeFilePath),
      resumeUploadedAt: clearResume ? null : (resumeUploadedAt ?? this.resumeUploadedAt),
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
      'resumeFileName': resumeFileName,
      'resumeFilePath': resumeFilePath,
      'resumeUploadedAt': resumeUploadedAt,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String> parsedSkills = ['Python', 'Flutter', 'React', 'System Design', 'AI/ML', 'PostgreSQL'];
    if (json['skills'] is List) {
      parsedSkills = (json['skills'] as List).map((e) => e.toString()).toList();
    }

    Map<String, double> parsedScores = {
      'AI / ML Engineering': 0.92,
      'Full-Stack Tech': 0.85,
      'System Architecture': 0.78,
    };
    if (json['domainScores'] is Map) {
      try {
        parsedScores = (json['domainScores'] as Map).map(
          (k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 0.8),
        );
      } catch (_) {}
    }

    return UserProfile(
      name: json['name']?.toString() ?? 'Arjun Verma',
      degree: json['degree']?.toString() ?? 'B.Tech CS',
      college: json['college']?.toString() ?? 'IIT Delhi (2021-2025)',
      targetRole: json['targetRole']?.toString() ?? 'Senior AI & Full-Stack Engineer',
      avatarInitials: json['avatarInitials']?.toString() ?? 'AV',
      avatarImagePath: json['avatarImagePath']?.toString(),
      cgpa: json['cgpa']?.toString() ?? '8.9',
      streakDays: int.tryParse(json['streakDays']?.toString() ?? '') ?? 12,
      isCvVerified: json['isCvVerified'] == true,
      skills: parsedSkills,
      domainScores: parsedScores,
      resumeFileName: json['resumeFileName']?.toString(),
      resumeFilePath: json['resumeFilePath']?.toString(),
      resumeUploadedAt: json['resumeUploadedAt']?.toString(),
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
      resumeFileName: null,
      resumeFilePath: null,
      resumeUploadedAt: null,
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
    bool clearAvatarImagePath = false,
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
      avatarImagePath: avatarImagePath,
      clearAvatarImagePath: clearAvatarImagePath,
      cgpa: cgpa ?? state.cgpa,
    );

    await _saveProfile();
  }

  Future<void> setAvatarImagePath(String? path) async {
    if (path == null) {
      state = state.copyWith(clearAvatarImagePath: true);
    } else {
      state = state.copyWith(avatarImagePath: path);
    }
    await _saveProfile();
  }

  Future<void> setResume({
    required String fileName,
    required String filePath,
    String? uploadedAt,
  }) async {
    final timeStr = uploadedAt ?? '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    state = state.copyWith(
      resumeFileName: fileName,
      resumeFilePath: filePath,
      resumeUploadedAt: timeStr,
      isCvVerified: true,
    );
    await _saveProfile();
  }

  Future<void> removeResume() async {
    state = state.copyWith(clearResume: true);
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

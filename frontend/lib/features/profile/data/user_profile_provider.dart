import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/supabase_storage_service.dart';

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String degree;
  final String branch;
  final String college;
  final String yearOfPassing;
  final String targetRole;
  final String aboutSummary;
  final String careerPreference;
  final String targetAnnualPackage;
  final double experienceYears;
  final String githubUrl;
  final String linkedinUrl;
  final String portfolioUrl;
  final bool isEmailVerified;
  final String avatarInitials;
  final String? avatarImagePath;
  final bool isCvVerified;
  final List<String> skills;
  final Map<String, double> domainScores;
  final String? resumeFileName;
  final String? resumeFilePath;
  final String? resumeUrl;
  final String? resumeUploadedAt;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.degree,
    required this.branch,
    required this.college,
    required this.yearOfPassing,
    required this.targetRole,
    required this.aboutSummary,
    required this.careerPreference,
    required this.targetAnnualPackage,
    required this.experienceYears,
    required this.githubUrl,
    required this.linkedinUrl,
    required this.portfolioUrl,
    required this.isEmailVerified,
    required this.avatarInitials,
    this.avatarImagePath,
    required this.isCvVerified,
    required this.skills,
    required this.domainScores,
    this.resumeFileName,
    this.resumeFilePath,
    this.resumeUrl,
    this.resumeUploadedAt,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? degree,
    String? branch,
    String? college,
    String? yearOfPassing,
    String? targetRole,
    String? aboutSummary,
    String? careerPreference,
    String? targetAnnualPackage,
    double? experienceYears,
    String? githubUrl,
    String? linkedinUrl,
    String? portfolioUrl,
    bool? isEmailVerified,
    String? avatarInitials,
    String? avatarImagePath,
    bool clearAvatarImagePath = false,
    bool? isCvVerified,
    List<String>? skills,
    Map<String, double>? domainScores,
    String? resumeFileName,
    String? resumeFilePath,
    String? resumeUrl,
    String? resumeUploadedAt,
    bool clearResume = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      degree: degree ?? this.degree,
      branch: branch ?? this.branch,
      college: college ?? this.college,
      yearOfPassing: yearOfPassing ?? this.yearOfPassing,
      targetRole: targetRole ?? this.targetRole,
      aboutSummary: aboutSummary ?? this.aboutSummary,
      careerPreference: careerPreference ?? this.careerPreference,
      targetAnnualPackage: targetAnnualPackage ?? this.targetAnnualPackage,
      experienceYears: experienceYears ?? this.experienceYears,
      githubUrl: githubUrl ?? this.githubUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarImagePath: clearAvatarImagePath ? null : (avatarImagePath ?? this.avatarImagePath),
      isCvVerified: isCvVerified ?? this.isCvVerified,
      skills: skills ?? this.skills,
      domainScores: domainScores ?? this.domainScores,
      resumeFileName: clearResume ? null : (resumeFileName ?? this.resumeFileName),
      resumeFilePath: clearResume ? null : (resumeFilePath ?? this.resumeFilePath),
      resumeUrl: clearResume ? null : (resumeUrl ?? this.resumeUrl),
      resumeUploadedAt: clearResume ? null : (resumeUploadedAt ?? this.resumeUploadedAt),
    );
  }

  /// Real dynamic profile strength percentage (0.0 to 1.0)
  double get profileStrengthPercentage {
    double score = 0.0;
    // 1. Full name (10%)
    if (name.trim().isNotEmpty) score += 0.10;
    // 2. Email (10%)
    if (email.trim().isNotEmpty) score += 0.10;
    // 3. Phone (10%)
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length >= 10) score += 0.10;
    // 4. Academics (College 5%, Degree 5%, Branch 5% = 15%)
    if (college.trim().isNotEmpty) score += 0.05;
    if (degree.trim().isNotEmpty) score += 0.05;
    if (branch.trim().isNotEmpty) score += 0.05;
    // 5. Target Career Role (15%)
    if (targetRole.trim().isNotEmpty) score += 0.15;
    // 6. Resume / CV Uploaded or Verified (20%)
    final hasResume = (resumeFileName != null && resumeFileName!.trim().isNotEmpty) ||
        (resumeUrl != null && resumeUrl!.trim().isNotEmpty) ||
        (resumeFilePath != null && resumeFilePath!.trim().isNotEmpty) ||
        isCvVerified;
    if (hasResume) score += 0.20;
    // 7. Social / Portfolio (GitHub, LinkedIn, or Portfolio) (10%)
    int socialCount = 0;
    if (githubUrl.trim().isNotEmpty) socialCount++;
    if (linkedinUrl.trim().isNotEmpty) socialCount++;
    if (portfolioUrl.trim().isNotEmpty) socialCount++;
    if (socialCount >= 2) {
      score += 0.10;
    } else if (socialCount == 1) {
      score += 0.05;
    }
    // 8. Core Skills (10%)
    if (skills.length >= 3) {
      score += 0.10;
    } else if (skills.isNotEmpty) {
      score += 0.05;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Dynamic recommendation text based on missing elements
  String get profileStrengthMissingHint {
    final hasResume = (resumeFileName != null && resumeFileName!.trim().isNotEmpty) ||
        (resumeUrl != null && resumeUrl!.trim().isNotEmpty) ||
        (resumeFilePath != null && resumeFilePath!.trim().isNotEmpty) ||
        isCvVerified;
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final hasPhone = cleanPhone.length >= 10;
    final hasSocial = githubUrl.trim().isNotEmpty || linkedinUrl.trim().isNotEmpty || portfolioUrl.trim().isNotEmpty;
    final hasRole = targetRole.trim().isNotEmpty;
    final hasAcademics = college.trim().isNotEmpty && degree.trim().isNotEmpty;
    final hasSkills = skills.length >= 3;

    if (!hasResume) return 'Upload resume to gain +20% strength';
    if (!hasRole) return 'Set target career role (+15%)';
    if (!hasAcademics) return 'Add college & degree details (+10%)';
    if (!hasSkills) return 'Add 3+ core skills (+10%)';
    if (!hasSocial) return 'Link GitHub or LinkedIn (+10%)';
    if (!hasPhone) return 'Add verified phone number (+10%)';
    if (profileStrengthPercentage >= 0.95) return '🎉 All-Star Profile Complete (100%)';
    return 'Complete remaining fields to reach 100%';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'degree': degree,
      'branch': branch,
      'college': college,
      'yearOfPassing': yearOfPassing,
      'targetRole': targetRole,
      'aboutSummary': aboutSummary,
      'careerPreference': careerPreference,
      'targetAnnualPackage': targetAnnualPackage,
      'experienceYears': experienceYears,
      'githubUrl': githubUrl,
      'linkedinUrl': linkedinUrl,
      'portfolioUrl': portfolioUrl,
      'isEmailVerified': isEmailVerified,
      'avatarInitials': avatarInitials,
      'avatarImagePath': avatarImagePath,
      'isCvVerified': isCvVerified,
      'skills': skills,
      'domainScores': domainScores,
      'resumeFileName': resumeFileName,
      'resumeFilePath': resumeFilePath,
      'resumeUrl': resumeUrl,
      'resumeUploadedAt': resumeUploadedAt,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String> parsedSkills = [];
    if (json['skills'] is List) {
      parsedSkills = (json['skills'] as List).map((e) => e.toString()).toList();
    }

    Map<String, double> parsedScores = {};
    if (json['domainScores'] is Map) {
      try {
        parsedScores = (json['domainScores'] as Map).map(
          (k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 0.8),
        );
      } catch (_) {}
    }

    return UserProfile(
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['phone_number']?.toString() ?? '',
      degree: json['degree']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      college: json['college']?.toString() ?? '',
      yearOfPassing: json['yearOfPassing']?.toString() ?? json['year_of_passing']?.toString() ?? '',
      targetRole: json['targetRole']?.toString() ?? json['target_role']?.toString() ?? '',
      aboutSummary: json['aboutSummary']?.toString() ?? json['about_summary']?.toString() ?? '',
      careerPreference: json['careerPreference']?.toString() ?? json['career_preference']?.toString() ?? '',
      targetAnnualPackage: json['targetAnnualPackage']?.toString() ?? json['target_annual_package']?.toString() ?? '',
      experienceYears: double.tryParse(json['experienceYears']?.toString() ?? json['experience_years']?.toString() ?? '0') ?? 0.0,
      githubUrl: json['githubUrl']?.toString() ?? json['github_url']?.toString() ?? '',
      linkedinUrl: json['linkedinUrl']?.toString() ?? json['linkedin_url']?.toString() ?? '',
      portfolioUrl: json['portfolioUrl']?.toString() ?? json['portfolio_url']?.toString() ?? '',
      isEmailVerified: json['isEmailVerified'] == true || json['is_email_verified'] == true,
      avatarInitials: json['avatarInitials']?.toString() ?? '',
      avatarImagePath: json['avatarImagePath']?.toString() ?? json['avatar_url']?.toString(),
      isCvVerified: json['isCvVerified'] == true || (json['resume_url'] != null && json['resume_url'].toString().isNotEmpty),
      skills: parsedSkills,
      domainScores: parsedScores,
      resumeFileName: json['resumeFileName']?.toString(),
      resumeFilePath: json['resumeFilePath']?.toString(),
      resumeUrl: json['resumeUrl']?.toString() ?? json['resume_url']?.toString(),
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
      name: '',
      email: '',
      phone: '',
      degree: '',
      branch: '',
      college: '',
      yearOfPassing: '',
      targetRole: '',
      aboutSummary: '',
      careerPreference: '',
      targetAnnualPackage: '',
      experienceYears: 0.0,
      githubUrl: '',
      linkedinUrl: '',
      portfolioUrl: '',
      isEmailVerified: false,
      avatarInitials: '',
      avatarImagePath: null,
      isCvVerified: false,
      skills: [],
      domainScores: {
        'Frontend Development': 0.85,
        'Backend Engineering': 0.78,
        'System Architecture': 0.70,
        'Database Optimization': 0.82,
        'Mobile App Dev': 0.90,
      },
    );
  }

  Future<void> _loadProfile() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null && user.email != null && user.email!.isNotEmpty) {
        await refreshProfileFromDb(user.email);
        return;
      }
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.getUserProfile();
      if (raw != null) {
        final Map<String, dynamic> json = jsonDecode(raw);
        final loaded = UserProfile.fromJson(json);
        if (loaded.email.isNotEmpty) {
          state = loaded;
        }
      }
    } catch (_) {}
  }

  Future<void> resetForUser(String email, {String? fullName, String? phone, String? targetRole}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return;

    final nameToUse = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : (cleanEmail.contains('@') ? cleanEmail.split('@').first : 'Learner');

    final initials = nameToUse.trim().isNotEmpty
        ? nameToUse.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : (cleanEmail.isNotEmpty ? cleanEmail[0].toUpperCase() : 'U');

    state = UserProfile(
      name: nameToUse,
      email: cleanEmail,
      phone: phone ?? '',
      degree: '',
      branch: '',
      college: '',
      yearOfPassing: '',
      targetRole: targetRole ?? '',
      aboutSummary: '',
      careerPreference: '',
      targetAnnualPackage: '',
      experienceYears: 0.0,
      githubUrl: '',
      linkedinUrl: '',
      portfolioUrl: '',
      isEmailVerified: false,
      avatarInitials: initials,
      avatarImagePath: null,
      isCvVerified: false,
      skills: [],
      domainScores: const {
        'Java & Spring Boot': 0.70,
        'Flutter & Mobile Apps': 0.65,
        'Python, FastAPI & AI/ML': 0.60,
        'System Architecture': 0.55,
        'PostgreSQL & Cloud DBs': 0.50,
      },
    );

    try {
      final storage = ref.read(secureStorageProvider);
      await storage.saveUserProfile(jsonEncode(state.toJson()));
    } catch (_) {}

    await refreshProfileFromDb(cleanEmail);
  }

  Future<void> clearProfile() async {
    state = _defaultProfile();
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.clearAuth();
    } catch (_) {}
  }

  Future<void> refreshProfileFromDb([String? email]) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final targetEmail = (email != null && email.trim().isNotEmpty)
          ? email.trim()
          : (user?.email?.trim().isNotEmpty == true ? user!.email!.trim() : state.email.trim());

      if (targetEmail.isEmpty) return;

      final res = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('email', targetEmail)
          .maybeSingle();

      if (res != null) {
          final dbName = res['full_name']?.toString() ?? state.name;
          final dbEmail = res['email']?.toString() ?? targetEmail;
          final dbPhone = res['phone_number']?.toString() ?? state.phone;
          final dbCollege = res['college']?.toString() ?? state.college;
          final dbDegree = res['degree']?.toString() ?? state.degree;
          final dbBranch = res['branch']?.toString() ?? state.branch;
          final dbRole = res['target_role']?.toString() ?? state.targetRole;
          final dbPkg = res['target_annual_package']?.toString() ?? state.targetAnnualPackage;
          final dbExp = double.tryParse(res['experience_years']?.toString() ?? '') ?? state.experienceYears;
          final dbGithub = res['github_url']?.toString() ?? state.githubUrl;
          final dbLinkedin = res['linkedin_url']?.toString() ?? state.linkedinUrl;
          final dbPortfolio = res['portfolio_url']?.toString() ?? state.portfolioUrl;
          final dbEmailVerified = res['is_email_verified'] == true;

          final dbResumeUrl = res['resume_url']?.toString() ?? state.resumeUrl;
          String? dbResumeFileName = state.resumeFileName;
          if (dbResumeUrl != null && dbResumeUrl.isNotEmpty) {
            final lastPart = dbResumeUrl.split('/').last;
            if (lastPart.isNotEmpty) {
              dbResumeFileName = lastPart;
            }
          }
          final dbAvatar = res['avatar_url']?.toString() ?? state.avatarImagePath;

          final initials = dbName.trim().isNotEmpty
              ? dbName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
              : (dbEmail.isNotEmpty ? dbEmail[0].toUpperCase() : 'UN');

          // Calculate Real Domain Match Scores from database interactions
          final domainMap = <String, double>{
            'Java & Spring Boot': 0.70,
            'Flutter & Mobile Apps': 0.65,
            'Python, FastAPI & AI/ML': 0.60,
            'System Architecture': 0.55,
            'PostgreSQL & Cloud DBs': 0.50,
          };

          try {
            final lowerRole = dbRole.toLowerCase();
            if (lowerRole.contains('java') || lowerRole.contains('backend') || lowerRole.contains('spring')) {
              domainMap['Java & Spring Boot'] = (domainMap['Java & Spring Boot']! + 0.20).clamp(0.0, 0.98);
            }
            if (lowerRole.contains('flutter') || lowerRole.contains('mobile') || lowerRole.contains('dart')) {
              domainMap['Flutter & Mobile Apps'] = (domainMap['Flutter & Mobile Apps']! + 0.22).clamp(0.0, 0.98);
            }
            if (lowerRole.contains('python') || lowerRole.contains('ai') || lowerRole.contains('ml') || lowerRole.contains('data')) {
              domainMap['Python, FastAPI & AI/ML'] = (domainMap['Python, FastAPI & AI/ML']! + 0.20).clamp(0.0, 0.98);
            }

            final interviewReports = await SupabaseConfig.client
                .from('ai_interview_reports')
                .select('target_role, overall_score')
                .eq('user_email', targetEmail);

            if (interviewReports.isNotEmpty) {
              for (final rep in interviewReports) {
                final repRole = (rep['target_role']?.toString() ?? '').toLowerCase();
                final score = (rep['overall_score'] as num?)?.toDouble() ?? 75.0;
                final normalized = (score / 100.0).clamp(0.5, 0.98);

                if (repRole.contains('java') || repRole.contains('spring')) {
                  domainMap['Java & Spring Boot'] = (domainMap['Java & Spring Boot']! * 0.35 + normalized * 0.65).clamp(0.0, 0.98);
                } else if (repRole.contains('flutter') || repRole.contains('mobile')) {
                  domainMap['Flutter & Mobile Apps'] = (domainMap['Flutter & Mobile Apps']! * 0.35 + normalized * 0.65).clamp(0.0, 0.98);
                } else if (repRole.contains('system') || repRole.contains('design') || repRole.contains('architect')) {
                  domainMap['System Architecture'] = (domainMap['System Architecture']! * 0.35 + normalized * 0.65).clamp(0.0, 0.98);
                }
              }
            }
          } catch (_) {}

          final sortedEntries = domainMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top5Domains = Map.fromEntries(sortedEntries.take(5));

          state = state.copyWith(
            name: dbName,
            email: dbEmail,
            phone: dbPhone,
            college: dbCollege,
            degree: dbDegree,
            branch: dbBranch,
            targetRole: dbRole,
            targetAnnualPackage: dbPkg,
            experienceYears: dbExp,
            githubUrl: dbGithub,
            linkedinUrl: dbLinkedin,
            portfolioUrl: dbPortfolio,
            isEmailVerified: dbEmailVerified,
            avatarInitials: initials,
            avatarImagePath: dbAvatar,
            resumeUrl: dbResumeUrl,
            resumeFileName: dbResumeFileName,
            isCvVerified: dbResumeUrl != null && dbResumeUrl.isNotEmpty,
            domainScores: top5Domains,
          );
          debugPrint('✅ Refreshed 100% real profile from Supabase DB for $targetEmail (Resume: $dbResumeFileName, Strength: ${(state.profileStrengthPercentage * 100).toInt()}%)');
        }
    } catch (dbErr) {
      debugPrint('Supabase profile refresh notice: $dbErr');
    }
  }

  Future<void> _saveProfile() async {
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.saveUserProfile(jsonEncode(state.toJson()));

      final user = SupabaseConfig.client.auth.currentUser;
      final targetEmail = user?.email ?? (state.email.isNotEmpty ? state.email : null);

      if (targetEmail != null && targetEmail.isNotEmpty) {
        try {
          final payload = <String, dynamic>{
            'email': targetEmail,
            'username': targetEmail.split('@')[0],
            'full_name': state.name,
            'phone_number': state.phone,
            'college': state.college,
            'degree': state.degree,
            'branch': state.branch,
            'target_role': state.targetRole,
            'target_annual_package': double.tryParse(state.targetAnnualPackage) ?? 0.0,
            'experience_years': state.experienceYears,
            'github_url': state.githubUrl,
            'linkedin_url': state.linkedinUrl,
            'portfolio_url': state.portfolioUrl,
            'resume_url': state.resumeUrl ?? state.resumeFilePath,
            'avatar_url': state.avatarImagePath,
            'profile_strength_score': (state.profileStrengthPercentage * 100).toInt(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          final updateRes = await SupabaseConfig.client
              .from('users')
              .upsert(payload, onConflict: 'email')
              .select();

          debugPrint('✅ Persisted real profile updates to Supabase DB for $targetEmail: $updateRes');
        } catch (dbErr) {
          debugPrint('Supabase profile save notice/error: $dbErr');
        }
      }
    } catch (e) {
      debugPrint('Save profile local error: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? college,
    String? degree,
    String? branch,
    String? yearOfPassing,
    String? targetRole,
    String? aboutSummary,
    String? careerPreference,
    String? targetAnnualPackage,
    double? experienceYears,
    String? githubUrl,
    String? linkedinUrl,
    String? portfolioUrl,
    String? avatarInitials,
    String? avatarImagePath,
    bool clearAvatarImagePath = false,
    String? cgpa,
  }) async {
    await updateFullProfile(
      name: name,
      email: email,
      phone: phone,
      college: college,
      degree: degree,
      branch: branch,
      yearOfPassing: yearOfPassing,
      targetRole: targetRole,
      aboutSummary: aboutSummary,
      careerPreference: careerPreference,
      targetAnnualPackage: targetAnnualPackage,
      experienceYears: experienceYears,
      githubUrl: githubUrl,
      linkedinUrl: linkedinUrl,
      portfolioUrl: portfolioUrl,
      avatarImagePath: avatarImagePath,
      clearAvatarImagePath: clearAvatarImagePath,
    );
  }

  Future<void> updateFullProfile({
    String? name,
    String? email,
    String? phone,
    String? college,
    String? degree,
    String? branch,
    String? yearOfPassing,
    String? targetRole,
    String? aboutSummary,
    String? careerPreference,
    String? targetAnnualPackage,
    double? experienceYears,
    String? githubUrl,
    String? linkedinUrl,
    String? portfolioUrl,
    String? avatarImagePath,
    bool clearAvatarImagePath = false,
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
      email: email ?? state.email,
      phone: phone ?? state.phone,
      college: college ?? state.college,
      degree: degree ?? state.degree,
      branch: branch ?? state.branch,
      yearOfPassing: yearOfPassing ?? state.yearOfPassing,
      targetRole: targetRole ?? state.targetRole,
      aboutSummary: aboutSummary ?? state.aboutSummary,
      careerPreference: careerPreference ?? state.careerPreference,
      targetAnnualPackage: targetAnnualPackage ?? state.targetAnnualPackage,
      experienceYears: experienceYears ?? state.experienceYears,
      githubUrl: githubUrl ?? state.githubUrl,
      linkedinUrl: linkedinUrl ?? state.linkedinUrl,
      portfolioUrl: portfolioUrl ?? state.portfolioUrl,
      avatarInitials: initials,
      avatarImagePath: avatarImagePath,
      clearAvatarImagePath: clearAvatarImagePath,
    );

    await _saveProfile();
  }

  Future<void> updateSkills(List<String> newSkills) async {
    state = state.copyWith(skills: newSkills);
    await _saveProfile();
  }

  Future<void> addSkill(String skill) async {
    final trimmed = skill.trim();
    if (trimmed.isNotEmpty && !state.skills.contains(trimmed)) {
      final updated = List<String>.from(state.skills)..add(trimmed);
      state = state.copyWith(skills: updated);
      await _saveProfile();
    }
  }

  Future<void> removeSkill(String skill) async {
    final updated = List<String>.from(state.skills)..remove(skill);
    state = state.copyWith(skills: updated);
    await _saveProfile();
  }

  Future<void> removeResume() async {
    state = state.copyWith(clearResume: true);
    await _saveProfile();
  }

  Future<void> setResume({required String fileName, required String filePath}) async {
    await setResumeFile(filePath, fileName);
  }

  Future<void> setAvatarImagePath(String? path) async {
    if (path == null) {
      state = state.copyWith(
        avatarImagePath: null,
        clearAvatarImagePath: true,
      );
      await _saveProfile();
      return;
    }

    // Set local path immediately for instantaneous UI feedback
    state = state.copyWith(avatarImagePath: path);

    // Upload to Supabase Storage 'avatars' bucket in background
    if (!path.startsWith('http')) {
      final userEmail = state.email.isNotEmpty ? state.email : (SupabaseConfig.client.auth.currentUser?.email ?? 'user');
      final cloudUrl = await SupabaseStorageService().uploadAvatar(
        filePath: path,
        userEmail: userEmail,
      );
      if (cloudUrl != null) {
        state = state.copyWith(avatarImagePath: cloudUrl);
      }
    }

    await _saveProfile();
  }

  Future<void> setResumeFile(String filePath, String fileName) async {
    // Set immediate state
    state = state.copyWith(
      resumeFileName: fileName,
      resumeFilePath: filePath,
      resumeUrl: filePath,
      resumeUploadedAt: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      isCvVerified: true,
    );

    // Upload to Supabase Storage 'resumes' bucket
    if (!filePath.startsWith('http')) {
      final userEmail = state.email.isNotEmpty ? state.email : (SupabaseConfig.client.auth.currentUser?.email ?? 'user');
      final cloudUrl = await SupabaseStorageService().uploadResume(
        filePath: filePath,
        fileName: fileName,
        userEmail: userEmail,
      );
      if (cloudUrl != null) {
        state = state.copyWith(
          resumeUrl: cloudUrl,
          resumeFilePath: cloudUrl,
        );
      }
    }

    await _saveProfile();
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref);
});

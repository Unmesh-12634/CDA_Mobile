import 'package:flutter/material.dart';

/// Dynamic Job Description / Interview Track Block Model
/// Maps 1-to-1 with database records and backend API /api/v1/interview/blocks
class InterviewBlockModel {
  final String id;
  final String title;
  final String companyName;
  final String description;
  final List<String> requiredSkills;
  final String experienceLevel;
  final String interviewType;
  final String difficulty;
  final int targetQuestionCount;
  final String badgeTag;
  final String iconName;
  final bool isActive;
  final DateTime? createdAt;

  const InterviewBlockModel({
    required this.id,
    required this.title,
    this.companyName = 'Cranes Varsity',
    required this.description,
    this.requiredSkills = const [],
    this.experienceLevel = 'Mid-Level',
    this.interviewType = 'Technical',
    this.difficulty = 'Intermediate',
    this.targetQuestionCount = 5,
    this.badgeTag = 'HOT JD',
    this.iconName = 'code',
    this.isActive = true,
    this.createdAt,
  });

  factory InterviewBlockModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic input) {
      if (input is List) {
        return input.map((e) => e.toString()).toList();
      }
      return [];
    }

    return InterviewBlockModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Software Developer',
      companyName: json['company_name']?.toString() ?? json['companyName']?.toString() ?? 'Cranes Varsity',
      description: json['description']?.toString() ?? '',
      requiredSkills: parseList(json['required_skills'] ?? json['requiredSkills']),
      experienceLevel: json['experience_level']?.toString() ?? json['experienceLevel']?.toString() ?? 'Mid-Level',
      interviewType: json['interview_type']?.toString() ?? json['interviewType']?.toString() ?? 'Technical',
      difficulty: json['difficulty']?.toString() ?? 'Intermediate',
      targetQuestionCount: json['target_question_count'] as int? ?? json['targetQuestionCount'] as int? ?? 5,
      badgeTag: json['badge_tag']?.toString() ?? json['badgeTag']?.toString() ?? 'HOT JD',
      iconName: json['icon_name']?.toString() ?? json['iconName']?.toString() ?? 'code',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company_name': companyName,
      'description': description,
      'required_skills': requiredSkills,
      'experience_level': experienceLevel,
      'interview_type': interviewType,
      'difficulty': difficulty,
      'target_question_count': targetQuestionCount,
      'badge_tag': badgeTag,
      'icon_name': iconName,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Helper to get appropriate Material IconData from string identifier
  IconData get iconData {
    switch (iconName.toLowerCase()) {
      case 'mobile':
      case 'flutter':
      case 'phone':
        return Icons.phone_android_rounded;
      case 'cloud':
      case 'devops':
      case 'aws':
        return Icons.cloud_done_rounded;
      case 'psychology':
      case 'ai':
      case 'ml':
      case 'brain':
        return Icons.psychology_rounded;
      case 'database':
      case 'storage':
      case 'sql':
        return Icons.storage_rounded;
      case 'security':
      case 'lock':
        return Icons.security_rounded;
      case 'terminal':
      case 'backend':
        return Icons.terminal_rounded;
      case 'groups':
      case 'behavioral':
      case 'hr':
        return Icons.groups_rounded;
      case 'code':
      default:
        return Icons.code_rounded;
    }
  }

  InterviewBlockModel copyWith({
    String? id,
    String? title,
    String? companyName,
    String? description,
    List<String>? requiredSkills,
    String? experienceLevel,
    String? interviewType,
    String? difficulty,
    int? targetQuestionCount,
    String? badgeTag,
    String? iconName,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return InterviewBlockModel(
      id: id ?? this.id,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      description: description ?? this.description,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      interviewType: interviewType ?? this.interviewType,
      difficulty: difficulty ?? this.difficulty,
      targetQuestionCount: targetQuestionCount ?? this.targetQuestionCount,
      badgeTag: badgeTag ?? this.badgeTag,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

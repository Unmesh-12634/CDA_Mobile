/// Data models for Database-Driven Interview Profiles, Modes, and Evaluation Matrices.
class InterviewProfile {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<String> requiredSkills;
  final int defaultTurns;
  final String systemPromptContext;
  final List<String> sampleTopics;

  const InterviewProfile({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.requiredSkills,
    this.defaultTurns = 5,
    required this.systemPromptContext,
    this.sampleTopics = const [],
  });

  factory InterviewProfile.fromJson(Map<String, dynamic> json) {
    return InterviewProfile(
      id: json['id'] as String? ?? 'general_tech',
      title: json['title'] as String? ?? 'General Technical Engineer',
      category: json['category'] as String? ?? 'Technical',
      description: json['description'] as String? ?? '',
      requiredSkills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      defaultTurns: json['default_turns'] as int? ?? 5,
      systemPromptContext: json['system_prompt_context'] as String? ?? '',
      sampleTopics: (json['sample_topics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'skills': requiredSkills,
      'default_turns': defaultTurns,
      'system_prompt_context': systemPromptContext,
      'sample_topics': sampleTopics,
    };
  }
}

enum StrictnessLevel { strict, balanced, coaching }

class InterviewMode {
  final String id;
  final String displayName;
  final String subtitle;
  final int questionCount;
  final int timeLimitSeconds;
  final StrictnessLevel strictnessLevel;
  final String evalPromptInstructions;
  final String iconKey;
  final int badgeColorHex;

  const InterviewMode({
    required this.id,
    required this.displayName,
    required this.subtitle,
    required this.questionCount,
    required this.timeLimitSeconds,
    this.strictnessLevel = StrictnessLevel.balanced,
    required this.evalPromptInstructions,
    this.iconKey = 'code',
    this.badgeColorHex = 0xFF0284C7,
  });

  factory InterviewMode.fromJson(Map<String, dynamic> json) {
    StrictnessLevel level = StrictnessLevel.balanced;
    final rawLevel = (json['strictness_level'] as String? ?? '').toLowerCase();
    if (rawLevel == 'strict') level = StrictnessLevel.strict;
    if (rawLevel == 'coaching') level = StrictnessLevel.coaching;

    return InterviewMode(
      id: json['id'] as String? ?? 'comprehensive',
      displayName: json['display_name'] as String? ?? 'Comprehensive Round',
      subtitle: json['subtitle'] as String? ?? 'Balanced technical and conceptual interview',
      questionCount: json['question_count'] as int? ?? 5,
      timeLimitSeconds: json['time_limit_seconds'] as int? ?? 90,
      strictnessLevel: level,
      evalPromptInstructions: json['eval_prompt_instructions'] as String? ?? '',
      iconKey: json['icon_key'] as String? ?? 'code',
      badgeColorHex: json['badge_color_hex'] as int? ?? 0xFF0284C7,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'subtitle': subtitle,
      'question_count': questionCount,
      'time_limit_seconds': timeLimitSeconds,
      'strictness_level': strictnessLevel.name,
      'eval_prompt_instructions': evalPromptInstructions,
      'icon_key': iconKey,
      'badge_color_hex': badgeColorHex,
    };
  }
}

class EvaluationMatrix {
  final double technicalWeight;
  final double edgeCaseWeight;
  final double keywordWeight;
  final double communicationWeight;
  final Map<String, String> criteriaRubrics;

  const EvaluationMatrix({
    this.technicalWeight = 0.35,
    this.edgeCaseWeight = 0.25,
    this.keywordWeight = 0.20,
    this.communicationWeight = 0.20,
    this.criteriaRubrics = const {
      'technical': 'Accuracy of code/architecture explanations and fundamental correctness',
      'edge_cases': 'Handling concurrency, memory leaks, latency, boundary limits',
      'keywords': 'Use of correct industry standard terminology and protocol names',
      'communication': 'Structured thought process, STAR response layout, and confidence',
    },
  });

  factory EvaluationMatrix.fromJson(Map<String, dynamic> json) {
    return EvaluationMatrix(
      technicalWeight: (json['technical_weight'] as num?)?.toDouble() ?? 0.35,
      edgeCaseWeight: (json['edge_case_weight'] as num?)?.toDouble() ?? 0.25,
      keywordWeight: (json['keyword_weight'] as num?)?.toDouble() ?? 0.20,
      communicationWeight: (json['communication_weight'] as num?)?.toDouble() ?? 0.20,
      criteriaRubrics: (json['criteria_rubrics'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'technical_weight': technicalWeight,
      'edge_case_weight': edgeCaseWeight,
      'keyword_weight': keywordWeight,
      'communication_weight': communicationWeight,
      'criteria_rubrics': criteriaRubrics,
    };
  }
}

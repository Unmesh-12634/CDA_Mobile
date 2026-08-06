/// User Profile Model matching `public.edu_user` Supabase table
class UserProfile {
  final String id;
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String role;
  final String avatarUrl;
  final String bio;
  final String timezone;
  final String preferredLang;
  final String? phoneNumber;
  final bool isSuperuser;
  final bool isStaff;
  final bool isActive;
  final bool isEmailVerified;
  final String? degree;
  final String? branch;
  final String? college;
  final String? roll;
  final DateTime? dateJoined;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final DateTime? lastSeenAt;
  final int coursesEnrolled;
  final int coursesCompleted;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStreakDate;
  final int totalActiveSeconds;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.password = '',
    required this.firstName,
    required this.lastName,
    this.role = 'student',
    this.avatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
    this.bio = 'Passionate Embedded Systems and Software Engineering Student.',
    this.timezone = 'Asia/Kolkata',
    this.preferredLang = 'en-US',
    this.phoneNumber = '+91 98765 43210',
    this.isSuperuser = false,
    this.isStaff = false,
    this.isActive = true,
    this.isEmailVerified = true,
    this.degree = 'B.E / B.Tech',
    this.branch = 'Electronics & Communication (ECE)',
    this.college = 'Cranes Institute of Technology',
    this.roll = 'CIT2024-ECE042',
    this.dateJoined,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.lastSeenAt,
    this.coursesEnrolled = 4,
    this.coursesCompleted = 2,
    this.currentStreak = 7,
    this.longestStreak = 14,
    this.lastStreakDate,
    this.totalActiveSeconds = 48500,
  });

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? degree,
    String? branch,
    String? college,
    String? roll,
    String? bio,
    String? avatarUrl,
    String? timezone,
    String? preferredLang,
  }) {
    return UserProfile(
      id: id,
      username: username,
      email: email ?? this.email,
      password: password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      timezone: timezone ?? this.timezone,
      preferredLang: preferredLang ?? this.preferredLang,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isSuperuser: isSuperuser,
      isStaff: isStaff,
      isActive: isActive,
      isEmailVerified: isEmailVerified,
      degree: degree ?? this.degree,
      branch: branch ?? this.branch,
      college: college ?? this.college,
      roll: roll ?? this.roll,
      dateJoined: dateJoined,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLogin: lastLogin,
      lastSeenAt: lastSeenAt,
      coursesEnrolled: coursesEnrolled,
      coursesCompleted: coursesCompleted,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastStreakDate: lastStreakDate,
      totalActiveSeconds: totalActiveSeconds,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      avatarUrl: json['avatar_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      preferredLang: json['preferred_lang'] as String? ?? 'en-US',
      phoneNumber: json['phone_number'] as String?,
      isSuperuser: json['is_superuser'] as bool? ?? false,
      isStaff: json['is_staff'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isEmailVerified: json['is_email_verified'] as bool? ?? true,
      degree: json['degree'] as String?,
      branch: json['branch'] as String?,
      college: json['college'] as String?,
      roll: json['roll'] as String?,
      dateJoined: json['date_joined'] != null ? DateTime.tryParse(json['date_joined'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      lastLogin: json['last_login'] != null ? DateTime.tryParse(json['last_login'] as String) : null,
      lastSeenAt: json['last_seen_at'] != null ? DateTime.tryParse(json['last_seen_at'] as String) : null,
      coursesEnrolled: json['courses_enrolled'] as int? ?? 0,
      coursesCompleted: json['courses_completed'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastStreakDate: json['last_streak_date'] != null ? DateTime.tryParse(json['last_streak_date'] as String) : null,
      totalActiveSeconds: json['total_active_seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'avatar_url': avatarUrl,
      'bio': bio,
      'timezone': timezone,
      'preferred_lang': preferredLang,
      'phone_number': phoneNumber,
      'is_superuser': isSuperuser,
      'is_staff': isStaff,
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
      'degree': degree,
      'branch': branch,
      'college': college,
      'roll': roll,
      'date_joined': dateJoined?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'courses_enrolled': coursesEnrolled,
      'courses_completed': coursesCompleted,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_streak_date': lastStreakDate?.toIso8601String(),
      'total_active_seconds': totalActiveSeconds,
    };
  }
}

/// Course Model matching `public.edu_course` Supabase table
class Course {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String shortDescription;
  final String thumbnailUrl;
  final String language;
  final String difficulty;
  final double price;
  final bool isFree;
  final String? targetAudience;
  final String? learningMode;
  final String prerequisites;
  final String whyThisCourse;
  final String learningOutcomes;
  final String certificationInfo;
  final String industryDemand;
  final String careerOpportunities;
  final String industryRelevance;
  final String shortNote;
  final List<Map<String, dynamic>> curriculum;
  final List<String> careerPaths;
  final String status;
  final DateTime? publishedAt;
  final int totalLessons;
  final int estimatedDurationMinutes;
  final int enrolledCount;
  final int completionCount;
  final String? instructorId;
  final String instructorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Course({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.shortDescription,
    required this.thumbnailUrl,
    this.language = 'en-US',
    required this.difficulty,
    this.price = 0.0,
    this.isFree = false,
    this.targetAudience = 'Engineering & Tech Students',
    this.learningMode = 'Hybrid / Interactive Labs',
    required this.prerequisites,
    required this.whyThisCourse,
    required this.learningOutcomes,
    required this.certificationInfo,
    required this.industryDemand,
    required this.careerOpportunities,
    required this.industryRelevance,
    required this.shortNote,
    this.curriculum = const [],
    this.careerPaths = const [],
    this.status = 'PUBLISHED',
    this.publishedAt,
    required this.totalLessons,
    this.estimatedDurationMinutes = 7200,
    required this.enrolledCount,
    this.completionCount = 0,
    this.instructorId,
    this.instructorName = 'Cranes Senior Faculty',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      language: json['language'] as String? ?? 'en-US',
      difficulty: json['difficulty'] as String? ?? 'INTERMEDIATE',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isFree: json['is_free'] as bool? ?? false,
      targetAudience: json['target_audience'] as String?,
      learningMode: json['learning_mode'] as String?,
      prerequisites: json['prerequisites'] as String? ?? '',
      whyThisCourse: json['why_this_course'] as String? ?? '',
      learningOutcomes: json['learning_outcomes'] as String? ?? '',
      certificationInfo: json['certification_info'] as String? ?? '',
      industryDemand: json['industry_demand'] as String? ?? '',
      careerOpportunities: json['career_opportunities'] as String? ?? '',
      industryRelevance: (json['Industry_relevance'] ?? json['industry_relevance']) as String? ?? '',
      shortNote: json['short_note'] as String? ?? '',
      curriculum: json['curriculum'] != null ? List<Map<String, dynamic>>.from(json['curriculum'] as List) : const [],
      careerPaths: json['career_paths'] != null ? List<String>.from(json['career_paths'] as List) : const [],
      status: json['status'] as String? ?? 'PUBLISHED',
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
      totalLessons: json['total_lessons'] as int? ?? 0,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int? ?? 0,
      enrolledCount: json['enrolled_count'] as int? ?? 0,
      completionCount: json['completion_count'] as int? ?? 0,
      instructorId: json['instructor_id'] as String?,
      instructorName: json['instructor_name'] as String? ?? 'Cranes Senior Faculty',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'thumbnail_url': thumbnailUrl,
      'language': language,
      'difficulty': difficulty,
      'price': price,
      'is_free': isFree,
      'target_audience': targetAudience,
      'learning_mode': learningMode,
      'prerequisites': prerequisites,
      'why_this_course': whyThisCourse,
      'learning_outcomes': learningOutcomes,
      'certification_info': certificationInfo,
      'industry_demand': industryDemand,
      'career_opportunities': careerOpportunities,
      'Industry_relevance': industryRelevance,
      'short_note': shortNote,
      'curriculum': curriculum,
      'career_paths': careerPaths,
      'status': status,
      'published_at': publishedAt?.toIso8601String(),
      'total_lessons': totalLessons,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'enrolled_count': enrolledCount,
      'completion_count': completionCount,
      'instructor_id': instructorId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

/// Course Module Model matching `edu_module`
class ModuleModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int order;
  final List<LessonModel> lessons;

  const ModuleModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.order,
    required this.lessons,
  });
}

/// Lesson Model matching `edu_lesson`
class LessonModel {
  final String id;
  final String moduleId;
  final String title;
  final String lessonType; // 'video', 'document', 'quiz'
  final int order;
  final String description;
  final String videoUrl;
  final int durationSeconds;
  final String documentUrl;
  final String textContent;
  final bool isCompleted;

  const LessonModel({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.lessonType,
    required this.order,
    required this.description,
    required this.videoUrl,
    required this.durationSeconds,
    required this.documentUrl,
    required this.textContent,
    this.isCompleted = false,
  });

  LessonModel copyWith({bool? isCompleted}) {
    return LessonModel(
      id: id,
      moduleId: moduleId,
      title: title,
      lessonType: lessonType,
      order: order,
      description: description,
      videoUrl: videoUrl,
      durationSeconds: durationSeconds,
      documentUrl: documentUrl,
      textContent: textContent,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Q&A Comment Model matching `edu_discussioncomment`
class DiscussionComment {
  final String id;
  final String lessonId;
  final String authorName;
  final String authorAvatar;
  final String body;
  final DateTime createdAt;

  const DiscussionComment({
    required this.id,
    required this.lessonId,
    required this.authorName,
    required this.authorAvatar,
    required this.body,
    required this.createdAt,
  });
}

/// Job Opening & Company Models matching `edu_jobopening`, `edu_jobrole`, `edu_company`
class Company {
  final String id;
  final String name;
  final String logoUrl;
  final String location;
  final String website;

  const Company({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.location,
    required this.website,
  });
}

class JobRole {
  final String id;
  final String title;
  final String description;
  final String requiredSkills;
  final String salaryRange;
  final String demandLevel; // 'High Demand', 'Very High', 'Critical'

  const JobRole({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredSkills,
    required this.salaryRange,
    required this.demandLevel,
  });
}

class JobOpening {
  final String id;
  final Company company;
  final JobRole role;
  final String location;
  final String jobType; // 'Full-Time', 'Internship', 'Contract'
  final String experienceRequired;
  final String description;
  final DateTime postedDate;
  final bool isSaved;

  const JobOpening({
    required this.id,
    required this.company,
    required this.role,
    required this.location,
    required this.jobType,
    required this.experienceRequired,
    required this.description,
    required this.postedDate,
    this.isSaved = false,
  });

  JobOpening copyWith({bool? isSaved}) {
    return JobOpening(
      id: id,
      company: company,
      role: role,
      location: location,
      jobType: jobType,
      experienceRequired: experienceRequired,
      description: description,
      postedDate: postedDate,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

/// Technical Mock Interview Question Model matching `edu_interviewmcqquestion`
class MockInterviewQuestion {
  final String id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption; // 'A', 'B', 'C', 'D'
  final String explanation;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final String topic;
  final bool isBookmarked;

  const MockInterviewQuestion({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    required this.explanation,
    required this.difficulty,
    required this.topic,
    this.isBookmarked = false,
  });

  MockInterviewQuestion copyWith({bool? isBookmarked}) {
    return MockInterviewQuestion(
      id: id,
      question: question,
      optionA: optionA,
      optionB: optionB,
      optionC: optionC,
      optionD: optionD,
      correctOption: correctOption,
      explanation: explanation,
      difficulty: difficulty,
      topic: topic,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

/// DIY Hardware/Software Project Challenge Model matching `edu_doityourselfquestion`
class DiyProjectQuestion {
  final String id;
  final String title;
  final String course;
  final String topic;
  final String hardwareRequired;
  final String difficulty;
  final String abstractText;
  final String problemStatement;
  final String constraints;
  final String expectedOutput;

  const DiyProjectQuestion({
    required this.id,
    required this.title,
    required this.course,
    required this.topic,
    required this.hardwareRequired,
    required this.difficulty,
    required this.abstractText,
    required this.problemStatement,
    required this.constraints,
    required this.expectedOutput,
  });
}

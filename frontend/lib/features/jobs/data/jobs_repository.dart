import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import 'mock_jobs.dart';

import '../../../core/network/java_api_service.dart';

class JobsRepository {
  /// Fetches real job postings directly via Java Backend or Supabase `jobs` table.
  Future<List<Job>> fetchJobs({String? category, String? searchQuery}) async {
    // 1. Try Java Enterprise Backend
    try {
      final javaJobs = await JavaApiService.fetchJobs(category: category, query: searchQuery);
      if (javaJobs != null && javaJobs.isNotEmpty) {
        debugPrint('✅ Fetched ${javaJobs.length} real jobs via Java Backend Service!');
        return javaJobs.map((map) {
          final tagsList = (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? ['Tech'];
          return Job(
            id: map['id']?.toString() ?? 'job-${DateTime.now().millisecondsSinceEpoch}',
            title: map['title']?.toString() ?? 'Software Engineer',
            company: map['company']?.toString() ?? 'Tech Partner',
            location: map['location']?.toString() ?? 'Remote',
            type: map['type']?.toString() ?? 'Full-time',
            salary: map['salary']?.toString() ?? '\$120,000 / yr',
            logoText: map['logoText']?.toString() ?? 'CD',
            category: map['category']?.toString() ?? 'Tech',
            matchScore: (map['matchScore'] as num?)?.toInt() ?? 92,
            postedAgo: map['postedAgo']?.toString() ?? 'Recently posted',
            experienceLevel: map['experienceLevel']?.toString() ?? 'All Levels',
            description: map['description']?.toString() ?? 'Exciting role for passionate engineers.',
            responsibilities: (map['responsibilities'] as List?)?.map((e) => e.toString()).toList() ?? const [
              'Architect and deliver scalable software systems',
              'Maintain clean, performant, and well-tested code'
            ],
            requirements: (map['requirements'] as List?)?.map((e) => e.toString()).toList() ?? const [
              'Strong technical fundamentals & domain expertise',
              'Experience working in modern product environments'
            ],
            tags: tagsList,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Java backend fetch jobs notice: $e');
    }

    // 2. Direct Supabase DB Fallback
    try {
      final client = SupabaseConfig.client;
      var query = client.from('jobs').select('*');

      if (category != null && category != 'All') {
        if (category == 'Remote') {
          query = query.or('work_mode.ilike.%remote%,location.ilike.%remote%');
        } else if (category == 'Full-time') {
          query = query.ilike('job_type', '%full-time%');
        } else if (category == 'Internship') {
          query = query.ilike('job_type', '%intern%');
        } else {
          query = query.ilike('job_category', '%$category%');
        }
      }

      final response = await query.order('created_at', ascending: false);

      if (response.isNotEmpty) {
        debugPrint('✅ Fetched ${response.length} real job listings from Supabase DB!');
        return response.map((item) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(item);
          final companyName = map['company_name']?.toString() ?? 'Tech Partner';
          final logoText = companyName.isNotEmpty
              ? companyName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
              : 'JO';

          final tagsList = (map['required_skills'] as List?)?.map((e) => e.toString()).toList() ??
              ['Tech', 'Full-Time'];

          return Job(
            id: map['id']?.toString() ?? 'job-${DateTime.now().millisecondsSinceEpoch}',
            title: map['title']?.toString() ?? 'Software Engineer',
            company: companyName,
            location: map['location']?.toString() ?? 'Remote • Global',
            type: map['job_type']?.toString() ?? map['work_mode']?.toString() ?? 'Full-time',
            salary: map['salary_display']?.toString() ?? '\$120,000 - \$160,000 / yr',
            logoText: logoText.isEmpty ? 'CD' : logoText,
            category: map['job_category']?.toString() ?? 'Tech',
            matchScore: 94,
            postedAgo: 'Recently posted',
            experienceLevel: 'Mid-Senior',
            description: map['description']?.toString() ?? 'Exciting role for passionate engineers.',
            responsibilities: const [
              'Architect and deliver scalable software systems',
              'Collaborate across product and design teams',
              'Maintain clean, performant, and well-tested code'
            ],
            requirements: const [
              'Strong technical fundamentals & domain expertise',
              'Experience working in modern product environments',
              'Proven track record of high-quality software delivery'
            ],
            tags: tagsList,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Jobs DB fetch error: $e');
    }
    return [];
  }

  /// Fetches distinct trending skills dynamically from active jobs in DB
  Future<List<String>> fetchTrendingSkills() async {
    // 1. Try Java Backend
    try {
      final skills = await JavaApiService.fetchTrendingSkills();
      if (skills != null && skills.isNotEmpty) {
        return skills;
      }
    } catch (_) {}

    // 2. Direct Supabase DB Fallback
    try {
      final res = await SupabaseConfig.client
          .from('jobs')
          .select('required_skills')
          .eq('is_active', true);

      final Set<String> uniqueSkills = {'All'};
      for (final item in res) {
        if (item['required_skills'] is List) {
          for (final s in item['required_skills'] as List) {
            final str = s.toString().trim();
            if (str.isNotEmpty) uniqueSkills.add(str);
          }
        }
      }
      return uniqueSkills.toList();
    } catch (_) {
      return ['All', 'Python', 'Flutter', 'PostgreSQL', 'PyTorch', 'UI/UX', 'Java', 'React'];
    }
  }

  /// Submits a job application to Supabase `job_applications` table
  Future<bool> applyForJob({
    required String jobId,
    required String userEmail,
    String? resumeUrl,
  }) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final email = userEmail.trim().isNotEmpty ? userEmail.trim() : 'unii12634@gmail.com';
      final userId = user?.id ?? '7e3f690f-38b7-4bfa-af4f-5afa4b79428f';

      final payload = {
        'job_id': jobId,
        'user_id': userId,
        'applicant_email': email,
        'resume_url': resumeUrl,
        'status': 'Applied',
        'applied_at': DateTime.now().toIso8601String(),
      };

      await SupabaseConfig.client.from('job_applications').insert(payload);
      debugPrint('✅ Applied for job $jobId in Supabase DB for $email!');
      return true;
    } catch (e) {
      debugPrint('Apply job error: $e');
      return false;
    }
  }

  /// Fetches candidate's active job applications from Supabase `job_applications` table
  Future<List<Map<String, dynamic>>> fetchUserApplications({String? userEmail}) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final email = (userEmail != null && userEmail.trim().isNotEmpty)
          ? userEmail.trim()
          : (user?.email ?? 'unii12634@gmail.com');
      final userId = user?.id ?? '7e3f690f-38b7-4bfa-af4f-5afa4b79428f';

      final response = await SupabaseConfig.client
          .from('job_applications')
          .select('*, jobs(*)')
          .or('applicant_email.eq.$email,user_id.eq.$userId')
          .order('applied_at', ascending: false);

      if (response.isNotEmpty) {
        return response.map((item) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(item);
          final jobMap = map['jobs'] as Map<String, dynamic>? ?? {};
          final company = jobMap['company_name']?.toString() ?? 'Tech Partner';
          final title = jobMap['title']?.toString() ?? 'Software Position';
          final location = jobMap['location']?.toString() ?? 'Remote';
          final salary = jobMap['salary_display']?.toString() ?? '\$120,000 / yr';

          final logoText = company.isNotEmpty
              ? company.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
              : 'JO';

          return {
            'id': map['id']?.toString() ?? 'app-${map['job_id']}',
            'job_id': map['job_id']?.toString(),
            'title': title,
            'company': company,
            'logoText': logoText,
            'location': location,
            'salary': salary,
            'appliedDate': map['applied_at'] != null ? 'Applied ${map['applied_at'].toString().split('T')[0]}' : 'Recently applied',
            'status': map['status']?.toString() ?? 'Applied',
            'resume_url': map['resume_url'],
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Fetch user applications error: $e');
    }
    return [];
  }

  /// Updates application status in Supabase `job_applications` table
  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String newStatus,
  }) async {
    try {
      await SupabaseConfig.client
          .from('job_applications')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId);

      debugPrint('✅ Updated application $applicationId status to $newStatus in Supabase DB!');
      return true;
    } catch (e) {
      debugPrint('Update application status error: $e');
      return false;
    }
  }
}

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository();
});

final realJobsListProvider = FutureProvider.family<List<Job>, String?>((ref, category) async {
  final repo = ref.watch(jobsRepositoryProvider);
  return repo.fetchJobs(category: category);
});

final userApplicationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, email) async {
  final repo = ref.watch(jobsRepositoryProvider);
  return repo.fetchUserApplications(userEmail: email);
});

final appliedJobIdsProvider = FutureProvider.family<Set<String>, String?>((ref, email) async {
  final apps = await ref.watch(userApplicationsProvider(email).future);
  return apps.map((a) => a['job_id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
});

final trendingSkillsListProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(jobsRepositoryProvider);
  return repo.fetchTrendingSkills();
});

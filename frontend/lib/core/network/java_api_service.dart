import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Java Backend API Service
/// Connects Flutter mobile app to Java (Spring Boot 3-Tier Enterprise + JDBC) backend server.
class JavaApiService {
  // Supports local machine, Android emulator, and network interfaces
  static const String baseUrl = 'http://localhost:8080/api/v1';

  /// Check if Java backend is running
  static Future<bool> isJavaBackendOnline() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/jobs'))
          .timeout(const Duration(milliseconds: 1500));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── USER PROFILE ───────────────────────────────────────────
  static Future<Map<String, dynamic>?> fetchUserProfile(String email) async {
    try {
      final url = Uri.parse('$baseUrl/profile?email=$email');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          debugPrint('✅ Fetched profile via Java Backend!');
          return json['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Java backend profile notice: $e');
    }
    return null;
  }

  static Future<bool> saveUserProfile(Map<String, dynamic> profileData) async {
    try {
      final url = Uri.parse('$baseUrl/profile');
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(profileData),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (e) {
      debugPrint('Java backend save profile error: $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>?> fetchProfileAnalytics(String email) async {
    try {
      final url = Uri.parse('$baseUrl/profile/analytics?email=$email');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          debugPrint('✅ Fetched profile analytics via Java Backend!');
          return json['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Java backend profile analytics notice: $e');
    }
    return null;
  }

  // ── 7-DAY PROGRESS & STREAK ────────────────────────────────
  static Future<Map<String, dynamic>?> fetchProgress(String email) async {
    try {
      final url = Uri.parse('$baseUrl/progress?email=$email');
      final res = await http.get(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          debugPrint('✅ Fetched 7-day progress via Java Backend!');
          return json['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Java backend progress notice: $e');
    }
    return null;
  }

  static Future<bool> completeTodayProgress(String email) async {
    try {
      final url = Uri.parse('$baseUrl/progress/complete-today?email=$email');
      final res = await http.post(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (e) {
      debugPrint('Java backend complete today error: $e');
    }
    return false;
  }

  // ── SUBSCRIPTION & AI TRIALS ───────────────────────────────
  static Future<Map<String, dynamic>?> fetchSubscription(String email) async {
    try {
      final url = Uri.parse('$baseUrl/subscription?email=$email');
      final res = await http.get(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          debugPrint('✅ Fetched subscription via Java Backend!');
          return json['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Java backend subscription notice: $e');
    }
    return null;
  }

  static Future<bool> consumeTrial(String email) async {
    try {
      final url = Uri.parse('$baseUrl/subscription/consume-trial?email=$email');
      final res = await http.post(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (e) {
      debugPrint('Java backend consume trial error: $e');
    }
    return false;
  }

  static Future<bool> upgradeToPro(String email, {String planCycle = '1_month'}) async {
    try {
      final url = Uri.parse('$baseUrl/subscription/upgrade-pro?email=${Uri.encodeComponent(email)}&planCycle=${Uri.encodeComponent(planCycle)}');
      final res = await http.post(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (e) {
      debugPrint('Java backend upgrade pro error: $e');
    }
    return false;
  }

  // ── JOBS & APPLICATIONS ────────────────────────────────────
  static Future<List<Map<String, dynamic>>?> fetchJobs({String? category, String? query}) async {
    try {
      String urlStr = '$baseUrl/jobs';
      final params = <String>[];
      if (category != null && category.isNotEmpty) params.add('category=${Uri.encodeComponent(category)}');
      if (query != null && query.isNotEmpty) params.add('query=${Uri.encodeComponent(query)}');
      if (params.isNotEmpty) urlStr += '?${params.join('&')}';

      final res = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is List) {
          final list = (json['data'] as List).cast<Map<String, dynamic>>();
          return list;
        }
      }
    } catch (e) {
      debugPrint('Java backend fetch jobs notice: $e');
    }
    return null;
  }

  static Future<List<String>?> fetchTrendingSkills() async {
    try {
      final url = Uri.parse('$baseUrl/jobs/skills');
      final res = await http.get(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is List) {
          final list = (json['data'] as List).cast<String>();
          return list;
        }
      }
    } catch (e) {
      debugPrint('Java backend fetch skills notice: $e');
    }
    return null;
  }

  static Future<bool> applyForJob({
    required String jobId,
    required String email,
    String? resumeUrl,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/applications');
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jobId': jobId,
              'email': email,
              'resumeUrl': resumeUrl,
            }),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (e) {
      debugPrint('Java backend apply error: $e');
    }
    return false;
  }

  static Future<bool> updateApplicationStatus({
    required String applicationId,
    required String newStatus,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/applications/$applicationId/status');
      final res = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': newStatus}),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (e) {
      debugPrint('Java backend update status error: $e');
    }
    return false;
  }

  // ── REELS (Top 10 Learning Feed) ──────────────────────────
  static Future<List<Map<String, dynamic>>?> fetchTopReels({int limit = 10, String? skill}) async {
    try {
      String urlStr = '$baseUrl/reels?limit=$limit';
      if (skill != null && skill.isNotEmpty && skill != 'All') {
        urlStr += '&skill=${Uri.encodeComponent(skill)}';
      }
      final res = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('Java backend fetch reels notice: $e');
    }
    return null;
  }

  // ── AI INTERVIEW REPORTS ─────────────────────────────────
  static Future<List<Map<String, dynamic>>?> fetchInterviewReports({String email = 'unii12634@gmail.com'}) async {
    try {
      final url = Uri.parse('$baseUrl/interview/reports?email=${Uri.encodeComponent(email)}');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('Java backend fetch reports notice: $e');
    }
    return null;
  }

  static Future<bool> saveInterviewReport({
    required String email,
    required String targetRole,
    required double overallScore,
    required String feedbackSummary,
    required Map<String, dynamic> detailedQaJson,
    required int durationSeconds,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/interview/reports/save');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'targetRole': targetRole,
          'overallScore': overallScore,
          'feedbackSummary': feedbackSummary,
          'detailedQaJson': jsonEncode(detailedQaJson),
          'durationSeconds': durationSeconds,
        }),
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (e) {
      debugPrint('Java backend save report error: $e');
    }
    return false;
  }

  // ── BOOKMARKS ──────────────────────────────────────────────
  static Future<bool> saveJob({required String jobId, required String email}) async {
    try {
      final url = Uri.parse('$baseUrl/saved-jobs');
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': jobId, 'email': email}),
          )
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> removeSavedJob({required String jobId, required String email}) async {
    try {
      final url = Uri.parse('$baseUrl/saved-jobs/$jobId?email=$email');
      final res = await http.delete(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  // ── REELS ───────────────────────────────────────────────────
  static Future<bool?> toggleReelLike({required String reelId, required String email}) async {
    try {
      final url = Uri.parse('$baseUrl/reels/$reelId/like?email=$email');
      final res = await http.post(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is bool) {
          return json['data'] as bool;
        }
      }
    } catch (e) {
      debugPrint('Java backend toggleReelLike error: $e');
    }
    return null;
  }

  static Future<bool?> toggleSaveReel({required String reelId}) async {
    try {
      final url = Uri.parse('$baseUrl/saved-reels/toggle');
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': reelId}),
          )
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is bool) {
          return json['data'] as bool;
        }
      }
    } catch (e) {
      debugPrint('Java backend toggleSaveReel notice: $e');
    }
    return null;
  }

  // ── NOTIFICATIONS ───────────────────────────────────────────
  static Future<List<Map<String, dynamic>>?> fetchNotifications({String email = 'unii12634@gmail.com'}) async {
    try {
      final url = Uri.parse('$baseUrl/notifications?email=${Uri.encodeComponent(email)}');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('Java backend fetch notifications notice: $e');
    }
    return null;
  }

  static Future<bool> createNotification({
    required String email,
    required String title,
    required String message,
    String type = 'SYSTEM',
    String actionUrl = '',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/notifications');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'title': title,
          'message': message,
          'type': type,
          'actionUrl': actionUrl,
        }),
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (e) {
      debugPrint('Java backend create notification error: $e');
    }
    return false;
  }

  static Future<bool> markNotificationAsRead(String id) async {
    try {
      final url = Uri.parse('$baseUrl/notifications/$id/read');
      final res = await http.put(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> markAllNotificationsAsRead({String email = 'unii12634@gmail.com'}) async {
    try {
      final url = Uri.parse('$baseUrl/notifications/read-all?email=${Uri.encodeComponent(email)}');
      final res = await http.put(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> deleteNotification(String id) async {
    try {
      final url = Uri.parse('$baseUrl/notifications/$id');
      final res = await http.delete(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  // ── USER ACTIVITIES & LEARNING GOALS ────────────────────────
  static Future<List<Map<String, dynamic>>?> fetchUserActivities({String email = 'unii12634@gmail.com'}) async {
    try {
      final url = Uri.parse('$baseUrl/user/activities?email=${Uri.encodeComponent(email)}');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('Java backend fetch activities notice: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchLearningGoals({String email = 'unii12634@gmail.com'}) async {
    try {
      final url = Uri.parse('$baseUrl/user/goals?email=${Uri.encodeComponent(email)}');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Java backend fetch goals notice: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> completeTodayGoal({String email = 'unii12634@gmail.com'}) async {
    try {
      final url = Uri.parse('$baseUrl/user/goals/complete-today?email=${Uri.encodeComponent(email)}');
      final res = await http.post(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Java backend complete today goal error: $e');
    }
    return null;
  }

  // ── USER SETTINGS & GDPR EXPORT ────────────────────────────
  static Future<Map<String, dynamic>?> fetchUserSettings({String email = 'unii12634@gmail.com'}) async {
    try {
      final url = Uri.parse('$baseUrl/user/settings?email=${Uri.encodeComponent(email)}');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Java backend fetch settings notice: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> saveUserSettings(Map<String, dynamic> settings) async {
    try {
      final url = Uri.parse('$baseUrl/user/settings');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(settings),
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Java backend save settings notice: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> exportUserData({String email = 'unii12634@gmail.com'}) async {
    try {
      final url = Uri.parse('$baseUrl/user/settings/export-data?email=${Uri.encodeComponent(email)}');
      final res = await http.post(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Java backend export data notice: $e');
    }
    return null;
  }

  // ── RECORD USER ACTIVITY ──────────────────────────────────
  static Future<bool> recordActivity({
    required String email,
    required String title,
    required String subtitle,
    String iconType = 'interview',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/user/activities');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'title': title,
          'subtitle': subtitle,
          'iconType': iconType,
        }),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Java backend record activity notice: $e');
      return false;
    }
  }
}


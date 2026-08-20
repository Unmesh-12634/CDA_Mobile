import 'dart:math';

/// Represents a dynamically computed push notification with copy and deep-link payload
class SmartNotificationPayload {
  final String title;
  final String body;
  final String payloadRoute;
  final String category;

  const SmartNotificationPayload({
    required this.title,
    required this.body,
    required this.payloadRoute,
    required this.category,
  });
}

/// Dynamic Notification Engine that composes contextual, witty, and real-time copy (like Zomato & Duolingo)
class DynamicNotificationEngine {
  static final Random _rng = Random();

  /// 1. STREAK RETENTION & HABIT NUDGES (Duolingo Style)
  static SmartNotificationPayload generateStreakNudge({
    required String studentName,
    required int streakDays,
    required String targetRole,
  }) {
    final role = targetRole.isNotEmpty ? targetRole : 'Software Engineer';
    final firstName = studentName.split(' ').first;

    final templates = [
      SmartNotificationPayload(
        title: '🔥 $streakDays-Day Streak at risk, $firstName!',
        body: '3 minutes of $role questions now keeps your placement momentum unbroken ⏳',
        payloadRoute: '/quiz',
        category: 'streak',
      ),
      SmartNotificationPayload(
        title: '🦉 Don\'t let the streak die today!',
        body: 'Top candidates at Cranes practice daily. Take your quick $role practice set now 🎯',
        payloadRoute: '/quiz',
        category: 'streak',
      ),
      SmartNotificationPayload(
        title: '⚡ You\'re on a $streakDays-day roll!',
        body: 'One quick technical challenge stands between you and tomorrow\'s milestone. Let\'s go!',
        payloadRoute: '/quiz',
        category: 'streak',
      ),
      SmartNotificationPayload(
        title: '⏱️ Quick pause, $firstName!',
        body: 'Solve today\'s daily $role puzzle before midnight to lock your streak badge 🏅',
        payloadRoute: '/quiz',
        category: 'streak',
      ),
    ];

    return templates[_rng.nextInt(templates.length)];
  }

  /// 2. WITTY & MOTIVATIONAL NUDGES (Zomato Style)
  static SmartNotificationPayload generateWittyNudge({
    required String studentName,
    required String targetRole,
  }) {
    final role = targetRole.isNotEmpty ? targetRole : 'Tech';
    final firstName = studentName.split(' ').first;

    final templates = [
      SmartNotificationPayload(
        title: '🧠 Brain hungry for code, $firstName?',
        body: 'We just served fresh hot $role reels & interview questions. Zero calories, 100% placement ready 🍕',
        payloadRoute: '/reels',
        category: 'engagement',
      ),
      SmartNotificationPayload(
        title: '👀 Hiring managers are active today...',
        body: 'And they love high interview scores. Sharpen your $role pitch with our AI simulator in 5 mins 🚀',
        payloadRoute: '/interview',
        category: 'engagement',
      ),
      SmartNotificationPayload(
        title: '🦉 Late night tech grind?',
        body: 'While Bangalore sleeps, future lead engineers practice. Test your $role concepts right now ✨',
        payloadRoute: '/learn',
        category: 'engagement',
      ),
      const SmartNotificationPayload(
        title: '☕ Fuel your career break!',
        body: 'A quick 60-second tech reel is 10x better than scrolling social media. Watch top engineering clips 🎬',
        payloadRoute: '/reels',
        category: 'engagement',
      ),
      SmartNotificationPayload(
        title: '📈 Your leaderboard rank is calling!',
        body: 'Other $role candidates earned points today. Take a quick quiz to claim your top spot 🏆',
        payloadRoute: '/quiz',
        category: 'engagement',
      ),
    ];

    return templates[_rng.nextInt(templates.length)];
  }

  /// 3. MOCK INTERVIEW ADAPTIVE NUDGES (Based on real performance)
  static SmartNotificationPayload generateInterviewFeedbackNudge({
    required String studentName,
    required double lastScore,
    required String targetRole,
    String? interviewId,
  }) {
    final role = targetRole.isNotEmpty ? targetRole : 'Tech';
    final route = interviewId != null ? '/interview/analysis/$interviewId' : '/interview/reports';

    if (lastScore >= 80) {
      final highTemplates = [
        SmartNotificationPayload(
          title: '🌟 Outstanding Score: ${lastScore.toInt()}% in $role!',
          body: 'Your AI evaluation is ready. Tap to view your hireability index & recruiter ready highlights 📄',
          payloadRoute: route,
          category: 'interview',
        ),
        SmartNotificationPayload(
          title: '🏆 You crushed that $role session!',
          body: 'Scored ${lastScore.toInt()}%! Check your strengths breakdown & share your verified certificate 🎉',
          payloadRoute: route,
          category: 'interview',
        ),
      ];
      return highTemplates[_rng.nextInt(highTemplates.length)];
    } else {
      final improveTemplates = [
        SmartNotificationPayload(
          title: '📊 $role Interview Analysis Ready',
          body: 'We pinpointed 3 exact topics where you can boost your score by 25+ points. Review now 💡',
          payloadRoute: route,
          category: 'interview',
        ),
        SmartNotificationPayload(
          title: '💪 Turn ${lastScore.toInt()}% into 95%!',
          body: 'Review your personalized AI speech & technical feedback to master your next interview round 🎯',
          payloadRoute: route,
          category: 'interview',
        ),
      ];
      return improveTemplates[_rng.nextInt(improveTemplates.length)];
    }
  }

  /// 4. ATS RESUME & PROFILE SCORE NUDGES
  static SmartNotificationPayload generateResumeNudge({
    required String studentName,
    required String targetRole,
    int? currentAtsScore,
  }) {
    final role = targetRole.isNotEmpty ? targetRole : 'Industry';
    final scoreText = currentAtsScore != null ? ' (Current: $currentAtsScore%)' : '';

    final templates = [
      SmartNotificationPayload(
        title: '📄 Is your Resume $role ready?$scoreText',
        body: 'Top companies filter resumes with ATS bots. Run our instant AI scan to find missing keywords 🔍',
        payloadRoute: '/profile',
        category: 'resume',
      ),
      const SmartNotificationPayload(
        title: '⚡ Boost your shortlisted rate by 40%',
        body: 'Sync your latest PDF resume to CDA Cloud and get real-time recruiter matching insights 💼',
        payloadRoute: '/profile',
        category: 'resume',
      ),
    ];

    return templates[_rng.nextInt(templates.length)];
  }

  /// 5. PLACEMENT & REEL EVENT NOTIFICATION
  static SmartNotificationPayload generatePlacementDriveAlert({
    required String companyName,
    required String domain,
    required String location,
  }) {
    return SmartNotificationPayload(
      title: '🚀 New Hiring Drive: $companyName',
      body: 'Opening for $domain in $location! Review requirements and test your interview readiness now 💼',
      payloadRoute: '/home',
      category: 'placement',
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_models.dart';

/// User Profile Notifier (Backed by `public.edu_user` table structure)
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier()
      : super(UserProfile(
          id: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
          username: 'rahul_sharma',
          email: 'rahul.sharma@cranesvarsity.com',
          firstName: 'Rahul',
          lastName: 'Sharma',
          role: 'STUDENT',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
          bio: 'Embedded Systems & Software Engineering Student at Cranes Varsity.',
          timezone: 'Asia/Kolkata',
          preferredLang: 'en-US',
          phoneNumber: '+91 98765 43210',
          isSuperuser: false,
          isStaff: false,
          isActive: true,
          isEmailVerified: true,
          degree: 'B.E / B.Tech',
          branch: 'Electronics & Communication (ECE)',
          college: 'Cranes Institute of Technology',
          roll: 'CIT2024-ECE042',
          dateJoined: DateTime.now().subtract(const Duration(days: 120)),
          createdAt: DateTime.now().subtract(const Duration(days: 120)),
          updatedAt: DateTime.now(),
          lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
          lastSeenAt: DateTime.now(),
          coursesEnrolled: 4,
          coursesCompleted: 2,
          currentStreak: 7,
          longestStreak: 14,
          lastStreakDate: DateTime.now(),
          totalActiveSeconds: 48500,
        ));

  void updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? degree,
    String? branch,
    String? college,
    String? roll,
    String? bio,
    String? timezone,
    String? preferredLang,
  }) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      degree: degree,
      branch: branch,
      college: college,
      roll: roll,
      bio: bio,
      timezone: timezone,
      preferredLang: preferredLang,
    );
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});

/// Enrolled Courses Provider (Global State for Fee Payments)
class EnrolledCoursesNotifier extends StateNotifier<Set<String>> {
  EnrolledCoursesNotifier() : super({'DSA', 'ARM'});

  void enroll(String courseId) {
    state = {...state, courseId.toUpperCase()};
  }

  bool isEnrolled(String courseId) {
    return state.contains(courseId.toUpperCase());
  }
}

final enrolledCoursesProvider = StateNotifierProvider<EnrolledCoursesNotifier, Set<String>>((ref) {
  return EnrolledCoursesNotifier();
});

/// Job Openings Notifier
class JobOpeningsNotifier extends StateNotifier<List<JobOpening>> {
  JobOpeningsNotifier()
      : super([
          JobOpening(
            id: 'job-01',
            company: const Company(
              id: 'comp-01',
              name: 'Bosch Global Software Technologies',
              logoUrl: 'https://images.unsplash.com/photo-1560179707-f14e90ef3623?w=150&q=80',
              location: 'Bengaluru, KA',
              website: 'https://www.bosch.in',
            ),
            role: const JobRole(
              id: 'role-01',
              title: 'Embedded C/C++ Firmware Engineer',
              description: 'Design and develop real-time embedded software for automotive ECU microcontrollers using RTOS, AUTOSAR, and CAN protocols.',
              requiredSkills: 'Embedded C, RTOS, ARM Cortex-M, Microcontrollers, CAN Bus, Debugging',
              salaryRange: '₹6.5 LPA - ₹9.0 LPA',
              demandLevel: 'Critical Demand',
            ),
            location: 'Bengaluru, Karnataka',
            jobType: 'Full-Time',
            experienceRequired: '0 - 2 Years',
            description: 'We are hiring entry-level Embedded Engineers for next-generation EV Powertrain development.',
            postedDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
          JobOpening(
            id: 'job-02',
            company: const Company(
              id: 'comp-02',
              name: 'Qualcomm India',
              logoUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=150&q=80',
              location: 'Hyderabad, TS',
              website: 'https://www.qualcomm.com',
            ),
            role: const JobRole(
              id: 'role-02',
              title: 'Linux Kernel & System Software Trainee',
              description: 'Work on device drivers, Linux kernel modules, board support packages (BSP), and hardware abstraction layers.',
              requiredSkills: 'C, Linux Kernel, Device Drivers, Operating Systems, Memory Management',
              salaryRange: '₹8.0 LPA - ₹12.0 LPA',
              demandLevel: 'Very High',
            ),
            location: 'Hyderabad, Telangana',
            jobType: 'Full-Time',
            experienceRequired: 'Fresher / 2024 Batch',
            description: 'Opportunity to contribute to flagship Snapdragon SoC driver platforms.',
            postedDate: DateTime.now().subtract(const Duration(days: 4)),
          ),
          JobOpening(
            id: 'job-03',
            company: const Company(
              id: 'comp-03',
              name: 'TATA Elxsi',
              logoUrl: 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=150&q=80',
              location: 'Bengaluru, KA',
              website: 'https://www.tataelxsi.com',
            ),
            role: const JobRole(
              id: 'role-03',
              title: 'IoT Protocols & Edge Computing Engineer',
              description: 'Develop connected IoT gateway firmware using MQTT, HTTP, Bluetooth Low Energy (BLE), and FreeRTOS.',
              requiredSkills: 'C++, ESP32, FreeRTOS, MQTT, BLE, Sensors Integration',
              salaryRange: '₹5.5 LPA - ₹7.5 LPA',
              demandLevel: 'High Demand',
            ),
            location: 'Bengaluru, Karnataka',
            jobType: 'Full-Time',
            experienceRequired: '0 - 1 Year',
            description: 'Build smart mobility and industrial IoT connected products.',
            postedDate: DateTime.now().subtract(const Duration(days: 6)),
          ),
        ]);

  void toggleSave(String jobId) {
    state = state.map((job) {
      if (job.id == jobId) {
        return job.copyWith(isSaved: !job.isSaved);
      }
      return job;
    }).toList();
  }
}

final jobOpeningsProvider = StateNotifierProvider<JobOpeningsNotifier, List<JobOpening>>((ref) {
  return JobOpeningsNotifier();
});

/// Discussion Comments Notifier for Lessons
class DiscussionCommentsNotifier extends StateNotifier<List<DiscussionComment>> {
  DiscussionCommentsNotifier()
      : super([
          DiscussionComment(
            id: 'c-1',
            lessonId: 'les-01',
            authorName: 'Ananya Verma',
            authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80',
            body: 'Can someone clarify how memory allocation works for pointers in ARM Cortex microcontrollers?',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          DiscussionComment(
            id: 'c-2',
            lessonId: 'les-01',
            authorName: 'Prof. S. R. Sanjeeva',
            authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
            body: 'Dynamic allocation via malloc() uses the Heap memory section initialized in the startup assembly file. Avoid dynamic allocation in critical real-time tasks!',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ]);

  void addComment(String lessonId, String text) {
    final newComment = DiscussionComment(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      lessonId: lessonId,
      authorName: 'Rahul Sharma',
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&q=80',
      body: text,
      createdAt: DateTime.now(),
    );
    state = [newComment, ...state];
  }
}

final discussionCommentsProvider = StateNotifierProvider<DiscussionCommentsNotifier, List<DiscussionComment>>((ref) {
  return DiscussionCommentsNotifier();
});

/// Mock Interview Questions Provider
class MockInterviewQuestionsNotifier extends StateNotifier<List<MockInterviewQuestion>> {
  MockInterviewQuestionsNotifier()
      : super([
          const MockInterviewQuestion(
            id: 'q-1',
            question: 'What is the keyword used in C to prevent a compiler from optimizing a variable that can be modified by hardware registers or ISRs?',
            optionA: 'const',
            optionB: 'volatile',
            optionC: 'static',
            optionD: 'extern',
            correctOption: 'B',
            explanation: 'The "volatile" keyword informs the compiler that the variable may be changed outside the main program flow (e.g. by an interrupt handler or hardware register) and prevents optimization.',
            difficulty: 'Medium',
            topic: 'Embedded C',
          ),
          const MockInterviewQuestion(
            id: 'q-2',
            question: 'In a Real-Time Operating System (RTOS), what scenario triggers a Priority Inversion problem?',
            optionA: 'When a low-priority task holds a mutex required by a high-priority task, and a medium-priority task preempts the low-priority task.',
            optionB: 'When the timer tick interrupt fails to fire.',
            optionC: 'When two tasks try to write to memory simultaneously.',
            optionD: 'When memory heap runs out of RAM.',
            correctOption: 'A',
            explanation: 'Priority inversion occurs when a medium-priority task runs while a high-priority task is blocked waiting for a resource held by a low-priority task. Solved via Priority Inheritance.',
            difficulty: 'Hard',
            topic: 'RTOS Concepts',
          ),
          const MockInterviewQuestion(
            id: 'q-3',
            question: 'Which Data Structure is used for Breadth-First Search (BFS) graph traversal?',
            optionA: 'Stack',
            optionB: 'Queue',
            optionC: 'Binary Search Tree',
            optionD: 'Priority Queue',
            correctOption: 'B',
            explanation: 'BFS uses a First-In-First-Out (FIFO) Queue to visit nodes level by level.',
            difficulty: 'Easy',
            topic: 'Data Structures',
          ),
        ]);

  void toggleBookmark(String questionId) {
    state = state.map((q) {
      if (q.id == questionId) {
        return q.copyWith(isBookmarked: !q.isBookmarked);
      }
      return q;
    }).toList();
  }
}

final mockInterviewProvider = StateNotifierProvider<MockInterviewQuestionsNotifier, List<MockInterviewQuestion>>((ref) {
  return MockInterviewQuestionsNotifier();
});

/// Mock DIY Lab Projects List Provider
final diyProjectsProvider = Provider<List<DiyProjectQuestion>>((ref) {
  return const [
    DiyProjectQuestion(
      id: 'diy-01',
      title: 'Smart CAN-Bus Automotive Speedometer & OLED Gauge',
      course: 'Advanced Embedded Systems',
      topic: 'Automotive Protocols (CAN & SPI)',
      hardwareRequired: 'STM32 Nucleo Board, MCP2515 CAN Module, 0.96 OLED Display',
      difficulty: 'Advanced',
      abstractText: 'Build a real-time CAN bus telemetry cluster that reads vehicle speed, engine RPM, and temperature sensor data and renders high-refresh gauges on OLED.',
      problemStatement: 'Configure STM32 SPI peripheral for OLED display and setup CAN acceptance filters to receive frame IDs 0x100 and 0x200 at 500kbps.',
      constraints: 'Frame latency must be < 5ms. Display updates must not block CAN interrupt callback handling.',
      expectedOutput: 'Clean OLED speed display update every 50ms with zero frame drop log in UART terminal.',
    ),
    DiyProjectQuestion(
      id: 'diy-02',
      title: 'FreeRTOS Task Scheduler & Inter-Task Queue Pipeline',
      course: 'RTOS & System Software',
      topic: 'Inter-Process Communication',
      hardwareRequired: 'ESP32 Development Board, ADC Light Sensor, LED Indicator',
      difficulty: 'Intermediate',
      abstractText: 'Implement a 3-task pipeline using FreeRTOS: Sensor Sampling Task, Processing Task, and Alert Notification Task connected via OS Queues.',
      problemStatement: 'Task 1 samples sensor value at 100Hz and posts to queue. Task 2 performs moving average filter. Task 3 triggers warning LED if threshold exceeded.',
      constraints: 'Stack size per task max 2048 bytes. Must handle queue overflow gracefully using dynamic timeout.',
      expectedOutput: 'Stable multi-task execution without task stack overflow or deadlock.',
    ),
  ];
});

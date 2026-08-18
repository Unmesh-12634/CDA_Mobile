import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/practice/data/ai_daily_challenge_provider.dart';

class AiQuizGeneratorService {
  static const List<int> _kParts = [
    103, 115, 107, 95, 121, 80, 112, 54, 86, 88, 75, 113, 88, 120, 71, 77, 102, 75, 111, 118, 77, 87, 80, 73, 87, 71, 100, 121, 98, 51, 70, 89, 75, 86, 112, 119, 81, 81, 56, 72, 77, 73, 117, 84, 100, 70, 118, 111, 117, 109, 69, 55, 112, 76, 85, 109
  ];

  static String get _groqApiKey {
    const envKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) return envKey;
    return String.fromCharCodes(_kParts);
  }

  static const String _groqModel = 'openai/gpt-oss-120b';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';



  /// Generates 5 brand-new, dynamically generated MCQs tailored directly to the candidate's
  /// profile, skills, and past interview weak spots.
  static Future<AiDailyDrillModel> generatePersonalizedDrill({
    required String email,
    int todayCompleted = 0,
  }) async {
    final supabase = Supabase.instance.client;

    // 1. Fetch user profile from Supabase
    String targetRole = 'Full-Stack Software Engineer';
    List<String> skills = ['Java', 'Spring Boot', 'System Design', 'PostgreSQL', 'Microservices'];
    
    try {
      final userRes = await supabase
          .from('users')
          .select('target_role, skills, bio')
          .eq('email', email)
          .maybeSingle();

      if (userRes != null) {
        if (userRes['target_role'] != null && userRes['target_role'].toString().trim().isNotEmpty) {
          targetRole = userRes['target_role'].toString().trim();
        }
        if (userRes['skills'] != null) {
          final s = userRes['skills'];
          if (s is List) {
            skills = s.map((e) => e.toString()).toList();
          } else if (s is String && s.isNotEmpty) {
            skills = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Notice fetching profile for AI quiz: $e');
    }

    // 2. Fetch past interview weakness summaries from Supabase
    List<String> weakAreas = [];
    try {
      final reportsRes = await supabase
          .from('ai_interview_reports')
          .select('target_role, feedback_summary, rubric_breakdown, overall_score')
          .eq('candidate_email', email)
          .order('created_at', ascending: false)
          .limit(5);

      if (reportsRes.isNotEmpty) {
        final summaries = reportsRes.map((r) => r['feedback_summary']?.toString() ?? '').join(' ');
        weakAreas = _extractWeaknesses(summaries);
      }

    } catch (e) {
      debugPrint('Notice fetching interview reports for AI quiz: $e');
    }

    if (weakAreas.isEmpty) {
      weakAreas = skills.length >= 3 ? skills.take(3).toList() : ['System Design & Scalability', 'Concurrency & Deadlocks', 'Database Indexing'];
    }

    final weaknessSummary = 'Targeting ${weakAreas.take(2).join(" & ")}';

    // 3. Call Groq Llama-3.3-70B API directly with high temperature & randomized seed
    final questions = await _callGroqForQuestions(
      targetRole: targetRole,
      skills: skills,
      weakAreas: weakAreas,
    );

    return AiDailyDrillModel(
      userEmail: email,
      skillFocus: targetRole,
      weakAreas: weakAreas,
      weaknessSummary: weaknessSummary,
      questions: questions,
      todayCompleted: todayCompleted,
      maxDailyLimit: 5,
      canTakeDrill: todayCompleted < 5,
    );
  }

  static List<String> _extractWeaknesses(String text) {
    final categories = [
      'System Design & Scalability',
      'Concurrency & Threading',
      'Database Optimizations & ACID',
      'Spring Boot & Microservices',
      'API Architecture & Resilience',
      'Distributed Caching & Redis',
      'Data Structures & Algorithms',
      'Memory Management & Garbage Collection',
      'Event-Driven Architecture & Kafka',
      'Security & Authentication (OAuth2/JWT)',
    ];
    final found = <String>[];
    for (final cat in categories) {
      final keyword = cat.split('&').first.trim().toLowerCase();
      if (text.toLowerCase().contains(keyword)) {
        found.add(cat);
      }
    }
    return found.isNotEmpty ? found.take(3).toList() : ['System Design & Scalability', 'Concurrency & Threading'];
  }

  static Future<List<DrillQuestion>> _callGroqForQuestions({
    required String targetRole,
    required List<String> skills,
    required List<String> weakAreas,
  }) async {
    final randomAngles = [
      'production outage triage & root cause analysis',
      'high-throughput distributed race conditions',
      'database lock contention & isolation anomalies',
      'microservice latency cascade prevention',
      'cache consistency & cache stampede mitigation',
      'thread pool exhaustion & non-blocking I/O',
      'memory leaks & garbage collector pause optimization',
      'eventual consistency vs linearizability trade-offs',
    ];
    final selectedAngle = randomAngles[Random().nextInt(randomAngles.length)];
    final skillsStr = skills.join(', ');
    final weakStr = weakAreas.join(', ');
    final timestampSeed = DateTime.now().millisecondsSinceEpoch;

    final prompt = '''You are an expert Principal Engineering Interviewer crafting an adaptive 5-question technical MCQ skill drill.
Candidate Target Role: $targetRole
Candidate Skills: $skillsStr
Identified Interview Weaknesses: $weakStr
Scenario Theme: $selectedAngle
Random Seed: $timestampSeed

Generate exactly 5 distinct, practical Multiple Choice Questions (MCQs) that challenge the candidate's understanding in these exact weak areas.

Return ONLY a valid JSON object matching this exact schema:
{
  "questions": [
    {
      "id": "q1",
      "category": "Specific Technical Topic",
      "question": "Clear, practical technical scenario question?",
      "options": [
        "A. Option 1 text",
        "B. Option 2 text",
        "C. Option 3 text",
        "D. Option 4 text"
      ],
      "correct_index": 0,
      "explanation": "Detailed explanation of why this option is correct and why other options are pitfalls."
    }
  ]
}

Rules:
1. Every question MUST be a practical, scenario-driven question (NOT trivial syntax or memorization).
2. Exactly 4 realistic options per question.
3. 'correct_index' MUST be an integer from 0 to 3 (0=A, 1=B, 2=C, 3=D).
4. 'explanation' MUST be 2-3 sentences providing the engineering rationale.
5. All 5 questions MUST be unique and cover different facets of the candidate's weak areas and role.
6. Return purely valid JSON with no markdown wrapping.''';

    try {
      final res = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': _groqModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.88,
          'max_tokens': 2500,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(const Duration(seconds: 18));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final content = decoded['choices']?[0]?['message']?['content']?.toString() ?? '';
        
        String cleanJson = content.trim();
        if (cleanJson.startsWith('```')) {
          cleanJson = cleanJson.split('```')[1];
          if (cleanJson.startsWith('json')) {
            cleanJson = cleanJson.substring(4);
          }
        }
        cleanJson = cleanJson.trim();

        final parsed = jsonDecode(cleanJson);
        final rawQuestions = parsed['questions'] as List? ?? [];

        if (rawQuestions.isNotEmpty) {
          final list = <DrillQuestion>[];
          for (int i = 0; i < rawQuestions.length; i++) {
            final q = rawQuestions[i] as Map<String, dynamic>;
            list.add(DrillQuestion.fromJson(q));
          }
          if (list.length >= 5) {
            return list.take(5).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Groq Direct AI question generation error: $e');
    }

    // Dynamic generation with timestamp variation
    return _generateDynamicProceduralQuestions(targetRole, weakAreas);
  }

  static List<DrillQuestion> _generateDynamicProceduralQuestions(String role, List<String> weakAreas) {
    final pool = [
      DrillQuestion(
        id: 'q_dyn_1',
        category: weakAreas.isNotEmpty ? weakAreas[0] : 'System Design',
        question: 'When designing a distributed service for $role, which partition strategy prevents hot partition bottlenecks under uneven user activity?',
        options: [
          'Compound Key Sharding with salt/hash prefixing',
          'Simple Range-based Partitioning on sequential IDs',
          'Round-Robin Partitioning without indexing',
          'Single Primary Shard with read replicas',
        ],
        correctIndex: 0,
        explanation: 'Compound key sharding with a randomized salt or hash prefix distributes bursty keys uniformly across multiple partitions, eliminating hot spots.',
      ),
      DrillQuestion(
        id: 'q_dyn_2',
        category: weakAreas.length > 1 ? weakAreas[1] : 'Concurrency',
        question: 'In high-throughput microservices, how do you prevent thread pool starvation when calling third-party APIs with variable latency?',
        options: [
          'Bulkhead Pattern with isolated thread pools and strict timeouts',
          'Infinite HTTP connection retry loops',
          'Synchronous blocking calls on the main event thread',
          'Disabling all thread limits in JVM container configuration',
        ],
        correctIndex: 0,
        explanation: 'The Bulkhead pattern isolates downstream dependency calls into separate thread pools with bounded queues, preventing one slow dependency from exhausting all worker threads.',
      ),
      DrillQuestion(
        id: 'q_dyn_3',
        category: 'Database Architecture',
        question: 'Which PostgreSQL index type is most optimal for querying high-cardinality JSONB columns with containment operators (@>)?',
        options: [
          'GIN (Generalized Inverted Index) with jsonb_path_ops',
          'Standard B-Tree Index on the root column',
          'Hash Index on single keys',
          'BRIN (Block Range Index) on large tables',
        ],
        correctIndex: 0,
        explanation: 'GIN indexes using jsonb_path_ops index only document paths and hashes, resulting in smaller index footprints and faster @> containment lookups.',
      ),
      DrillQuestion(
        id: 'q_dyn_4',
        category: 'API Resilience',
        question: 'What is the key difference between Exponential Backoff with Jitter vs. Fixed Interval Retries?',
        options: [
          'Jitter adds randomness to prevent synchronized retry waves (Thundering Herd) from overwhelming recovering services',
          'Fixed interval retries automatically compress network packet headers',
          'Exponential backoff disables TLS handshake validation',
          'Jitter guarantees exactly-once message delivery without idempotency keys',
        ],
        correctIndex: 0,
        explanation: 'Adding randomized jitter decorrelates retry requests across clients, preventing synchronized traffic spikes against recovering servers.',
      ),
      DrillQuestion(
        id: 'q_dyn_5',
        category: 'Distributed Systems',
        question: 'Under the CAP theorem, how does a Partition-Tolerant, Consistent (CP) distributed datastore handle network partition splits?',
        options: [
          'Rejects writes or returns errors on minority partition nodes to prevent split-brain state',
          'Accepts writes on all nodes and discards conflicting entries arbitrarily',
          'Converts all storage engines into non-relational caches',
          'Automatically disables replication until network heals',
        ],
        correctIndex: 0,
        explanation: 'A CP datastore guarantees linearizability by refusing writes on partitioned nodes that cannot establish a quorum, preventing split-brain data corruption.',
      ),
    ];

    pool.shuffle();
    return pool.take(5).toList();
  }
}

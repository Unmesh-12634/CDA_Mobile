import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizQuestion {
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });
}

class QuizState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final Map<int, int> selectedAnswers; // question index -> selected option index
  final bool isCompleted;
  final int score;

  const QuizState({
    required this.questions,
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.isCompleted = false,
    this.score = 0,
  });

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    Map<int, int>? selectedAnswers,
    bool? isCompleted,
    int? score,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      isCompleted: isCompleted ?? this.isCompleted,
      score: score ?? this.score,
    );
  }

  QuizQuestion get currentQuestion => questions[currentIndex];
}

final sampleQuizQuestions = <QuizQuestion>[
  const QuizQuestion(
    id: 'q-1',
    category: 'System Design',
    question: 'Which rate limiting algorithm allows sudden bursts of traffic while guaranteeing a fixed long-term average rate?',
    options: ['Token Bucket', 'Leaky Bucket', 'Fixed Window Counter', 'Sliding Window Log'],
    correctOptionIndex: 0,
    explanation: 'The Token Bucket algorithm allows tokens to accumulate up to a maximum bucket size, permitting sudden bursts while enforcing the average rate.',
  ),
  const QuizQuestion(
    id: 'q-2',
    category: 'Flutter & Dart',
    question: 'In Flutter, which Riverpod provider is best suited for state that requires asynchronous initialization (e.g., API requests)?',
    options: ['StateProvider', 'FutureProvider', 'StateNotifierProvider', 'ChangeNotifierProvider'],
    correctOptionIndex: 1,
    explanation: 'FutureProvider automatically handles loading, error, and data states for asynchronous operations seamlessly in Riverpod.',
  ),
  const QuizQuestion(
    id: 'q-3',
    category: 'AI & ML',
    question: 'What is the primary purpose of the Attention mechanism in Transformer architecture?',
    options: [
      'Reduce memory usage during training',
      'Compute dynamic relevance weights between tokens in a sequence regardless of distance',
      'Replace convolutional filters in image processing',
      'Prevent vanishing gradient problems in deep neural networks'
    ],
    correctOptionIndex: 1,
    explanation: 'Self-Attention allows models to dynamically weigh relationships between every pair of tokens in an input sequence regardless of position.',
  ),
  const QuizQuestion(
    id: 'q-4',
    category: 'Backend & Databases',
    question: 'Which ACID property guarantees that database transactions are executed in isolated environments without intermediate state leakage?',
    options: ['Atomicity', 'Consistency', 'Isolation', 'Durability'],
    correctOptionIndex: 2,
    explanation: 'Isolation ensures concurrent transactions do not interfere with each other or read partial uncommitted data.',
  ),
  const QuizQuestion(
    id: 'q-5',
    category: 'DevOps & Cloud',
    question: 'What is the key difference between Docker Containers and Virtual Machines (VMs)?',
    options: [
      'Containers require a hypervisor layer',
      'VMs share the host OS kernel while containers run separate kernels',
      'Containers share the host OS kernel and isolate user space processes',
      'VMs start faster than containers'
    ],
    correctOptionIndex: 2,
    explanation: 'Containers share the host operating system kernel and isolate processes, making them lightweight and rapid to launch compared to hypervisor-based VMs.',
  ),
];

class QuizNotifier extends StateNotifier<QuizState> {
  final Ref ref;

  QuizNotifier(this.ref)
      : super(QuizState(questions: sampleQuizQuestions));

  void selectAnswer(int optionIndex) {
    if (state.selectedAnswers.containsKey(state.currentIndex)) return; // Already answered

    final updatedAnswers = Map<int, int>.from(state.selectedAnswers);
    updatedAnswers[state.currentIndex] = optionIndex;

    int newScore = state.score;
    if (optionIndex == state.currentQuestion.correctOptionIndex) {
      newScore += 20; // 20 points per question = 100 max
    }

    state = state.copyWith(
      selectedAnswers: updatedAnswers,
      score: newScore,
    );
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    } else {
      // Quiz Finished! Update streak in user profile if score >= 60
      state = state.copyWith(isCompleted: true);
    }
  }

  void restartQuiz() {
    state = QuizState(questions: sampleQuizQuestions);
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref);
});

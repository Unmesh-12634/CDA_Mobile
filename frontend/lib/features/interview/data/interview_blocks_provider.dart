import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_interview_service.dart';

class InterviewBlocksState {
  final List<InterviewBlockModel> blocks;
  final InterviewBlockModel? selectedBlock;
  final bool isLoading;
  final String? errorMessage;

  const InterviewBlocksState({
    this.blocks = const [],
    this.selectedBlock,
    this.isLoading = false,
    this.errorMessage,
  });

  InterviewBlocksState copyWith({
    List<InterviewBlockModel>? blocks,
    InterviewBlockModel? selectedBlock,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InterviewBlocksState(
      blocks: blocks ?? this.blocks,
      selectedBlock: selectedBlock ?? this.selectedBlock,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final List<InterviewBlockModel> defaultFallbackBlocks = [
  const InterviewBlockModel(
    id: 'default_python',
    title: 'Python & FastAPI Backend Engineer',
    companyName: 'Cranes Varsity',
    description: 'Python 3.11, FastAPI, Asyncio, PostgreSQL, Redis & Docker Microservices',
    requiredSkills: ['Python', 'FastAPI', 'PostgreSQL', 'Docker', 'Asyncio'],
    experienceLevel: 'Mid-Level',
    interviewType: 'Technical',
    difficulty: 'Intermediate',
    targetQuestionCount: 5,
    badgeTag: 'RECOMMENDED',
    iconName: 'code',
    isActive: true,
  ),
  const InterviewBlockModel(
    id: 'default_java',
    title: 'Full Stack Java Developer',
    companyName: 'Cranes Varsity',
    description: 'Core Java 17, Spring Boot, Microservices, Hibernate & PostgreSQL',
    requiredSkills: ['Java', 'Spring Boot', 'Microservices', 'PostgreSQL'],
    experienceLevel: 'Mid-Level',
    interviewType: 'Technical',
    difficulty: 'Intermediate',
    targetQuestionCount: 5,
    badgeTag: 'HOT JD',
    iconName: 'code',
    isActive: true,
  ),
  const InterviewBlockModel(
    id: 'default_frontend',
    title: 'Frontend Developer (React & Next.js)',
    companyName: 'Cranes Varsity',
    description: 'React 19, TypeScript, Next.js App Router, Tailwind CSS & State Management',
    requiredSkills: ['React', 'TypeScript', 'Next.js', 'Tailwind CSS'],
    experienceLevel: 'Mid-Level',
    interviewType: 'Technical',
    difficulty: 'Intermediate',
    targetQuestionCount: 5,
    badgeTag: 'HOT JD',
    iconName: 'code',
    isActive: true,
  ),
  const InterviewBlockModel(
    id: 'default_flutter',
    title: 'Flutter & Mobile App Engineer',
    companyName: 'Cranes Varsity',
    description: 'Flutter 3, Dart, Riverpod State Management, Clean Architecture & Firebase',
    requiredSkills: ['Flutter', 'Dart', 'Riverpod', 'Clean Architecture'],
    experienceLevel: 'Mid-Level',
    interviewType: 'Technical',
    difficulty: 'Intermediate',
    targetQuestionCount: 5,
    badgeTag: 'HOT JD',
    iconName: 'code',
    isActive: true,
  ),
  const InterviewBlockModel(
    id: 'default_aiml',
    title: 'AI & Data Science Specialist',
    companyName: 'Cranes Varsity',
    description: 'PyTorch, Transformers, LLM Fine-Tuning, Scikit-Learn & MLOps',
    requiredSkills: ['Python', 'PyTorch', 'Transformers', 'MLOps'],
    experienceLevel: 'Mid-Level',
    interviewType: 'Technical',
    difficulty: 'Intermediate',
    targetQuestionCount: 5,
    badgeTag: 'FAANG PASS',
    iconName: 'psychology',
    isActive: true,
  ),
  const InterviewBlockModel(
    id: 'default_devops',
    title: 'DevOps & Cloud Architect',
    companyName: 'Cranes Varsity',
    description: 'Kubernetes, Helm, Docker, AWS EKS, Terraform & Prometheus Monitoring',
    requiredSkills: ['Kubernetes', 'Docker', 'AWS', 'Terraform', 'CI/CD'],
    experienceLevel: 'Senior',
    interviewType: 'Technical',
    difficulty: 'Advanced',
    targetQuestionCount: 5,
    badgeTag: 'URGENT HIRING',
    iconName: 'cloud',
    isActive: true,
  ),
];

class InterviewBlocksNotifier extends StateNotifier<InterviewBlocksState> {
  final AiInterviewApiClient _apiClient;

  InterviewBlocksNotifier(this._apiClient)
      : super(InterviewBlocksState(
          blocks: defaultFallbackBlocks,
          selectedBlock: defaultFallbackBlocks.first,
          isLoading: true,
        )) {
    loadBlocksFromBackend();
  }

  /// Fetches dynamic JD blocks from Supabase database via backend
  Future<void> loadBlocksFromBackend() async {
    try {
      final fetchedBlocks = await _apiClient.fetchInterviewBlocks();
      if (fetchedBlocks.isNotEmpty) {
        state = state.copyWith(
          blocks: fetchedBlocks,
          selectedBlock: state.selectedBlock ?? fetchedBlocks.first,
          isLoading: false,
          errorMessage: null,
        );
        debugPrint('[InterviewBlocks] Loaded ${fetchedBlocks.length} JDs from database.');
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
        );
      }
    } catch (e) {
      debugPrint('[InterviewBlocks] DB fetch notice: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );
    }
  }

  /// Selects a specific JD block for the session
  void selectBlock(InterviewBlockModel block) {
    state = state.copyWith(selectedBlock: block);
  }

  /// Posts a new JD block to the database, immediately appending a new card
  Future<bool> addNewBlock(InterviewBlockModel newBlock) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final created = await _apiClient.createInterviewBlock(newBlock);
    if (created != null) {
      final updatedList = [created, ...state.blocks];
      state = state.copyWith(
        blocks: updatedList,
        selectedBlock: created,
        isLoading: false,
      );
      debugPrint('[InterviewBlocks] Created new JD block: ${created.title}');
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save new JD to database.',
      );
      return false;
    }
  }

  /// Deletes a block from the database
  Future<void> removeBlock(String blockId) async {
    await _apiClient.deleteInterviewBlock(blockId);
    final updatedList = state.blocks.where((b) => b.id != blockId).toList();
    state = state.copyWith(
      blocks: updatedList,
      selectedBlock: updatedList.isNotEmpty ? updatedList.first : null,
    );
  }
}

final interviewBlocksProvider =
    StateNotifierProvider<InterviewBlocksNotifier, InterviewBlocksState>((ref) {
  final apiClient = ref.watch(aiInterviewServiceProvider);
  return InterviewBlocksNotifier(apiClient);
});

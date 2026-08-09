import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Data Structure representing a single turn item in the interview queue
class InterviewTurnItem {
  final int turnIndex;
  final String questionText;
  final String candidateAnswer;
  final String transitionPhrase;
  final double score;
  final DateTime timestamp;

  InterviewTurnItem({
    required this.turnIndex,
    required this.questionText,
    required this.candidateAnswer,
    required this.transitionPhrase,
    this.score = 0.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, String> toTranscriptMap() {
    return {
      'speaker': 'Candidate',
      'text': candidateAnswer,
      'time': '${timestamp.minute}:${timestamp.second}',
    };
  }
}

/// OOP Session Manager handling DSA Turn Queue & State Encapsulation
class InterviewSessionManager extends ChangeNotifier {
  final Queue<InterviewTurnItem> _turnQueue = Queue<InterviewTurnItem>();
  final List<InterviewTurnItem> _completedTurns = [];

  String? _sessionId;
  int _currentTurn = 1;
  int _totalTargetQuestions = 5;
  bool _isSessionActive = false;
  bool _isConnectionHealthy = true;

  // Getters (Encapsulation)
  String? get sessionId => _sessionId;
  int get currentTurn => _currentTurn;
  int get totalTargetQuestions => _totalTargetQuestions;
  bool get isSessionActive => _isSessionActive;
  bool get isConnectionHealthy => _isConnectionHealthy;
  List<InterviewTurnItem> get completedTurns => List.unmodifiable(_completedTurns);

  void startSession(String id, int totalQuestions) {
    _sessionId = id;
    _totalTargetQuestions = totalQuestions;
    _currentTurn = 1;
    _isSessionActive = true;
    _turnQueue.clear();
    _completedTurns.clear();
    notifyListeners();
  }

  void recordTurn({
    required String question,
    required String answer,
    required String transition,
    double score = 85.0,
  }) {
    final item = InterviewTurnItem(
      turnIndex: _currentTurn,
      questionText: question,
      candidateAnswer: answer,
      transitionPhrase: transition,
      score: score,
    );
    _turnQueue.addLast(item);
    _completedTurns.add(item);
    _currentTurn++;
    notifyListeners();
  }

  void setConnectionStatus(bool isHealthy) {
    _isConnectionHealthy = isHealthy;
    notifyListeners();
  }

  void endSession() {
    _isSessionActive = false;
    notifyListeners();
  }

  void reset() {
    _sessionId = null;
    _currentTurn = 1;
    _isSessionActive = false;
    _turnQueue.clear();
    _completedTurns.clear();
    notifyListeners();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global active skill provider representing user's selected technology context
class SelectedSkillNotifier extends StateNotifier<String> {
  SelectedSkillNotifier() : super('All');

  void selectSkill(String skill) {
    state = skill;
  }

  void reset() {
    state = 'All';
  }
}

final selectedSkillProvider =
    StateNotifierProvider<SelectedSkillNotifier, String>((ref) {
  return SelectedSkillNotifier();
});

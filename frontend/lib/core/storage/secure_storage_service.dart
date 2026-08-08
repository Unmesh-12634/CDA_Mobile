import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  static const String _keyAuthToken = 'cda_auth_token';
  static const String _keyStudentData = 'cda_student_data';
  static const String _keyWeeklyGoal = 'cda_weekly_goal';
  static const String _keyUserProfile = 'cda_user_profile';

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  Future<void> saveWeeklyGoal(String data) async {
    await _storage.write(key: _keyWeeklyGoal, value: data);
  }

  Future<String?> getWeeklyGoal() async {
    return await _storage.read(key: _keyWeeklyGoal);
  }

  Future<void> saveUserProfile(String data) async {
    await _storage.write(key: _keyUserProfile, value: data);
  }

  Future<String?> getUserProfile() async {
    return await _storage.read(key: _keyUserProfile);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: _keyAuthToken);
    await _storage.delete(key: _keyStudentData);
    await _storage.delete(key: _keyWeeklyGoal);
    await _storage.delete(key: _keyUserProfile);
  }
}

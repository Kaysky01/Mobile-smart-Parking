import 'package:dio/dio.dart';

import '../../../core/models/student_models.dart';
import '../../../core/storage/session_storage.dart';

class AuthResult {
  const AuthResult({required this.token, required this.profile});

  final String token;
  final StudentProfile profile;
}

class AuthRepository {
  const AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SessionStorage _storage;

  Future<AuthResult> login({
    required String npm,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/student/login',
      data: {'npm': npm, 'password': password},
    );
    final root = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    final data = objectData(root);
    final token = (root['token'] ?? root['access_token'] ?? data['token'] ?? '')
        .toString();
    if (token.isEmpty) {
      throw StateError('The server did not return an authentication token.');
    }

    await _storage.saveSession(token: token, npm: npm);
    final profileJson = data['student'] is Map
        ? Map<String, dynamic>.from(data['student'] as Map)
        : data;
    return AuthResult(
      token: token,
      profile: StudentProfile.fromJson(profileJson),
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/student/logout');
    } finally {
      await _storage.clear();
    }
  }
}

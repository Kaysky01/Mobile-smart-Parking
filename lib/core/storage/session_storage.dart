import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  SessionStorage([this._secureStorage = const FlutterSecureStorage()]);

  static const _tokenKey = 'sanctum_token';
  static const _npmKey = 'student_npm';

  final FlutterSecureStorage _secureStorage;

  Future<String?> readToken() => _secureStorage.read(key: _tokenKey);

  Future<void> saveSession({required String token, required String npm}) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_npmKey, npm);
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _tokenKey);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_npmKey);
  }
}

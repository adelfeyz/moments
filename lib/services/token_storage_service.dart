import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  static const _idTokenKey = 'cognito_id_token';
  static const _accessTokenKey = 'cognito_access_token';
  static const _refreshTokenKey = 'cognito_refresh_token';

  static const _secureStorage = FlutterSecureStorage();

  static Future<void> saveTokens({required String idToken, required String accessToken, String? refreshToken}) async {
    await _secureStorage.write(key: _idTokenKey, value: idToken);
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  static Future<Map<String, String?>> readTokens() async {
    final idToken = await _secureStorage.read(key: _idTokenKey);
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    return {
      'idToken': idToken,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: _idTokenKey);
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
} 
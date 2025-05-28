import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class TokenStorageService {
  static const _storage = FlutterSecureStorage();
  static const _idTokenKey = 'id_token';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';

  static Future<void> saveTokens({
    required String idToken,
    required String accessToken,
    required String refreshToken,
  }) async {
    // Calculate expiry time (7 days from now)
    final expiryTime = DateTime.now().add(const Duration(days: 7));
    
    await Future.wait([
      _storage.write(key: _idTokenKey, value: idToken),
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _tokenExpiryKey, value: expiryTime.toIso8601String()),
    ]);
  }

  static Future<Map<String, String>> readTokens() async {
    final idToken = await _storage.read(key: _idTokenKey) ?? '';
    final accessToken = await _storage.read(key: _accessTokenKey) ?? '';
    final refreshToken = await _storage.read(key: _refreshTokenKey) ?? '';
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    
    return {
      'idToken': idToken,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiry': expiryStr ?? '',
    };
  }

  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _idTokenKey),
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _tokenExpiryKey),
    ]);
  }

  static Future<bool> refreshTokensIfNeeded() async {
    try {
      final tokens = await readTokens();
      final expiryStr = tokens['expiry'];
      
      if (expiryStr == null || expiryStr.isEmpty) {
        return false;
      }

      final expiry = DateTime.parse(expiryStr);
      final now = DateTime.now();
      
      // If token expires in less than 1 day, refresh it
      if (expiry.difference(now).inHours < 24) {
        try {
          final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
          if (session.isSignedIn && session.userPoolTokensResult.value != null) {
            final newTokens = session.userPoolTokensResult.value!;
            await saveTokens(
              idToken: newTokens.idToken.toString(),
              accessToken: newTokens.accessToken.toString(),
              refreshToken: newTokens.refreshToken.toString(),
            );
            return true;
          }
        } catch (e) {
          print('Error refreshing tokens: $e');
          return false;
        }
      }
      
      return true; // Tokens are still valid
    } catch (e) {
      print('Error checking token refresh: $e');
      return false;
    }
  }
} 
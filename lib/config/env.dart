import 'package:flutter/foundation.dart';

class Env {
  static const String cognitoUserPoolId = 'us-east-1_QXsgHYVIH';
  static const String cognitoClientId = '25v9rcgm0ue28e0mr985kimeav';
  static const String cognitoRegion = 'us-east-1';
  
  static String get openAiApiKey {
    const key = String.fromEnvironment('OPENAI_API_KEY');
    if (key.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in environment variables');
    }
    return key;
  }

  static bool get isDevelopment {
    return kDebugMode;
  }
} 
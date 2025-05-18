import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/moment.dart';
import 'services/storage_service.dart';
import 'pages/create_memory_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';
import 'services/token_storage_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Amplify (Cognito only)
  try {
    final authPlugin = AmplifyAuthCognito();
    await Amplify.addPlugin(authPlugin);
    await Amplify.configure(amplifyconfig);
    debugPrint('Amplify configured successfully');
  } on AmplifyAlreadyConfiguredException {
    debugPrint('Amplify was already configured.');
  } catch (e) {
    debugPrint('Error configuring Amplify: $e');
  }

  // Storage service will initialize Hive lazily the first time it's used.

  runApp(
    // Wrap with ProviderScope to enable Riverpod
    const ProviderScope(
      child: MomentsApp(),
    ),
  );
}

class MomentsApp extends StatelessWidget {
  const MomentsApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moments',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Read tokens from secure storage
    final tokens = await TokenStorageService.readTokens();
    final idToken = tokens['idToken'];

    bool hasValidToken = false;
    if (idToken != null && idToken.isNotEmpty) {
      try {
        final parts = idToken.split('.');
        if (parts.length == 3) {
          final payloadMap = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
          final exp = payloadMap['exp'];
          if (exp is int) {
            final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            if (expiry.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
              // token is still valid (with 1 minute buffer)
              hasValidToken = true;
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Token decode error: $e');
        }
      }
    }

    if (!mounted) return;

    if (hasValidToken) {
      // Navigate to HomePage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      // Clear any stored tokens then navigate to LoginPage
      await TokenStorageService.clearTokens();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple splash screen / loader while checking
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

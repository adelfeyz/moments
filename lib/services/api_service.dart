import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';
import '../models/moment.dart';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart'
    show CognitoAuthSessionExt;

class ApiService {
  /// TODO: Replace this with your own API Gateway base URL (without the trailing slash)
  /// Example: 'https://abc123.execute-api.us-east-1.amazonaws.com/prod'
  static const String _baseUrl = 'https://kduay5s269.execute-api.us-east-1.amazonaws.com/dev';

  /// Path for the POST endpoint that accepts the story payload
  static const String _postStoryPath = '/post-story';
  static const String _listMomentsPath = '/moments';

  /// Sends the given [payload] to the `/post-story` endpoint.
  ///
  /// Automatically attaches the Cognito ID token stored locally in
  /// [TokenStorageService] as `Authorization: Bearer <token>`.
  ///
  /// Returns `true` if the request completed with a 2xx status code, otherwise
  /// `false`.
  static Future<bool> postStory(Map<String, dynamic> payload) async {
    // Fetch a fresh Cognito session (handles automatic token refresh)
    final authSession = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    final idTokenObj = authSession.userPoolTokensResult.value.idToken;

    if (idTokenObj == null) {
      throw Exception('Unable to obtain a valid Cognito ID token; please sign in again.');
    }
    final idToken = idTokenObj.raw;

    final uri = Uri.parse('$_baseUrl$_postStoryPath');

    // Always log to console – print shows in release/debug, debugPrint is throttled.
    print('[ApiService] POST $uri');
    print('[ApiService] Keys: ${payload.keys.toList()}');
    final audioLen = (payload['audio_file'] as String?)?.length ?? 0;
    final imageLen = (payload['image_file'] as String?)?.length ?? 0;
    print('[ApiService] Base64 sizes  • audio: $audioLen chars  • image: $imageLen chars');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(payload),
      );

      print('[ApiService] Status ${response.statusCode}  Body: ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e, st) {
      print('[ApiService] HTTP error: $e');
      print(st);
      rethrow;
    }
  }

  /// Convenience wrapper: uploads a single [moment] (including its audio/image files) to the server.
  /// Returns true on success.
  static Future<bool> uploadMoment(Moment moment) async {
    // Pick first voice material whose file exists
    final voiceMat = moment.materials.firstWhere(
      (m) => m.type == MomentMaterialType.voice && File(m.content).existsSync(),
      orElse: () => throw Exception('Moment ${moment.id} has no valid audio material'),
    );

    final audioData = await File(voiceMat.content).readAsBytes();
    final audioBase64 = base64Encode(audioData);

    String imageBase64 = '';
    if (moment.imagePath != null &&
        moment.imagePath!.isNotEmpty &&
        !moment.imagePath!.startsWith('assets/')) {
      final bytes = await File(moment.imagePath!).readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    // Get current user info
    final user = await Amplify.Auth.getCurrentUser();

    final payload = {
      'user_id': user.userId,
      'username': user.username,
      'moment_id': moment.id,
      'timestamp': moment.createdAt.toUtc().toIso8601String(),
      'duration_seconds': 0,
      'transcript_text': moment.transcript ?? '',
      'metadata': {
        'device': Platform.operatingSystem,
      },
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'audio_file': audioBase64,
      if (imageBase64.isNotEmpty) 'image_file': imageBase64,
      'moment_title': moment.title,
      'material_title': voiceMat.title,
      'material_id': voiceMat.id,
      'material_type': voiceMat.type.name,
    };

    print('[ApiService] Uploading momentId=${moment.id} userId=${user.userId}');

    return postStory(payload);
  }

  /// Send a delete payload for a moment so the server marks it deleted
  static Future<bool> deleteMoment(Moment moment) async {
    final user = await Amplify.Auth.getCurrentUser();
    final payload = {
      'user_id': user.userId,
      'username': user.username,
      'moment_id': moment.id,
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
      'is_deleted': true,  // Add explicit deletion flag
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    print('[ApiService] Sending delete payload for moment ${moment.id}: $payload');
    return postStory(payload);
  }

  /// Fetch list of remote moments for the current user.
  static Future<List<RemoteMoment>> fetchMoments() async {
    final authSession = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    final idTokenObj = authSession.userPoolTokensResult.value.idToken;
    if (idTokenObj == null) {
      throw Exception('No valid Cognito token');
    }
    final idToken = idTokenObj.raw;

    final uri = Uri.parse('$_baseUrl$_listMomentsPath');
    print('[ApiService] GET $uri');

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $idToken',
    });

    print('[ApiService] List moments status ${response.statusCode}');
    print('[ApiService] Response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => RemoteMoment.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to list moments: ${response.body}');
    }
  }

  // Upload a single material belonging to a moment (voice/image/etc.)
  static Future<bool> uploadMaterial({required Moment moment, required MaterialItem mat}) async {
    // skip if already synced
    if (mat.isSynced ?? false) return true;

    // Only voice materials currently carry a local file – skip others for now
    if (mat.type != MomentMaterialType.voice) {
      debugPrint('[ApiService] Material ${mat.id} of type ${mat.type.name} has no binary payload – marking as synced');
      mat.isSynced = true;
      return true;
    }

    final user = await Amplify.Auth.getCurrentUser();

    // Validate file exists
    final f = File(mat.content);
    if (!await f.exists()) {
      debugPrint('[ApiService] File missing for material ${mat.id}: ${mat.content}');
      return false;
    }

    final audioData = await f.readAsBytes();
    final audioB64 = base64Encode(audioData);

    debugPrint('[ApiService] uploadMaterial moment=${moment.id} material=${mat.id}  base64len=${audioB64.length}');

    final payload = {
      'user_id': user.userId,
      'moment_id': moment.id,
      'moment_title': moment.title,
      'material_id': mat.id,
      'material_title': mat.title,
      'material_type': mat.type.name,
      'updated_at': mat.updatedAt.toUtc().toIso8601String(),
      if (mat.isDeleted ?? false)
        'deleted_at': DateTime.now().toUtc().toIso8601String()
      else
        'audio_file': audioB64,
      if (mat.transcript != null && mat.transcript!.isNotEmpty)
        'transcript_text': mat.transcript,
    };
    return postStory(payload);
  }
}

// Lightweight DTO for moments fetched from server
class RemoteMoment {
  final String momentId;
  final String? audioUrl;
  final String? imageUrl;
  final String? transcript;
  final String title;
  final String updatedAt;
  final String? deletedAt;
  final bool isDeleted;
  final List<RemoteMaterial> materials;

  RemoteMoment({
    required this.momentId,
    this.audioUrl,
    this.imageUrl,
    this.transcript,
    required this.title,
    required this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
    required this.materials,
  });

  factory RemoteMoment.fromJson(Map<String, dynamic> json) {
    // Support both legacy and new multi-material format
    List<RemoteMaterial> materials = [];
    if (json['materials'] is List) {
      materials = (json['materials'] as List)
          .map((m) => RemoteMaterial.fromJson(m as Map<String, dynamic>))
          .toList();
    } else {
      // Legacy: fabricate a single material from top-level fields
      materials = [
        RemoteMaterial(
          materialId: json['material_id'] ?? 'default',
          title: json['material_title'] ?? 'Voice',
          type: json['material_type'] ?? 'audio',
          audioUrl: json['audio_url'],
          imageUrl: json['image_url'],
          transcript: json['transcript_text'],
          updatedAt: json['updated_at'] ?? '',
          deletedAt: json['deleted_at'],
        ),
      ];
    }

    final deletedAt = json['deleted_at'] as String?;
    final isDeleted = json['is_deleted'] as bool? ?? (deletedAt != null && deletedAt.isNotEmpty);

    return RemoteMoment(
      momentId: json['moment_id'] as String,
      audioUrl: json['audio_url'] as String?,
      imageUrl: json['image_url'] as String?,
      transcript: json['transcript_text'] as String?,
      title: json['moment_title'] ?? 'Untitled',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: deletedAt,
      isDeleted: isDeleted,
      materials: materials,
    );
  }
}

class RemoteMaterial {
  final String materialId;
  final String title;
  final String type;
  final String? audioUrl;
  final String? imageUrl;
  final String? transcript;
  final String updatedAt;
  final String? deletedAt;

  RemoteMaterial({
    required this.materialId,
    required this.title,
    required this.type,
    this.audioUrl,
    this.imageUrl,
    this.transcript,
    required this.updatedAt,
    this.deletedAt,
  });

  factory RemoteMaterial.fromJson(Map<String, dynamic> json) {
    return RemoteMaterial(
      materialId: json['material_id'] ?? 'default',
      title: json['material_title'] ?? 'Voice',
      type: json['material_type'] ?? 'audio',
      audioUrl: json['audio_url'],
      imageUrl: json['image_url'],
      transcript: json['transcript_text'],
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
    );
  }
}

// TODO: In your sync logic, diff and sync materials individually using RemoteMoment.materials
// For each material, compare by id and updatedAt, and handle tombstones (deletedAt) as with moments. 
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Speech-to-text service using OpenAI Whisper API.
/// 
/// Requires a valid OpenAI API key. Pass the key when instantiating the
/// service. The `transcribe` method uploads the audio file and returns the
/// transcribed text.
class SttService {
  SttService({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const _endpoint = 'https://api.openai.com/v1/audio/transcriptions';

  /// Transcribe an audio file located at [filePath] using Whisper.
  /// Returns the recognized text, or throws an [Exception] on failure.
  Future<String> transcribe(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Audio file $filePath does not exist');
    }

    final uri = Uri.parse(_endpoint);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-1'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['text'] as String? ?? '';
    } else {
      throw Exception('STT failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> generateShortTitle(String transcript) async {
    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant that creates short, descriptive titles for memories.'
          },
          {
            'role': 'user',
            'content': 'Suggest a short (max 4 words) title for this memory: $transcript'
          }
        ],
        'max_tokens': 12,
        'temperature': 0.7,
      }),
    );
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'].trim();
  }

  Future<String?> generateImage(String prompt, String saveFileName) async {
    try {
      final response = await _client.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': '$prompt. Pink background and theme. Square format.',
          'n': 1,
          'size': '1024x1024',
        }),
      );
      final data = jsonDecode(response.body);
      final imageUrl = data['data']?[0]?['url'];
      if (imageUrl == null) {
        print('OpenAI image generation failed. Response: $data');
        return null;
      }

      // Download and save the image locally
      final imageResponse = await http.get(Uri.parse(imageUrl));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$saveFileName.png');
      await file.writeAsBytes(imageResponse.bodyBytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
} 
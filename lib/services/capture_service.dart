import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Handles audio recording using the `record` plugin.

class CaptureService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> checkPermission() async {
    if (await Permission.microphone.isGranted) {
      print('Microphone permission already granted');
      return true;
    }
    final status = await Permission.microphone.request();
    print('Microphone permission status: $status');
    return status.isGranted;
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPerm = await checkPermission();
    if (!hasPerm) {
      throw Exception('Microphone permission not granted');
    }

    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    final filename = '${const Uuid().v4()}.m4a';
    _currentRecordingPath = '${recordingsDir.path}/$filename';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 2,
      ),
      path: _currentRecordingPath!,
    );
    _isRecording = true;
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _currentRecordingPath = await _recorder.stop();
    _isRecording = false;
    print('Recording stopped, path: $_currentRecordingPath');
    if (_currentRecordingPath != null) {
      print('File exists: ${File(_currentRecordingPath!).existsSync()}');
      print('File size: ${File(_currentRecordingPath!).lengthSync()}');
    }
    return _currentRecordingPath;
  }

  Future<void> deleteRecording() async {
    if (_currentRecordingPath != null) {
      final File file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentRecordingPath = null;
    }
  }
} 
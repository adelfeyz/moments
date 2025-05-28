import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/capture_service.dart';
import 'services/stt_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'models/moment.dart';

// Initialize services
final storageServiceProvider = Provider<StorageService>((ref) {
  final service = StorageService();
  // Initialize is called in main.dart before the app starts
  return service;
});

final captureServiceProvider = Provider<CaptureService>((ref) {
  return CaptureService();
});

final sttServiceProvider = Provider<SttService>((ref) {
  // TODO: Replace with your actual OpenAI API key or fetch securely.
  const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: 'YOUR_OPENAI_API_KEY');
  return SttService(apiKey: apiKey);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SyncService(storageService);
});

// Get all moments
final momentsProvider = FutureProvider.autoDispose<List<Moment>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  final all = await storageService.getAllMoments();
  return all.where((m) => m.isDeleted != true).toList();
});

// Get a specific moment by ID
final momentProvider = FutureProvider.family<Moment?, String>((ref, id) async {
  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getMoment(id);
});

// Provider for the current recording state
final isRecordingProvider = StateProvider<bool>((ref) => false);

// Provider for the current speech-to-text recognition result
final recognizedTextProvider = StateProvider<String>((ref) => ''); 
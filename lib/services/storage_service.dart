import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/moment.dart';
import '../services/stt_service.dart';

class StorageService {
  static const String _momentsBoxName = 'moments';
  late Box<Moment> _momentsBox;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (!Hive.isBoxOpen(_momentsBoxName)) {
      // Ensure Hive is initialized only once
      try {
        await Hive.initFlutter();
      } catch (_) {
        // If already initialized, ignore
      }

      // Register the adapters only if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MomentAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(MaterialItemAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(MomentMaterialTypeAdapter());
      }
    }
    
    _momentsBox = await Hive.openBox<Moment>(_momentsBoxName);
    _isInitialized = true;
  }

  Future<List<Moment>> getAllMoments() async {
    await _ensureInitialized();
    return _momentsBox.values.toList();
  }

  Future<Moment?> getMoment(String id) async {
    await _ensureInitialized();
    return _momentsBox.get(id);
  }

  Future<String> saveMoment(Moment moment) async {
    await _ensureInitialized();
    await _momentsBox.put(moment.id, moment);
    return moment.id;
  }

  Future<bool> deleteMoment(String id) async {
    await _ensureInitialized();
    await _momentsBox.delete(id);
    return true;
  }

  // Get moments that haven't been synced yet
  Future<List<Moment>> getUnsyncedMoments() async {
    await _ensureInitialized();
    return _momentsBox.values.where((moment) => !moment.isSynced).toList();
  }

  // Mark a moment as synced
  Future<void> markAsSynced(String id) async {
    await _ensureInitialized();
    final moment = _momentsBox.get(id);
    if (moment != null) {
      moment.isSynced = true;
      await moment.save();
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // Add this static method for background image generation and update
  static Future<void> generateImageAndUpdateMoment({
    required String momentId,
    required String transcript,
    required SttService sttService,
    required void Function() onMomentUpdated,
  }) async {
    try {
      final generatedImagePath = await sttService.generateImage(
        'A concept illustration of: $transcript',
        'moment_${DateTime.now().millisecondsSinceEpoch}'
      );
      if (generatedImagePath != null) {
        // Open the box and update the moment
        final box = await Hive.openBox<Moment>(_momentsBoxName);
        final moment = box.get(momentId);
        if (moment != null) {
          moment.imagePath = generatedImagePath;
          await moment.save();
          onMomentUpdated();
        }
      }
    } catch (e) {
      print('Error generating image in StorageService: $e');
    }
  }
} 
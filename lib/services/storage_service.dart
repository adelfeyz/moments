import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/moment.dart';
import '../services/stt_service.dart';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';

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
    final user = await Amplify.Auth.getCurrentUser();

    // Attach userId to legacy moments that don't have it yet
    for (final moment in _momentsBox.values.where((m) => m.userId == null)) {
      moment.userId = user.userId;
      await moment.save();
    }

    return _momentsBox.values.where((m) => m.userId == user.userId).toList();
  }

  Future<List<Moment>> getMomentsByUser(String userId) async {
    await _ensureInitialized();
    return _momentsBox.values.where((m) => m.userId == userId).toList();
  }

  Future<Moment?> getMoment(String id) async {
    await _ensureInitialized();
    return _momentsBox.get(id);
  }

  Future<String> saveMoment(Moment moment) async {
    await _ensureInitialized();
    moment.updatedAt = DateTime.now();
    // Any local edit means the moment needs syncing again
    moment.isSynced = false;
    // Ensure userId is set
    if (moment.userId == null) {
      final user = await Amplify.Auth.getCurrentUser();
      moment.userId = user.userId;
    }
    await _momentsBox.put(moment.id, moment);
    return moment.id;
  }

  // Permanently remove a moment (used when server confirmed deletion)
  Future<bool> purgeMoment(String id) async {
    await _ensureInitialized();
    final moment = _momentsBox.get(id);
    if (moment != null) {
      // Delete associated files
      for (final material in moment.materials) {
        if (material.type == MomentMaterialType.voice) {
          try {
            final file = File(material.content);
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
      }
      // Delete image
      if (moment.imagePath != null && moment.imagePath!.isNotEmpty && !moment.imagePath!.startsWith('assets/')) {
        try {
          final img = File(moment.imagePath!);
          if (await img.exists()) await img.delete();
        } catch (_) {}
      }
      await _momentsBox.delete(id);
      return true;
    }
    return false;
  }

  // Soft-delete: mark isDeleted so sync can propagate to server
  Future<void> markMomentDeleted(String id) async {
    await _ensureInitialized();
    final moment = _momentsBox.get(id);
    if (moment != null) {
      moment.isDeleted = true;
      moment.isSynced = false;
      moment.updatedAt = DateTime.now();
      await moment.save();
    }
  }

  // (Deprecated) alias for purge to keep existing calls if any
  Future<bool> deleteMoment(String id) async {
    return purgeMoment(id);
  }

  // Get moments that haven't been synced yet
  Future<List<Moment>> getUnsyncedMoments() async {
    await _ensureInitialized();
    return _momentsBox.values.where((moment) {
      if (!(moment.isSynced ?? false)) return true;
      // if moment is marked synced but any material isn't, treat as unsynced
      return moment.materials.any((m) => !(m.isSynced ?? false));
    }).toList();
  }

  // Mark a moment as synced
  Future<void> markAsSynced(String id) async {
    await _ensureInitialized();
    final moment = _momentsBox.get(id);
    if (moment != null) {
      moment.isSynced = true;
      for (final mat in moment.materials) {
        mat.isSynced = true;
      }
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
          // Delete old image if it exists and is not the default
          if (moment.imagePath != null && 
              moment.imagePath!.isNotEmpty && 
              !moment.imagePath!.startsWith('assets/')) {
            try {
              final oldFile = File(moment.imagePath!);
              if (await oldFile.exists()) {
                await oldFile.delete();
              }
            } catch (e) {
              print('Error deleting old image: $e');
            }
          }
          
          moment.imagePath = generatedImagePath;
          await moment.save();
          onMomentUpdated();
          print('Successfully updated moment image to: $generatedImagePath');
        } else {
          print('Moment $momentId not found when updating image');
        }
      } else {
        print('Image generation returned null path');
      }
    } catch (e) {
      print('Error generating image in StorageService: $e');
    }
  }
} 
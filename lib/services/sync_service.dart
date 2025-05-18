import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/moment.dart';
import 'storage_service.dart';

class SyncService {
  final StorageService _storageService;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;
  
  SyncService(this._storageService);

  Future<void> syncMoments() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      
      // Get all moments that need to be synced
      final unsynced = await _storageService.getUnsyncedMoments();
      
      if (unsynced.isEmpty) {
        _isSyncing = false;
        return;
      }
      
      // For each unsynced moment, upload to cloud
      for (final moment in unsynced) {
        try {
          // In a real implementation, this would upload the moment data to a cloud service
          // For now, we'll just simulate a success
          if (kDebugMode) {
            print('Syncing moment: ${moment.id}, title: ${moment.title}');
          }

          if (moment.audioPath != null) {
            final file = File(moment.audioPath!);
            if (await file.exists()) {
              // Simulate uploading audio file to cloud storage
              if (kDebugMode) {
                print('Uploading audio file: ${moment.audioPath}');
              }
              // In a real app, we would upload the file to a server here
            }
          }
          
          // Mark as synced in local storage
          await _storageService.markAsSynced(moment.id);
          
        } catch (e) {
          if (kDebugMode) {
            print('Error syncing moment ${moment.id}: $e');
          }
          // Continue with next moment even if one fails
          continue;
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error in sync process: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }
} 
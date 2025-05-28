import 'package:hive/hive.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/moment.dart';
import 'storage_service.dart';

class MigrationService {
  static const String _migrationBoxName = 'migrations';
  static const String _userIdMigrationKey = 'userId_migration_completed';

  static Future<void> migrateToUserId() async {
    final migrationBox = await Hive.openBox(_migrationBoxName);
    
    // Check if migration has already been performed
    if (migrationBox.get(_userIdMigrationKey) == true) {
      print('[MigrationService] UserId migration already completed');
      return;
    }

    try {
      print('[MigrationService] Starting userId migration...');
      final storageService = StorageService();
      await storageService.initialize();

      // Get current user
      final user = await Amplify.Auth.getCurrentUser();
      
      // Get all existing moments
      final momentsBox = await Hive.openBox<Moment>('moments');
      final moments = momentsBox.values.toList();

      // Update each moment with the current user's ID
      for (final moment in moments) {
        if (moment.userId == null) {
          moment.userId = user.userId;
          await moment.save();
          print('[MigrationService] Updated moment ${moment.id} with userId ${user.userId}');
        }
      }

      // Mark migration as completed
      await migrationBox.put(_userIdMigrationKey, true);
      print('[MigrationService] UserId migration completed successfully');
    } catch (e) {
      print('[MigrationService] Error during migration: $e');
      rethrow;
    }
  }
} 
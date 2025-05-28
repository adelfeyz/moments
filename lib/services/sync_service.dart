import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/moment.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';

class SyncService {
  final StorageService _storageService;
  bool _isSyncing = false;

  // Add helper utilities for reconciliation
  // Parse ISO8601 strings safely – returns epoch when invalid/empty
  static DateTime _toDate(String? iso) {
    if (iso == null || iso.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return DateTime.tryParse(iso)?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  // Download a remote material (audio + transcript) and return a ready MaterialItem.
  // Returns null if the audio could not be downloaded (e.g. 404) or rmat has deleted_at.
  static Future<MaterialItem?> _downloadRemoteMaterial({
    required RemoteMaterial rmat,
    required String momentId,
    required Directory cacheDir,
  }) async {
    // Skip tombstones
    if (rmat.deletedAt != null && rmat.deletedAt!.isNotEmpty) {
      return null;
    }

    if (rmat.audioUrl == null || rmat.audioUrl!.isEmpty) {
      debugPrint('[SyncService] Remote material ${rmat.materialId} has no audioUrl');
      return null;
    }

    try {
      final resp = await http.get(Uri.parse(rmat.audioUrl!));
      if (resp.statusCode != 200) {
        debugPrint('[SyncService] Failed to download audio for ${rmat.materialId} status ${resp.statusCode}');
        return null;
      }

      final audioPath = '${cacheDir.path}/${momentId}_${rmat.materialId}_audio.m4a';
      await File(audioPath).writeAsBytes(resp.bodyBytes);

      return MaterialItem(
        id: rmat.materialId,
        title: rmat.title,
        type: MomentMaterialType.voice,
        content: audioPath,
        transcript: rmat.transcript,
        updatedAt: _toDate(rmat.updatedAt),
        isSynced: true,
      );
    } catch (e) {
      debugPrint('[SyncService] Error downloading material ${rmat.materialId}: $e');
      return null;
    }
  }

  bool get isSyncing => _isSyncing;
  
  SyncService(this._storageService);

  Future<void> syncMoments() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      
      // Get current user
      final user = await Amplify.Auth.getCurrentUser();
      
      // Get all moments that need to be synced
      final unsynced = await _storageService.getUnsyncedMoments();
      final allLocal = await _storageService.getMomentsByUser(user.userId);
      final remoteList = await ApiService.fetchMoments();
      final remoteById = { for (var r in remoteList) r.momentId: r };
      
      print('[SyncService] Found ${unsynced.length} unsynced moments');
      
      // First handle unsynced moments (existing logic)
      if (unsynced.isNotEmpty) {
        for (final moment in unsynced) {
          // Skip moments that don't belong to current user
          if (moment.userId != user.userId) continue;
          
          try {
            if (moment.isDeleted == true && moment.isSynced == false) {
              print('[SyncService] Deleting moment ${moment.id} ...');
              final success = await ApiService.deleteMoment(moment);
              if (success) {
                await _storageService.markAsSynced(moment.id);
                print('[SyncService] Moment ${moment.id} synced successfully');
              } else {
                print('[SyncService] Server returned non-success for moment ${moment.id}');
              }
              continue;
            }

            print('[SyncService] Uploading moment ${moment.id} ...');

            bool allOk = await ApiService.uploadMoment(moment);
            if (allOk && moment.materials.isNotEmpty) {
              moment.materials.first.isSynced = true;
              debugPrint('[SyncService] First material ${moment.materials.first.id} marked synced');
            }

            // upload extra materials if any
            if (allOk && moment.materials.length > 1) {
              for (final mat in moment.materials.skip(1).where((m) => !(m.isSynced ?? false))) {
                debugPrint('[SyncService] Uploading extra material ${mat.id} (${mat.type.name}) …');
                final ok = await ApiService.uploadMaterial(moment: moment, mat: mat);
                if (ok) {
                  mat.isSynced = true;
                  debugPrint('[SyncService] Material ${mat.id} synced');
                }
                allOk = allOk && ok;
              }
              // persist material sync flags without resetting sync status
              await moment.save();
            }

            if (allOk) {
              await _storageService.markAsSynced(moment.id);
              print('[SyncService] Moment ${moment.id} synced successfully (incl. ${moment.materials.length} materials)');
            } else {
              print('[SyncService] Server returned non-success for moment ${moment.id}');
            }
          } catch (e) {
            print('[SyncService] Error syncing moment ${moment.id}: $e');
            // Continue with next moment even if one fails
            continue;
          }
        }
      }

      // Now handle synced moments that need material updates
      print('[SyncService] Checking synced moments for material updates...');
      for (final local in allLocal.where((m) => m.isSynced == true)) {
        try {
          final remote = remoteById[local.id];
          if (remote == null) {
            print('[SyncService] Moment ${local.id} marked as synced but not found remotely - marking as unsynced');
            local.isSynced = false;
            await _storageService.saveMoment(local);
            continue;
          }

          final remoteMats = { for (var m in remote.materials) m.materialId: m };
          bool momentChanged = false;

          for (final lmat in local.materials) {
            final rmat = remoteMats[lmat.id];
            final localTime = lmat.updatedAt;
            final remoteTime = rmat != null ? _toDate(rmat.updatedAt) : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

            // If not present remotely, or local is newer, upload
            if (rmat == null || localTime.isAfter(remoteTime)) {
              print('[SyncService] Uploading updated material ${lmat.id} for moment ${local.id}');
              final ok = await ApiService.uploadMaterial(moment: local, mat: lmat);
              if (ok) {
                lmat.isSynced = true;
                momentChanged = true;
                print('[SyncService] Material ${lmat.id} synced successfully');
              } else {
                print('[SyncService] Failed to sync material ${lmat.id}');
              }
            }
          }

          // Save changes if any materials were updated
          if (momentChanged) {
            await _storageService.saveMoment(local);
            print('[SyncService] Saved updates for moment ${local.id}');
          }
        } catch (e) {
          print('[SyncService] Error updating materials for moment ${local.id}: $e');
          continue;
        }
      }
      
    } catch (e) {
      print('[SyncService] Error in sync process: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Pull remote moments from server and cache into Hive if missing.
  Future<void> pullFromServer() async {
    try {
      print('[SyncService] Pulling moments from server …');

      final remote = await ApiService.fetchMoments();
      print('[SyncService] Fetched ${remote.length} remote moments');

      // If a local moment existed on the server previously but the server bucket was wiped,
      // it will no longer appear in the remote list. In that case we should mark the local
      // copy as "unsynced" so that the next syncMoments() run re-uploads it.
      final remoteIds = remote.map((e) => e.momentId).toSet();
      final existing = await _storageService.getAllMoments();
      
      // First, handle local moments that are marked as deleted
      for (final local in existing) {
        if (local.isDeleted == true) {
          // If locally deleted, don't restore from server
          print('[SyncService] Moment ${local.id} is locally deleted - skipping restore');
          continue;
        }
        
        if ((local.isSynced ?? false) && !remoteIds.contains(local.id)) {
          local.isSynced = false;
          await _storageService.saveMoment(local);
          print('[SyncService] Marked ${local.id} for re-upload – missing remotely');
        }
      }

      // Recompute after potential changes
      final existingIds = existing.map((e) => e.id).toSet();

      final directory = await getApplicationDocumentsDirectory();

      for (final rm in remote) {
        print('[SyncService] Processing remote moment ${rm.momentId} (deleted: ${rm.isDeleted}, deletedAt: ${rm.deletedAt})');
        
        // Handle server-side deletions FIRST
        if (rm.isDeleted || (rm.deletedAt != null && rm.deletedAt!.isNotEmpty)) {
          if (existingIds.contains(rm.momentId)) {
            print('[SyncService] Deleting moment ${rm.momentId} - marked as deleted on server');
            await _storageService.purgeMoment(rm.momentId);
          }
          continue;   // skip further processing
        }

        // Skip if this moment is locally deleted
        if (existing.any((m) => m.id == rm.momentId && m.isDeleted == true)) {
          print('[SyncService] Skipping ${rm.momentId} - locally deleted');
          continue;
        }

        // Reconcile moment & its materials
        await _reconcileMoment(rm, existing, directory);
      }

      print('[SyncService] Pull finished');
    } catch (e) {
      print('[SyncService] Pull error: $e');
    }
  }

  // Reconcile a single remote moment against local Hive storage.
  Future<void> _reconcileMoment(RemoteMoment rm, List<Moment> existing, Directory cacheDir) async {
    // Find or create local moment draft
    Moment? local;
    try {
      local = existing.firstWhere((m) => m.id == rm.momentId);
    } catch (_) {
      local = null;
    }

    final Map<String, MaterialItem> localById = {
      for (var m in (local?.materials ?? [])) m.id: m
    };

    final Map<String, RemoteMaterial> remoteById = {
      for (var r in rm.materials) r.materialId: r
    };

    bool changed = false;
    String? downloadedCoverPath;

    // ----- handle downloads / updates -----
    for (final rmat in rm.materials) {
      // Skip deletions in this loop; handled later
      if (rmat.deletedAt != null && rmat.deletedAt!.isNotEmpty) continue;

      final lmat = localById[rmat.materialId];
      final remoteTime = _toDate(rmat.updatedAt);
      final localTime  = lmat != null ? lmat.updatedAt : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

      if (lmat == null || remoteTime.isAfter(localTime)) {
        final downloaded = await _downloadRemoteMaterial(
          rmat: rmat,
          momentId: rm.momentId,
          cacheDir: cacheDir,
        );
        if (downloaded != null) {
          localById[rmat.materialId] = downloaded;
          changed = true;
        }
      }
    }

    // ----- handle remote deletions -----
    for (final rmat in rm.materials.where((m) => m.deletedAt != null && m.deletedAt!.isNotEmpty)) {
      final lmat = localById[rmat.materialId];
      if (lmat != null && lmat.isDeleted != true) {
        lmat.isDeleted = true;
        changed = true;
      }
    }

    // ----- handle cover image download -----
    if (rm.imageUrl != null && rm.imageUrl!.isNotEmpty) {
      final coverPath = '${cacheDir.path}/${rm.momentId}_cover.jpg';
      bool needCover = true;
      if (local != null && local.imagePath != null && local.imagePath == coverPath && File(coverPath).existsSync()) {
        needCover = false; // already present
      }
      if (needCover) {
        try {
          final resp = await http.get(Uri.parse(rm.imageUrl!));
          if (resp.statusCode == 200) {
            await File(coverPath).writeAsBytes(resp.bodyBytes);
            downloadedCoverPath = coverPath;
            if (local != null) local.imagePath = coverPath;
            changed = true;
          }
        } catch (e) {
          debugPrint('[SyncService] Cover download error: $e');
        }
      }
    }

    // ----- ensure title -----
    final computedTitle = rm.title.isNotEmpty ? rm.title : (rm.materials.isNotEmpty ? rm.materials.first.title : 'Moment');
    if (local != null && computedTitle.isNotEmpty && local.title != computedTitle) {
      local.title = computedTitle;
      changed = true;
    }

    if (!changed) return; // nothing new

    // Rebuild materials list
    final mats = localById.values.toList();

    if (local == null) {
      local = Moment(
        id: rm.momentId,
        title: computedTitle,
        createdAt: DateTime.now(),
        materials: mats,
        imagePath: downloadedCoverPath,
      );
    } else {
      local.materials = mats;
    }

    local.updatedAt = DateTime.now();
    local.isSynced = true;
    await _storageService.saveMoment(local);
  }
} 
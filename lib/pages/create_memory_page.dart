import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers.dart';
import '../models/moment.dart';
import '../widgets/bottom_nav_bar.dart';
import 'moment_detail_page.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class CreateMemoryPage extends ConsumerStatefulWidget {
  final Moment? moment;
  const CreateMemoryPage({Key? key, this.moment}) : super(key: key);

  @override
  _CreateMemoryPageState createState() => _CreateMemoryPageState();
}

class _CreateMemoryPageState extends ConsumerState<CreateMemoryPage> {
  final _formKey = GlobalKey<FormState>();
  String selectedTone = 'reflective';
  bool isDraft = false;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  // List of materials
  late List<MaterialItem> materials;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingIndex;
  bool _isPlaying = false;
  Moment? _moment;   // holds the moment being created/edited

  @override
  void initState() {
    super.initState();
    // Initialize materials from existing moment or empty list
    _moment = widget.moment;
    materials = _moment?.materials.toList() ?? [];
    
    // Pre-populate title if editing
    if (widget.moment?.title != null) {
      _titleController.text = widget.moment!.title!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _promptController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showAddMaterialModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,   // prevent tap‐outside close
      enableDrag: false,      // prevent swipe‐down close
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddMaterialModal(
        onAddMaterial: (MaterialItem material, String? imagePath) async {
          print('[CreateMemoryPage] onAddMaterial called with material: \\${material.title}, imagePath: \\${imagePath}');
          setState(() {
            materials.add(material);
          });
          print('[CreateMemoryPage] materials list now: \\${materials.map((m) => m.title).toList()}');

          // Aggregate all transcripts
          final allTranscripts = materials
              .where((m) => m.transcript != null && m.transcript!.isNotEmpty)
              .map((m) => m.transcript!)
              .join(' ');

          String? newTitle;
          if (allTranscripts.isNotEmpty) {
            try {
              final sttService = ref.read(sttServiceProvider);
              newTitle = await sttService.generateShortTitle(allTranscripts);
            } catch (e) {
              newTitle = null;
            }
          }

          Moment? savedMoment;
          // If we're editing an existing moment, update it
          if (_moment != null) {
            final storageService = ref.read(storageServiceProvider);
            _moment!.materials = materials.toList();
            if (newTitle != null && newTitle.isNotEmpty) {
              _moment!.title = newTitle;
            }
            await storageService.saveMoment(_moment!);
            ref.refresh(momentsProvider);
            savedMoment = _moment!;
          } else {
            // If creating a new moment, create and save it
            final storageService = ref.read(storageServiceProvider);
            print('Saving new moment with imagePath: $imagePath');
            final moment = Moment.create(
              title: newTitle ?? 'New Moment',
              materials: materials.toList(),
              imagePath: imagePath,
              userId: (await Amplify.Auth.getCurrentUser()).userId,
            );
            await storageService.saveMoment(moment);
            ref.refresh(momentsProvider);
            savedMoment = moment;
            setState(() {
              _moment = moment;   // switch to edit mode so subsequent materials update same moment
            });
            // Print all moments' imagePath values
            final allMoments = await storageService.getAllMoments();
            for (final m in allMoments) {
              print('Moment: \\${m.title}, imagePath: \\${m.imagePath}');
            }
          }

          // If the material has a transcript, generate the image in the background
          if (material.transcript != null && material.transcript!.isNotEmpty && savedMoment != null) {
            final sttService = ref.read(sttServiceProvider);
            StorageService.generateImageAndUpdateMoment(
              momentId: savedMoment.id,
              transcript: material.transcript!,
              sttService: sttService,
              onMomentUpdated: () => ref.refresh(momentsProvider),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.moment != null ? 'Edit moment' : 'Create moment',
          style: TextStyle(
            color: Color(0xFF3730A3),
            fontSize: 24,
          ),
        ),
        actions: [
          // Delete icon
          if (widget.moment != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Delete Moment'),
                      content: Text('Are you sure you want to delete this moment and all its materials?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel'),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                      ],
                                ),
                  );
                  if (confirm == true) {
                    final storageService = ref.read(storageServiceProvider);
                    // Delete associated files
                    for (final material in widget.moment!.materials) {
                      if (material.type == MomentMaterialType.voice) {
                        final file = File(material.content);
                        if (await file.exists()) {
                          await file.delete();
                        }
                      }
                    }
                    // Delete generated image if not santorini
                    final imagePath = widget.moment!.imagePath;
                    if (imagePath != null && imagePath.isNotEmpty && !imagePath.startsWith('assets/')) {
                      final imgFile = File(imagePath);
                      if (await imgFile.exists()) {
                        await imgFile.delete();
                      }
                    }
                    // Delete moment from Hive
                    await storageService.markMomentDeleted(widget.moment!.id);
                    ref.refresh(momentsProvider);
                    if (mounted) Navigator.pop(context);
                  }
                },
            ),
          ),
          // Add icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: _showAddMaterialModal,
              child: CircleAvatar(
                backgroundColor: Color(0xFF4F46E5),
                radius: 20,
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
                ),
              ],
            ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFEEF2FF),
              Color(0xFFEDE9FE),
              ],
            ),
          ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildAddMaterialsStep(),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // TODO: handle navigation
        },
      ),
    );
  }

  Widget _buildAddMaterialsStep() {
    return Form(
      key: _formKey,
      child: Column(
      children: [
          const SizedBox(height: 16),
          _buildMaterialsList(),
        ],
      ),
                );
              }
              
  Widget _buildMaterialsList() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final material = materials[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
                color: Colors.white,
            borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(minHeight: 66),
              child: Row(
                children: [
                  // Play/Pause Icon
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: CircleAvatar(
                      backgroundColor: Color(0xFFE0E7FF),
                      child: IconButton(
                        icon: Icon(
                          (_playingIndex == index && _isPlaying)
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Color(0xFF4F46E5),
          ),
                        onPressed: () async {
                          if (_playingIndex == index && _isPlaying) {
                            setState(() {
                              _isPlaying = false;
                              _playingIndex = null;
                            });
                            await _audioPlayer.pause();
                          } else {
                            setState(() {
                              _playingIndex = index;
                              _isPlaying = true;
                            });
                            try {
                              await _audioPlayer.stop();
                              await _audioPlayer.setFilePath(material.content);
                              await _audioPlayer.play();
                              _audioPlayer.playerStateStream.listen((state) {
                                if (state.processingState == ProcessingState.completed) {
                                  setState(() {
                                    _isPlaying = false;
                                    _playingIndex = null;
                                  });
                                }
                              });
                            } catch (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not play audio.')),
                              );
                            }
                          }
                        },
                      ),
                    ),
              ),
                  // Body of the tile (navigates to detail)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MomentDetailPage(
                              moment: Moment.create(
                                title: material.title,
                                materials: [material],
                  ),
                ),
              ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                            Text(material.title),
                            SizedBox(height: 4),
                            Text(
                              material.type == MomentMaterialType.voice && material.transcript != null
                                  ? 'Voice & Transcript'
                                  : material.type.label,
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        ),
                    ),
                  ),
                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete_outline),
                onPressed: () {
                      setState(() {
                        materials.removeAt(index);
                      });
                      // Update the moment in storage
                      if (_moment != null) {
                        final storageService = ref.read(storageServiceProvider);
                        _moment!.materials = materials.toList();
                        storageService.saveMoment(_moment!);
                        ref.refresh(momentsProvider);
                      }
                    },
              ),
            ],
          ),
            );
          },
        ),
      ],
    );
  }
}

// Add Material Modal
class AddMaterialModal extends ConsumerStatefulWidget {
  final Function(MaterialItem, String?) onAddMaterial;

  const AddMaterialModal({super.key, required this.onAddMaterial});

  @override
  _AddMaterialModalState createState() => _AddMaterialModalState();
}

class _AddMaterialModalState extends ConsumerState<AddMaterialModal> {
  final TextEditingController _textController = TextEditingController();
  final List<MaterialItem> tempMaterials = [];
  bool _isRecording = false;
  int _selectedStyle = -1;
  bool _isGeneratingImage = false;

  // Add at top of state
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void dispose() {
    _textController.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _recordDuration = Duration.zero;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _recordDuration += const Duration(seconds: 1));
      }
    });
  }

  void _stopTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$m:$s';
  }

  Future<void> _toggleRecording() async {
    if (_isGeneratingImage) return; // Prevent recording while generating image
    // Access capture service via Riverpod
    final captureService = ref.read(captureServiceProvider);

    if (!_isRecording) {
      final hasPermission = await captureService.checkPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission not granted')),
          );
        }
        print('[AddMaterialModal] Microphone permission not granted');
        return;
      }

      // Enable wakelock before starting recording
      await WakelockPlus.enable();
      await captureService.startRecording();
      _startTimer();
      if (mounted) setState(() => _isRecording = true);
    } else {
      // Disable wakelock after stopping recording
      await WakelockPlus.disable();
      _stopTimer();
      if (mounted) setState(() => _isRecording = false);
      final path = await captureService.stopRecording();
      print('[AddMaterialModal] Stopped recording, path: \\${path}');
      if (mounted) {
        setState(() => _isRecording = false);
      }

      if (path != null) {
        // Show a snackbar while transcribing
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transcribing audio...')),
          );
        }

        String? transcript;
        String title = 'Voice Clip \\${tempMaterials.length + 1}';
        String? imagePath;
        try {
          final sttService = ref.read(sttServiceProvider);
          transcript = await sttService.transcribe(path);
          print('[AddMaterialModal] Transcript: \\${transcript}');
          if (transcript != null && transcript.isNotEmpty) {
            title = await sttService.generateShortTitle(transcript);
            print('[AddMaterialModal] Generated title: \\${title}');
            if (mounted) {
              setState(() => _isGeneratingImage = true);
            }
            // Save the material and moment immediately, with fallback image
            imagePath = 'assets/images/santorini.jpg';
            final voiceMaterial = MaterialItem(
              title: title,
              type: MomentMaterialType.voice,
              content: path,
              transcript: transcript,
            );
            print('[AddMaterialModal] Calling onAddMaterial with: \\${voiceMaterial.title}, imagePath: \\${imagePath}');
            if (mounted) {
              setState(() {
                tempMaterials.add(voiceMaterial);
              });
            }
            widget.onAddMaterial(voiceMaterial, imagePath);
            print('[AddMaterialModal] Modal closing after add');
            if (mounted) Navigator.of(context).pop();
            // Generate image in background
            _generateAndUpdateImage(transcript, path);
          } else {
            // If no transcript, fallback to static image
            imagePath = 'assets/images/santorini.jpg';
            final voiceMaterial = MaterialItem(
              title: title,
              type: MomentMaterialType.voice,
              content: path,
              transcript: transcript,
            );
            print('[AddMaterialModal] No transcript, calling onAddMaterial with: \\${voiceMaterial.title}, imagePath: \\${imagePath}');
            if (mounted) {
              setState(() {
                tempMaterials.add(voiceMaterial);
              });
            }
            widget.onAddMaterial(voiceMaterial, imagePath);
            print('[AddMaterialModal] Modal closing after add (no transcript)');
            if (mounted) Navigator.of(context).pop();
          }
        } catch (e) {
          print('[AddMaterialModal] Error during transcription or add: \\${e}');
          if (mounted) {
            setState(() => _isGeneratingImage = false);
          }
        }
      }
    }
  }

  Future<void> _generateAndUpdateImage(String transcript, String path) async {
    try {
      final sttService = ref.read(sttServiceProvider);
      final storageService = ref.read(storageServiceProvider);
      final allMoments = await storageService.getAllMoments();
      // Find the most recent moment (by createdAt)
      allMoments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latestMoment = allMoments.firstWhere(
        (m) => m.materials.isNotEmpty && m.materials.last.content == path,
        orElse: () => allMoments.first,
      );

      // Use StorageService's static method for background image generation
      StorageService.generateImageAndUpdateMoment(
        momentId: latestMoment.id,
        transcript: transcript,
        sttService: sttService,
        onMomentUpdated: () {
          if (mounted) {
            ref.refresh(momentsProvider);
          }
        },
      );
    } catch (e) {
      print('Error generating image: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
      }
    }
  }

  void _addTextMaterial() {
    if (_textController.text.isNotEmpty) {
      final material = MaterialItem(
        title: 'Text Note ${tempMaterials.length + 1}',
        type: MomentMaterialType.text,
        content: _textController.text,
      );
      setState(() {
        tempMaterials.add(material);
        widget.onAddMaterial(material, null);
        _textController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ←— Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.close, size: 24, color: Colors.grey[700]),
                  onPressed: () {
                    if (_isRecording) {
                      _toggleRecording();   // stop if still recording
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // …existing ElevatedButton.icon for recording …
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isGeneratingImage
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 28),
                label: Text(
                  _isGeneratingImage
                      ? 'Generating Picture…'
                      : (_isRecording
                          ? _formatDuration(_recordDuration)
                          : 'Start Recording'),
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                ),
                onPressed: _isGeneratingImage ? null : _toggleRecording,
              ),
            ),
            // …the rest of your tempMaterials list …
          ],
        ),
      ),
    );
  }
}
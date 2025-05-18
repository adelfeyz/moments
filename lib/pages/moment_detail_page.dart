import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/moment.dart';

class MomentDetailPage extends StatefulWidget {
  final Moment moment;
  const MomentDetailPage({super.key, required this.moment});

  @override
  State<MomentDetailPage> createState() => _MomentDetailPageState();
}

class _MomentDetailPageState extends State<MomentDetailPage> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final path = widget.moment.audioPath;
    if (path != null) {
      try {
        await _player.setFilePath(path);
        setState(() {
          _isReady = true;
        });
      } catch (_) {
        // ignore errors; keep _isReady false
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (!_isReady) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moment.title ?? 'Moment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      iconSize: 40,
                      icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                      onPressed: _isReady ? _togglePlay : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(_isReady
                          ? (widget.moment.materials.isNotEmpty
                              ? widget.moment.materials.first.title
                              : 'Voice Recording')
                          : 'No audio available'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Transcript',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.moment.transcript ?? 'No transcript available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
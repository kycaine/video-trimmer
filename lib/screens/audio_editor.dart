import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/audio_placeholder.dart';
import '../widgets/timeline_slider.dart';
import '../providers/clip_list_provider.dart';
import '../models/clip_model.dart';
import '../services/audio_service.dart';

/// Screen editor audio — mirror dari VideoEditor tapi dengan AudioPlaceholder.
/// Menggunakan clipListProvider yang sudah ada (shared).
class AudioEditor extends ConsumerStatefulWidget {
  final File file;

  const AudioEditor({super.key, required this.file});

  @override
  ConsumerState<AudioEditor> createState() => _AudioEditorState();
}

class _AudioEditorState extends ConsumerState<AudioEditor> {
  late final Player _player = Player();
  bool _initialized = false;

  Duration? _currentStart;
  Duration? _currentEnd;

  @override
  void initState() {
    super.initState();

    _player.stream.duration.listen((duration) {
      if (duration > Duration.zero) {
        if (mounted) {
          setState(() {
            if (!_initialized) {
              _initialized = true;
              _currentStart = Duration.zero;
              _currentEnd = duration;
            } else {
              if (_currentEnd == _player.state.duration ||
                  _currentEnd! > duration) {
                _currentEnd = duration;
              }
            }
          });
        }
      }
    });

    _player.open(Media(widget.file.path), play: false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _addClip() {
    if (_currentStart != null && _currentEnd != null) {
      if (_currentStart! >= _currentEnd!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Start time must be before End time.')),
        );
        return;
      }
      ref.read(clipListProvider.notifier).addClip(
            ClipModel(start: _currentStart!, end: _currentEnd!),
          );
    }
  }

  void _exportClips(List<ClipModel> clips) async {
    ValueNotifier<int> currentClipNotifier = ValueNotifier(1);
    ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cutting Audio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: currentClipNotifier,
                builder: (context, current, _) =>
                    Text('Processing Clip $current of ${clips.length}'),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, progress, _) => Column(
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text('${(progress * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Please keep the app open.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );

    try {
      final savedPaths = await AudioService.cutAudioClips(
        inputFile: widget.file,
        clips: clips,
        onProgress: (current, total, progress) {
          currentClipNotifier.value = current;
          progressNotifier.value = progress;
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        if (savedPaths.isNotEmpty) {
          final String originalExt = widget.file.path.split('.').last;
          int successCount = 0;

          for (int i = 0; i < savedPaths.length; i++) {
            final String defaultFileName = 'audiocut_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.$originalExt';
            
            try {
              final tempFile = File(savedPaths[i]);
              final bytes = await tempFile.readAsBytes();

              final savedPath = await FilePicker.platform.saveFile(
                dialogTitle: 'Save Audio Clip ${i + 1} of ${savedPaths.length}',
                fileName: defaultFileName,
                bytes: bytes,
              );

              if (savedPath != null) {
                successCount++;
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save Clip ${i + 1}: $e')),
                );
              }
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$successCount of ${savedPaths.length} audio clip(s) saved successfully!'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio cut failed. Please try again.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clips = ref.watch(clipListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text('Cut Audio',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Audio Placeholder (instead of video preview)
            Expanded(
              flex: 4,
              child: Center(
                child: AudioPlaceholder(player: _player, file: widget.file),
              ),
            ),
            // Timeline + Range Slider + Clip list
            Expanded(
              flex: 5,
              child: !_initialized
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TimelineSlider(player: _player),
                          const SizedBox(height: 16),
                          if (_currentStart != null &&
                              _currentEnd != null &&
                              _player.state.duration.inMilliseconds > 0)
                            Column(
                              children: [
                                RangeSlider(
                                  min: 0.0,
                                  max: _player
                                      .state.duration.inMilliseconds
                                      .toDouble(),
                                  values: RangeValues(
                                    _currentStart!.inMilliseconds
                                        .toDouble()
                                        .clamp(
                                            0.0,
                                            _player.state.duration
                                                .inMilliseconds
                                                .toDouble()),
                                    _currentEnd!.inMilliseconds
                                        .toDouble()
                                        .clamp(
                                            0.0,
                                            _player.state.duration
                                                .inMilliseconds
                                                .toDouble()),
                                  ),
                                  onChanged: (RangeValues values) {
                                    setState(() {
                                      _currentStart = Duration(
                                          milliseconds:
                                              values.start.toInt());
                                      _currentEnd = Duration(
                                          milliseconds:
                                              values.end.toInt());
                                    });
                                    _player.seek(Duration(
                                        milliseconds:
                                            values.start.toInt()));
                                  },
                                  activeColor: Colors.deepPurple,
                                  inactiveColor: Colors.grey,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'Start: ${_formatDuration(_currentStart!)}'),
                                    Text(
                                        'End: ${_formatDuration(_currentEnd!)}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _addClip,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Clip'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          const Divider(height: 16),
                          Expanded(
                            child: clips.isEmpty
                                ? const Center(
                                    child: Text('No clips added yet.'))
                                : ListView.builder(
                                    itemCount: clips.length,
                                    itemBuilder: (context, index) {
                                      final clip = clips[index];
                                      return ListTile(
                                        leading: const Icon(
                                            Icons.music_note,
                                            color: Colors.deepPurple),
                                        title: Text('Clip ${index + 1}'),
                                        subtitle: Text(
                                            '${_formatDuration(clip.start)} - ${_formatDuration(clip.end)}'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.redAccent),
                                          onPressed: () {
                                            ref
                                                .read(clipListProvider
                                                    .notifier)
                                                .removeClip(index);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: clips.isEmpty
                                ? null
                                : () => _exportClips(clips),
                            icon: const Icon(Icons.content_cut),
                            label: const Text('Export All Audio Clips'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

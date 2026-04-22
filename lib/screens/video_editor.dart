import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../widgets/video_preview.dart';
import '../widgets/timeline_slider.dart';
import '../providers/clip_list_provider.dart';
import '../models/clip_model.dart';
import '../providers/export_mode_provider.dart';
import '../services/ffmpeg_export_service.dart';

class VideoEditor extends ConsumerStatefulWidget {
  final File file;

  const VideoEditor({super.key, required this.file});

  @override
  ConsumerState<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends ConsumerState<VideoEditor> {
  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);
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
              if (_currentEnd == _player.state.duration || _currentEnd! > duration) {
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
          const SnackBar(content: Text('Start time must be before End time.')),
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
          title: const Text('Exporting Clips'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: currentClipNotifier,
                builder: (context, current, _) => Text('Processing Clip $current of ${clips.length}'),
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
              const Text('Please keep the app open.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );

    try {
      await FFmpegExportService.exportClips(
        inputFile: widget.file,
        clips: clips,
        mode: ExportMode.precise,
        onProgress: (current, total, progress) {
          currentClipNotifier.value = current;
          progressNotifier.value = progress;
        },
      );
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export complete! Check your gallery.')),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text('Trim Video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: VideoPreview(player: _player, controller: _controller),
              ),
            ),
            Expanded(
              flex: 5,
              child: !_initialized 
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TimelineSlider(player: _player),
                        const SizedBox(height: 16),
                        if (_currentStart != null && _currentEnd != null && _player.state.duration.inMilliseconds > 0)
                          Column(
                            children: [
                              RangeSlider(
                                min: 0.0,
                                max: _player.state.duration.inMilliseconds.toDouble(),
                                values: RangeValues(
                                  _currentStart!.inMilliseconds.toDouble().clamp(0.0, _player.state.duration.inMilliseconds.toDouble()),
                                  _currentEnd!.inMilliseconds.toDouble().clamp(0.0, _player.state.duration.inMilliseconds.toDouble()),
                                ),
                                onChanged: (RangeValues values) {
                                  setState(() {
                                    _currentStart = Duration(milliseconds: values.start.toInt());
                                    _currentEnd = Duration(milliseconds: values.end.toInt());
                                  });
                                  _player.seek(Duration(milliseconds: values.start.toInt()));
                                },
                                activeColor: Colors.deepPurple,
                                inactiveColor: Colors.grey,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Start: ${_formatDuration(_currentStart!)}'),
                                  Text('End: ${_formatDuration(_currentEnd!)}'),
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
                              ? const Center(child: Text('No clips added yet.'))
                              : ListView.builder(
                                  itemCount: clips.length,
                                  itemBuilder: (context, index) {
                                    final clip = clips[index];
                                    return ListTile(
                                      title: Text('Clip ${index + 1}'),
                                      subtitle: Text('${_formatDuration(clip.start)} - ${_formatDuration(clip.end)}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () {
                                          ref.read(clipListProvider.notifier).removeClip(index);
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: clips.isEmpty ? null : () => _exportClips(clips),
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Export All (Precise Mode)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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

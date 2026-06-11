import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:file_picker/file_picker.dart';
import '../services/audio_service.dart';

/// Screen khusus untuk konversi Video → Audio.
/// Terpisah dari VideoEditor dan AudioEditor.
class VideoConverterScreen extends ConsumerStatefulWidget {
  final File file;

  const VideoConverterScreen({super.key, required this.file});

  @override
  ConsumerState<VideoConverterScreen> createState() =>
      _VideoConverterScreenState();
}

class _VideoConverterScreenState extends ConsumerState<VideoConverterScreen> {
  late final Player _player = Player();
  bool _initialized = false;
  bool _isConverting = false;
  AudioOutputFormat _selectedFormat = AudioOutputFormat.aac;

  @override
  void initState() {
    super.initState();

    _player.stream.duration.listen((duration) {
      if (duration > Duration.zero && mounted) {
        setState(() {
          _initialized = true;
        });
      }
    });

    _player.open(Media(widget.file.path), play: false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String get _fileName => widget.file.path.split('/').last;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _convert() async {
    setState(() => _isConverting = true);
    ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Converting to ${_selectedFormat.label}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Extracting audio from video...'),
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
      final outputPath = await AudioService.convertVideoToAudio(
        inputFile: widget.file,
        videoDuration: _player.state.duration,
        format: _selectedFormat,
        onProgress: (progress) {
          progressNotifier.value = progress;
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        if (outputPath != null) {
          final String originalName = widget.file.path.split('/').last.split('.').first;
          final String defaultFileName = '${originalName}_audio.${_selectedFormat.extension}';

          try {
            final tempFile = File(outputPath);
            final bytes = await tempFile.readAsBytes();

            final savedPath = await FilePicker.platform.saveFile(
              dialogTitle: 'Save Audio File',
              fileName: defaultFileName,
              bytes: bytes,
            );

            if (savedPath != null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_selectedFormat.label} saved successfully to $savedPath'),
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Save cancelled. Converted audio remains in app cache.')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save file: $e')),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversion failed. Try a different format.'),
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
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  const Text('Video to Audio',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Content
            Expanded(
              child: !_initialized
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Video file icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.videocam,
                                size: 56, color: Colors.teal),
                          ),
                          const SizedBox(height: 24),
                          // File name
                          Text(
                            _fileName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Duration
                          Text(
                            'Duration: ${_formatDuration(_player.state.duration)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Format selector
                          Text(
                            'Output Format',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: AudioOutputFormat.values.map((format) {
                              final isSelected = _selectedFormat == format;
                              return ChoiceChip(
                                label: Text(format.label),
                                selected: isSelected,
                                onSelected: _isConverting
                                    ? null
                                    : (selected) {
                                        if (selected) {
                                          setState(
                                              () => _selectedFormat = format);
                                        }
                                      },
                                selectedColor:
                                    Colors.teal.withValues(alpha: 0.25),
                                labelStyle: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.teal
                                      : colorScheme.onSurfaceVariant,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),
                          // Convert button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (_initialized && !_isConverting)
                                  ? _convert
                                  : null,
                              icon: const Icon(Icons.swap_horiz),
                              label: Text(_isConverting
                                  ? 'Converting...'
                                  : 'Convert to ${_selectedFormat.label}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
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

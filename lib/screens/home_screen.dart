import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/video_state_provider.dart';
import '../providers/clip_list_provider.dart';
import '../providers/theme_provider.dart';
import 'video_editor.dart';
import 'audio_editor.dart';
import 'video_converter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _requestPermissions() async {
    await [
      Permission.videos,
      Permission.photos,
      Permission.notification,
      Permission.storage,
      Permission.audio,
    ].request();
  }

  Future<void> _pickVideoForTrim(BuildContext context, WidgetRef ref) async {
    await _requestPermissions();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      ref.read(videoStateProvider.notifier).setVideo(file, Duration.zero);
      ref.read(clipListProvider.notifier).clear();

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => VideoEditor(file: file)),
        );
      }
    }
  }

  Future<void> _pickVideoForConvert(BuildContext context, WidgetRef ref) async {
    await _requestPermissions();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => VideoConverterScreen(file: file)),
        );
      }
    }
  }

  Future<void> _pickAudioForCut(BuildContext context, WidgetRef ref) async {
    await _requestPermissions();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      ref.read(clipListProvider.notifier).clear();

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AudioEditor(file: file)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KyStudio'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _requestPermissions(),
          ),
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Welcome to KyStudio',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a tool to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // Feature Cards
              Expanded(
                child: ListView(
                  children: [
                    // ── Card 1: Video Trimmer ──
                    _FeatureCard(
                      icon: Icons.content_cut,
                      iconColor: Colors.deepPurple,
                      title: 'Video Trimmer',
                      subtitle: 'Potong video menjadi beberapa clip dan export.',
                      buttonLabel: 'Select Video',
                      buttonColor: Colors.deepPurple,
                      onPressed: () => _pickVideoForTrim(context, ref),
                    ),
                    const SizedBox(height: 16),
                    // ── Card 2: Video to MP3 ──
                    _FeatureCard(
                      icon: Icons.swap_horiz,
                      iconColor: Colors.teal,
                      title: 'Video to MP3',
                      subtitle: 'Konversi video menjadi file audio MP3 (192kbps).',
                      buttonLabel: 'Select Video',
                      buttonColor: Colors.teal,
                      onPressed: () => _pickVideoForConvert(context, ref),
                    ),
                    const SizedBox(height: 16),
                    // ── Card 3: Audio Cutter ──
                    _FeatureCard(
                      icon: Icons.music_note,
                      iconColor: Colors.orange,
                      title: 'Audio Cutter',
                      subtitle: 'Potong file audio menjadi beberapa clip dan export.',
                      buttonLabel: 'Select Audio',
                      buttonColor: Colors.orange,
                      onPressed: () => _pickAudioForCut(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card widget untuk setiap fitur di home screen.
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onPressed;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 30, color: iconColor),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

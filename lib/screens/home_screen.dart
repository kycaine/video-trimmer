import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/video_state_provider.dart';
import '../providers/clip_list_provider.dart';
import '../providers/theme_provider.dart';
import 'video_editor.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _requestPermissions() async {
    await [
      Permission.videos,
      Permission.photos,
      Permission.notification,
      Permission.storage,
    ].request();
  }

  Future<void> _pickVideo(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ky-Cut'),
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
      floatingActionButton: null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Ky-Cut',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Pick a video to start trimming'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _pickVideo(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Select a Video'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

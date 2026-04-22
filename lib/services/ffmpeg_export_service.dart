import 'dart:io';
import 'dart:async';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/clip_model.dart';
import '../providers/export_mode_provider.dart';

class FFmpegExportService {
  static const String channelId = 'export_channel_v2';
  static const int notificationId = 999;
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _notifications.initialize(
      settings: initSettings,
    );
  }

  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitMillis = (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds.$twoDigitMillis";
  }

  static Future<void> _updateNotification(String title, String body) async {
    const android = AndroidNotificationDetails(
      channelId,
      'Video Export',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
      ongoing: true,
    );
    const details = NotificationDetails(android: android);
    await _notifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static Future<void> exportClips({
    required File inputFile,
    required List<ClipModel> clips,
    required ExportMode mode,
    required Function(int current, int total, double progress) onProgress,
  }) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String tempPath = '${tempDir.path}/export_temp';
    final outputDir = Directory(tempPath);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    int total = clips.length;

    for (int i = 0; i < total; i++) {
      final clip = clips[i];
      final String startStr = _formatDuration(clip.start);
      final String endStr = _formatDuration(clip.end);
      final String outputPath = '$tempPath/clip_${i+1}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      List<String> commandArgs;
      if (mode == ExportMode.fast) {
        commandArgs = ['-y', '-ss', startStr, '-to', endStr, '-i', inputFile.path, '-c', 'copy', outputPath];
      } else {
        commandArgs = ['-y', '-ss', startStr, '-to', endStr, '-i', inputFile.path, '-c:v', 'libx264', '-preset', 'ultrafast', '-c:a', 'aac', outputPath];
      }

      await _updateNotification('Exporting Clip ${i + 1}/$total', 'Processing...');
      onProgress(i + 1, total, 0.0);

      final completer = Completer<void>();

      await FFmpegKit.executeWithArgumentsAsync(
        commandArgs,
        (session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            await Gal.putVideo(outputPath, album: 'VideoTrimmer');
          }
          completer.complete();
        },
        (log) {},
        (statistics) {
          final clipDurationMs = (clip.end - clip.start).inMilliseconds;
          final currentMs = statistics.getTime();
          double progress = 0.0;
          if (clipDurationMs > 0 && currentMs > 0) {
            progress = currentMs / clipDurationMs;
          }
          onProgress(i + 1, total, progress.clamp(0.0, 1.0));
        },
      );

      await completer.future;
      onProgress(i + 1, total, 1.0);
    }

    await _notifications.show(
      id: notificationId,
      title: 'Export Complete',
      body: 'All clips saved to Gallery',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(channelId, 'Video Export', importance: Importance.high),
      ),
    );
  }
}

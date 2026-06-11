import 'dart:io';
import 'dart:async';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/clip_model.dart';

/// Service FFmpeg terpisah untuk operasi audio.
/// TIDAK mengubah FFmpegExportService yang sudah ada.
class AudioService {
  static const String _channelId = 'audio_export_channel';
  static const int _notificationId = 998;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;

  /// Lazy-init notifications (reuses FFmpegExportService init if already done).
  static Future<void> _ensureNotificationsInitialized() async {
    if (_notificationsInitialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _notifications.initialize(settings: initSettings);
    _notificationsInitialized = true;
  }

  /// Format durasi ke string HH:MM:SS.ms untuk FFmpeg.
  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitMillis =
        (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds.$twoDigitMillis";
  }

  /// Update notifikasi progress.
  static Future<void> _updateNotification(String title, String body) async {
    await _ensureNotificationsInitialized();
    const android = AndroidNotificationDetails(
      _channelId,
      'Audio Export',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
      ongoing: true,
    );
    const details = NotificationDetails(android: android);
    await _notifications.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Mendapatkan direktori output untuk file audio.
  /// Menggunakan external storage agar file bisa diakses user.
  static Future<String> _getOutputDir() async {
    final Directory? extDir = await getExternalStorageDirectory();
    final String basePath = extDir?.path ?? (await getTemporaryDirectory()).path;
    final String outputPath = '$basePath/KyCut_Audio';
    final dir = Directory(outputPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return outputPath;
  }

  /// ─────────────────────────────────────────────
  /// CUT AUDIO (Multi-Clip)
  /// ─────────────────────────────────────────────
  /// Memotong file audio menjadi beberapa clip.
  /// Menggunakan `-c copy` untuk stream copy (sangat cepat).
  static Future<List<String>> cutAudioClips({
    required File inputFile,
    required List<ClipModel> clips,
    required Function(int current, int total, double progress) onProgress,
  }) async {
    final String outputDir = await _getOutputDir();
    final String inputExt = inputFile.path.split('.').last.toLowerCase();
    final int total = clips.length;
    final List<String> outputPaths = [];

    for (int i = 0; i < total; i++) {
      final clip = clips[i];
      final String startStr = _formatDuration(clip.start);

      final String outputPath =
          '$outputDir/audiocut_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.$inputExt';

      final duration = clip.end - clip.start;
      final String durationStr = _formatDuration(duration);

      // FFmpeg command: Re-encode audio for precise cutting (audio encoding is fast)
      final List<String> commandArgs = [
        '-y',
        '-ss', startStr,
        '-i', inputFile.path,
        '-t', durationStr,
        // Since we don't know the exact format, we re-encode to a standard format based on extension, or use a default
        if (inputExt == 'mp3') ...['-c:a', 'libmp3lame', '-b:a', '192k']
        else if (inputExt == 'm4a') ...['-c:a', 'aac', '-b:a', '192k']
        else if (inputExt == 'wav') ...['-c:a', 'pcm_s16le']
        else ...['-c:a', 'aac', '-b:a', '192k'], // fallback
        outputPath,
      ];

      await _updateNotification(
          'Cutting Audio ${i + 1}/$total', 'Processing...');
      onProgress(i + 1, total, 0.0);

      final completer = Completer<void>();

      await FFmpegKit.executeWithArgumentsAsync(
        commandArgs,
        (session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            outputPaths.add(outputPath);
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

    final List<String> savedPaths = [];
    for (final path in outputPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          savedPaths.add(path);
        }
      } catch (_) {
        // Skip files that can't be verified
      }
    }

    await _ensureNotificationsInitialized();
    await _notifications.show(
      id: _notificationId,
      title: 'Audio Cut Complete',
      body: '${savedPaths.length} clips saved to KyCut_Audio folder',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Audio Export',
          importance: Importance.high,
        ),
      ),
    );

    return savedPaths;
  }

  /// ─────────────────────────────────────────────
  /// CONVERT VIDEO TO AUDIO
  /// ─────────────────────────────────────────────
  /// Mengekstrak audio dari video ke format yang dipilih.
  /// Menggunakan native encoder yang tersedia di ffmpeg_kit min-gpl.
  static Future<String?> convertVideoToAudio({
    required File inputFile,
    required Duration videoDuration,
    required AudioOutputFormat format,
    required Function(double progress) onProgress,
  }) async {
    final String outputDir = await _getOutputDir();
    final String outputPath =
        '$outputDir/converted_${DateTime.now().millisecondsSinceEpoch}.${format.extension}';

    final List<String> commandArgs = [
      '-y',
      '-i', inputFile.path,
      '-vn',
      ...format.codecArgs,
      outputPath,
    ];

    await _updateNotification('Converting to ${format.label}', 'Processing...');
    onProgress(0.0);

    final completer = Completer<bool>();

    await FFmpegKit.executeWithArgumentsAsync(
      commandArgs,
      (session) async {
        final returnCode = await session.getReturnCode();
        completer.complete(ReturnCode.isSuccess(returnCode));
      },
      (log) {},
      (statistics) {
        final totalMs = videoDuration.inMilliseconds;
        final currentMs = statistics.getTime();
        double progress = 0.0;
        if (totalMs > 0 && currentMs > 0) {
          progress = currentMs / totalMs;
        }
        onProgress(progress.clamp(0.0, 1.0));
      },
    );

    final success = await completer.future;

    await _ensureNotificationsInitialized();
    await _notifications.show(
      id: _notificationId,
      title: success ? 'Conversion Complete' : 'Conversion Failed',
      body: success
          ? '${format.label} saved to KyCut_Audio folder'
          : 'Failed to convert video',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Audio Export',
          importance: Importance.high,
        ),
      ),
    );

    return success ? outputPath : null;
  }
}

/// Format output audio yang tersedia untuk konversi.
enum AudioOutputFormat {
  aac(
    label: 'AAC (.m4a)',
    extension: 'm4a',
    codecArgs: ['-c:a', 'aac', '-b:a', '192k'],
  ),
  mp3(
    label: 'MP3 (.mp3)',
    extension: 'mp3',
    codecArgs: ['-c:a', 'libmp3lame', '-b:a', '192k'],
  ),
  wav(
    label: 'WAV (.wav)',
    extension: 'wav',
    codecArgs: ['-c:a', 'pcm_s16le'],
  ),
  flac(
    label: 'FLAC (.flac)',
    extension: 'flac',
    codecArgs: ['-c:a', 'flac'],
  );

  final String label;
  final String extension;
  final List<String> codecArgs;

  const AudioOutputFormat({
    required this.label,
    required this.extension,
    required this.codecArgs,
  });
}

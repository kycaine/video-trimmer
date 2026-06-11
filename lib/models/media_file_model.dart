import 'dart:io';

/// Tipe media yang didukung oleh KyStudio.
enum MediaFileType { video, audio }

/// Model yang membungkus File beserta tipe medianya.
class MediaFileModel {
  final File file;
  final MediaFileType type;

  MediaFileModel({required this.file, required this.type});

  bool get isVideo => type == MediaFileType.video;
  bool get isAudio => type == MediaFileType.audio;

  /// Menentukan extension file asli (lowercase, tanpa dot).
  String get extension => file.path.split('.').last.toLowerCase();

  /// Factory yang otomatis mendeteksi tipe berdasarkan extension.
  factory MediaFileModel.fromFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    const audioExtensions = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'];
    final type = audioExtensions.contains(ext)
        ? MediaFileType.audio
        : MediaFileType.video;
    return MediaFileModel(file: file, type: type);
  }
}

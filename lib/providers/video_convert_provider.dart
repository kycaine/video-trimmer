import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State untuk proses Convert Video to MP3.
/// Terpisah sepenuhnya dari video trimmer state.
class VideoConvertState {
  final bool isConverting;
  final double progress;
  final String? error;

  const VideoConvertState({
    this.isConverting = false,
    this.progress = 0.0,
    this.error,
  });

  VideoConvertState copyWith({
    bool? isConverting,
    double? progress,
    String? error,
  }) {
    return VideoConvertState(
      isConverting: isConverting ?? this.isConverting,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

class VideoConvertNotifier extends Notifier<VideoConvertState> {
  @override
  VideoConvertState build() => const VideoConvertState();

  void startConvert() {
    state = const VideoConvertState(isConverting: true);
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void setError(String message) {
    state = state.copyWith(
      isConverting: false,
      error: message,
    );
  }

  void reset() {
    state = const VideoConvertState();
  }
}

final videoConvertProvider =
    NotifierProvider<VideoConvertNotifier, VideoConvertState>(
        VideoConvertNotifier.new);

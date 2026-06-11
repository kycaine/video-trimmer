import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State untuk proses Audio Cut (multi-clip).
/// Terpisah sepenuhnya dari video trimmer state.
class AudioCutState {
  final bool isExporting;
  final double progress;
  final int currentClip;
  final int totalClips;
  final String? error;

  const AudioCutState({
    this.isExporting = false,
    this.progress = 0.0,
    this.currentClip = 0,
    this.totalClips = 0,
    this.error,
  });

  AudioCutState copyWith({
    bool? isExporting,
    double? progress,
    int? currentClip,
    int? totalClips,
    String? error,
  }) {
    return AudioCutState(
      isExporting: isExporting ?? this.isExporting,
      progress: progress ?? this.progress,
      currentClip: currentClip ?? this.currentClip,
      totalClips: totalClips ?? this.totalClips,
      error: error,
    );
  }
}

class AudioCutNotifier extends Notifier<AudioCutState> {
  @override
  AudioCutState build() => const AudioCutState();

  void startExport(int totalClips) {
    state = AudioCutState(
      isExporting: true,
      totalClips: totalClips,
      currentClip: 1,
    );
  }

  void updateProgress(int currentClip, double progress) {
    state = state.copyWith(
      currentClip: currentClip,
      progress: progress,
    );
  }

  void setError(String message) {
    state = state.copyWith(
      isExporting: false,
      error: message,
    );
  }

  void reset() {
    state = const AudioCutState();
  }
}

final audioCutProvider =
    NotifierProvider<AudioCutNotifier, AudioCutState>(AudioCutNotifier.new);

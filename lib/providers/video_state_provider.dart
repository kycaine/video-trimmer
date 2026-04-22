import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoState {
  final File? file;
  final Duration? duration;

  VideoState({this.file, this.duration});

  VideoState copyWith({File? file, Duration? duration}) {
    return VideoState(
      file: file ?? this.file,
      duration: duration ?? this.duration,
    );
  }
}

class VideoStateNotifier extends Notifier<VideoState> {
  @override
  VideoState build() => VideoState();

  void setVideo(File file, Duration duration) {
    state = VideoState(file: file, duration: duration);
  }

  void clear() {
    state = VideoState();
  }
}

final videoStateProvider = NotifierProvider<VideoStateNotifier, VideoState>(VideoStateNotifier.new);

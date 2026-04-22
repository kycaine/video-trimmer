class ClipModel {
  final Duration start;
  final Duration end;

  ClipModel({required this.start, required this.end});

  ClipModel copyWith({Duration? start, Duration? end}) {
    return ClipModel(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

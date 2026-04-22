import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class TimelineSlider extends StatefulWidget {
  final Player player;

  const TimelineSlider({super.key, required this.player});

  @override
  State<TimelineSlider> createState() => _TimelineSliderState();
}

class _TimelineSliderState extends State<TimelineSlider> {
  bool _wasPlaying = false;
  // ignore: unused_field
  bool _isDragging = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _onDragStart(DragStartDetails details, double width) {
    _wasPlaying = widget.player.state.playing;
    if (_wasPlaying) widget.player.pause();
    _isDragging = true;
    _seekToPosition(details.localPosition.dx, width);
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    _seekToPosition(details.localPosition.dx, width);
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    if (_wasPlaying) widget.player.play();
  }

  void _seekToPosition(double localX, double width) {
    final dx = localX.clamp(0.0, width);
    final ratio = dx / width;
    final duration = widget.player.state.duration;
    final seekTime = Duration(milliseconds: (duration.inMilliseconds * ratio).toInt());
    widget.player.seek(seekTime);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? widget.player.state.position;
        final duration = widget.player.state.duration;
        final progressRatio = duration.inMilliseconds == 0
            ? 0.0
            : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

        return Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  onHorizontalDragStart: (details) => _onDragStart(details, width),
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, width),
                  onHorizontalDragEnd: _onDragEnd,
                  onTapDown: (details) {
                    _seekToPosition(details.localPosition.dx, width);
                  },
                  child: Container(
                    height: 40,
                    color: Colors.transparent,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: width * progressRatio,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Positioned(
                          left: (width * progressRatio) - 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position)),
                Text(_formatDuration(duration)),
              ],
            ),
          ],
        );
      },
    );
  }
}

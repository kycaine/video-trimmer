import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPreview extends StatelessWidget {
  final Player player;
  final VideoController controller;

  const VideoPreview({
    super.key,
    required this.player,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Video display
        Expanded(
          child: Video(
            controller: controller,
            controls: (state) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 8),
        // Playback controls: rewind 5s, play/pause, forward 5s
        _VideoControls(player: player, colorScheme: colorScheme),
      ],
    );
  }
}

/// Kontrol playback video: rewind 5s, play/pause, forward 5s.
class _VideoControls extends StatelessWidget {
  final Player player;
  final ColorScheme colorScheme;

  const _VideoControls({
    required this.player,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rewind 5s
            IconButton(
              icon: const Icon(Icons.replay_5),
              iconSize: 32,
              color: colorScheme.onSurface,
              onPressed: () {
                final pos = player.state.position;
                final newPos = pos - const Duration(seconds: 5);
                player.seek(newPos < Duration.zero ? Duration.zero : newPos);
              },
            ),
            const SizedBox(width: 8),
            // Play / Pause
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
              ),
              child: IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 36,
                color: colorScheme.onPrimary,
                onPressed: () => player.playOrPause(),
              ),
            ),
            const SizedBox(width: 8),
            // Forward 5s
            IconButton(
              icon: const Icon(Icons.forward_5),
              iconSize: 32,
              color: colorScheme.onSurface,
              onPressed: () {
                final pos = player.state.position;
                final dur = player.state.duration;
                final newPos = pos + const Duration(seconds: 5);
                player.seek(newPos > dur ? dur : newPos);
              },
            ),
          ],
        );
      },
    );
  }
}

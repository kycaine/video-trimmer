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
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Video(
          controller: controller,
          controls: (state) => const SizedBox.shrink(),
        ),
        _ControlsOverlay(player: player),
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        player.playOrPause();
      },
      child: Center(
        child: StreamBuilder<bool>(
          stream: player.stream.playing,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 50),
              child: isPlaying
                  ? const SizedBox.shrink()
                  : Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 60.0,
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

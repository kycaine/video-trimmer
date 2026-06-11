import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

/// Widget placeholder pengganti video preview saat file audio dimuat.
/// Menampilkan icon music, nama file, dan kontrol playback audio.
class AudioPlaceholder extends StatelessWidget {
  final Player player;
  final File file;

  const AudioPlaceholder({
    super.key,
    required this.player,
    required this.file,
  });

  String get _fileName => file.path.split('/').last;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated music icon
          _PulsingMusicIcon(colorScheme: colorScheme, player: player),
          const SizedBox(height: 16),
          // File name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _fileName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),
          // Playback controls
          _AudioControls(player: player, colorScheme: colorScheme),
        ],
      ),
    );
  }
}

/// Icon musik dengan animasi pulse saat audio diputar.
class _PulsingMusicIcon extends StatefulWidget {
  final ColorScheme colorScheme;
  final Player player;

  const _PulsingMusicIcon({
    required this.colorScheme,
    required this.player,
  });

  @override
  State<_PulsingMusicIcon> createState() => _PulsingMusicIconState();
}

class _PulsingMusicIconState extends State<_PulsingMusicIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    widget.player.stream.playing.listen((playing) {
      if (!mounted) return;
      if (playing) {
        _animController.repeat(reverse: true);
      } else {
        _animController.stop();
        _animController.reset();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.colorScheme.primary.withValues(alpha: 0.15),
        ),
        child: Icon(
          Icons.music_note_rounded,
          size: 48,
          color: widget.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Kontrol playback audio (play/pause).
class _AudioControls extends StatelessWidget {
  final Player player;
  final ColorScheme colorScheme;

  const _AudioControls({
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

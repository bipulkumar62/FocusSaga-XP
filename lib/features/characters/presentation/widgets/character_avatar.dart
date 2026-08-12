import 'package:flutter/material.dart';

import '../../../../shared/widgets/character_idle_widget.dart';

/// Renders a character's art with a safe fallback chain:
/// form image asset → idle hero art → deterministic warrior silhouette.
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    super.key,
    this.imagePath,
    this.characterName = 'unknown',
    this.size = 64,
    this.paused = true,
  });

  /// Art for this specific evolution form (optional).
  final String? imagePath;

  /// Character display name ("Kairo") — drives the idle art + silhouette.
  final String characterName;

  final double size;

  /// Cheap static preview in lists; the hero still renders normally.
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final fallback = CharacterIdleWidget(
      characterName: characterName,
      width: size,
      height: size,
      paused: paused,
    );
    final path = imagePath;
    if (path == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}

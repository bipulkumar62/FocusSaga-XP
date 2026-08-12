import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The six original warrior heroes of FocusSaga XP.
///
/// `id` doubles as the asset slug: art lives at
/// `assets/characters/<id>/preview.png`. All designs are original
/// (no copyrighted IP); replace the PNGs with hand-drawn/AI art later by
/// writing to the same paths — nothing else changes.
class CharacterIdleSpec {
  const CharacterIdleSpec({
    required this.id,
    required this.name,
    required this.classTitle,
    required this.accent,
  });

  final String id;
  final String name;
  final String classTitle;

  /// Theme color used for the glow behind the hero.
  final Color accent;

  /// Relative asset path of the hero art (no `assets/` prefix — Flutter
  /// resolves it).
  String get previewPath => 'characters/$id/preview.png';

  static const List<CharacterIdleSpec> all = [
    CharacterIdleSpec(
      id: 'kairo',
      name: 'Kairo',
      classTitle: 'Flame Ronin',
      accent: Color(0xFFFF5A2A),
    ),
    CharacterIdleSpec(
      id: 'tetsu',
      name: 'Tetsu',
      classTitle: 'Iron Vanguard',
      accent: Color(0xFF4E8FE6),
    ),
    CharacterIdleSpec(
      id: 'rin',
      name: 'Rin',
      classTitle: 'Storm Blade',
      accent: Color(0xFFF2C94C),
    ),
    CharacterIdleSpec(
      id: 'kuro',
      name: 'Kuro',
      classTitle: 'Shadow Assassin',
      accent: Color(0xFF8A7FD4),
    ),
    CharacterIdleSpec(
      id: 'sora',
      name: 'Sora',
      classTitle: 'Astral Champion',
      accent: Color(0xFFC9A86A),
    ),
    CharacterIdleSpec(
      id: 'arashi',
      name: 'Arashi',
      classTitle: 'Wind Samurai',
      accent: Color(0xFF4FD1B8),
    ),
  ];

  /// Art lookup by character display name ("Kairo" → kairo). Master ids are
  /// UUIDs and never used for art lookup — pass the display name.
  static CharacterIdleSpec? forName(String? name) {
    final slug = name?.trim().toLowerCase();
    if (slug == null || slug.isEmpty) return null;
    for (final spec in all) {
      if (spec.id == slug || spec.name.toLowerCase() == slug) return spec;
    }
    return null;
  }
}

/// Renders a hero with a gentle idle loop: floating bob, subtle breathing
/// scale and a pulsing theme-colored glow. Uses `preview.png`; on a missing
/// asset it falls back to a clean warrior silhouette — never a spinner.
class CharacterIdleWidget extends StatefulWidget {
  const CharacterIdleWidget({
    super.key,
    required this.characterName,
    this.width = 96,
    this.height = 96,
    this.paused = false,
  });

  /// Character display name (e.g. "Kairo") — art resolves via
  /// [CharacterIdleSpec.forName].
  final String characterName;

  final double width;
  final double height;

  /// When true the animation loop stops at the neutral pose (cheap preview
  /// in lists; the hero still renders normally).
  final bool paused;

  @override
  State<CharacterIdleWidget> createState() => _CharacterIdleWidgetState();
}

class _CharacterIdleWidgetState extends State<CharacterIdleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutSine,
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CharacterIdleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = CharacterIdleSpec.forName(widget.characterName);
    final width = widget.width;
    final height = widget.height;
    final radius = math.min(width, height) * 0.2;
    final glow = spec?.accent ?? const Color(0xFF5A6070);

    final art = SizedBox(
      width: width,
      height: height,
      child: spec == null
          ? CharacterSilhouette(
              characterName: widget.characterName,
              width: width,
              height: height,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.asset(
                spec.previewPath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => CharacterSilhouette(
                  characterName: widget.characterName,
                  width: width,
                  height: height,
                ),
              ),
            ),
    );

    if (widget.paused) return art;

    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        // Single wave drives float, breathe and glow in sync.
        final t = _t.value;
        final float = (t - 0.5) * 10; // -5..5 px vertical bob
        final breathe = 1.0 + t * 0.04; // 1.0..1.04 scale
        final glowOpacity = 0.18 + t * 0.30; // pulsing aura
        return Transform.translate(
          offset: Offset(0, float),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: glowOpacity),
                  blurRadius: 14 + t * 18,
                  spreadRadius: 2 + t * 4,
                ),
              ],
            ),
            child: Transform.scale(
              scale: breathe,
              child: child,
            ),
          ),
        );
      },
      child: art,
    );
  }
}

/// A warrior silhouette used when a hero has no art at all. Static,
/// deterministic per name, never a spinner.
class CharacterSilhouette extends StatelessWidget {
  const CharacterSilhouette({
    super.key,
    required this.characterName,
    this.width = 64,
    this.height = 64,
  });

  final String characterName;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hash = characterName.codeUnits
        .fold<int>(0, (h, c) => (h * 31 + c) & 0xFFFFFF);
    final color = HSLColor.fromAHSL(1, (hash % 360).toDouble(), 0.30, 0.20)
        .toColor();
    return ClipRRect(
      borderRadius: BorderRadius.circular(width * 0.18),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: color,
          child: Icon(
            Icons.sports_martial_arts,
            size: width * 0.62,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

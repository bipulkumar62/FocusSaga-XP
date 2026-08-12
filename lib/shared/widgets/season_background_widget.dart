import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/season.dart';

/// One global animated background layer for the whole app.
///
/// A single `AnimationController` (16 s, loops forever) drives a
/// season-specific [CustomPainter] that lives inside a [RepaintBoundary], so
/// the animated layer repaints without rebuilding any screen widgets. Particle
/// positions are precomputed once (fractions of the canvas) and cached for the
/// painter's lifetime — no allocation per frame. The painter never recreates
/// itself; only the painter for the active season exists.
///
/// Particle budgets (per requirement): leaves ≤ 24, rain ≤ 35, snow ≤ 40,
/// petals ≤ 20, fireflies ≤ 18, aurora glow ≤ 12 + static stars.
class SeasonBackgroundWidget extends StatefulWidget {
  const SeasonBackgroundWidget({
    super.key,
    required this.season,
    this.paused = false,
  });

  final SeasonType season;

  /// When true the loop stops at t = 0 (cheap static previews).
  final bool paused;

  @override
  State<SeasonBackgroundWidget> createState() => _SeasonBackgroundWidgetState();
}

class _SeasonBackgroundWidgetState extends State<SeasonBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 16000),
  );

  final Map<SeasonType, CustomPainter> _painters = {};

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SeasonBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _painters.putIfAbsent(
          widget.season,
          () => SeasonScenePainter.create(widget.season, _controller),
        ),
        size: Size.infinite,
        isComplex: true,
      ),
    );
  }
}

/// Builds the painter for a season. Painters are cheap to construct; the
/// widget caches one per season for its whole lifetime.
abstract class SeasonScenePainter {
  static CustomPainter create(SeasonType season, Listenable repaint) {
    return switch (season) {
      SeasonType.forestMorning => ForestLeavesPainter(repaint),
      SeasonType.rainyWindow => RainPainter(repaint),
      SeasonType.snowPine => SnowPainter(repaint),
      SeasonType.sunsetGarden => PetalPainter(repaint),
      SeasonType.neonNight => FireflyParticlePainter(repaint),
      SeasonType.cherryBlossom => BlossomPetalPainter(repaint),
      SeasonType.celestialAurora => AuroraPainter(repaint),
    };
  }
}

/// One cached particle. All fields are fractions of the canvas (0..1) so the
/// field survives resizes without regenerating randomness.
class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    this.sway = 0,
    this.phase = 0,
    this.alpha = 1,
    this.colorIndex = 0,
  });

  final double x;
  final double y;

  /// Vertical progress per full animation cycle (0..1 per loop).
  final double speed;
  final double size;
  final double sway;
  final double phase;
  final double alpha;
  final int colorIndex;
}

/// Shared machinery: gradient sky, cached particle field, looping wrap.
abstract class _SeasonPainter extends CustomPainter {
  _SeasonPainter(this._animation) : super(repaint: _animation);

  final Listenable _animation;
  final math.Random _rnd = math.Random(7);

  double get t => (_animation as Animation<double>).value;

  /// Number of particles per season (within the performance budgets).
  int get particleCount;

  /// Builds the cached particle field (called once, lazily). All values are
  /// fractions of the canvas, so the field survives resizes untouched.
  List<_Particle> buildParticles(math.Random rnd);

  List<_Particle>? _particles;

  List<_Particle> get particles => _particles ??= buildParticles(_rnd);

  @override
  void paint(Canvas canvas, Size size) {
    _paintScene(canvas, size, particles);
  }

  /// Draws the sky gradient into [rect].
  void fillSky(Canvas canvas, Size size, SeasonType season) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [season.skyTop, season.skyBottom],
        ).createShader(Offset.zero & size),
    );
  }

  /// Screen position of a particle at animation time [t], looping forever.
  Offset particlePos(_Particle p, Size size, double t, {double swayScale = 1}) {
    final cycle = (p.y + p.speed * t) % 1.2 - 0.1; // wraps 0..1.1
    final swayX = p.sway * math.sin(2 * math.pi * (t + p.phase));
    return Offset(
      (p.x + swayX * swayScale) * size.width,
      cycle * size.height,
    );
  }

  /// Alpha that fades a particle out as it reaches the bottom edge.
  double fadeAtBottom(_Particle p, Size size, double t) {
    final cycle = (p.y + p.speed * t) % 1.2 - 0.1;
    if (cycle < 0.8) return 1;
    return ((1.2 - cycle) / 0.4).clamp(0.0, 1.0);
  }

  /// Blurred "mountain range" silhouettes — overlapping low-alpha shapes.
  void drawSoftRidges(
    Canvas canvas,
    Size size,
    List<Color> colors,
    List<double> heights,
    double seed,
  ) {
    final rnd = math.Random((seed * 1000).round());
    for (var layer = 0; layer < colors.length; layer++) {
      final color = colors[layer];
      final baseY = size.height * (1 - heights[layer] * 0.32);
      final path = Path()..moveTo(0, size.height);
      final step = size.width / 6;
      var y = baseY;
      for (var i = 0; i <= 6; i++) {
        y = baseY - rnd.nextDouble() * size.height * heights[layer] * 0.5;
        path.lineTo(i * step, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonPainter oldDelegate) => false;

  void _paintScene(Canvas canvas, Size size, List<_Particle> particles);
}

/// Forest Morning — soft trees, blurred blue mountains, falling leaves.
class ForestLeavesPainter extends _SeasonPainter {
  ForestLeavesPainter(super.animation);

  static const List<Color> _leafColors = [
    Color(0xFF7BA05B),
    Color(0xFFD9A441),
    Color(0xFFC97B3D),
    Color(0xFF5D8C5E),
  ];

  @override
  int get particleCount => 18;

  @override
  List<_Particle> buildParticles(math.Random rnd) => [
        for (var i = 0; i < particleCount; i++)
          _Particle(
            x: rnd.nextDouble(),
            y: rnd.nextDouble(),
            speed: 0.05 + rnd.nextDouble() * 0.05,
            size: 3 + rnd.nextDouble() * 5,
            sway: 0.02 + rnd.nextDouble() * 0.03,
            phase: rnd.nextDouble(),
            alpha: 0.65 + rnd.nextDouble() * 0.3,
            colorIndex: rnd.nextInt(_leafColors.length),
          ),
      ];

  @override
  void _paintScene(Canvas canvas, Size size, List<_Particle> particles) {
    fillSky(canvas, size, SeasonType.forestMorning);

    // Soft sunlight from the top-right.
    final sun = Offset(size.width * 0.85, size.height * 0.12);
    canvas.drawCircle(
      sun,
      size.shortestSide * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF3D6).withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: size.shortestSide)),
    );

    // Blurred blue mountains (far → near).
    drawSoftRidges(
      canvas,
      size,
      [
        const Color(0xFFB9CFE8).withValues(alpha: 0.55),
        const Color(0xFF9CBFDE).withValues(alpha: 0.65),
        const Color(0xFF7FA8C9).withValues(alpha: 0.7),
      ],
      [0.55, 0.4, 0.26],
      1,
    );

    // Tree silhouettes along the bottom.
    _drawTrees(canvas, size);

    // Falling leaves, fading out near the bottom.
    for (final p in particles) {
      final pos = particlePos(p, size, t);
      final fade = fadeAtBottom(p, size, t);
      if (fade <= 0) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(math.sin(2 * math.pi * (t + p.phase)) * 0.6);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 2.4,
          height: p.size,
        ),
        Paint()..color = _leafColors[p.colorIndex].withValues(alpha: p.alpha * fade),
      );
      canvas.restore();
    }
  }

  void _drawTrees(Canvas canvas, Size size) {
    final rnd = math.Random(3);
    final base = size.height * 0.86;
    // Ground haze.
    canvas.drawRect(
      Rect.fromLTWH(0, base, size.width, size.height - base),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF5D8C5E).withValues(alpha: 0.35),
            const Color(0xFF3E6B4F).withValues(alpha: 0.6),
          ],
        ).createShader(
          Rect.fromLTWH(0, base, size.width, size.height - base),
        ),
    );
    for (var i = 0; i < 7; i++) {
      final x = size.width * (i / 6) + (rnd.nextDouble() - 0.5) * size.width * 0.08;
      final h = size.height * (0.16 + rnd.nextDouble() * 0.12);
      final trunkH = h * 0.35;
      final w = h * 0.8;
      final top = base - h;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - w * 0.16, top + h * 0.72, w * 0.32, trunkH),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF4A5543).withValues(alpha: 0.75),
      );
      for (var layer = 0; layer < 3; layer++) {
        final ly = top + h * 0.16 * layer;
        final lw = w * (1 - layer * 0.22);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, ly),
            width: lw,
            height: lw * 0.62,
          ),
          Paint()..color = const Color(0xFF4F7A52).withValues(alpha: 0.8),
        );
      }
    }
  }
}

/// Rainy Window — deep blue dusk, soft window blur, slow rain streaks.
class RainPainter extends _SeasonPainter {
  RainPainter(super.animation);

  @override
  int get particleCount => 32;

  @override
  List<_Particle> buildParticles(math.Random rnd) => [
        for (var i = 0; i < particleCount; i++)
          _Particle(
            x: rnd.nextDouble(),
            y: rnd.nextDouble(),
            speed: 0.55 + rnd.nextDouble() * 0.35,
            size: 0.05 + rnd.nextDouble() * 0.09, // streak length (fraction)
            sway: 0.002 + rnd.nextDouble() * 0.004,
            phase: rnd.nextDouble(),
            alpha: 0.2 + rnd.nextDouble() * 0.25,
          ),
      ];

  @override
  void _paintScene(Canvas canvas, Size size, List<_Particle> particles) {
    fillSky(canvas, size, SeasonType.rainyWindow);

    // Soft window blur: faint wide vertical bands of light.
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.12 + i * 0.25);
      canvas.drawRect(
        Rect.fromLTWH(x, 0, size.width * 0.1, size.height),
        Paint()..color = Colors.white.withValues(alpha: 0.03),
      );
    }
    // Foggy glow near the horizon (window light).
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.72),
      size.shortestSide * 0.5,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFB9CCE6).withValues(alpha: 0.16),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.72),
          radius: size.shortestSide,
        )),
    );

    // Slow rain streaks, slanting gently, fading at top/bottom.
    final stroke = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final p in particles) {
      final pos = particlePos(p, size, t);
      final len = p.size * size.height;
      final dx = size.width * 0.012;
      final a = p.alpha * fadeAtBottom(p, size, t);
      stroke
        .shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: a),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(pos.dx, pos.dy, dx + 1, len));
      canvas.drawLine(pos, Offset(pos.dx + dx, pos.dy + len), stroke);
    }
  }
}

/// Snow Pine — pale white-blue palette, blurred snowy mountains, pine trees.
class SnowPainter extends _SeasonPainter {
  SnowPainter(super.animation);

  @override
  int get particleCount => 38;

  @override
  List<_Particle> buildParticles(math.Random rnd) => [
        for (var i = 0; i < particleCount; i++)
          _Particle(
            x: rnd.nextDouble(),
            y: rnd.nextDouble(),
            speed: 0.03 + rnd.nextDouble() * 0.05,
            size: 1.5 + rnd.nextDouble() * 3,
            sway: 0.01 + rnd.nextDouble() * 0.02,
            phase: rnd.nextDouble() * 2,
            alpha: 0.5 + rnd.nextDouble() * 0.4,
          ),
      ];

  @override
  void _paintScene(Canvas canvas, Size size, List<_Particle> particles) {
    fillSky(canvas, size, SeasonType.snowPine);

    // Blurred snowy mountains.
    drawSoftRidges(
      canvas,
      size,
      [
        const Color(0xFFEAF3FB).withValues(alpha: 0.6),
        const Color(0xFFD8E8F5).withValues(alpha: 0.75),
        const Color(0xFFC3DAEE).withValues(alpha: 0.8),
      ],
      [0.5, 0.35, 0.2],
      2,
    );

    // Pine trees on the lower third.
    final rnd = math.Random(5);
    final base = size.height * 0.9;
    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.05 + i * 0.12) + rnd.nextDouble() * size.width * 0.05;
      final h = size.height * (0.2 + rnd.nextDouble() * 0.14);
      for (var layer = 0; layer < 3; layer++) {
        final y = base - h + layer * h * 0.3;
        final w = h * (1.1 - layer * 0.25);
        final path = Path()
          ..moveTo(x - w / 2, y)
          ..lineTo(x, y - h * 0.5)
          ..lineTo(x + w / 2, y);
        canvas.drawPath(path, Paint()..color = const Color(0xFF3E5C76).withValues(alpha: 0.75));
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(0, base, size.width, size.height - base),
      Paint()..color = const Color(0xFFEDF5FB).withValues(alpha: 0.8),
    );

    // Drifting snow, softly pulsing.
    for (final p in particles) {
      final pos = particlePos(p, size, t);
      final pulse = 0.6 + 0.4 * math.sin(2 * math.pi * (t * 0.8 + p.phase));
      canvas.drawCircle(
        pos,
        p.size,
        Paint()..color = Colors.white.withValues(alpha: p.alpha * pulse * 0.9),
      );
    }
  }
}

/// Base for petal-style seasons (sunset garden + cherry blossom).
abstract class _PetalPainter extends _SeasonPainter {
  _PetalPainter(super.animation);

  List<Color> get petalColors;

  double get petalSize;

  @override
  List<_Particle> buildParticles(math.Random rnd) => [
        for (var i = 0; i < particleCount; i++)
          _Particle(
            x: rnd.nextDouble(),
            y: rnd.nextDouble(),
            speed: 0.03 + rnd.nextDouble() * 0.05,
            size: petalSize + rnd.nextDouble() * petalSize * 0.8,
            sway: 0.015 + rnd.nextDouble() * 0.025,
            phase: rnd.nextDouble() * 2,
            alpha: 0.6 + rnd.nextDouble() * 0.35,
            colorIndex: rnd.nextInt(petalColors.length),
          ),
      ];

  @override
  void _paintScene(Canvas canvas, Size size, List<_Particle> particles) {
    fillSky(canvas, size, season);
    drawSceneBase(canvas, size);
    for (final p in particles) {
      final pos = particlePos(p, size, t);
      final fade = fadeAtBottom(p, size, t);
      if (fade <= 0) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(math.sin(2 * math.pi * (t + p.phase)) * 0.9);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 2,
          height: p.size * 0.8,
        ),
        Paint()
          ..color = petalColors[p.colorIndex].withValues(alpha: p.alpha * fade),
      );
      canvas.restore();
    }
  }

  SeasonType get season;

  void drawSceneBase(Canvas canvas, Size size);
}

/// Sunset Garden — orange-pink sky, garden silhouettes, floating petals.
class PetalPainter extends _PetalPainter {
  PetalPainter(super.animation);

  @override
  int get particleCount => 18;

  @override
  double get petalSize => 3.5;

  @override
  SeasonType get season => SeasonType.sunsetGarden;

  @override
  List<Color> get petalColors => const [
        Color(0xFFE8879E),
        Color(0xFFF2A0BE),
        Color(0xFFD96C8C),
      ];

  @override
  void drawSceneBase(Canvas canvas, Size size) {
    // Warm sun low in the sky.
    final sun = Offset(size.width * 0.5, size.height * 0.6);
    canvas.drawCircle(
      sun,
      size.shortestSide * 0.42,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFF1D0).withValues(alpha: 0.55),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: sun, radius: size.shortestSide)),
    );

    // Garden silhouettes along the bottom.
    final rnd = math.Random(9);
    final base = size.height * 0.86;
    for (var i = 0; i < 9; i++) {
      final x = size.width * (i / 8) + (rnd.nextDouble() - 0.5) * size.width * 0.06;
      final r = size.height * (0.08 + rnd.nextDouble() * 0.09);
      canvas.drawCircle(
        Offset(x, base + r * 0.3),
        r,
        Paint()..color = const Color(0xFF6B4A5A).withValues(alpha: 0.65),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, base, size.width, size.height - base),
      Paint()..color = const Color(0xFF5A4150).withValues(alpha: 0.55),
    );
  }
}

/// Cherry Blossom — pastel pink trees, falling blossom petals.
class BlossomPetalPainter extends _PetalPainter {
  BlossomPetalPainter(super.animation);

  @override
  int get particleCount => 20;

  @override
  double get petalSize => 3;

  @override
  SeasonType get season => SeasonType.cherryBlossom;

  @override
  List<Color> get petalColors => const [
        Color(0xFFF2A0BE),
        Color(0xFFF8C3D6),
        Color(0xFFE87FA4),
      ];

  @override
  void drawSceneBase(Canvas canvas, Size size) {
    // Blossom trees.
    final rnd = math.Random(11);
    final base = size.height * 0.9;
    for (var i = 0; i < 6; i++) {
      final x = size.width * (0.08 + i * 0.17) + (rnd.nextDouble() - 0.5) * size.width * 0.05;
      final h = size.height * (0.24 + rnd.nextDouble() * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 3, base - h * 0.6, 6, h * 0.6),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF8A6A63).withValues(alpha: 0.8),
      );
      final crown = Paint()
        ..color = const Color(0xFFE88FB0).withValues(alpha: 0.85);
      canvas.drawCircle(Offset(x - h * 0.28, base - h * 0.72), h * 0.34, crown);
      canvas.drawCircle(Offset(x + h * 0.26, base - h * 0.66), h * 0.3, crown);
      canvas.drawCircle(Offset(x, base - h * 0.85), h * 0.38, crown);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, base, size.width, size.height - base),
      Paint()..color = const Color(0xFFF2D8DE).withValues(alpha: 0.7),
    );
  }
}

/// Neon Night — dark purple-blue city blur, glowing particles.
class FireflyParticlePainter extends _SeasonPainter {
  FireflyParticlePainter(super.animation);

  static const List<Color> _glowColors = [
    Color(0xFF9F8FFF),
    Color(0xFFFF7FB0),
    Color(0xFF6FE3E0),
    Color(0xFFFFC77F),
  ];

  @override
  int get particleCount => 14;

  @override
  List<_Particle> buildParticles(math.Random rnd) => [
        for (var i = 0; i < particleCount; i++)
          _Particle(
            x: rnd.nextDouble(),
            y: rnd.nextDouble(),
            speed: 0.02 + rnd.nextDouble() * 0.04,
            size: 1.2 + rnd.nextDouble() * 1.6,
            sway: 0.01 + rnd.nextDouble() * 0.02,
            phase: rnd.nextDouble() * 2,
            alpha: 0.5 + rnd.nextDouble() * 0.4,
            colorIndex: rnd.nextInt(_glowColors.length),
          ),
      ];

  @override
  void _paintScene(Canvas canvas, Size size, List<_Particle> particles) {
    fillSky(canvas, size, SeasonType.neonNight);

    // Distant city blur: soft glowing window blocks.
    final rnd = math.Random(13);
    final cityBase = size.height * 0.72;
    for (var block = 0; block < 7; block++) {
      final x = size.width * (block / 7) + (rnd.nextDouble() - 0.5) * size.width * 0.06;
      final w = size.width * (0.08 + rnd.nextDouble() * 0.06);
      final h = size.height * (0.14 + rnd.nextDouble() * 0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, cityBase - h, w, h),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF171233).withValues(alpha: 0.8),
      );
      // A few lit windows.
      for (var win = 0; win < 3; win++) {
        canvas.drawRect(
          Rect.fromLTWH(
            x + w * (0.15 + rnd.nextDouble() * 0.6),
            cityBase - h * (0.25 + rnd.nextDouble() * 0.55),
            w * 0.08,
            w * 0.1,
          ),
          Paint()
            ..color = const Color(0xFFFFD9A0)
                .withValues(alpha: 0.25 + rnd.nextDouble() * 0.3),
        );
      }
    }
    // Street glow line.
    canvas.drawRect(
      Rect.fromLTWH(0, cityBase, size.width, size.height - cityBase),
      Paint()..color = const Color(0xFF0D0A22).withValues(alpha: 0.9),
    );

    // Twinkling fireflies with soft radial glow.
    for (final p in particles) {
      final pos = particlePos(p, size, t);
      final twinkle = 0.5 + 0.5 * math.sin(2 * math.pi * (t * 1.5 + p.phase));
      final color = _glowColors[p.colorIndex];
      final radius = p.size * 5;
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: p.alpha * twinkle * 0.5),
            Colors.transparent,
          ]).createShader(
            Rect.fromCircle(center: pos, radius: radius),
          ),
      );
      canvas.drawCircle(
        pos,
        p.size * 0.9,
        Paint()..color = color.withValues(alpha: p.alpha * twinkle),
      );
    }
  }
}

/// Celestial Aurora — legendary aurora sky, glow particles, cosmic mountains.
class AuroraPainter extends _SeasonPainter {
  AuroraPainter(super.animation);

  static const List<Color> _ribbonColors = [
    Color(0xFF5FE3B8),
    Color(0xFF6ECFF2),
    Color(0xFFB48BFF),
  ];

  static const List<Color> _glowColors = [
    Color(0xFF9DE8D0),
    Color(0xFFC9B8FF),
    Color(0xFF8FD8F5),
  ];

  late final List<_Particle> _stars = _makeStars();

  List<_Particle> _makeStars() {
    final rnd = math.Random(17);
    return [
      for (var i = 0; i < 40; i++)
        _Particle(
          x: rnd.nextDouble(),
          y: rnd.nextDouble() * 0.75,
          speed: 0,
          size: 0.6 + rnd.nextDouble() * 1.6,
          phase: rnd.nextDouble() * 2,
          alpha: 0.2 + rnd.nextDouble() * 0.5,
        ),
    ];
  }

  @override
  int get particleCount => 12;

  @override
  List<_Particle> buildParticles(math.Random rnd) => [
        for (var i = 0; i < particleCount; i++)
          _Particle(
            x: rnd.nextDouble(),
            y: rnd.nextDouble() * 0.8,
            speed: 0.015 + rnd.nextDouble() * 0.03,
            size: 1 + rnd.nextDouble() * 1.8,
            sway: 0.01,
            phase: rnd.nextDouble() * 2,
            alpha: 0.4 + rnd.nextDouble() * 0.4,
            colorIndex: rnd.nextInt(_glowColors.length),
          ),
      ];

  @override
  void _paintScene(Canvas canvas, Size size, List<_Particle> particles) {
    fillSky(canvas, size, SeasonType.celestialAurora);

    // Twinkling stars.
    for (final s in _stars) {
      final tw = 0.6 + 0.4 * math.sin(2 * math.pi * (t * 0.5 + s.phase));
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        Paint()..color = Colors.white.withValues(alpha: s.alpha * tw),
      );
    }

    // Aurora ribbons — slow sine curtains.
    for (var r = 0; r < 3; r++) {
      final baseY = size.height * (0.3 + r * 0.18);
      final amp = size.height * (0.1 + r * 0.03);
      final path = Path();
      final step = size.width / 8;
      for (var i = 0; i <= 8; i++) {
        final x = i * step;
        final y = baseY +
            math.sin(i * 0.9 + t * 1.6 + r * 1.7) * amp +
            math.sin(i * 0.45 - t * 0.9 + r) * amp * 0.4;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.quadraticBezierTo(x - step * 0.5, y - amp * 0.6, x, y);
        }
      }
      final bounds = path.getBounds().inflate(30);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26 + r * 10
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [
          _ribbonColors[r].withValues(alpha: 0.12),
          _ribbonColors[(r + 1) % 3].withValues(alpha: 0.3),
          _ribbonColors[r].withValues(alpha: 0.12),
        ]).createShader(bounds);
      canvas.drawPath(path, stroke);
      // Bright core.
      final core = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = _ribbonColors[r].withValues(alpha: 0.5);
      canvas.drawPath(path, core);
    }

    // Cosmic mountains.
    final ridge = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.78)
      ..lineTo(size.width * 0.18, size.height * 0.6)
      ..lineTo(size.width * 0.34, size.height * 0.74)
      ..lineTo(size.width * 0.52, size.height * 0.55)
      ..lineTo(size.width * 0.7, size.height * 0.72)
      ..lineTo(size.width * 0.85, size.height * 0.6)
      ..lineTo(size.width, size.height * 0.74)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(ridge, Paint()..color = const Color(0xFF0A1030).withValues(alpha: 0.9));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.9, size.width, size.height * 0.1),
      Paint()..color = const Color(0xFF070B22),
    );

    // Rising glow motes.
    for (final p in particles) {
      final pos = particlePos(p, size, t);
      final color = _glowColors[p.colorIndex];
      final radius = p.size * 6;
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: p.alpha * 0.35),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: pos, radius: radius)),
      );
      canvas.drawCircle(pos, p.size, Paint()..color = color.withValues(alpha: p.alpha));
    }
  }
}

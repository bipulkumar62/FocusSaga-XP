// Generates original dark-fantasy warrior preview art for FocusSaga XP.
//
// Each character gets one transparent PNG: `assets/characters/<id>/preview.png`
// (384x384), a full-body warrior in a serious pose — helmet, armor, cape and
// weapon — with a theme-colored aura. All designs are original (no
// copyrighted IP). Replace with hand-drawn/AI art later by writing a PNG to
// the same path — nothing else changes.
//
// Run: dart run tool/generate_warrior_art.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int canvasSize = 384;

enum WeaponStyle { katana, greatsword, dualBlade, shortSword, starBlade, windKatana }

enum HelmetStyle { kabuto, fullHelm, hood, crown }

class WarriorSpec {
  const WarriorSpec({
    required this.id,
    required this.name,
    required this.classTitle,
    required this.armor,
    required this.accent,
    required this.metal,
    required this.eyeGlow,
    required this.weapon,
    required this.helmet,
  });

  final String id;
  final String name;
  final String classTitle;

  /// Dark armor base color.
  final int armor;

  /// Theme accent (aura, trim, glow).
  final int accent;

  /// Weapon / plate metal color.
  final int metal;

  /// Glowing eyes / weapon edge color.
  final int eyeGlow;

  final WeaponStyle weapon;
  final HelmetStyle helmet;
}

const List<WarriorSpec> warriors = [
  WarriorSpec(
    id: 'kairo',
    name: 'Kairo',
    classTitle: 'Flame Ronin',
    armor: 0xFF2A1A16,
    accent: 0xFFFF5A2A,
    metal: 0xFFE8D9C5,
    eyeGlow: 0xFFFFB84D,
    weapon: WeaponStyle.katana,
    helmet: HelmetStyle.kabuto,
  ),
  WarriorSpec(
    id: 'tetsu',
    name: 'Tetsu',
    classTitle: 'Iron Vanguard',
    armor: 0xFF1B2230,
    accent: 0xFF4E8FE6,
    metal: 0xFFC9D6E8,
    eyeGlow: 0xFF7FB6FF,
    weapon: WeaponStyle.greatsword,
    helmet: HelmetStyle.fullHelm,
  ),
  WarriorSpec(
    id: 'rin',
    name: 'Rin',
    classTitle: 'Storm Blade',
    armor: 0xFF16202E,
    accent: 0xFFF2C94C,
    metal: 0xFFD8E6F2,
    eyeGlow: 0xFFFFE88A,
    weapon: WeaponStyle.dualBlade,
    helmet: HelmetStyle.kabuto,
  ),
  WarriorSpec(
    id: 'kuro',
    name: 'Kuro',
    classTitle: 'Shadow Assassin',
    armor: 0xFF14121C,
    accent: 0xFF8A7FD4,
    metal: 0xFFB8B0D8,
    eyeGlow: 0xFF9C92FF,
    weapon: WeaponStyle.shortSword,
    helmet: HelmetStyle.hood,
  ),
  WarriorSpec(
    id: 'sora',
    name: 'Sora',
    classTitle: 'Astral Champion',
    armor: 0xFF231A3A,
    accent: 0xFFC9A86A,
    metal: 0xFFE8DFC8,
    eyeGlow: 0xFFFFE9A8,
    weapon: WeaponStyle.starBlade,
    helmet: HelmetStyle.crown,
  ),
  WarriorSpec(
    id: 'arashi',
    name: 'Arashi',
    classTitle: 'Wind Samurai',
    armor: 0xFF14211E,
    accent: 0xFF4FD1B8,
    metal: 0xFFBFE8E0,
    eyeGlow: 0xFF8FF0DC,
    weapon: WeaponStyle.windKatana,
    helmet: HelmetStyle.kabuto,
  ),
];

void main() {
  final out = Directory('assets/characters');
  out.createSync(recursive: true);

  for (final spec in warriors) {
    final dir = Directory('assets/characters/${spec.id}');
    dir.createSync(recursive: true);

    final canvas = img.Image(
      width: canvasSize,
      height: canvasSize,
      numChannels: 4,
    );
    drawWarrior(canvas, spec);
    final path = '${dir.path}/preview.png';
    File(path).writeAsBytesSync(img.encodePng(canvas));
    stdout.writeln('wrote $path (${spec.name}, ${spec.classTitle})');
  }
  stdout.writeln('done: ${warriors.length} warriors');
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

void drawWarrior(img.Image canvas, WarriorSpec spec) {
  const cx = 192.0;
  const groundY = 332.0;
  final accent = spec.accent;

  // Ground shadow.
  _ellipse(canvas, cx, groundY, 110, 22, 0x000000, 0.45);

  // Aura: blurred accent glow behind the body.
  final aura = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  _circle(aura, cx, 190, 150, accent, 0.20);
  _circle(aura, cx, 190, 105, accent, 0.22);
  final blurred = img.gaussianBlur(aura, radius: 28);
  img.compositeImage(canvas, blurred);

  // Cape (behind the body).
  _cape(canvas, spec, cx, groundY);

  // Legs + boots.
  _leg(canvas, cx - 34, 205, groundY - 8, spec.armor, spec.accent);
  _leg(canvas, cx + 34, 205, groundY - 8, spec.armor, spec.accent);

  // Torso: broad shoulders narrowing to the waist.
  _torso(canvas, spec, cx);

  // Arms.
  _arm(canvas, spec, cx, raised: true);
  _arm(canvas, spec, cx, raised: false);

  // Weapon (front layer).
  _weapon(canvas, spec);

  // Head + helmet.
  _head(canvas, spec, cx);
}

void _cape(img.Image canvas, WarriorSpec spec, double cx, double groundY) {
  // Flowing cloak flaring out to the left and right.
  final sway = 14.0;
  _polygon(canvas, [
    img.Point((cx - 58).round(), 150),
    img.Point((cx - 118 - sway).round(), 318),
    img.Point((cx - 60).round(), 324),
    img.Point((cx - 24).round(), 170),
  ], _darken(spec.armor, 0.75), 235);

  _polygon(canvas, [
    img.Point((cx + 58).round(), 150),
    img.Point((cx + 118 + sway).round(), 318),
    img.Point((cx + 60).round(), 324),
    img.Point((cx + 24).round(), 170),
  ], _darken(spec.armor, 0.75), 235);

  // Accent hem line on the cape.
  _line(canvas, cx - 112 - sway, 312, cx - 62, 320, spec.accent, 3, 200);
  _line(canvas, cx + 112 + sway, 312, cx + 62, 320, spec.accent, 3, 200);
}

void _torso(img.Image canvas, WarriorSpec spec, double cx) {
  // Chest plate.
  _polygon(canvas, [
    img.Point((cx - 76).round(), 148),
    img.Point((cx + 76).round(), 148),
    img.Point((cx + 44).round(), 238),
    img.Point((cx - 44).round(), 238),
  ], spec.armor);

  // Chest emblem (accent diamond).
  _polygon(canvas, [
    img.Point(cx.round(), 168),
    img.Point((cx + 16).round(), 186),
    img.Point(cx.round(), 204),
    img.Point((cx - 16).round(), 186),
  ], spec.accent, 220);

  // Waist belt.
  _fillRect(canvas, cx - 44, 236, cx + 44, 246, spec.accent, 200);
  _fillRect(canvas, cx - 46, 246, cx + 46, 256, _darken(spec.armor, 0.6));

  // Shoulder pauldrons.
  _circle(canvas, cx - 80, 152, 26, spec.armor);
  _circle(canvas, cx + 80, 152, 26, spec.armor);
  _circle(canvas, cx - 80, 152, 26, spec.accent, 46);
  _circle(canvas, cx + 80, 152, 26, spec.accent, 46);
}

void _leg(img.Image canvas, double x, double yTop, double yBottom, int armor, int accent) {
  _thickLine(canvas, x, yTop, x, yBottom - 26, armor, 30);
  // Boot.
  _polygon(canvas, [
    img.Point((x - 14).round(), (yBottom - 24).round()),
    img.Point((x + 14).round(), (yBottom - 24).round()),
    img.Point((x + 20).round(), yBottom.round()),
    img.Point((x - 20).round(), yBottom.round()),
  ], _darken(armor, 0.6));
  _line(canvas, x - 14, yBottom - 22, x + 14, yBottom - 22, accent, 3, 160);
}

void _arm(img.Image canvas, WarriorSpec spec, double cx, {required bool raised}) {
  final side = raised ? -1.0 : 1.0;
  final shoulderX = cx + side * 74;
  final shoulderY = 156.0;
  final handX = raised ? cx - side * 30 : cx + side * 52;
  final handY = raised ? 228.0 : 268.0;
  _thickLine(canvas, shoulderX, shoulderY, handX, handY, spec.armor, 22);
  _circle(canvas, handX, handY, 12, _darken(spec.armor, 0.7));
  // Glove accent.
  _circle(canvas, handX, handY, 12, spec.accent, 60);
}

// ---------------------------------------------------------------------------
// Weapons
// ---------------------------------------------------------------------------

void _weapon(img.Image canvas, WarriorSpec spec) {
  switch (spec.weapon) {
    case WeaponStyle.katana:
      _katana(canvas, spec, handleX: 232, tipX: 118, tipY: 62);
    case WeaponStyle.greatsword:
      _greatsword(canvas, spec);
    case WeaponStyle.dualBlade:
      _katana(canvas, spec, handleX: 132, tipX: 266, tipY: 62);
      _katana(canvas, spec, handleX: 252, tipX: 120, tipY: 84);
    case WeaponStyle.shortSword:
      _katana(canvas, spec, handleX: 138, tipX: 258, tipY: 258, bladeLen: 96);
    case WeaponStyle.starBlade:
      _katana(canvas, spec, handleX: 244, tipX: 118, tipY: 48);
      _star(canvas, 250, 240, 14, spec.accent);
      _circle(canvas, 118, 48, 18, spec.eyeGlow, 140);
    case WeaponStyle.windKatana:
      _katana(canvas, spec, handleX: 252, tipX: 118, tipY: 78, curved: true);
  }
}

void _katana(
  img.Image canvas,
  WarriorSpec spec, {
  required double handleX,
  required double tipX,
  required double tipY,
  double bladeLen = 130,
  bool curved = false,
}) {
  // Sword drawn from handle (bottom-right) to tip (top-left).
  final dx = tipX - handleX;
  final dy = tipY - (handleY(handleX));
  final len = math.sqrt(dx * dx + dy * dy);

  // Blade.
  final edge = spec.eyeGlow;
  if (curved) {
    // Gentle bow in the blade for the wind katana.
    _thickLine(canvas, handleX, handleY(handleX), handleX + dx * 0.55,
        handleY(handleX) + dy * 0.55, spec.metal, 7);
    _thickLine(canvas, handleX + dx * 0.55, handleY(handleX) + dy * 0.55,
        tipX, tipY, spec.metal, 7);
    _line(canvas, handleX, handleY(handleX), tipX, tipY, edge, 2, 150);
  } else {
    _thickLine(canvas, handleX, handleY(handleX), tipX, tipY, spec.metal, 7);
    _line(canvas, handleX, handleY(handleX), tipX, tipY, edge, 2, 160);
  }

  // Guard (tsuba).
  final gx = handleX + dx * (bladeLen / len) - dx * 0.06;
  final gy = handleY(handleX) + dy * (bladeLen / len) - dy * 0.06;
  _thickLine(canvas, gx - 12, gy - 5, gx + 12, gy + 5, spec.accent, 5);

  // Handle.
  _thickLine(canvas, handleX, handleY(handleX), handleX - dx * 0.12,
      handleY(handleX) - dy * 0.12, 0xFF3A2C22, 6);
  _circle(canvas, handleX, handleY(handleX), 6, spec.accent);
}

double handleY(double x) => 288.0 - (x - 150) * 0.25;

void _greatsword(img.Image canvas, WarriorSpec spec) {
  // Massive blade resting over the right shoulder.
  const hx = 258.0, hy = 244.0;
  const tx = 96.0, ty = 52.0;
  _thickLine(canvas, hx, hy, tx, ty, spec.metal, 14);
  // Fuller line.
  _line(canvas, hx, hy, tx, ty, _darken(spec.metal, 0.5), 3, 255);
  // Crossguard.
  _thickLine(canvas, 218, 246, 296, 268, spec.accent, 6);
  _circle(canvas, 258, 244, 7, spec.accent);
  // Blade tip glow.
  _circle(canvas, 96, 52, 10, spec.eyeGlow, 160);
}

// ---------------------------------------------------------------------------
// Head + helmet
// ---------------------------------------------------------------------------

void _head(img.Image canvas, WarriorSpec spec, double cx) {
  const headY = 106.0;
  final headColor = _skinTone(spec);

  // Neck.
  _fillRect(canvas, cx - 18, 120, cx + 18, 146, _darken(spec.armor, 0.8));

  // Face.
  _circle(canvas, cx, headY, 40, headColor);

  // Glowing eyes.
  _circle(canvas, cx - 14, headY + 2, 5, spec.eyeGlow);
  _circle(canvas, cx + 14, headY + 2, 5, spec.eyeGlow);

  switch (spec.helmet) {
    case HelmetStyle.kabuto:
      // Helmet bowl.
      _circle(canvas, cx, headY - 6, 40, _darken(spec.armor, 0.4));
      // Crest (front plate).
      _polygon(canvas, [
        img.Point((cx - 16).round(), (headY - 22).round()),
        img.Point(cx.round(), (headY - 62).round()),
        img.Point((cx + 16).round(), (headY - 22).round()),
        img.Point(cx.round(), (headY - 30).round()),
      ], spec.accent, 235);
      // Neck guard.
      _polygon(canvas, [
        img.Point((cx - 34).round(), (headY + 26).round()),
        img.Point((cx + 34).round(), (headY + 26).round()),
        img.Point((cx + 26).round(), (headY + 52).round()),
        img.Point((cx - 26).round(), (headY + 52).round()),
      ], _darken(spec.armor, 0.5));
    case HelmetStyle.fullHelm:
      _circle(canvas, cx, headY - 2, 42, _darken(spec.armor, 0.4));
      // Visor slit.
      _fillRect(canvas, cx - 24, headY - 2, cx + 24, headY + 5, 0x0A0C12);
      // Visor glow.
      _line(canvas, cx - 22, headY + 1, cx + 22, headY + 1, spec.eyeGlow, 3, 200);
      // Top plume.
      _thickLine(canvas, cx - 8, headY - 38, cx + 18, headY - 76, spec.accent, 6);
    case HelmetStyle.hood:
      // Assassin hood over the head.
      _circle(canvas, cx, headY - 4, 44, spec.armor);
      _circle(canvas, cx, headY + 34, 30, spec.armor);
      // Hood opening with glowing eyes.
      _fillRect(canvas, cx - 24, headY - 8, cx + 24, headY + 10, 0x0A0912);
      _line(canvas, cx - 20, headY + 1, cx + 20, headY + 1, spec.eyeGlow, 2, 220);
      // Hood point.
      _polygon(canvas, [
        img.Point((cx - 6).round(), (headY - 40).round()),
        img.Point((cx + 6).round(), (headY - 40).round()),
        img.Point(cx.round(), (headY + 6).round()),
      ], spec.armor);
    case HelmetStyle.crown:
      _circle(canvas, cx, headY - 4, 40, _darken(spec.armor, 0.45));
      // Golden crown / diadem.
      _polygon(canvas, [
        img.Point((cx - 26).round(), (headY - 34).round()),
        img.Point((cx - 18).round(), (headY - 56).round()),
        img.Point((cx - 8).round(), (headY - 38).round()),
        img.Point(cx.round(), (headY - 62).round()),
        img.Point((cx + 8).round(), (headY - 38).round()),
        img.Point((cx + 18).round(), (headY - 56).round()),
        img.Point((cx + 26).round(), (headY - 34).round()),
      ], spec.accent);
      // Star on the brow.
      _star(canvas, cx, headY - 46, 9, spec.eyeGlow);
  }

  // Ear guards.
  _circle(canvas, cx - 42, headY + 8, 10, _darken(spec.armor, 0.5));
  _circle(canvas, cx + 42, headY + 8, 10, _darken(spec.armor, 0.5));
}

int _skinTone(WarriorSpec spec) {
  // Keep faces dark for kuro/sora; lighter for the rest.
  return switch (spec.id) {
    'kuro' => 0xFF241F33,
    'sora' => 0xFF2E2248,
    'tetsu' => 0xFF8A7A66,
    _ => 0xFF9A8166,
  };
}

// ---------------------------------------------------------------------------
// Drawing helpers
// ---------------------------------------------------------------------------

void _circle(img.Image canvas, double x, double y, double r, int color, [double? alpha]) {
  img.fillCircle(
    canvas,
    x: x.round(),
    y: y.round(),
    radius: r.round(),
    color: img.ColorRgba8(
      (color >> 16) & 0xFF,
      (color >> 8) & 0xFF,
      color & 0xFF,
      ((alpha ?? 1.0) * 255).round(),
    ),
    antialias: true,
  );
}

void _ellipse(img.Image canvas, double x, double y, double rx, double ry, int color, [double? alpha]) {
  // Approximate ellipse with a smooth polygon.
  final points = <img.Point>[];
  for (var i = 0; i < 48; i++) {
    final angle = i * math.pi * 2 / 48;
    points.add(img.Point(
      (x + math.cos(angle) * rx).round(),
      (y + math.sin(angle) * ry).round(),
    ));
  }
  _polygon(canvas, points, color, alpha);
}

void _polygon(img.Image canvas, List<img.Point> points, int color, [double? alpha]) {
  img.fillPolygon(
    canvas,
    vertices: points,
    color: img.ColorRgba8(
      (color >> 16) & 0xFF,
      (color >> 8) & 0xFF,
      color & 0xFF,
      ((alpha ?? 1.0) * 255).round(),
    ),
  );
}

void _fillRect(img.Image canvas, double x1, double y1, double x2, double y2, int color, [double? alpha]) {
  img.fillRect(
    canvas,
    x1: x1.round(),
    y1: y1.round(),
    x2: x2.round(),
    y2: y2.round(),
    color: img.ColorRgba8(
      (color >> 16) & 0xFF,
      (color >> 8) & 0xFF,
      color & 0xFF,
      ((alpha ?? 1.0) * 255).round(),
    ),
  );
}

void _line(img.Image canvas, double x1, double y1, double x2, double y2, int color, double thickness, [double? alpha]) {
  img.drawLine(
    canvas,
    x1: x1.round(),
    y1: y1.round(),
    x2: x2.round(),
    y2: y2.round(),
    thickness: thickness.round(),
    antialias: true,
    color: img.ColorRgba8(
      (color >> 16) & 0xFF,
      (color >> 8) & 0xFF,
      color & 0xFF,
      ((alpha ?? 1.0) * 255).round(),
    ),
  );
}

void _thickLine(img.Image canvas, double x1, double y1, double x2, double y2, int color, double thickness) {
  _line(canvas, x1, y1, x2, y2, color, thickness);
}

void _star(img.Image canvas, double x, double y, double r, int color) {
  final points = <img.Point>[];
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? r : r * 0.45;
    final angle = -math.pi / 2 + i * math.pi / 5;
    points.add(img.Point(
      (x + math.cos(angle) * radius).round(),
      (y + math.sin(angle) * radius).round(),
    ));
  }
  _polygon(canvas, points, color, 235);
}

int _darken(int color, double factor) {
  int ch(int shift) =>
      (((color >> shift) & 0xFF) * factor).round().clamp(0, 255);
  return (0xFF << 24) | (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

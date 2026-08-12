import 'package:flutter/material.dart';

import '../domain/season.dart';
import 'season_background_widget.dart';

/// Puts the selected season's animated background behind [child] — the single
/// global background layer used by the app shell and every full-screen route.
///
/// The animation itself lives in [SeasonBackgroundWidget] (a RepaintBoundary +
/// CustomPainter), so only the background repaints per frame; [child] renders
/// normally. When [season] is null (profile still loading) the default
/// [SeasonType.fallback] (Forest Morning) is shown, so no screen ever flashes
/// blank.
class GlobalBackgroundScaffold extends StatelessWidget {
  const GlobalBackgroundScaffold({
    super.key,
    required this.child,
    this.season,
    this.paused = false,
  });

  final Widget child;

  /// Equipped season; falls back to Forest Morning when null.
  final SeasonType? season;

  final bool paused;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: SeasonBackgroundWidget(
            season: season ?? SeasonType.fallback,
            paused: paused,
          ),
        ),
        child,
      ],
    );
  }
}

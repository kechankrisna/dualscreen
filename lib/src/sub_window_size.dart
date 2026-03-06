import 'dart:ui';

/// Describes the initial frame of a desktop sub-window created by
/// [MultiWindowManager.openSubWindow].
///
/// Choose one of the three factory constructors:
///
/// | Constructor              | Behaviour                                             |
/// |--------------------------|-------------------------------------------------------|
/// | [SubWindowSize.fullScreen] | Fills the secondary display (default)               |
/// | [SubWindowSize.fixed]      | An explicit screen-coordinate [Rect]                |
/// | [SubWindowSize.centered]   | A fixed logical size centred on the secondary display |
///
/// ## Multi-display coordinates
///
/// Desktop OSes use a global coordinate space where each display occupies a
/// non-overlapping rectangle. The primary display typically starts at the
/// origin `(0, 0)`. Secondary displays are tiled horizontally or vertically
/// depending on the user's layout.
///
/// Because Flutter's [PlatformDispatcher.displays] does not expose display
/// *positions*, [SubWindowSize.fullScreen] and [SubWindowSize.centered] assume
/// the secondary display is **positioned to the right** of the primary — the
/// most common POS / dual-display layout. For other physical arrangements
/// supply an explicit [SubWindowSize.fixed] rect.
sealed class SubWindowSize {
  const SubWindowSize();

  /// Fills the secondary display.
  ///
  /// Falls back to filling the primary display when only one display is
  /// detected.
  const factory SubWindowSize.fullScreen() = _FullScreen;

  /// An explicit window frame in global screen coordinates (logical pixels).
  ///
  /// Use this when the secondary display is not positioned to the right of the
  /// primary, or when you need precise control.
  const factory SubWindowSize.fixed(Rect frame) = _Fixed;

  /// A window of [width] × [height] logical pixels, centred on the secondary
  /// display (or the primary when only one is available).
  const factory SubWindowSize.centered({
    required double width,
    required double height,
  }) = _Centered;

  /// Resolves this spec into a concrete [Rect] in global screen coordinates
  /// (logical pixels).
  Rect resolveFrame();
}

// ── Private variants ──────────────────────────────────────────────────────────

final class _FullScreen extends SubWindowSize {
  const _FullScreen();

  @override
  Rect resolveFrame() {
    final displays = PlatformDispatcher.instance.displays.toList();
    if (displays.isEmpty) return const Rect.fromLTWH(0, 0, 1920, 1080);

    final primary =
        PlatformDispatcher.instance.implicitView?.display ?? displays.first;

    if (displays.length == 1) {
      return Rect.fromLTWH(
        0,
        0,
        primary.size.width / primary.devicePixelRatio,
        primary.size.height / primary.devicePixelRatio,
      );
    }

    final secondary = displays.firstWhere(
      (d) => d.id != primary.id,
      orElse: () => displays.last,
    );
    final primaryLogicalW = primary.size.width / primary.devicePixelRatio;
    final secLogicalW = secondary.size.width / secondary.devicePixelRatio;
    final secLogicalH = secondary.size.height / secondary.devicePixelRatio;
    return Rect.fromLTWH(primaryLogicalW, 0, secLogicalW, secLogicalH);
  }
}

final class _Fixed extends SubWindowSize {
  const _Fixed(this.frame);
  final Rect frame;

  @override
  Rect resolveFrame() => frame;
}

final class _Centered extends SubWindowSize {
  const _Centered({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Rect resolveFrame() {
    final displays = PlatformDispatcher.instance.displays.toList();
    if (displays.isEmpty) return Rect.fromLTWH(200, 200, width, height);

    final primary =
        PlatformDispatcher.instance.implicitView?.display ?? displays.first;
    final primaryLogicalW = primary.size.width / primary.devicePixelRatio;

    final secondary = displays.length > 1
        ? displays.firstWhere(
            (d) => d.id != primary.id,
            orElse: () => primary,
          )
        : primary;

    final offsetX = secondary.id != primary.id ? primaryLogicalW : 0.0;
    final secLogicalW = secondary.size.width / secondary.devicePixelRatio;
    final secLogicalH = secondary.size.height / secondary.devicePixelRatio;

    return Rect.fromLTWH(
      offsetX + (secLogicalW - width) / 2,
      (secLogicalH - height) / 2,
      width,
      height,
    );
  }
}

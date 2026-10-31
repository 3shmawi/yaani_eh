import 'package:flutter/widgets.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';

/// The mashrabiya behind the header band: the turned-wood beads and
/// spindles of a Cairo window screen, drawn as a faint lattice that fades
/// out before the band's controls. Decorative only; the band leaves it out
/// in its flat (Reduce Transparency / Increase Contrast) version.
class HeaderPattern extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0x8C000000), Color(0x00000000)],
          stops: [0, 0.55, 1],
        ).createShader(bounds),
        child: CustomPaint(
          painter: MashrabiyaPainter(tile: AppDimens.patternTile),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

/// One tile is a bead (a ring around a dot) held by four short spindles,
/// with a quarter bead in each corner, so tiles join into a lattice. Drawn
/// on a 32-unit grid and scaled to [tile].
class MashrabiyaPainter extends CustomPainter {
  const new({required this.tile, this.color = AppColors.headerPattern});

  final double tile;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (tile <= 0) return;
    final u = tile / 32;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * u
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;
    for (var y = 0.0; y < size.height + tile; y += tile) {
      for (var x = 0.0; x < size.width + tile; x += tile) {
        Offset at(double dx, double dy) => Offset(x + dx * u, y + dy * u);
        // Spindles between beads.
        canvas
          ..drawLine(at(0, 16), at(8, 16), line)
          ..drawLine(at(24, 16), at(32, 16), line)
          ..drawLine(at(16, 0), at(16, 8), line)
          ..drawLine(at(16, 24), at(16, 32), line)
          // The bead.
          ..drawCircle(at(16, 16), 4.5 * u, line)
          ..drawCircle(at(16, 16), 1.6 * u, fill);
        // Its four turned collars.
        for (final r in _collars) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                x + r.left * u,
                y + r.top * u,
                r.width * u,
                r.height * u,
              ),
              Radius.circular(2 * u),
            ),
            line,
          );
        }
        // The corner bead it shares with its neighbours.
        canvas.drawCircle(at(0, 0), 2.5 * u, line);
      }
    }
  }

  /// The collars around the bead, on the 32-unit grid.
  static const _collars = [
    Rect.fromLTWH(9, 14, 6, 4),
    Rect.fromLTWH(17, 14, 6, 4),
    Rect.fromLTWH(14, 9, 4, 6),
    Rect.fromLTWH(14, 17, 4, 6),
  ];

  @override
  bool shouldRepaint(MashrabiyaPainter old) =>
      old.tile != tile || old.color != color;
}

import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_fonts.dart';

/// The Yaani Eh mark: a speech bubble with an Arabic question mark (from
/// the Loading artboard). [fill] (0…1) pours crema and espresso into it,
/// so the first download reads as a cup filling up. Decorative: excluded
/// from semantics; say what's happening next to it.
class BrandMark extends StatelessWidget {
  const new({required this.size, this.fill = 0.4, super.key});

  final double size;
  final double fill;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fill.clamp(0, 1)),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, level, _) => CustomPaint(
          size: Size.square(size),
          painter: _BubblePainter(
            level: level,
            bubble: p.brandSoft,
            crema: p.crema,
            stroke: p.brand,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  new({
    required this.level,
    required this.bubble,
    required this.crema,
    required this.stroke,
    required this.textDirection,
  });

  final double level;
  final Color bubble;
  final Color crema;
  final Color stroke;
  final TextDirection textDirection;

  /// The bubble on a 1024 canvas (the artboard's SVG path).
  static Path _bubble() {
    const r = Radius.circular(160);
    return Path()
      ..moveTo(392, 250)
      ..lineTo(632, 250)
      ..arcToPoint(const Offset(792, 410), radius: r)
      ..lineTo(792, 540)
      ..arcToPoint(const Offset(700, 684), radius: r)
      ..lineTo(760, 792)
      ..lineTo(600, 700)
      ..lineTo(392, 700)
      ..arcToPoint(const Offset(232, 540), radius: r)
      ..lineTo(232, 410)
      ..arcToPoint(const Offset(392, 250), radius: r)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 1024);
    final bubblePath = _bubble();
    canvas.drawPath(bubblePath, Paint()..color = bubble);

    // The drink: crema on top of espresso, rising with [level].
    final top = 760 - (760 - 330) * level;
    canvas
      ..save()
      ..clipPath(bubblePath)
      ..drawRect(Rect.fromLTRB(200, top, 840, 820), Paint()..color = crema)
      ..drawRect(
        Rect.fromLTRB(200, top + 100, 840, 820),
        Paint()..color = AppColors.espresso,
      );
    final foam = Paint()..color = bubble;
    for (final (dx, dy, r) in const [
      (360.0, 0.0, 22.0),
      (470.0, 6.0, 14.0),
      (600.0, -2.0, 18.0),
    ]) {
      canvas.drawCircle(Offset(dx, top + dy), r, foam);
    }
    canvas
      ..restore()
      ..drawPath(
        bubblePath,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..strokeJoin = StrokeJoin.round,
      );

    // «؟» centred on x = 512 with its baseline at y = 560.
    final glyph = TextPainter(
      text: TextSpan(
        text: '؟',
        style: TextStyle(
          fontFamily: AppFonts.arabic,
          fontWeight: FontWeight.w700,
          fontSize: 300,
          color: stroke,
          height: 1,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    final baseline = glyph.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    glyph
      ..paint(canvas, Offset(512 - glyph.width / 2, 560 - baseline))
      ..dispose();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.level != level ||
      old.bubble != bubble ||
      old.crema != crema ||
      old.stroke != stroke;
}

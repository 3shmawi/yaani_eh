import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/recipe.dart';
import 'package:yaani_eh/features/recipes/presentation/recipe_look.dart';

/// The cup's shape, from how much it holds: a small cup for a shot, a cup
/// with a handle up to a mug, a tall glass above that.
enum CupShape {
  small,
  cup,
  glass;

  static CupShape forMl(int ml) => switch (ml) {
    <= 90 => small,
    <= 250 => cup,
    _ => glass,
  };
}

/// The drink's layers to scale, bottom to top, filling in one after another
/// (`AppMotion.pourLayer`). Still with Reduce Motion.
class RecipeCup extends StatefulWidget {
  const new({required this.recipe, required this.semanticLabel, super.key});

  final Recipe recipe;
  final String semanticLabel;

  @override
  State<RecipeCup> createState() => _RecipeCupState();
}

class _RecipeCupState extends State<RecipeCup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pour = AnimationController(
    vsync: this,
    duration:
        AppMotion.pourStagger * (widget.recipe.layers.length - 1) +
        AppMotion.pourLayer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pour.value = 1;
    } else if (_pour.isDismissed) {
      _pour.forward();
    }
  }

  @override
  void dispose() {
    _pour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: widget.semanticLabel,
    child: SizedBox(
      width: AppDimens.cupWidth,
      height: AppDimens.cupHeight,
      child: AnimatedBuilder(
        animation: _pour,
        builder: (context, _) => CustomPaint(
          painter: CupPainter(
            recipe: widget.recipe,
            shape: CupShape.forMl(widget.recipe.totalMl),
            progress: _pour.value,
            pourLayer: AppMotion.pourLayer,
            pourStagger: AppMotion.pourStagger,
            total: _pour.duration!,
          ),
        ),
      ),
    ),
  );
}

/// Draws [recipe] in a cup of [shape]. [progress] 0…1 runs through the
/// whole pour; each layer rises over its own slice of it.
class CupPainter extends CustomPainter {
  const new({
    required this.recipe,
    required this.shape,
    required this.progress,
    required this.pourLayer,
    required this.pourStagger,
    required this.total,
  });

  final Recipe recipe;
  final CupShape shape;
  final double progress;
  final Duration pourLayer;
  final Duration pourStagger;
  final Duration total;

  /// The thinnest a layer is drawn, so a spoon of foam still shows.
  static const _minLayer = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final body = _body(size);
    final inside = body.getBounds();
    final heights = _layerHeights(inside.height);

    canvas
      ..drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, inside.bottom + size.height * 0.04),
          width: inside.width * 1.05,
          height: size.height * 0.06,
        ),
        Paint()..color = AppColors.cupShadow,
      )
      ..save()
      ..clipPath(body);
    var bottom = inside.bottom;
    for (final (i, layer) in recipe.layers.indexed) {
      final t = _layerProgress(i);
      final h = heights[i] * Curves.easeOutCubic.transform(t);
      canvas.drawRect(
        Rect.fromLTRB(inside.left, bottom - h, inside.right, bottom),
        Paint()..color = layerColor(layer.tone),
      );
      bottom -= h;
    }
    canvas.restore();

    final line = Paint()
      ..color = AppColors.cupLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(body, line);
    if (shape != CupShape.glass) {
      final r = inside.height * (shape == CupShape.small ? 0.22 : 0.2);
      final handle = Path()
        ..moveTo(inside.right - 2, inside.top + inside.height * 0.2)
        ..arcToPoint(
          Offset(inside.right - 4, inside.top + inside.height * 0.2 + 2 * r),
          radius: Radius.circular(r),
        );
      canvas.drawPath(handle, line);
    }
  }

  Path _body(Size size) {
    final w = size.width;
    final h = size.height;
    switch (shape) {
      case CupShape.small:
        final top = h * 0.42;
        final bottom = h * 0.86;
        return Path()
          ..moveTo(w * 0.18, top)
          ..lineTo(w * 0.72, top)
          ..lineTo(w * 0.66, bottom - 6)
          ..quadraticBezierTo(w * 0.645, bottom, w * 0.6, bottom)
          ..lineTo(w * 0.3, bottom)
          ..quadraticBezierTo(w * 0.255, bottom, w * 0.24, bottom - 6)
          ..close();
      case CupShape.cup:
        final top = h * 0.16;
        final bottom = h * 0.88;
        return Path()
          ..moveTo(w * 0.1, top)
          ..lineTo(w * 0.78, top)
          ..lineTo(w * 0.73, bottom - 8)
          ..quadraticBezierTo(w * 0.71, bottom, w * 0.64, bottom)
          ..lineTo(w * 0.24, bottom)
          ..quadraticBezierTo(w * 0.17, bottom, w * 0.15, bottom - 8)
          ..close();
      case CupShape.glass:
        final top = h * 0.04;
        final bottom = h * 0.9;
        return Path()
          ..moveTo(w * 0.2, top)
          ..lineTo(w * 0.8, top)
          ..lineTo(w * 0.74, bottom - 6)
          ..quadraticBezierTo(w * 0.73, bottom, w * 0.68, bottom)
          ..lineTo(w * 0.32, bottom)
          ..quadraticBezierTo(w * 0.27, bottom, w * 0.26, bottom - 6)
          ..close();
    }
  }

  /// Each layer's height to scale, none thinner than [_minLayer]; the
  /// cup's top keeps a small gap, like a real pour.
  List<double> _layerHeights(double inside) {
    final fill = inside * 0.92;
    final totalMl = recipe.totalMl;
    final raw = [for (final l in recipe.layers) fill * l.ml / totalMl];
    final thin = raw.where((h) => h < _minLayer).length;
    final rest = raw
        .where((h) => h >= _minLayer)
        .fold<double>(0, (a, b) => a + b);
    if (thin == 0 || rest == 0) return raw;
    final scale = (fill - thin * _minLayer) / rest;
    return [
      for (final h in raw)
        if (h < _minLayer) _minLayer else h * scale,
    ];
  }

  double _layerProgress(int i) {
    final ms = total.inMilliseconds;
    if (ms == 0) return progress;
    final start = pourStagger.inMilliseconds * i / ms;
    final length = pourLayer.inMilliseconds / ms;
    return ((progress - start) / length).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(CupPainter old) =>
      old.progress != progress || old.recipe != recipe || old.shape != shape;
}

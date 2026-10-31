import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yaani_eh/core/adaptive/adaptive.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/glass_tone.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';

export 'package:yaani_eh/core/ui/glass_tone.dart' show GlassTone;

/// The app's UI style: Liquid Glass (iOS 26/27 look) on every platform,
/// via liquid_glass_widgets. Screens use these wrappers, never a glass
/// widget directly, so the style can change in this one file — e.g. to
/// Flutter's own Cupertino Liquid Glass when it ships.
///
/// Quality adapts to the device (premium on iOS, standard elsewhere,
/// stepping down when frames get slow). Reduce Motion and Increase
/// Contrast are respected automatically.
abstract final class AppUi {
  static const style = 'glass';

  /// CI emulators render without a real GPU, where the glass shaders stall
  /// the whole device. `--dart-define=GLASS_LITE=true` (CI integration tests)
  /// draws the solid Reduce Transparency variant and skips the shader preload.
  static const lite = bool.fromEnvironment('GLASS_LITE');

  static Future<void> initialize() => lite
      ? LiquidGlassWidgets.initialize(warmUpMode: GlassWarmUpMode.never)
      : LiquidGlassWidgets.initialize();

  static Widget wrap(Widget app) {
    final glass = LiquidGlassWidgets.wrap(
      child: app,
      brightnessResolver: Theme.maybeBrightnessOf,
      // Measures real frame times and steps quality down on slow devices;
      // at `minimal`, AppGlass switches to lite (no blur).
      adaptiveQuality: true,
      theme: GlassThemeData.simple(
        blur: AppDimens.blurGlass,
        thickness: 30,
        quality: defaultTargetPlatform == TargetPlatform.iOS
            ? GlassQuality.premium
            : GlassQuality.standard,
      ),
    );
    return lite ? testWrap(glass) : glass;
  }

  /// Tests (and accessibility checks) run with solid surfaces: the most
  /// readable variant, and no shader needed in flutter_test.
  static Widget testWrap(Widget child) =>
      GlassAccessibilityScope(reduceTransparency: true, child: child);

  /// Whether glass draws without blur here: `GLASS_LITE`, Reduce
  /// Transparency / Increase Contrast, or a device too slow for the shader.
  static bool isLite(BuildContext context) =>
      lite ||
      GlassAccessibilityData.of(context).reduceTransparency ||
      GlassAdaptiveScopeData.maybeOf(context)?.effectiveQuality ==
          GlassQuality.minimal;
}

/// What glass is for: [clear] for controls (very transparent, adapts to
/// the photo behind it), [frosted] for reading (sentences stay readable).
enum GlassKind { clear, frosted }

/// The one glass surface of the app (Design System → GlassSurface).
///
/// Needs something behind it: a drink photo or [AppBackground]. Never stack
/// more than two. Content gets the right color automatically through
/// `DefaultTextStyle` and `IconTheme`.
class AppGlass extends StatefulWidget {
  const new({
    required this.child,
    this.kind = GlassKind.frosted,
    this.tone = GlassTone.auto,
    this.radius,
    this.padding,
    this.backdrop,
    this.backdropRegion = const Rect.fromLTWH(0, 0, 1, 1),
    this.blur,
    this.minimal = false,
    super.key,
  });

  final Widget child;
  final GlassKind kind;

  /// Many glass surfaces at once (grid labels): the cheapest shader, so
  /// scrolling stays smooth on mid-range Android.
  final bool minimal;

  /// Clear glass only. [GlassTone.auto] measures [backdrop] under
  /// [backdropRegion] when given, otherwise follows the theme.
  final GlassTone tone;

  /// Corner radius; defaults to `radius-lg`. Pills pass half their height.
  final double? radius;
  final EdgeInsetsGeometry? padding;

  /// The photo behind this control, for [GlassTone.auto].
  final ImageProvider? backdrop;

  /// Where this control sits on [backdrop], as fractions of the image.
  final Rect backdropRegion;

  /// Blur sigma override, e.g. `AppDimens.blurGlassStrong` for sheets.
  final double? blur;

  @override
  State<AppGlass> createState() => _AppGlassState();
}

class _AppGlassState extends State<AppGlass> {
  GlassTone? _measured;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  @override
  void didUpdateWidget(AppGlass old) {
    super.didUpdateWidget(old);
    if (old.backdrop != widget.backdrop ||
        old.backdropRegion != widget.backdropRegion) {
      _measure();
    }
  }

  void _measure() {
    final image = widget.backdrop;
    _measured = null;
    if (widget.tone != GlassTone.auto || image == null) return;
    final region = widget.backdropRegion;
    _measured = GlassToneResolver.cached(image, region);
    if (_measured != null) return;
    unawaited(
      GlassToneResolver.resolve(image, region).then((tone) {
        if (mounted && widget.backdrop == image) {
          setState(() => _measured = tone);
        }
      }),
    );
  }

  GlassTone _tone(BuildContext context) => switch (widget.tone) {
    GlassTone.light || GlassTone.dark => widget.tone,
    GlassTone.auto =>
      _measured ??
          (Theme.of(context).brightness == Brightness.dark
              ? GlassTone.dark
              : GlassTone.light),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lite = AppUi.isLite(context);
    final clear = widget.kind == GlassKind.clear;
    final tone = _tone(context);
    final radius = widget.radius ?? AppDimens.radiusLg;

    final foreground = lite || !clear
        ? p.ink
        : tone == GlassTone.light
        ? AppColors.onGlassLight
        : AppColors.onGlassDark;
    final content = IconTheme.merge(
      data: IconThemeData(color: foreground),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: Padding(
          padding: widget.padding ?? EdgeInsets.zero,
          child: widget.child,
        ),
      ),
    );

    if (lite) {
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      );
      // Lite is for slow devices and Reduce Transparency: a near-solid fill
      // and the rim, no blurred shadow (cheap to draw, even in software).
      // Material, so ListTile / InkWell ink stays visible.
      return Material(
        color: p.glassFillLite,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          foregroundPainter: _RimPainter(radius),
          child: content,
        ),
      );
    }

    final tint = !clear
        ? p.glassFill
        : tone == GlassTone.light
        ? AppColors.glassClearLight
        : AppColors.glassClearDark;
    return GlassContainer(
      quality: widget.minimal ? GlassQuality.minimal : null,
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      settings: LiquidGlassSettings(
        glassColor: tint,
        blur:
            widget.blur ??
            (clear ? AppDimens.blurGlassClear : AppDimens.blurGlass),
        saturation: clear ? AppDimens.glassSaturation : 1.2,
        lightIntensity: 0.6,
      ),
      child: Material(type: MaterialType.transparency, child: content),
    );
  }
}

/// The specular rim: bright at the top-start and bottom-end corners,
/// faint in between. Drawn on lite glass (the shader draws its own).
class _RimPainter extends CustomPainter {
  new(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.glassRim,
          AppColors.glassRimSoft,
          AppColors.glassRimSoft,
          AppColors.glassRim,
        ],
        stops: [0, 0.3, 0.7, 1],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.radius != radius;
}

/// The brand gradient (espresso → crema → milk) that sits behind glass
/// when there is no photo. Screens with photos pass their own
/// [AppScaffold.background].
class AppBackground extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: context.palette.brandGradient),
    child: const SizedBox.expand(),
  );
}

class AppScaffold extends StatelessWidget {
  const new({
    required this.body,
    this.title,
    this.actions = const [],
    this.background,
    super.key,
  });

  final String? title;
  final List<Widget> actions;
  final Widget body;

  /// Defaults to the flat `surface`; pass a photo or [AppBackground] when
  /// the screen's glass needs something colorful behind it.
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final hasBar = title != null || actions.isNotEmpty || canPop;
    if (AppUi.isLite(context)) {
      return _lite(context, canPop: canPop, hasBar: hasBar);
    }
    return GlassScaffold(
      background: background ?? ColoredBox(color: context.palette.surface),
      appBar: hasBar
          ? GlassAppBar(
              // Back, title and actions share the title slot (no flex: the
              // slot's width may be unbounded).
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canPop)
                    AppIconButton(
                      icon: AdaptiveIcons.back(context),
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  if (title != null)
                    Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (actions.isNotEmpty) ...[
                    SizedBox(width: AppDimens.space2),
                    ...actions,
                  ],
                ],
              ),
            )
          : null,
      // Transparent Material: ListTile, InkWell, TextField… need one, and
      // GlassScaffold (unlike Scaffold) doesn't provide it.
      body: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lite mode: no glass shaders and no background capture at all (the
/// package scaffold re-captures the screen every frame, which slow devices
/// and software-rendered emulators can't keep up with).
extension on AppScaffold {
  Widget _lite(
    BuildContext context, {
    required bool canPop,
    required bool hasBar,
  }) {
    final p = context.palette;
    return Material(
      color: p.surface,
      child: Stack(
        children: [
          if (background != null) Positioned.fill(child: background!),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasBar)
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppDimens.space2,
                      vertical: AppDimens.space1,
                    ),
                    child: Row(
                      children: [
                        if (canPop)
                          AppIconButton(
                            icon: AdaptiveIcons.back(context),
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        SizedBox(width: AppDimens.space2),
                        Expanded(
                          child: title == null
                              ? const SizedBox.shrink()
                              : Semantics(
                                  header: true,
                                  child: Text(
                                    title!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context
                                        .text(TextRole.headline)
                                        .copyWith(color: p.ink),
                                  ),
                                ),
                        ),
                        ...actions,
                      ],
                    ),
                  ),
                const OfflineBanner(),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A frosted glass card for reading (padding `space-4`, `radius-lg`).
class AppCard extends StatelessWidget {
  const new({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => AppGlass(
    padding: padding ?? EdgeInsets.all(AppDimens.space4),
    child: child,
  );
}

/// A round clear-glass button for controls over a photo: back, save, play.
/// The [tooltip] is also its accessibility label; the hit area is 48×48.
/// [selected] (a saved heart) draws a `brand` fill with `on-brand` content.
class AppIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected,
    this.tone = GlassTone.auto,
    this.backdrop,
    this.backdropRegion = const Rect.fromLTWH(0, 0, 1, 1),
    this.minimal = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// For toggles; null for plain buttons.
  final bool? selected;
  final GlassTone tone;
  final ImageProvider? backdrop;
  final Rect backdropRegion;

  /// One per card in a list (the cards' play button): the cheapest glass,
  /// like the card labels, so a screen of cards stays within the frame
  /// budget.
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    const size = AppDimens.touchTarget;
    final p = context.palette;
    final on = selected ?? false;
    final iconWidget = Icon(icon, size: AppDimens.icon);
    final face = on
        ? DecoratedBox(
            decoration: BoxDecoration(color: p.brand, shape: BoxShape.circle),
            child: IconTheme.merge(
              data: IconThemeData(color: p.onBrand),
              child: Center(child: iconWidget),
            ),
          )
        : AppGlass(
            kind: GlassKind.clear,
            tone: tone,
            radius: size / 2,
            backdrop: backdrop,
            backdropRegion: backdropRegion,
            minimal: minimal,
            child: Center(child: iconWidget),
          );
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        toggled: selected,
        label: tooltip,
        onTap: onPressed,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            child: SizedBox.square(dimension: size, child: face),
          ),
        ),
      ),
    );
  }
}

enum AppButtonKind {
  /// One per screen: `brand` pill with `on-brand` label.
  primary,

  /// Clear glass, only over photos or the brand gradient.
  clear,

  /// Low emphasis, `brand` label on solid surfaces.
  text,
}

/// The Design System button: 44 tall, 48 hit area, pill, verb label.
class AppButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
    this.tone = GlassTone.auto,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final IconData? icon;
  final GlassTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;
    final height = AppDimens.controlHeight;
    // Buttons read at body size, semibold (Design System → Button).
    final textStyle = context
        .text(TextRole.body)
        .copyWith(fontWeight: FontWeight.w600);
    final row = Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppDimens.space5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppDimens.iconChip),
            SizedBox(width: AppDimens.space2),
          ],
          Flexible(child: Text(label, style: textStyle)),
        ],
      ),
    );
    final face = switch (kind) {
      AppButtonKind.primary => DecoratedBox(
        decoration: BoxDecoration(
          color: p.brand,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: p.onBrand),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: p.onBrand),
            child: row,
          ),
        ),
      ),
      AppButtonKind.clear => AppGlass(
        kind: GlassKind.clear,
        tone: tone,
        radius: height / 2,
        child: row,
      ),
      AppButtonKind.text => IconTheme.merge(
        data: IconThemeData(color: p.brand),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: p.brand),
          child: row,
        ),
      ),
    };
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppDimens.touchTarget,
              minHeight: AppDimens.touchTarget,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: SizedBox(height: height, child: face),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rises and fades [child] into place once, when it first shows
/// (`AppMotion.reveal`). [index] staggers a list's first cards; from
/// `AppMotion.revealStaggered` on, they show at once. Nothing moves with
/// Reduce Motion.
class AppReveal extends StatefulWidget {
  const new({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _progress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    if (MediaQuery.disableAnimationsOf(context) ||
        widget.index >= AppMotion.revealStaggered) {
      return;
    }
    // The delay is the start of one animation (no timers), so it settles
    // in tests and stops when the card is disposed.
    final delay = AppMotion.revealStagger * widget.index;
    final total = delay + AppMotion.reveal;
    final controller = _controller = AnimationController(
      vsync: this,
      duration: total,
    );
    _progress = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppMotion.enter,
      ),
    );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null) return widget.child;
    return AnimatedBuilder(
      animation: progress,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: progress.value,
        child: Transform.translate(
          offset: Offset(0, AppMotion.revealRise * (1 - progress.value)),
          child: child,
        ),
      ),
    );
  }
}

/// A whole card as one tap target that shrinks a little while it's
/// pressed (`AppMotion.pressScale`). A scroll that starts on it cancels
/// the press. Still with Reduce Motion; no feedback when [onTap] is null.
/// Screen readers don't see the tap here: wrap it in a labelled
/// `Semantics(onTap:)`.
class AppPressable extends StatefulWidget {
  const new({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    final still = onTap == null || MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      // The card's own Semantics carries the tap and its label.
      excludeFromSemantics: true,
      onTap: onTap,
      onTapDown: still ? null : (_) => _set(true),
      onTapUp: still ? null : (_) => _set(false),
      onTapCancel: still ? null : () => _set(false),
      child: AnimatedScale(
        scale: _down ? AppMotion.pressScale : 1,
        duration: AppMotion.press,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// One option of an [AppSegmentedControl]; `badge` is a short tag after
/// the label («قريبًا»).
typedef AppSegment = ({String id, String label, String? badge});

/// A single-choice switch on the header band (Design System → Segmented
/// control): clear glass, the selected option a solid `AppColors.selected`
/// pill. Every option is at least [AppDimens.touchTarget] tall.
class AppSegmentedControl extends StatelessWidget {
  const new({
    required this.segments,
    required this.selectedId,
    required this.onSelected,
    this.tone = GlassTone.dark,
    super.key,
  });

  final List<AppSegment> segments;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final GlassTone tone;

  @override
  Widget build(BuildContext context) {
    // The whole height is the tap area; the selected pill sits inside it.
    const height = AppDimens.touchTarget;
    final inset = AppDimens.space1;
    return AppGlass(
      kind: GlassKind.clear,
      tone: tone,
      radius: height / 2,
      padding: EdgeInsetsDirectional.symmetric(horizontal: inset),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: _Segment(
                segment: s,
                selected: s.id == selectedId,
                height: height,
                pill: height - inset * 2,
                onTap: () => onSelected(s.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const new({
    required this.segment,
    required this.selected,
    required this.height,
    required this.pill,
    required this.onTap,
  });

  final AppSegment segment;
  final bool selected;

  /// The tap area's height, and the drawn pill's inside it.
  final double height;
  final double pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final badge = segment.badge;
    // Unselected: the glass's own text colour (it follows the glass tone
    // and the lite / high-contrast variant).
    final fg = selected ? AppColors.onSelected : null;
    final label = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            segment.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.forText(
              segment.label,
              TextRole.label,
            ).copyWith(color: fg),
          ),
        ),
        if (badge != null) ...[
          SizedBox(width: AppDimens.space1),
          DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? p.brand : AppColors.glassClearDark,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppDimens.space2,
              ),
              child: Text(
                badge,
                maxLines: 1,
                style: AppTextStyles.forText(
                  badge,
                  TextRole.caption,
                ).copyWith(color: selected ? p.onBrand : null),
              ),
            ),
          ),
        ],
      ],
    );
    return Semantics(
      button: true,
      selected: selected,
      label: [segment.label, ?badge].join('، '),
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Center(
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.select,
                constraints: BoxConstraints(minHeight: pill),
                alignment: Alignment.center,
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimens.space3,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.selected
                      : AppColors.selected.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                ),
                child: label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

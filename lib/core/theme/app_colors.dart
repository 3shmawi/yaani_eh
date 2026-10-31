import 'package:flutter/material.dart';

/// Colors that are the same in light and dark (Design System tokens).
/// Everything that changes with the theme lives in [AppPalette].
abstract final class AppColors {
  /// Material 3 seed: the light `brand` token (crema).
  static const brand = Color(0xFF9A4A24);

  static const espresso = Color(0xFF3B1F12);
  static const headerTop = Color(0xFF5A2C17);
  static const headerBottom = Color(0xFF24120A);
  static const onHeader = Color(0xFFFFFFFF);
  static const onHeaderMuted = Color(0xFFEBD9C6);

  /// Clear glass for controls; the tone comes from what's behind it.
  static const glassClearLight = Color(0x80FFFFFF);
  static const glassClearDark = Color(0x8C18100C);
  static const onGlassLight = Color(0xFF24170F);
  static const onGlassDark = Color(0xFFFFFFFF);

  /// The soft shadow at the bottom of a card photo that carries its name:
  /// espresso, clear at the top, fading in toward the text. [photoScrimStrong]
  /// with Reduce Transparency / Increase Contrast.
  static const photoScrim = Color(0xB3140C08);
  static const photoScrimStrong = Color(0xE6140C08);

  /// Specular rim: bright corners fading to the soft middle.
  static const glassRim = Color(0x99FFFFFF);
  static const glassRimSoft = Color(0x1AFFFFFF);

  /// A selected chip, tab or switch option on the header band: warm milk,
  /// the band's own secondary text colour, in both themes (pure white
  /// looked pasted on, and glared in dark mode).
  static const selected = Color(0xFFEBD9C6);
  static const onSelected = Color(0xFF24170F);

  /// The mashrabiya pattern behind the header band: milk, faint, so text
  /// on the band keeps its contrast.
  static const headerPattern = Color(0x2EEBD9C6);

  /// The cup in «طريقة التحضير»: what each layer looks like in real life,
  /// so the same in both themes. Each sits next to its name in the legend.
  static const layerEspresso = Color(0xFF4A2414);
  static const layerCoffee = Color(0xFF6B3A20);
  static const layerFoam = Color(0xFFF4EBDD);
  static const layerWater = Color(0xFFB9D3DC);
  static const layerMilk = Color(0xFFE9DCC8);
  static const layerMilkCoffee = Color(0xFFC8A27E);
  static const layerCondensed = Color(0xFFE7C995);
  static const layerChocolate = Color(0xFF5A3324);
  static const layerWhiteChocolate = Color(0xFFF1E4CC);
  static const layerCaramel = Color(0xFFC9803A);
  static const layerVanilla = Color(0xFFF2E3B8);
  static const layerCream = Color(0xFFFBF6EE);
  static const layerIce = Color(0xFFDDEAF0);
  static const layerTea = Color(0xFFA0522D);
  static const layerGreenTea = Color(0xFFB5B86A);
  static const layerMatcha = Color(0xFF8DB255);
  static const layerHibiscus = Color(0xFF9E1B32);
  static const layerMint = Color(0xFF9DBF7A);
  static const layerMango = Color(0xFFF2A93B);
  static const layerStrawberry = Color(0xFFD9475A);
  static const layerOrange = Color(0xFFF39C2B);
  static const layerLemon = Color(0xFFE8E08A);
  static const layerFruit = Color(0xFFE8C46A);
  static const layerBerry = Color(0xFF7B2D52);
  static const layerSahlab = Color(0xFFF3E9D6);
  static const layerNuts = Color(0xFFA9774A);
  static const layerCookies = Color(0xFF8B6B58);
  static const layerSoda = Color(0xFFE4EFE6);

  /// The cup's outline and its saucer shadow, over any surface.
  static const cupLine = Color(0x8C8C7564);
  static const cupShadow = Color(0x1F000000);

  /// Progress on the header band (step by step): done in warm milk, to come
  /// in faint milk.
  static const onHeaderFaint = Color(0x40FFFFFF);

  /// Cards and chips drawn on the header band (the welcome's pictures). The
  /// band is dark in both themes, so these don't change with it.
  static const bandCard = Color(0xF01C1511);
  static const bandCardLine = Color(0x24FFFFFF);
  static const bandCardInk = Color(0xFFF6EDE5);
  static const bandCardMuted = Color(0xFFBCA898);
  static const bandAccent = Color(0xFFE5A178);
  static const bandAccentFill = Color(0xFF3B2418);
  static const bandChip = Color(0x1FFFFFFF);
}

/// Theme-dependent Design System colors. Read with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const new({
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.inkMutedGlass,
    required this.line,
    required this.lineStrong,
    required this.brand,
    required this.onBrand,
    required this.brandSoft,
    required this.crema,
    required this.milk,
    required this.glassFill,
    required this.glassFillLite,
    required this.glassStroke,
    required this.scrim,
    required this.success,
    required this.warning,
    required this.danger,
    required this.focus,
    required this.glassShadow,
    required this.cardShadow,
  });

  static const light = AppPalette(
    surface: Color(0xFFF6EEE6),
    surfaceRaised: Color(0xFFFFFCF9),
    ink: Color(0xFF24170F),
    inkMuted: Color(0xFF6B5647),
    inkMutedGlass: Color(0xFF45352A),
    line: Color(0xFFEADCCF),
    lineStrong: Color(0xFF8C7564),
    brand: Color(0xFF9A4A24),
    onBrand: Color(0xFFFFFFFF),
    brandSoft: Color(0xFFF5E4D7),
    crema: Color(0xFFC9874F),
    milk: Color(0xFFEBD9C6),
    glassFill: Color(0xBDFFFAF5),
    glassFillLite: Color(0xF0FFFAF5),
    glassStroke: Color(0xB3FFFFFF),
    scrim: Color(0x73140C08),
    success: Color(0xFF2E6B3F),
    warning: Color(0xFF7A5200),
    danger: Color(0xFFB0301F),
    focus: Color(0xFF9A4A24),
    glassShadow: [
      BoxShadow(
        color: Color(0x293B1F12),
        offset: Offset(0, 10),
        blurRadius: 30,
      ),
    ],
    cardShadow: [
      BoxShadow(color: Color(0x0F3B1F12), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x143B1F12), offset: Offset(0, 8), blurRadius: 24),
    ],
  );

  static const dark = AppPalette(
    surface: Color(0xFF14100D),
    surfaceRaised: Color(0xFF1F1814),
    ink: Color(0xFFF6EDE5),
    inkMuted: Color(0xFFBCA898),
    inkMutedGlass: Color(0xFFDCCBBD),
    line: Color(0xFF3A2D25),
    lineStrong: Color(0xFF7D6656),
    brand: Color(0xFFE5A178),
    onBrand: Color(0xFF2A1409),
    brandSoft: Color(0xFF3B2418),
    crema: Color(0xFFA8683A),
    milk: Color(0xFF4A3529),
    glassFill: Color(0xC71C1511),
    glassFillLite: Color(0xF21C1511),
    glassStroke: Color(0x29FFFFFF),
    scrim: Color(0x8C000000),
    success: Color(0xFF8FD3A0),
    warning: Color(0xFFF0C36A),
    danger: Color(0xFFFFB4A8),
    focus: Color(0xFFE5A178),
    glassShadow: [
      BoxShadow(
        color: Color(0x73000000),
        offset: Offset(0, 10),
        blurRadius: 30,
      ),
    ],
    cardShadow: [
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 16),
    ],
  );

  final Color surface;
  final Color surfaceRaised;
  final Color ink;

  /// Secondary text on solid surfaces only.
  final Color inkMuted;

  /// Secondary text on frosted glass.
  final Color inkMutedGlass;
  final Color line;
  final Color lineStrong;
  final Color brand;
  final Color onBrand;
  final Color brandSoft;
  final Color crema;
  final Color milk;

  /// Frosted glass, the material for reading.
  final Color glassFill;

  /// Glass without blur (lite mode, Reduce Transparency).
  final Color glassFillLite;
  final Color glassStroke;
  final Color scrim;
  final Color success;
  final Color warning;
  final Color danger;
  final Color focus;
  final List<BoxShadow> glassShadow;
  final List<BoxShadow> cardShadow;

  /// The gradient behind glass when there is no photo: espresso → crema → milk.
  LinearGradient get brandGradient => LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [AppColors.espresso, crema, milk],
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension AppPaletteContext on BuildContext {
  /// The Design System colors for the current theme.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

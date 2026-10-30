import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yaani_eh/core/backend/media.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';

/// A drink photo filling its box, cached on the device after the first
/// view (works offline from then on). No photo, or not loaded yet: the
/// brand gradient with the drink's first letter. Decorative for screen
/// readers; the name is always in text next to it.
class DrinkPhoto extends StatelessWidget {
  const new({required this.name, this.imagePath, super.key});

  final String name;

  /// Path in the `item-images` bucket.
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final url = MediaUrls.itemImage(imagePath);
    final fallback = _Fallback(name: name);
    return ExcludeSemantics(
      child: url == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (_, _) => fallback,
              errorWidget: (_, _, _) => fallback,
            ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const new({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '؟' : name.trim().characters.first;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.palette.brandGradient),
      child: Align(
        alignment: const AlignmentDirectional(0, -0.35),
        child: Text(
          initial.toUpperCase(),
          style: AppTextStyles.forText(initial, TextRole.largeTitle).copyWith(
            color: AppColors.onHeader.withValues(alpha: 0.85),
            fontSize: 56,
          ),
        ),
      ),
    );
  }
}

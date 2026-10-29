import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The menu on this device. A simple list for now; `browse_menu` turns it
/// into the Home artboard (photos, chips, drink of the day, tab bar).
class HomeView extends StatelessWidget {
  const new({required this.items, required this.onOpenSettings, super.key});

  /// Null while loading from the device.
  final List<CatalogItem>? items;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = this.items;
    return Material(
      color: context.palette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderBand(
            eyebrow: l10n.appEyebrow,
            title: l10n.menuTitle,
            subtitle: l10n.menuTagline,
            trailing: AppIconButton(
              key: const Key('home_settings_button'),
              icon: AppIcons.settings,
              tooltip: l10n.settingsTitle,
              tone: GlassTone.dark,
              onPressed: onOpenSettings,
            ),
          ),
          const OfflineBanner(),
          Expanded(
            child: switch (items) {
              null => const LoadingView(),
              [] => EmptyView(message: l10n.menuEmpty),
              _ => _MenuList(items: items),
            },
          ),
        ],
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  const new({required this.items});

  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView.separated(
      key: const Key('menu_list'),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimens.space4,
        AppDimens.space4,
        AppDimens.space4,
        AppDimens.space8,
      ),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: AppDimens.space3),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            context.l10n.menuCount(items.length),
            style: context.text(TextRole.headline).copyWith(color: p.ink),
          );
        }
        return _MenuRow(item: items[index - 1]);
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  const new({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final explanation = arabic ? item.explanationAr : item.explanationEn;
    return Container(
      padding: EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: p.cardShadow,
      ),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.menuName,
              style: AppTextStyles.forText(
                item.menuName,
                TextRole.headline,
              ).copyWith(color: p.ink),
            ),
            Text(
              item.menuNameAr,
              style: AppTextStyles.forText(
                item.menuNameAr,
                TextRole.caption,
              ).copyWith(color: p.inkMuted),
            ),
            SizedBox(height: AppDimens.space2),
            Text(
              explanation,
              style: AppTextStyles.forText(
                explanation,
                TextRole.body,
              ).copyWith(color: p.ink),
            ),
          ],
        ),
      ),
    );
  }
}

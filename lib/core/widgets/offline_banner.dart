import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yaani_eh/core/network/connectivity.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// Connection state for the whole app, set once in `AppShell`.
/// [OfflineBanner] reads it; so can any screen (`ConnectionScope.of`).
class ConnectionScope extends StatefulWidget {
  const new({required this.child, this.onlineChanges, super.key});

  final Widget child;

  /// Defaults to the device connectivity; tests pass their own stream.
  final Stream<bool>? onlineChanges;

  /// How long "Back online" stays after the connection returns.
  static const backOnlineFor = Duration(seconds: 3);

  static NetworkState of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ConnectionInherited>()
          ?.state ??
      NetworkState.online;

  @override
  State<ConnectionScope> createState() => _ConnectionScopeState();
}

/// What the banner shows.
enum NetworkState { online, offline, backOnline }

class _ConnectionScopeState extends State<ConnectionScope> {
  StreamSubscription<bool>? _sub;
  Timer? _hide;
  NetworkState _state = NetworkState.online;

  @override
  void initState() {
    super.initState();
    _sub = (widget.onlineChanges ?? ConnectivityStatus.onlineChanges).listen(
      _onChange,
    );
  }

  void _onChange(bool online) {
    _hide?.cancel();
    final next = online
        ? (_state == NetworkState.offline
              ? NetworkState.backOnline
              : NetworkState.online)
        : NetworkState.offline;
    if (next == NetworkState.backOnline) {
      _hide = Timer(ConnectionScope.backOnlineFor, () {
        if (mounted) setState(() => _state = NetworkState.online);
      });
    }
    if (next != _state) setState(() => _state = next);
  }

  @override
  void dispose() {
    _hide?.cancel();
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ConnectionInherited(state: _state, child: widget.child);
}

class _ConnectionInherited extends InheritedWidget {
  const new({required this.state, required super.child});

  final NetworkState state;

  @override
  bool updateShouldNotify(_ConnectionInherited old) => old.state != state;
}

/// A small pill under the top bar (or the header band) that reports the
/// connection without blocking anything: the app is offline-first, so this
/// is information, not an error. `AppScaffold` shows it automatically;
/// screens that open with a `HeaderBand` place it right under the band.
class OfflineBanner extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ConnectionScope.of(context);
    final p = context.palette;
    final l10n = context.l10n;
    final pill = switch (state) {
      NetworkState.online => null,
      NetworkState.offline => (AppIcons.wifiSlash, p.ink, l10n.offlineBanner),
      NetworkState.backOnline => (
        AppIcons.checkCircle,
        p.success,
        l10n.backOnline,
      ),
    };
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: pill == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppDimens.space4,
                AppDimens.space3,
                AppDimens.space4,
                0,
              ),
              child: Semantics(
                liveRegion: true,
                container: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    boxShadow: p.cardShadow,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppDimens.space4,
                      vertical: AppDimens.space3,
                    ),
                    child: Row(
                      children: [
                        Icon(pill.$1, color: pill.$2, size: AppDimens.icon),
                        SizedBox(width: AppDimens.space3),
                        Expanded(
                          child: Text(
                            pill.$3,
                            style: context
                                .text(TextRole.callout)
                                .copyWith(color: p.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

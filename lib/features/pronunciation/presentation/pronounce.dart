import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/pronunciation/domain/entities/pronunciation.dart';
import 'package:yaani_eh/features/pronunciation/domain/usecases/clips_for.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronunciation_controller.dart';
import 'package:yaani_eh/features/pronunciation/presentation/widgets/play_name_button.dart';
import 'package:yaani_eh/features/pronunciation/presentation/widgets/pronounce_pill.dart';

/// What [item]'s [voice] is doing in [state] (any voice when null).
SegmentState segmentState(
  PronunciationState state,
  CatalogItem item, [
  Voice? voice,
]) => switch (state.playback) {
  final PlaybackLoading p when p.isFor(item.id, voice) => SegmentState.loading,
  final PlaybackPlaying p when p.isFor(item.id, voice) => SegmentState.playing,
  final PlaybackFailed p when p.isFor(item.id, voice) => SegmentState.failed,
  _ => SegmentState.idle,
};

/// The drink page's pronounce pill, wired to the app's player. Prefetches
/// the clips so they also play offline later. Nothing when the drink has
/// no clips.
class ItemPronounce extends ConsumerStatefulWidget {
  const new({required this.item, super.key});

  final CatalogItem item;

  @override
  ConsumerState<ItemPronounce> createState() => _ItemPronounceState();
}

class _ItemPronounceState extends ConsumerState<ItemPronounce> {
  @override
  void initState() {
    super.initState();
    ref.read(pronunciationProvider.notifier).prefetch(widget.item);
  }

  @override
  void didUpdateWidget(ItemPronounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      ref.read(pronunciationProvider.notifier).prefetch(widget.item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final state = ref.watch(pronunciationProvider);
    final controller = ref.read(pronunciationProvider.notifier);
    final playback = state.playback;
    return PronouncePill(
      name: item.menuName,
      voices: [for (final clip in const ClipsFor()(item)) clip.voice],
      states: {
        for (final voice in Voice.values)
          if (segmentState(state, item, voice) case final s
              when s != SegmentState.idle)
            voice: s,
      },
      failure: playback is PlaybackFailed && playback.isFor(item.id)
          ? playback.failure
          : null,
      speed: state.speed,
      onToggle: (voice) => controller.toggle(item, voice),
      onToggleSpeed: controller.toggleSpeed,
    );
  }
}

/// The cards' round play button, wired to the app's player: plays the
/// drink's first clip. Nothing when the drink has no clips.
class ItemPlayButton extends ConsumerWidget {
  const new({required this.item, this.tone = GlassTone.auto, super.key});

  final CatalogItem item;
  final GlassTone tone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (const ClipsFor()(item).isEmpty) return const SizedBox.shrink();
    final state = ref.watch(pronunciationProvider);
    final playback = state.playback;
    return PlayNameButton(
      key: Key('play_${item.slug}'),
      name: item.menuName,
      state: segmentState(state, item),
      failure: playback is PlaybackFailed && playback.isFor(item.id)
          ? playback.failure
          : null,
      tone: tone,
      onPressed: () =>
          ref.read(pronunciationProvider.notifier).toggleFirst(item),
    );
  }
}

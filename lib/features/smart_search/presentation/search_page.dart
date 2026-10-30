import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/widgets/search_field.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_controller.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_controller.dart';
import 'package:yaani_eh/features/smart_search/presentation/search_controller.dart';
import 'package:yaani_eh/features/smart_search/presentation/search_view.dart';

/// `/search?q=…`: wires the query (debounced 150 ms) to [SearchView].
class SearchPage extends ConsumerStatefulWidget {
  const new({this.initialQuery = '', super.key});

  /// From a deep link; already trimmed and capped by the router.
  final String initialQuery;

  static const debounce = Duration(milliseconds: 150);

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _reportedEmpty = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    unawaited(
      Future.microtask(() {
        if (mounted) {
          ref.read(searchQueryProvider.notifier).set(widget.initialQuery);
        }
      }),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(SearchPage.debounce, () {
      if (mounted) ref.read(searchQueryProvider.notifier).set(text);
    });
  }

  void _try(String text) {
    final capped = text.length > SearchField.maxLength
        ? text.substring(0, SearchField.maxLength)
        : text;
    _controller
      ..text = capped
      ..selection = TextSelection.collapsed(offset: capped.length);
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).set(capped);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final answer = results?.answer;
    ItemFacts? facts;
    if (answer != null) {
      final details = ref.watch(drinkDetailsProvider(answer.item.slug));
      facts = const DescribeItem()(
        item: answer.item,
        traitSchema: details is DrinkFound ? details.traitSchema : null,
        lang: Localizations.localeOf(context).languageCode,
        now: ref.watch(todayProvider),
      );
    }
    // Only how often search comes up empty, never what was typed.
    if (results != null &&
        results.query.isNotEmpty &&
        results.isEmpty &&
        results.query != _reportedEmpty) {
      _reportedEmpty = results.query;
      unawaited(
        Analytics.capture('search_no_results', {
          'length': results.query.length,
        }),
      );
    }
    return SearchView(
      controller: _controller,
      results: results,
      answerFacts: facts,
      onChanged: _onChanged,
      onTry: _try,
      onBack: _back,
      onOpen: (item, from, position) {
        unawaited(
          Analytics.capture('search_result_opened', {
            'from': from.name,
            'position': position,
          }),
        );
        unawaited(context.push<void>(AppRoutes.drink(item.slug)));
      },
    );
  }
}

import 'package:cadence/models/search.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// C1: the search and the family filter, on one line: the families as text
/// tabs, the magnifier on the right. Used on the main
/// screen, the Techniques screen and, from step 4, the form.
///
/// The [filter] belongs to the screen's controller: this widget shows it and
/// reports the changes. It only keeps what is about display: whether the
/// text field is open.
class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({
    super.key,
    required this.filter,
    required this.onQueryChanged,
    required this.onFamilyChanged,
  });

  final SearchFilter filter;
  final ValueChanged<String> onQueryChanged;

  /// Null for « Toutes ».
  final ValueChanged<Family?> onFamilyChanged;

  /// Fixed, so that a screen can pin the bar (the form).
  static const height = 56.0;

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

/// A [StatefulWidget] keeps its [State] object between two builds: the text
/// field and its controller survive each keystroke.
class _SearchFilterBarState extends State<SearchFilterBar> {
  late final _text = TextEditingController(text: widget.filter.query);
  final _focus = FocusNode();
  bool _editing = false;

  // Whether tabs are hidden beyond each edge: those edges fade out, so the
  // user sees that the line scrolls.
  bool _moreBefore = false;
  bool _moreAfter = false;

  @override
  void initState() {
    super.initState();
    // Leaving the field (back key, tap elsewhere) folds it back; the text
    // stays and is shown as a chip.
    _focus.addListener(() {
      if (!_focus.hasFocus) setState(() => _editing = false);
    });
  }

  /// Called when the screen rebuilds this widget with a new [filter]: after
  /// « Tout effacer », the field must empty too.
  @override
  void didUpdateWidget(SearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.query != _text.text) _text.text = widget.filter.query;
  }

  /// A [TextEditingController] and a [FocusNode] hold resources: they are
  /// released when the widget leaves the screen.
  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Called on each scroll, and when the line is first laid out or resized.
  bool _onScroll(ScrollMetrics metrics) {
    final before = metrics.pixels > metrics.minScrollExtent + 1;
    final after = metrics.pixels < metrics.maxScrollExtent - 1;
    if (before != _moreBefore || after != _moreAfter) {
      setState(() {
        _moreBefore = before;
        _moreAfter = after;
      });
    }
    // Lets the notification go on to the screen, as if it was not caught.
    return false;
  }

  void _clearQuery() {
    _text.clear();
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SearchFilterBar.height,
      child: _editing ? _field() : _tabs(),
    );
  }

  Widget _field() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.gutter,
        vertical: 4,
      ),
      child: TextField(
        controller: _text,
        focusNode: _focus,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: (text) {
          widget.onQueryChanged(text);
          // Shows or hides the clear button.
          setState(() {});
        },
        onSubmitted: (_) => _focus.unfocus(),
        decoration: InputDecoration(
          hintText: switch (widget.filter.family) {
            null => 'Rechercher',
            final family => 'Rechercher dans ${family.label}',
          },
          isDense: true,
          prefixIcon: IconButton(
            tooltip: 'Fermer la recherche',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _focus.unfocus,
          ),
          suffixIcon: _text.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Effacer la recherche',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(_clearQuery),
                ),
        ),
      ),
    );
  }

  /// Fades the tabs out at the edges where more are hidden. The mask is
  /// opaque in the middle and transparent at a faded edge: [BlendMode.dstIn]
  /// keeps the tabs only where the mask is opaque.
  Widget _fadeEdges(Widget child) {
    const fade = 40.0;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final edge = (fade / rect.width).clamp(0.0, 0.5);
        return LinearGradient(
          colors: [
            _moreBefore ? Colors.transparent : Colors.black,
            Colors.black,
            Colors.black,
            _moreAfter ? Colors.transparent : Colors.black,
          ],
          stops: [0, edge, 1 - edge, 1],
        ).createShader(rect);
      },
      child: child,
    );
  }

  Widget _tabs() {
    final query = widget.filter.query.trim();
    final selected = widget.filter.family;
    return Row(
      children: [
        Expanded(
          // ScrollMetricsNotification: the first layout, before any scroll.
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (n) => _onScroll(n.metrics),
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (n) => _onScroll(n.metrics),
              child: _fadeEdges(
                ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: AppTheme.gutter - 12),
                  children: [
                    if (query.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Center(
                          child: InputChip(
                            label: Text('« $query »'),
                            onPressed: () => setState(() => _editing = true),
                            onDeleted: _clearQuery,
                            deleteButtonTooltipMessage: 'Effacer la recherche',
                          ),
                        ),
                      ),
                    _Tab(
                      label: 'Toutes',
                      selected: selected == null,
                      onTap: () => widget.onFamilyChanged(null),
                    ),
                    for (final family in Family.values)
                      _Tab(
                        label: family.label,
                        family: family,
                        selected: selected == family,
                        // Touching the selected family again goes back to « Toutes ».
                        onTap: () => widget.onFamilyChanged(
                          selected == family ? null : family,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Rechercher',
          icon: const Icon(Icons.search_rounded),
          onPressed: () => setState(() => _editing = true),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

/// One family as a text tab: capitals, a gold line under the selected one,
/// and a square of the family color before the name (V3: never the color
/// alone).
class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.family,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Family? family;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
    );
    final family = this.family;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () {
          // The touched tab slides toward the middle: the next ones appear.
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              if (family != null) ...[
                SizedBox.square(
                  dimension: 8,
                  child: ColoredBox(
                    color: CadenceColors.of(context).family(family),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(label.toUpperCase(), style: style),
            ],
          ),
        ),
      ),
    );
  }
}

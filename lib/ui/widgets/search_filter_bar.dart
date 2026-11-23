import 'package:cadence/models/search.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({
    super.key,
    required this.filter,
    required this.onQueryChanged,
    required this.onFamilyChanged,
  });

  final SearchFilter filter;
  final ValueChanged<String> onQueryChanged;

  final ValueChanged<Family?> onFamilyChanged;

  static const height = 56.0;

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late final _text = TextEditingController(text: widget.filter.query);
  final _focus = FocusNode();
  bool _editing = false;

  // A faded edge shows that the line scrolls.
  bool _moreBefore = false;
  bool _moreAfter = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) setState(() => _editing = false);
    });
  }

  @override
  void didUpdateWidget(SearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.query != _text.text) _text.text = widget.filter.query;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollMetrics metrics) {
    final before = metrics.pixels > metrics.minScrollExtent + 1;
    final after = metrics.pixels < metrics.maxScrollExtent - 1;
    if (before != _moreBefore || after != _moreAfter) {
      setState(() {
        _moreBefore = before;
        _moreAfter = after;
      });
    }
    // Lets the notification bubble up.
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
          // Also sent on the first layout, before any scroll.
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (notification) => _onScroll(notification.metrics),
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) => _onScroll(notification.metrics),
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

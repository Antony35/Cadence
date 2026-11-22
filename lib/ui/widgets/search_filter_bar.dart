import 'package:cadence/models/search.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';

/// C1: the search and the family filter, on one line. Used on the main
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

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

/// A [StatefulWidget] keeps its [State] object between two builds: the text
/// field and its controller survive each keystroke.
class _SearchFilterBarState extends State<SearchFilterBar> {
  late final _text = TextEditingController(text: widget.filter.query);
  final _focus = FocusNode();
  bool _editing = false;

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

  void _clearQuery() {
    _text.clear();
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 56, child: _editing ? _field() : _chips());
  }

  Widget _field() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
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

  Widget _chips() {
    final query = widget.filter.query.trim();
    final selected = widget.filter.family;
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        IconButton(
          tooltip: 'Rechercher',
          icon: const Icon(Icons.search_rounded),
          onPressed: () => setState(() => _editing = true),
        ),
        if (query.isNotEmpty)
          _spaced(
            InputChip(
              label: Text('« $query »'),
              onPressed: () => setState(() => _editing = true),
              onDeleted: _clearQuery,
              deleteButtonTooltipMessage: 'Effacer la recherche',
            ),
          ),
        _spaced(
          ChoiceChip(
            label: const Text('Toutes'),
            showCheckmark: false,
            selected: selected == null,
            onSelected: (_) => widget.onFamilyChanged(null),
          ),
        ),
        for (final family in Family.values)
          _spaced(
            ChoiceChip(
              avatar: FamilyBadge(family, size: 20),
              label: Text(family.label),
              showCheckmark: false,
              selected: selected == family,
              // Touching the selected family again goes back to « Toutes ».
              onSelected: (on) => widget.onFamilyChanged(on ? family : null),
            ),
          ),
      ],
    );
  }

  Widget _spaced(Widget chip) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Center(child: chip),
  );
}

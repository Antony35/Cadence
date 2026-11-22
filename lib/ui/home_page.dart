import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/home_controller.dart';
import 'package:cadence/state/load_state.dart';
import 'package:cadence/ui/combo_form_page.dart';
import 'package:cadence/ui/combo_page.dart';
import 'package:cadence/ui/techniques_page.dart';
import 'package:cadence/ui/widgets/combo_tile.dart';
import 'package:cadence/ui/widgets/review_card.dart';
import 'package:cadence/ui/widgets/search_filter_bar.dart';
import 'package:cadence/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// E1: the « À réviser » card and the list of combos (F1 to F5).
///
/// A [StatefulWidget], because the screen owns objects that must live as
/// long as it does, then be released: its controller and its lifecycle
/// listener.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  late final AppLifecycleListener _lifecycle;

  /// Called once, when the screen appears.
  @override
  void initState() {
    super.initState();
    // `read` takes a service declared in CadenceApp, once, like a
    // constructor injection in Symfony.
    _controller = HomeController(
      combos: context.read<ComboRepository>(),
      clock: context.read<Clock>(),
    )..load();
    // Back to the foreground after a night in the background, « today » has
    // changed: the figures are computed again.
    _lifecycle = AppLifecycleListener(onResume: _controller.load);
  }

  /// Called once, when the screen goes away.
  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openTechniques() async {
    Navigator.pop(context); // Closes the side menu first.
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const TechniquesPage()),
    );
    // While we waited, the screen may have been closed: `mounted` says if it
    // is still there.
    if (!mounted) return;
    // Back from another screen, the list is read again: a combo may have
    // been changed or deleted from a technique sheet.
    await _controller.load();
  }

  /// F5: the form; back with a new combo, the list is read again.
  Future<void> _create() async {
    final combo = await Navigator.push(
      context,
      MaterialPageRoute<Combo>(builder: (_) => const ComboFormPage()),
    );
    if (!mounted) return;
    await _controller.load();
    if (combo != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistré · à réviser demain')),
      );
    }
  }

  /// F5: touching a row opens the sheet of the combo.
  Future<void> _open(Combo combo) async {
    await Navigator.push(
      context,
      MaterialPageRoute<bool>(builder: (_) => ComboPage(id: combo.id)),
    );
    if (!mounted) return;
    await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CADENCE')),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 16, 16),
                child: Text(
                  'CADENCE',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              // Paramètres and À propos come with step 6.
              ListTile(
                leading: const Icon(Icons.grid_view_rounded),
                title: Text(
                  'TECHNIQUES',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                onTap: _openTechniques,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        tooltip: 'Ajouter un enchaînement',
        child: const Icon(Icons.add_rounded),
      ),
      // Rebuilds what is below each time the controller notifies.
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.state) {
          Loading() => const LoadingView(),
          Failed(:final message) => ErrorView(
            message: message,
            onRetry: _controller.load,
          ),
          Empty() => MessageView(
            icon: Icons.sports_mma_rounded,
            title: 'Aucun enchaînement',
            text:
                'Notez les enchaînements vus en cours : '
                'Cadence vous dira quand les réviser.',
            action: FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter un enchaînement'),
            ),
          ),
          Ready() => _content(),
        },
      ),
    );
  }

  Widget _content() {
    final visible = _controller.visible;
    final text = Theme.of(context).textTheme;
    return ListView(
      // Leaves room for the + button under the last combo.
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ReviewCard(summary: _controller.summary),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 4),
          // One text with two styles: it wraps with enlarged text.
          child: Text.rich(
            TextSpan(
              style: text.titleMedium,
              children: [
                const TextSpan(text: 'MES ENCHAÎNEMENTS '),
                TextSpan(
                  text: '${_controller.summary.total}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SearchFilterBar(
          filter: _controller.filter,
          onQueryChanged: _controller.search,
          onFamilyChanged: _controller.selectFamily,
        ),
        if (visible.isEmpty)
          NoResultView(onClear: _controller.clearFilter)
        else
          // Rows separated by thin lines, like the lines of a notebook.
          for (final (index, combo) in visible.indexed) ...[
            if (index > 0) const Divider(indent: 16, endIndent: 16),
            ComboTile(
              combo: combo,
              today: _controller.today,
              onTap: () => _open(combo),
            ),
          ],
      ],
    );
  }
}

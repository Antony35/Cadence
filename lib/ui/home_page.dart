import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/home_controller.dart';
import 'package:cadence/state/load_state.dart';
import 'package:cadence/ui/about_page.dart';
import 'package:cadence/ui/combo_form_page.dart';
import 'package:cadence/ui/combo_page.dart';
import 'package:cadence/ui/session_page.dart';
import 'package:cadence/ui/settings_page.dart';
import 'package:cadence/ui/techniques_page.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/brand.dart';
import 'package:cadence/ui/widgets/combo_tile.dart';
import 'package:cadence/ui/widgets/review_card.dart';
import 'package:cadence/ui/widgets/search_filter_bar.dart';
import 'package:cadence/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(
      combos: context.read<ComboRepository>(),
      clock: context.read<Clock>(),
    )..load();
    // After a night in the background, « today » has changed.
    _lifecycle = AppLifecycleListener(onResume: _controller.load);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openTechniques() async {
    Navigator.pop(context); // The side menu.
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const TechniquesPage()),
    );
    if (!mounted) return;
    // A combo may have been changed or deleted from a technique sheet.
    await _controller.load();
  }

  Future<void> _openFromMenu(Widget page) async {
    Navigator.pop(context); // The side menu.
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

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

  Future<void> _startSession() async {
    final reviewAhead = _controller.summary.due == 0;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SessionPage(reviewAhead: reviewAhead),
      ),
    );
    if (!mounted) return;
    await _controller.load();
  }

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
      appBar: AppBar(
        title: const Row(
          children: [
            BrandMark(size: 36),
            SizedBox(width: 12),
            Flexible(child: Text('CADENCE', overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const BrandPoster(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                20,
                AppTheme.gutter,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CADENCE',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    "Carnet d'enchaînements",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.gutter,
              ),
              leading: const Icon(Icons.grid_view_rounded),
              title: Text(
                'TECHNIQUES',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              onTap: _openTechniques,
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.gutter,
              ),
              leading: const Icon(Icons.tune_rounded),
              title: Text(
                'PARAMÈTRES',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              onTap: () => _openFromMenu(const SettingsPage()),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.gutter,
              ),
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(
                'À PROPOS',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              onTap: () => _openFromMenu(const AboutPage()),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        tooltip: 'Ajouter un enchaînement',
        child: const Icon(Icons.add_rounded),
      ),
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
            visual: const BrandMark(size: 160),
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
          Ready() => _buildList(),
        },
      ),
    );
  }

  Widget _buildList() {
    final visibleCombos = _controller.visibleCombos;
    final summary = _controller.summary;
    final text = Theme.of(context).textTheme;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 16),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
              child: ReviewCard(summary: summary, onStart: _startSession),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              40,
              AppTheme.gutter,
              8,
            ),
            child: Text.rich(
              TextSpan(
                style: text.titleMedium,
                children: [
                  const TextSpan(text: 'MES ENCHAÎNEMENTS '),
                  TextSpan(
                    text: '${summary.total}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SearchFilterBar(
            filter: _controller.filter,
            onQueryChanged: _controller.search,
            onFamilyChanged: _controller.selectFamily,
          ),
        ),
        if (visibleCombos.isEmpty)
          SliverToBoxAdapter(
            child: NoResultView(onClear: _controller.clearFilter),
          )
        else
          SliverList.separated(
            itemCount: visibleCombos.length,
            separatorBuilder: (_, _) => const Divider(
              indent: AppTheme.gutter,
              endIndent: AppTheme.gutter,
            ),
            itemBuilder: (_, index) => ComboTile(
              combo: visibleCombos[index],
              today: _controller.today,
              onTap: () => _open(visibleCombos[index]),
            ),
          ),
        // Room for the + button under the last combo.
        const SliverPadding(padding: EdgeInsets.only(bottom: 112)),
      ],
    );
  }
}

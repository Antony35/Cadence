import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/load_state.dart';
import 'package:cadence/state/techniques_controller.dart';
import 'package:cadence/ui/technique_page.dart';
import 'package:cadence/ui/widgets/search_filter_bar.dart';
import 'package:cadence/ui/widgets/state_views.dart';
import 'package:cadence/ui/widgets/technique_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// E5: the 41 techniques, with the search and the family filter (F24).
class TechniquesPage extends StatefulWidget {
  const TechniquesPage({super.key});

  @override
  State<TechniquesPage> createState() => _TechniquesPageState();
}

class _TechniquesPageState extends State<TechniquesPage> {
  late final _controller = TechniquesController(
    techniques: context.read<TechniqueRepository>(),
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(Technique technique) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => TechniquePage(technique: technique),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TECHNIQUES')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.state) {
          Loading() => const LoadingView(),
          Failed(:final message) => ErrorView(
            message: message,
            onRetry: _controller.load,
          ),
          // The catalog is inserted with the database: never empty.
          Empty() => const MessageView(
            icon: Icons.grid_view_rounded,
            title: 'Aucune technique',
            text: 'Le catalogue est vide.',
          ),
          Ready() => Column(
            children: [
              SearchFilterBar(
                filter: _controller.filter,
                onQueryChanged: _controller.search,
                onFamilyChanged: _controller.selectFamily,
              ),
              Expanded(
                child: _controller.visible.isEmpty
                    ? NoResultView(onClear: _controller.clearFilter)
                    : TechniqueGrid(
                        techniques: _controller.visible,
                        onTap: _open,
                      ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

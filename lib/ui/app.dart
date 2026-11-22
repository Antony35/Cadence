import 'package:cadence/data/repositories.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/ui/home_page.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

/// The root of the app. It receives the services built by `main.dart` (or
/// fakes, in the tests) and makes them available to every screen.
class CadenceApp extends StatelessWidget {
  const CadenceApp({
    super.key,
    required this.techniques,
    required this.combos,
    required this.reviews,
    this.images = const TechniqueImages.none(),
    this.clock = const Clock(),
  });

  final TechniqueRepository techniques;
  final ComboRepository combos;
  final ReviewRepository reviews;
  final TechniqueImages images;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    // The service container of the app: any screen below can ask for one
    // with `context.read<ComboRepository>()`, without it being passed from
    // screen to screen. Above MaterialApp, so that the screens pushed later
    // see them too.
    return MultiProvider(
      providers: [
        Provider<TechniqueRepository>.value(value: techniques),
        Provider<ComboRepository>.value(value: combos),
        Provider<ReviewRepository>.value(value: reviews),
        Provider<TechniqueImages>.value(value: images),
        Provider<Clock>.value(value: clock),
      ],
      child: MaterialApp(
        title: 'Cadence',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // Material's own texts in French: tooltips, the date picker…
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomePage(),
      ),
    );
  }
}

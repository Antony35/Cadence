import 'package:cadence/data/repositories.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/screen_awake.dart';
import 'package:cadence/state/speaker.dart';
import 'package:cadence/ui/home_page.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class CadenceApp extends StatelessWidget {
  const CadenceApp({
    super.key,
    required this.techniques,
    required this.combos,
    required this.reviews,
    required this.speaker,
    required this.screenAwake,
    this.images = const TechniqueImages.none(),
    this.clock = const Clock(),
  });

  final TechniqueRepository techniques;
  final ComboRepository combos;
  final ReviewRepository reviews;
  final Speaker speaker;
  final ScreenAwake screenAwake;
  final TechniqueImages images;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    // Above MaterialApp, so that pushed screens see the services too.
    return MultiProvider(
      providers: [
        Provider<TechniqueRepository>.value(value: techniques),
        Provider<ComboRepository>.value(value: combos),
        Provider<ReviewRepository>.value(value: reviews),
        Provider<TechniqueImages>.value(value: images),
        Provider<Clock>.value(value: clock),
        Provider<Speaker>.value(value: speaker),
        Provider<ScreenAwake>.value(value: screenAwake),
      ],
      child: MaterialApp(
        title: 'Cadence',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Android draws the app under its navigation bar: one SafeArea for every
        // screen.
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(top: false, child: child!),
        ),
        home: const HomePage(),
      ),
    );
  }
}

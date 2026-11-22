import 'package:cadence/data/demo.dart';
import 'package:cadence/data/drift/database.dart';
import 'package:cadence/data/drift/drift_combo_repository.dart';
import 'package:cadence/data/drift/drift_review_repository.dart';
import 'package:cadence/data/drift/drift_technique_repository.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/ui/app.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds the services once, then starts the app. The only file that knows
/// the drift implementations: everything else sees the contracts.
Future<void> main() async {
  // Lets the code below use the engine (the files of the app) before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Opened on the first query; an error then reaches the screens, which show
  // their error state (S1).
  final db = AppDatabase.open();
  final techniques = DriftTechniqueRepository(db);
  final combos = DriftComboRepository(db, techniques);
  final reviews = DriftReviewRepository(db);
  const clock = Clock();

  if (DemoData.enabled) {
    await DemoData.loadIfEmpty(
      techniques: techniques,
      combos: combos,
      reviews: reviews,
      now: clock.now(),
    );
  }

  runApp(
    CadenceApp(
      techniques: techniques,
      combos: combos,
      reviews: reviews,
      images: await TechniqueImages.load(rootBundle),
      clock: clock,
    ),
  );
}

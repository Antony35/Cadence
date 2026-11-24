import 'package:cadence/data/demo.dart';
import 'package:cadence/data/drift/database.dart';
import 'package:cadence/data/drift/drift_combo_repository.dart';
import 'package:cadence/data/drift/drift_review_repository.dart';
import 'package:cadence/data/drift/drift_technique_repository.dart';
import 'package:cadence/data/preferences/preferences_settings_repository.dart';
import 'package:cadence/models/app_info.dart';
import 'package:cadence/platform/clip_speaker.dart';
import 'package:cadence/platform/wakelock_screen_awake.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/settings_controller.dart';
import 'package:cadence/ui/app.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Error details stay out of the phone's logs in the published app.
  if (kReleaseMode) debugPrint = (message, {wrapWidth}) {};

  // Opened on the first query: an error shows on the screens, not here.
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

  final settingsRepository = PreferencesSettingsRepository(
    SharedPreferencesAsync(),
  );
  // Read before runApp: the app opens in the chosen theme, without a flash.
  final settings = SettingsController(
    repository: settingsRepository,
    initial: await settingsRepository.load(),
  );
  final package = await PackageInfo.fromPlatform();

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Barlow',
      'Barlow Condensed',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });

  runApp(
    CadenceApp(
      settings: settings,
      appInfo: AppInfo(version: package.version),
      techniques: techniques,
      combos: combos,
      reviews: reviews,
      speaker: ClipSpeaker(),
      screenAwake: const WakelockScreenAwake(),
      images: await TechniqueImages.load(rootBundle),
      clock: clock,
    ),
  );
}

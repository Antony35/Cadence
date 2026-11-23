import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';

/// The recorded clips of the voice, in `assets/voice/`: one per technique,
/// side and target, named after its code (`techniques/low_kick.ogg`).
///
/// A step is said by playing its clips in a row: « Crochet » « arrière »
/// « au corps ». The words are the ones of [ComboStep.label].
abstract final class VoiceClips {
  static const _folder = 'assets/voice';

  static String technique(Technique technique) =>
      '$_folder/techniques/${technique.slug}.ogg';

  static String side(Side side) => '$_folder/sides/${side.name}.ogg';

  static String target(Target target) => '$_folder/targets/${target.name}.ogg';

  /// The clips of [step], in the order they are said.
  static List<String> of(ComboStep step) => [
    technique(step.technique),
    if (step.saidSide case final saidSide?) side(saidSide),
    if (step.saidTarget case final saidTarget?) target(saidTarget),
  ];
}

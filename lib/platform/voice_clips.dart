import 'package:cadence/models/combo.dart';
import 'package:cadence/models/drill.dart';
import 'package:cadence/models/technique.dart';

/// The recorded calls of the voice, in `assets/voice/`, one file per
/// sentence ([Drill.call]), said in one breath:
///
/// - `full/`: the slow calls, technique, side and target
///   (`full/hook_rear_body.ogg`, « Crochet arrière au corps »);
/// - `short/`: the faster ones that differ from them, the target in one
///   word (`short/hook_body.ogg`, « Crochet corps ») or the technique alone
///   (`short/hook.ogg`, « Crochet »).
///
/// A technique without any choice (« Pivot ») is the same at every pace:
/// only `full/` has it.
abstract final class VoiceClips {
  static const _folder = 'assets/voice';

  /// The file of [step] at [pace].
  static String of(ComboStep step, Pace pace) {
    final technique = step.technique;
    return switch ((pace, step.saidTarget)) {
      (Pace.slow, final target) => _full([
        technique.slug,
        ?step.saidSide?.name,
        ?target?.name,
      ]),
      (Pace.medium, final target?) => _short([technique.slug, target.name]),
      _ => alone(technique),
    };
  }

  /// The technique alone: `full/` holds it when there is nothing else to
  /// say, no side nor target to choose.
  static String alone(Technique technique) => technique.hasNoChoice
      ? _full([technique.slug])
      : _short([technique.slug]);

  static String _full(List<String> words) =>
      '$_folder/full/${words.join('_')}.ogg';

  static String _short(List<String> words) =>
      '$_folder/short/${words.join('_')}.ogg';
}

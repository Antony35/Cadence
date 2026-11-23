import 'package:cadence/models/combo.dart';
import 'package:cadence/models/drill.dart';
import 'package:cadence/models/technique.dart';

abstract final class VoiceClips {
  static const _folder = 'assets/voice';

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

  static String alone(Technique technique) => technique.hasNoChoice
      ? _full([technique.slug])
      : _short([technique.slug]);

  static String _full(List<String> words) =>
      '$_folder/full/${words.join('_')}.ogg';

  static String _short(List<String> words) =>
      '$_folder/short/${words.join('_')}.ogg';
}

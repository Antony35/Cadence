import 'dart:io';

import 'package:cadence/models/catalog.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/drill.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/platform/voice_clips.dart';
import 'package:flutter_test/flutter_test.dart';

import '../models/fixtures.dart';

void main() {
  test('one file per call, in one breath', () {
    final hook = step('hook', side: Side.rear, target: Target.body);
    expect(
      VoiceClips.of(hook, Pace.slow),
      'assets/voice/full/hook_rear_body.ogg',
    );
    expect(
      VoiceClips.of(hook, Pace.medium),
      'assets/voice/short/hook_body.ogg',
    );
    expect(VoiceClips.of(hook, Pace.fast), 'assets/voice/short/hook.ogg');
    // « Pivot » has nothing to choose: the same file at every pace.
    for (final pace in Pace.values) {
      expect(VoiceClips.of(step('pivot'), pace), 'assets/voice/full/pivot.ogg');
    }
  });

  test('every call has its file, and every file is a call', () {
    final expected = {
      for (final technique in catalog)
        for (final Side? side
            in technique.sides.isEmpty ? [null] : technique.sides)
          for (final Target? target
              in technique.targets.isEmpty ? [null] : technique.targets)
            for (final pace in Pace.values)
              VoiceClips.of(
                ComboStep(technique: technique, side: side, target: target),
                pace,
              ),
    };
    final files = {
      for (final file in Directory('assets/voice').listSync(recursive: true))
        if (file is File) file.path.replaceAll(r'\', '/'),
    };
    expect(files, expected);
    expect(files, hasLength(89 + 51));
  });
}

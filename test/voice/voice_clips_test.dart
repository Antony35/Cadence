import 'dart:io';

import 'package:cadence/models/catalog.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/voice/voice_clips.dart';
import 'package:flutter_test/flutter_test.dart';

import '../models/fixtures.dart';

void main() {
  test('a step is said with the words of its label', () {
    expect(VoiceClips.of(step('jab')), ['assets/voice/techniques/jab.ogg']);
    expect(VoiceClips.of(step('hook', side: Side.rear, target: Target.body)), [
      'assets/voice/techniques/hook.ogg',
      'assets/voice/sides/rear.ogg',
      'assets/voice/targets/body.ogg',
    ]);
  });

  test('every word has its clip, and every clip is a word', () {
    final expected = {
      for (final technique in catalog) VoiceClips.technique(technique),
      for (final side in Side.values) VoiceClips.side(side),
      for (final target in Target.values) VoiceClips.target(target),
    };
    final files = {
      for (final file in Directory('assets/voice').listSync(recursive: true))
        if (file is File) file.path.replaceAll(r'\', '/'),
    };
    expect(files, expected);
  });
}

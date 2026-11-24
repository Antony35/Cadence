import 'dart:async';

import 'package:cadence/models/combo.dart';
import 'package:cadence/models/drill.dart';
import 'package:cadence/platform/clip_speaker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import '../models/fixtures.dart';

class _FakePlayer implements AudioPlayer {
  Completer<void>? pendingSpeed;
  int playCount = 0;

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async => null;

  @override
  Future<void> setSpeed(double speed) =>
      (pendingSpeed = Completer<void>()).future;

  @override
  Future<void> play() async => playCount++;

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final ComboStep jab = step('jab');

  test('stopped between loading and playing: the clip is not played', () async {
    final player = _FakePlayer();
    final speaker = ClipSpeaker(player: player);

    final speech = speaker.speak(jab, Pace.slow);
    await pumpEventQueue();
    await speaker.stop();
    player.pendingSpeed!.complete();
    await speech;

    expect(player.playCount, 0);
  });

  test('not stopped: the clip is played', () async {
    final player = _FakePlayer();
    final speaker = ClipSpeaker(player: player);

    final speech = speaker.speak(jab, Pace.slow);
    await pumpEventQueue();
    player.pendingSpeed!.complete();
    await speech;

    expect(player.playCount, 1);
  });
}

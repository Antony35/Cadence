import 'package:cadence/state/screen_awake.dart';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WakelockScreenAwake implements ScreenAwake {
  const WakelockScreenAwake();

  // A failure only lets the screen go off: not worth stopping the session.
  @override
  Future<void> keepOn() async {
    try {
      await WakelockPlus.enable();
    } catch (error) {
      debugPrint('WakelockScreenAwake.keepOn: $error');
    }
  }

  @override
  Future<void> release() async {
    try {
      await WakelockPlus.disable();
    } catch (error) {
      debugPrint('WakelockScreenAwake.release: $error');
    }
  }
}

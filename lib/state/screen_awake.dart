/// Keeps the screen on during a session (F21).
///
/// A contract for the same reason as `Speaker`: the real one calls Android
/// (`lib/platform/wakelock_screen_awake.dart`), which does not exist in the
/// tests.
abstract interface class ScreenAwake {
  Future<void> keepOn();

  /// Lets the screen go off again, as the phone's settings say.
  Future<void> release();
}

abstract interface class ScreenAwake {
  Future<void> keepOn();

  Future<void> release();
}

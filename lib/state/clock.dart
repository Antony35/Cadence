/// Gives the current time to the controllers.
///
/// A service rather than `DateTime.now()` in the code, so that a test can
/// set the date: the main screen of 23 November is the same every time the
/// test runs. Symfony has the same idea with its `ClockInterface`.
class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}

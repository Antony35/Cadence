/// The four states of a screen fed by the database (§ 5 of the spec).
///
/// A `sealed` class: its subclasses are all in this file, so a `switch` on a
/// [LoadState] must handle the four cases, or the code does not compile. And
/// a screen is in exactly one state: never « loading » and « error » at once.
///
/// [T] is the type of the data once read (`List<Combo>`, `List<Technique>`).
sealed class LoadState<T> {
  const LoadState();
}

/// Reading has not finished yet.
final class Loading<T> extends LoadState<T> {
  const Loading();
}

/// The data is there and not empty.
final class Ready<T> extends LoadState<T> {
  const Ready(this.data);

  final T data;
}

/// Reading succeeded and found nothing: not an error (S1).
final class Empty<T> extends LoadState<T> {
  const Empty();
}

/// Reading failed. [message] is French, written by the controller and shown
/// as is by the screen (S3).
final class Failed<T> extends LoadState<T> {
  const Failed(this.message);

  final String message;
}

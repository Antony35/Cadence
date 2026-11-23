sealed class LoadState<T> {
  const LoadState();
}

final class Loading<T> extends LoadState<T> {
  const Loading();
}

final class Ready<T> extends LoadState<T> {
  const Ready(this.data);

  final T data;
}

final class Empty<T> extends LoadState<T> {
  const Empty();
}

final class Failed<T> extends LoadState<T> {
  const Failed(this.message);

  final String message;
}

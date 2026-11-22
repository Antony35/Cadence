/// Errors of the data layer, in the words of the app: the screens never read
/// a SQLite message.
library;

/// The same sequence is already saved (D8, F12).
class DuplicateComboException implements Exception {
  const DuplicateComboException(this.existingId);

  /// The combo that has this sequence, for « Ouvrir l'existant ».
  final int existingId;

  @override
  String toString() => 'DuplicateComboException: same steps as #$existingId';
}

/// An update or a delete touched no row (R5): the record no longer exists.
class NotFoundException implements Exception {
  const NotFoundException(this.what, this.id);

  final String what;
  final int id;

  @override
  String toString() => 'NotFoundException: no $what #$id';
}

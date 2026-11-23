library;

class DuplicateComboException implements Exception {
  const DuplicateComboException(this.existingId);

  final int existingId;

  @override
  String toString() => 'DuplicateComboException: same steps as #$existingId';
}

class NotFoundException implements Exception {
  const NotFoundException(this.entity, this.id);

  final String entity;
  final int id;

  @override
  String toString() => 'NotFoundException: no $entity #$id';
}

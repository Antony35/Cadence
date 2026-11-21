import 'package:freezed_annotation/freezed_annotation.dart';

part 'review.freezed.dart';

/// The grade given after a combo in a session (F22).
enum Grade {
  hard('Difficile'),
  good('Correct'),
  easy('Facile');

  const Grade(this.label);

  final String label;
}

/// One review of a combo. Deleted with its combo.
@freezed
class Review with _$Review {
  const Review({
    required this.id,
    required this.comboId,
    required this.reviewedAt,
    required this.grade,
  });

  final int id;
  final int comboId;
  final DateTime reviewedAt;
  final Grade grade;
}

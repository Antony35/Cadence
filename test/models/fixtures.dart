import 'package:cadence/models/catalog.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';

Technique technique(String slug) => catalog.firstWhere((t) => t.slug == slug);

ComboStep step(String slug, {Side? side, Target? target}) {
  final t = technique(slug);
  return ComboStep(
    technique: t,
    side: side ?? t.defaultSide,
    target: target ?? t.defaultTarget,
  );
}

Combo combo({
  int id = 1,
  String? name,
  List<ComboStep>? steps,
  int box = 1,
  required DateTime dueOn,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime(2026, 11, 1, 18);
  return Combo(
    id: id,
    name: name,
    steps: steps ?? [step('jab'), step('cross')],
    box: box,
    dueOn: dueOn,
    createdAt: created,
    updatedAt: created,
  );
}

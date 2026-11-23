// A CHECK refers to its own column: drift's generator reads the getter, it
// is never called.
// ignore_for_file: recursive_getters

import 'package:cadence/data/drift/converters.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/models/technique.dart';
import 'package:drift/drift.dart';

// Public: drift copies the CHECK expressions into `database.g.dart`.
Expression<bool> isOneOf(Column<String> column, List<Enum> values) =>
    column.isIn(values.map((value) => value.name));

@DataClassName('TechniqueRow')
class Techniques extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get slug => text().unique()();

  TextColumn get name => text()();

  TextColumn get family =>
      textEnum<Family>().check(isOneOf(family, Family.values))();

  TextColumn get defaultSide =>
      textEnum<Side>().nullable().check(isOneOf(defaultSide, Side.values))();

  TextColumn get defaultTarget => textEnum<Target>().nullable().check(
    isOneOf(defaultTarget, Target.values),
  )();

  IntColumn get position => integer().unique()();
}

@DataClassName('TechniqueSideRow')
class TechniqueSides extends Table {
  IntColumn get techniqueId => integer().references(Techniques, #id)();

  TextColumn get side => textEnum<Side>().check(isOneOf(side, Side.values))();

  @override
  Set<Column> get primaryKey => {techniqueId, side};
}

@DataClassName('TechniqueTargetRow')
class TechniqueTargets extends Table {
  IntColumn get techniqueId => integer().references(Techniques, #id)();

  TextColumn get target =>
      textEnum<Target>().check(isOneOf(target, Target.values))();

  @override
  Set<Column> get primaryKey => {techniqueId, target};
}

@DataClassName('ComboRow')
@TableIndex(name: 'combos_due_on', columns: {#dueOn})
class Combos extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().nullable()();

  TextColumn get signature => text().unique()();

  IntColumn get box => integer().check(box.isBetweenValues(1, 6))();

  TextColumn get dueOn => text().map(const DayConverter())();

  TextColumn get createdAt => text().map(const InstantConverter())();

  TextColumn get updatedAt => text().map(const InstantConverter())();
}

@DataClassName('ComboStepRow')
@TableIndex(name: 'combo_steps_technique_id', columns: {#techniqueId})
class ComboSteps extends Table {
  IntColumn get comboId =>
      integer().references(Combos, #id, onDelete: KeyAction.cascade)();

  IntColumn get position => integer().check(position.isBetweenValues(0, 11))();

  IntColumn get techniqueId =>
      integer().references(Techniques, #id, onDelete: KeyAction.restrict)();

  TextColumn get side =>
      textEnum<Side>().nullable().check(isOneOf(side, Side.values))();

  TextColumn get target =>
      textEnum<Target>().nullable().check(isOneOf(target, Target.values))();

  @override
  Set<Column> get primaryKey => {comboId, position};
}

@DataClassName('ReviewRow')
@TableIndex(name: 'reviews_combo_id', columns: {#comboId})
class Reviews extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get comboId =>
      integer().references(Combos, #id, onDelete: KeyAction.cascade)();

  TextColumn get reviewedAt => text().map(const InstantConverter())();

  TextColumn get grade =>
      textEnum<Grade>().check(isOneOf(grade, Grade.values))();
}

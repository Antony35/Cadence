import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/drill.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/screen_awake.dart';
import 'package:cadence/state/session_controller.dart';
import 'package:cadence/state/speaker.dart';
import 'package:cadence/ui/format.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/state_views.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// E4: the review session (F19 to F23). [ahead] for « Réviser en avance ».
class SessionPage extends StatefulWidget {
  const SessionPage({super.key, this.ahead = false});

  final bool ahead;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late final SessionController _session;
  late final ScreenAwake _awake;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _session = SessionController(
      combos: context.read<ComboRepository>(),
      reviews: context.read<ReviewRepository>(),
      clock: context.read<Clock>(),
      speaker: context.read<Speaker>(),
      ahead: widget.ahead,
    )..start();
    // Kept here: `context` can no longer be read in dispose.
    _awake = context.read<ScreenAwake>()..keepOn();
    // F21: hidden (another app, the screen locked), the session pauses. It
    // does not resume by itself: the voice would start in a pocket.
    _lifecycle = AppLifecycleListener(onHide: _session.pause);
  }

  /// The back button and « Arrêter » both close the screen: the voice stops
  /// here. The grades already given are saved (F22).
  @override
  void dispose() {
    _lifecycle.dispose();
    _session.dispose();
    _awake.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SÉANCE'),
        leading: IconButton(
          tooltip: 'Arrêter',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: _session,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_session.voiceAvailable) const _NoVoiceBanner(),
            Expanded(
              child: switch (_session.phase) {
                Preparing() => const LoadingView(),
                SessionFailed(:final message) => ErrorView(
                  message: message,
                  onRetry: _session.start,
                ),
                Ready() => _ReadyView(_session),
                Drilling(:final cue, :final paused) => _DrillView(
                  session: _session,
                  cue: cue,
                  paused: paused,
                ),
                Grading(:final saving, :final failed) => _GradeView(
                  session: _session,
                  saving: saving,
                  failed: failed,
                ),
                Finished(:final reviewed, :final canContinue) => _FinishedView(
                  reviewed: reviewed,
                  onContinue: canContinue ? _session.continueSession : null,
                  onEnd: () => Navigator.pop(context),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// S4: said once, at the top; the session goes on without sound.
class _NoVoiceBanner extends StatelessWidget {
  const _NoVoiceBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_off_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Voix indisponible : les répétitions défilent sans le son.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// « ENCHAÎNEMENT 2 / 5 » and the name of the combo, above each phase.
class _ComboHeader extends StatelessWidget {
  const _ComboHeader(this.session);

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        16,
        AppTheme.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENCHAÎNEMENT ${session.index + 1} / ${session.seriesLength}',
            style: text.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(session.current.displayName, style: text.titleLarge),
        ],
      ),
    );
  }
}

/// F20, F21: the round board, the sequence with the strike being said, and
/// the buttons.
class _DrillView extends StatelessWidget {
  const _DrillView({
    required this.session,
    required this.cue,
    required this.paused,
  });

  final SessionController session;
  final Cue cue;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final steps = session.current.steps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComboHeader(session),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            16,
            AppTheme.gutter,
            8,
          ),
          child: _RoundBoard(cue: cue, paused: paused),
        ),
        Expanded(
          child: _StepList(steps: steps, current: cue.step),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            8,
            AppTheme.gutter,
            16,
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: paused ? session.resume : session.pause,
                  icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  ),
                  label: Text(paused ? 'Reprendre' : 'Pause'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: session.skipToGrade,
                  child: const Text('Passer à la note'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// F20: the combo before the voice, and « Commencer »: the first strike
/// is said only when you are ready.
class _ReadyView extends StatelessWidget {
  const _ReadyView(this.session);

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComboHeader(session),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            8,
            AppTheme.gutter,
            8,
          ),
          child: Text(
            '${Drill.repetitions} répétitions : ${Drill.perPace} lentes, '
            '${Drill.perPace} moyennes, ${Drill.perPace} rapides.',
            style: text.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: _StepList(steps: session.current.steps)),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            8,
            AppTheme.gutter,
            16,
          ),
          child: FilledButton.icon(
            onPressed: session.startCombo,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Commencer'),
          ),
        ),
      ],
    );
  }
}

/// The sequence of the combo; a gold bar marks the [current] strike, the
/// one the voice says.
class _StepList extends StatelessWidget {
  const _StepList({required this.steps, this.current});

  final List<ComboStep> steps;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: steps.length,
      separatorBuilder: (_, _) =>
          const Divider(indent: AppTheme.gutter, endIndent: AppTheme.gutter),
      itemBuilder: (context, index) {
        final now = index == current;
        return Container(
          // A gold bar at the left of the strike being said.
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: now ? scheme.primaryContainer : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter - 4,
            6,
            AppTheme.gutter,
            6,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  stepNumber(index),
                  style: text.labelLarge?.copyWith(color: scheme.primary),
                ),
              ),
              TechniqueImage(steps[index].technique, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  steps[index].label,
                  style: now
                      ? text.titleMedium
                      : text.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// « RÉPÉTITION 05 / 12 · MOYEN », with 12 marks like the rounds of a
/// fight.
class _RoundBoard extends StatelessWidget {
  const _RoundBoard({required this.cue, required this.paused});

  final Cue cue;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final board = CadenceColors.of(context).scoreboard;
    final text = Theme.of(context).textTheme;
    final repetition = cue.repetition;
    return Semantics(
      label:
          'Répétition $repetition sur ${Drill.repetitions}, '
          '${paused ? 'en pause' : cue.pace.label}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: board.fill,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'RÉPÉTITION ',
                            style: text.titleMedium?.copyWith(color: board.ink),
                          ),
                          TextSpan(
                            text: repetition.toString().padLeft(2, '0'),
                            style: text.displaySmall?.copyWith(
                              color: board.accent,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${Drill.repetitions}',
                            style: text.titleMedium?.copyWith(
                              color: board.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    (paused ? 'En pause' : cue.pace.label).toUpperCase(),
                    style: text.titleMedium?.copyWith(color: board.accent),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var mark = 1; mark <= Drill.repetitions; mark++) ...[
                    if (mark > 1)
                      SizedBox(
                        // A wider gap between the paces: 4 · 4 · 4.
                        width: (mark - 1) % Drill.perPace == 0 ? 8 : 3,
                      ),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: mark <= repetition
                              ? board.accent
                              : board.ink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// F22: three buttons of the same weight, each with the next due day it
/// gives: the choice is not pushed toward one of them.
class _GradeView extends StatelessWidget {
  const _GradeView({
    required this.session,
    required this.saving,
    required this.failed,
  });

  final SessionController session;
  final bool saving;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        _ComboHeader(session),
        if (saving) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(minHeight: 2),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            32,
            AppTheme.gutter,
            16,
          ),
          child: Text("COMMENT C'ÉTAIT ?", style: text.headlineSmall),
        ),
        if (failed)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              0,
              AppTheme.gutter,
              16,
            ),
            child: Text(
              "La note n'a pas été enregistrée : réessayez.",
              style: text.bodyMedium?.copyWith(color: scheme.error),
            ),
          ),
        for (final grade in Grade.values)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              0,
              AppTheme.gutter,
              12,
            ),
            child: OutlinedButton(
              onPressed: saving ? null : () => session.grade(grade),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(grade.label, style: text.titleMedium)),
                  Text(
                    dueLabel(session.dueOnAfter(grade), session.today),
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// F23: « Séance terminée », then « Continuer » if combos are waiting.
class _FinishedView extends StatelessWidget {
  const _FinishedView({
    required this.reviewed,
    required this.onContinue,
    required this.onEnd,
  });

  final int reviewed;
  final VoidCallback? onContinue;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: Icons.flag_rounded,
      title: 'Séance terminée',
      text: reviewed == 0
          ? "Rien à réviser pour l'instant."
          : plural(reviewed, 'enchaînement révisé', 'enchaînements révisés'),
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onContinue != null) ...[
            FilledButton(onPressed: onContinue, child: const Text('Continuer')),
            const SizedBox(height: 12),
          ],
          OutlinedButton(onPressed: onEnd, child: const Text('Terminer')),
        ],
      ),
    );
  }
}

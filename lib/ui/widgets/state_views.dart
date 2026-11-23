import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.action,
    this.visual,
  });

  final IconData icon;

  final Widget? visual;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual ?? Icon(icon, size: 32, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title.toUpperCase(),
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action case final action?) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MessageView(
    icon: Icons.error_outline_rounded,
    title: 'Une erreur est survenue',
    text: message,
    action: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Réessayer'),
    ),
  );
}

class NoResultView extends StatelessWidget {
  const NoResultView({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => MessageView(
    icon: Icons.search_off_rounded,
    title: 'Aucun résultat',
    text: 'Essayez un autre mot ou une autre famille.',
    action: OutlinedButton(
      onPressed: onClear,
      child: const Text('Tout effacer'),
    ),
  );
}

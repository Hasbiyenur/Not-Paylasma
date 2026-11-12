import 'package:flutter/material.dart';

enum AppStatus { empty, loading, error }

/// Yeniden deneme yalnızca gerçek bir işlem bağlandığında gösterilir.
class AppStatusView extends StatelessWidget {
  const AppStatusView({
    required this.title,
    required this.message,
    this.status = AppStatus.empty,
    this.icon = Icons.auto_stories_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert((actionLabel == null) == (onAction == null));

  final String title;
  final String message;
  final AppStatus status;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            if (status == AppStatus.loading)
              const CircularProgressIndicator()
            else
              Icon(
                status == AppStatus.error ? Icons.error_outline : icon,
                size: 42,
                color: status == AppStatus.error
                    ? theme.colorScheme.error
                    : theme.colorScheme.secondary,
              ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: status != AppStatus.empty,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PageLayout extends StatelessWidget {
  const PageLayout({
    required this.title,
    required this.subtitle,
    required this.children,
    this.headerTextAlign = TextAlign.start,
    super.key,
  });

  final TextAlign headerTextAlign;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: headerTextAlign,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: headerTextAlign,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ...children,
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

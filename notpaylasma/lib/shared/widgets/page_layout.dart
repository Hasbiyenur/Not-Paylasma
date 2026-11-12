import 'package:flutter/material.dart';

class PageLayout extends StatelessWidget {
  const PageLayout({
    required this.title,
    required this.subtitle,
    required this.children,
    this.headerTextAlign = TextAlign.start,
    this.centerContent = false,
    this.maxWidth = 960,
    super.key,
  });

  final TextAlign headerTextAlign;
  final bool centerContent;
  final double maxWidth;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, viewport) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: centerContent ? viewport.maxHeight : 0,
          ),
          child: Align(
            alignment: centerContent ? Alignment.center : Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
        ),
      ),
    );
  }
}

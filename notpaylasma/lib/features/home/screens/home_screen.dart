import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/app_dependencies.dart';
import '../../../models/note_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/note_feed.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.onExplore, required this.onShare, super.key});
  final VoidCallback onExplore, onShare;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = '';
  String? _category;
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return PageLayout(
      title: 'Merhaba, ${user.firstName} 👋',
      subtitle: 'Bilgini paylaş, birlikte öğrenelim.',
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bir not, birçok kişiye ilham.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  context.read<AppDependencies>().isLocalJson
                      ? 'Notların ve favorilerin JSON kaydında korunur. Giriş çıkış yapsan da kaldığın yerden devam edebilirsin.'
                      : context.read<AppDependencies>().isPersistent
                      ? 'Demo modu: notların ve favorilerin bu cihazda korunur. Bilgini paylaşmaya kaldığın yerden devam et.'
                      : 'Bellek test modu: değişiklikler bu çalıştırma boyunca saklanır.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: widget.onExplore,
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Keşfetmeye başla'),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.onShare,
                      icon: const Icon(Icons.add),
                      label: const Text('Not paylaş'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Not veya ders ara',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Tümü'),
              selected: _category == null,
              onSelected: (_) => setState(() => _category = null),
            ),
            for (final category in context.watch<CategoryProvider>().items)
              ChoiceChip(
                label: Text(category.name),
                selected: _category == category.id,
                onSelected: (_) => setState(() => _category = category.id),
              ),
          ],
        ),
        for (final section in [
          ('Son eklenenler', NoteSort.newest),
          ('Popüler notlar', NoteSort.popular),
          ('En çok indirilenler', NoteSort.downloads),
        ]) ...[
          const SizedBox(height: 24),
          Text(section.$1, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          NoteFeed(
            search: _search,
            categoryId: _category,
            sort: section.$2,
            limit: 3,
            paginate: false,
          ),
        ],
      ],
    );
  }
}

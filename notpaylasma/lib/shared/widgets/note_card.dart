import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/note_model.dart';
import '../../providers/favorite_provider.dart';
import '../../features/notes/screens/note_detail_screen.dart';
import 'feedback.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({required this.note, super.key});
  final NoteModel note;
  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>();
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(note.createdAt.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  note.fileType == 'pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.courseName,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: favorites.ids.contains(note.id)
                      ? 'Favoriden çıkar'
                      : 'Favoriye ekle',
                  onPressed: favorites.pending.contains(note.id)
                      ? null
                      : () async {
                          try {
                            await favorites.toggle(note.id);
                          } catch (e) {
                            if (context.mounted) showError(context, e);
                          }
                        },
                  icon: Icon(
                    favorites.ids.contains(note.id)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
                ),
              ],
            ),
            Text(note.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${note.userName} • $date'),
            const SizedBox(height: 8),
            Text(
              '${note.fileType.toUpperCase()} • ${note.downloadCount} indirme • ${note.favoriteCount} favori',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => NoteDetailScreen(noteId: note.id),
                ),
              ),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Notu incele'),
            ),
          ],
        ),
      ),
    );
  }
}

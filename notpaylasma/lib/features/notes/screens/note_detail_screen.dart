import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../core/services/app_dependencies.dart';
import '../../../core/services/device_file_service.dart';
import '../../../core/utils/app_exception.dart';
import '../../../models/note_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/favorite_provider.dart';
import '../../../providers/note_provider.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/app_status_view.dart';
import '../../../shared/widgets/feedback.dart';
import 'image_preview_screen.dart';
import 'pdf_preview_screen.dart';
import 'share_note_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({required this.noteId, super.key});
  final String noteId;
  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Future<NoteModel?>? _future;
  int? _revision;
  bool _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = context.watch<NoteProvider>().revision;
    if (_revision != revision) {
      _revision = revision;
      _future = context.read<AppDependencies>().notes.getById(widget.noteId);
    }
  }

  Future<void> _fileAction(NoteModel note, bool download) async {
    setState(() => _busy = true);
    final deps = context.read<AppDependencies>();
    final uid = deps.auth.currentUser?.uid;
    try {
      final file = await deps.files.read(note.storagePath);
      if (!mounted || deps.auth.currentUser?.uid != uid) return;
      if (download) {
        final result = await deps.device.export(file);
        if (!mounted || deps.auth.currentUser?.uid != uid) return;
        if (result != ExportResult.cancelled) {
          await deps.notes.recordDownload(note.id);
          if (mounted) {
            showMessage(
              context,
              result == ExportResult.saved ? 'Dosya kaydedildi.' : 'İndirme tarayıcıya iletildi; tamamlanmasını tarayıcıdan kontrol edin.',
            );
          }
        }
      } else if (kIsWeb && file.extension == 'pdf') {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => PdfPreviewScreen(file: file)),
        );
      } else if (['jpg', 'jpeg', 'png'].contains(file.extension)) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ImagePreviewScreen(file: file),
          ),
        );
      } else {
        await deps.device.open(file);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not silinsin mi?'),
        content: const Text('Not ve ilişkili yerel dosyası silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<AppDependencies>().notes.delete(widget.noteId);
      if (mounted) {
        showMessage(context, 'Not ve dosyası silindi.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Not detayı')),
    body: SafeArea(
      child: FutureBuilder<NoteModel?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStatusView(
              status: AppStatus.error,
              title: 'Not yüklenemedi',
              message: errorMessage(snapshot.error!),
              actionLabel: 'Tekrar dene',
              onAction: () => setState(
                () => _future = context.read<AppDependencies>().notes.getById(
                  widget.noteId,
                ),
              ),
            );
          }
          final note = snapshot.data;
          if (note == null) {
            return const AppStatusView(
              title: 'Not bulunamadı',
              message: 'Bu not silinmiş olabilir.',
            );
          }
          final favorites = context.watch<FavoriteProvider>();
          final own = context.watch<AuthProvider>().user?.uid == note.userId;
          return PageLayout(
            title: note.title,
            subtitle:
                '${note.courseName} • ${context.watch<CategoryProvider>().name(note.categoryId)}',
            children: [
              Text('Paylaşan: ${note.userName}'),
              const SizedBox(height: 8),
              Text(
                MaterialLocalizations.of(context)
                    .formatFullDate(note.createdAt.toLocal()),
              ),
              if (note.university.isNotEmpty) Text(note.university),
              const SizedBox(height: 20),
              Text(note.description),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: note.tags
                    .map((t) => Chip(label: Text('#$t')))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(
                '${note.fileName}\n${note.fileType.toUpperCase()} • ${(note.fileSize / 1024).toStringAsFixed(1)} KB\n${note.downloadCount} indirme • ${note.favoriteCount} favori',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _fileAction(note, false),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(
                      note.fileType == 'docx'
                          ? (kIsWeb
                                ? 'İndir ve uygulamayla aç'
                                : 'Uygulamayla aç')
                          : 'Dosyayı görüntüle',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _fileAction(note, true),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('İndir'),
                  ),
                  OutlinedButton.icon(
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
                    label: Text(
                      favorites.ids.contains(note.id)
                          ? 'Favoriden çıkar'
                          : 'Favoriye ekle',
                    ),
                  ),
                  if (own) ...[
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ShareNoteScreen(note: note),
                              ),
                            ),
                      child: const Text('Düzenle'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _delete,
                      child: const Text('Notu sil'),
                    ),
                  ],
                ],
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        },
      ),
    ),
  );
}

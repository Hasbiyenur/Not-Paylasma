import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/app_dependencies.dart';
import '../../../core/utils/validators.dart';
import '../../../models/note_model.dart';
import '../../../models/selected_file.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/note_provider.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/app_status_view.dart';
import '../../../shared/widgets/feedback.dart';

class ShareNoteScreen extends StatefulWidget {
  const ShareNoteScreen({this.note, super.key});
  final NoteModel? note;
  @override
  State<ShareNoteScreen> createState() => _ShareNoteScreenState();
}

class _ShareNoteScreenState extends State<ShareNoteScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController(),
      _course = TextEditingController();
  final _university = TextEditingController(), _tags = TextEditingController();
  String? _category;
  SelectedFile? _file;
  bool _picking = false;
  @override
  void initState() {
    super.initState();
    final note = widget.note;
    if (note != null) {
      _title.text = note.title;
      _description.text = note.description;
      _course.text = note.courseName;
      _university.text = note.university;
      _tags.text = note.tags.join(', ');
      _category = note.categoryId;
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _course, _university, _tags]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final result = await context.read<AppDependencies>().device.pick();
      if (mounted && result != null) setState(() => _file = result);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_file == null && widget.note == null) {
      showMessage(context, 'Bir dosya seçin.');
      return;
    }
    try {
      final draft = NoteDraft(
        title: _title.text,
        description: _description.text,
        courseName: _course.text,
        categoryId: _category!,
        university: _university.text,
        tags: Validators.tags(_tags.text),
      );
      await context.read<NoteProvider>().save(
        draft,
        id: widget.note?.id,
        file: _file,
      );
      if (!mounted) return;
      showMessage(
        context,
        widget.note == null
            ? (context.read<AppDependencies>().isLocalJson
                  ? 'Not JSON kaydına eklendi.'
                  : 'Not bu demo oturumuna eklendi.')
            : 'Not güncellendi.',
      );
      if (widget.note != null) {
        Navigator.of(context).pop();
      } else {
        for (final c in [_title, _description, _course, _university, _tags]) {
          c.clear();
        }
        setState(() {
          _category = null;
          _file = null;
        });
        _form.currentState!.reset();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteProvider>();
    final categories = context.watch<CategoryProvider>();
    final busy = notes.saving || _picking;
    final content = PageLayout(
      title: widget.note == null
          ? 'Bilgi paylaştıkça çoğalır.'
          : 'Notunu güncelle.',
      subtitle: 'PDF, DOCX, JPG, JPEG veya PNG • En fazla 20 MiB',
      children: [
        if (categories.error != null)
          AppStatusView(
            status: AppStatus.error,
            title: 'Kategoriler yüklenemedi',
            message: categories.error!,
            actionLabel: 'Tekrar dene',
            onAction: categories.load,
          ),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in [
                (_title, 'Not başlığı', 3, 120),
                (_description, 'Açıklama', 10, 3000),
                (_course, 'Ders adı', 2, 100),
              ]) ...[
                TextFormField(
                  controller: f.$1,
                  enabled: !busy,
                  maxLines: f.$1 == _description ? 4 : 1,
                  decoration: InputDecoration(labelText: f.$2),
                  validator: (v) => Validators.text(v, f.$2, f.$3, f.$4),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                key: ValueKey(_category),
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: categories.items
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: busy ? null : (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Kategori seçin.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _university,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Kurum (isteğe bağlı)',
                ),
                validator: (v) => Validators.text(v, 'Kurum', 0, 160),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tags,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Etiketler (virgülle ayırın)',
                ),
                validator: (v) {
                  try {
                    Validators.tags(v ?? '');
                    return null;
                  } catch (e) {
                    return e.toString();
                  }
                },
              ),
              const SizedBox(height: 20),
              Text(
                _file == null
                    ? widget.note?.fileName ?? 'Henüz dosya seçilmedi'
                    : '${_file!.name} • ${(_file!.size / 1024).toStringAsFixed(1)} KB',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : _pick,
                icon: const Icon(Icons.attach_file),
                label: Text(_picking ? 'Seçici açılıyor…' : 'Dosya seç'),
              ),
              if (notes.saving) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: notes.progress),
                Text('Yerel kopyalama: %${(notes.progress * 100).round()}'),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed:
                    busy || categories.loading || categories.error != null
                    ? null
                    : _save,
                child: Text(
                  notes.saving
                      ? 'Kaydediliyor…'
                      : widget.note == null
                      ? 'Notu paylaş'
                      : 'Değişiklikleri kaydet',
                ),
              ),
            ],
          ),
        ),
      ],
    );
    return PopScope(
      canPop: !busy,
      child: widget.note == null
          ? content
          : Scaffold(
              appBar: AppBar(title: const Text('Notu düzenle')),
              body: SafeArea(child: content),
            ),
    );
  }
}

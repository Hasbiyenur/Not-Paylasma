import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/note_model.dart';
import '../../../providers/category_provider.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/note_feed.dart';
import '../../../shared/widgets/app_status_view.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController(), _tag = TextEditingController();
  String _query = '', _tagQuery = '';
  String? _category;
  NoteSort _sort = NoteSort.newest;
  Timer? _debounce;
  void _changed(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _query = _search.text;
          _tagQuery = _tag.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _tag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    return PageLayout(
      title: 'Merak ettiğin her şey.',
      subtitle: 'Başlık veya ders kelimesiyle ara.',
      children: [
        TextField(
          key: const ValueKey('search-notes'),
          controller: _search,
          onChanged: _changed,
          decoration: const InputDecoration(
            labelText: 'Not veya ders ara',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        if (categories.error != null)
          AppStatusView(
            status: AppStatus.error,
            title: 'Kategoriler yüklenemedi',
            message: categories.error!,
            actionLabel: 'Tekrar dene',
            onAction: categories.load,
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _category ?? '',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Tüm kategoriler')),
              ...categories.items.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (v) => setState(() => _category = v == '' ? null : v),
          ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('filter-tag'),
          controller: _tag,
          onChanged: _changed,
          decoration: const InputDecoration(
            labelText: 'Etiket (ör. dart)',
            prefixIcon: Icon(Icons.tag),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<NoteSort>(
          initialValue: _sort,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Sırala'),
          items: const [
            DropdownMenuItem(value: NoteSort.newest, child: Text('En yeni')),
            DropdownMenuItem(
              value: NoteSort.downloads,
              child: Text('En çok indirilen'),
            ),
            DropdownMenuItem(
              value: NoteSort.popular,
              child: Text('En çok favorilenen'),
            ),
          ],
          onChanged: (v) => setState(() => _sort = v!),
        ),
        const SizedBox(height: 20),
        NoteFeed(
          search: _query,
          categoryId: _category,
          tag: _tagQuery,
          sort: _sort,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_dependencies.dart';
import '../../core/utils/app_exception.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../providers/favorite_provider.dart';
import 'app_status_view.dart';
import 'note_card.dart';

class NoteFeed extends StatefulWidget {
  const NoteFeed({
    this.search = '',
    this.categoryId,
    this.tag = '',
    this.userId,
    this.sort = NoteSort.newest,
    this.favoritesOnly = false,
    this.limit = 10,
    this.paginate = true,
    super.key,
  });
  final String search, tag;
  final String? categoryId, userId;
  final NoteSort sort;
  final bool favoritesOnly, paginate;
  final int limit;
  @override
  State<NoteFeed> createState() => _NoteFeedState();
}

class _NoteFeedState extends State<NoteFeed> {
  List<NoteModel> _items = [];
  String? _cursor, _error;
  bool _loading = true;
  int _generation = 0;
  Object? _signature;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = context.watch<NoteProvider>().revision;
    final favorites = context.watch<FavoriteProvider>().ids.toList()..sort();
    final signature = '$revision:${favorites.join(",")}';
    if (_signature != signature) {
      _signature = signature;
      _queueLoad();
    }
  }

  @override
  void didUpdateWidget(NoteFeed old) {
    super.didUpdateWidget(old);
    if (old.search != widget.search ||
        old.categoryId != widget.categoryId ||
        old.tag != widget.tag ||
        old.userId != widget.userId ||
        old.sort != widget.sort ||
        old.favoritesOnly != widget.favoritesOnly) {
      _queueLoad();
    }
  }

  void _queueLoad() {
    _generation++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    final deps = context.read<AppDependencies>();
    final favoriteIds = Set<String>.of(context.read<FavoriteProvider>().ids);
    final query = NoteQuery(
      search: widget.search,
      categoryId: widget.categoryId,
      tag: widget.tag,
      userId: widget.userId,
      sort: widget.sort,
      limit: widget.limit,
      cursor: more ? _cursor : null,
    );
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _items = [];
        _cursor = null;
      }
    });
    try {
      NotePage page;
      if (widget.favoritesOnly) {
        final notes = await Future.wait(favoriteIds.map(deps.notes.getById));
        final items = notes.whereType<NoteModel>().toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        page = NotePage(items, null);
      } else {
        page = await deps.notes.query(query);
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = more
            ? [
                ..._items,
                ...page.items.where(
                  (n) => !_items.any((old) => old.id == n.id),
                ),
              ]
            : page.items;
        _cursor = page.nextCursor;
        _loading = false;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AppStatusView(
        status: AppStatus.error,
        title: 'Notlar yüklenemedi',
        message: _error!,
        actionLabel: 'Tekrar dene',
        onAction: () => _load(),
      );
    }
    if (_loading && _items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_items.isEmpty) {
      return const AppStatusView(
        title: 'Henüz not yok',
        message: 'Filtreleri değiştirin veya yeni bir not paylaşın.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final note in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NoteCard(key: ValueKey(note.id), note: note),
          ),
        if (widget.paginate && _cursor != null)
          OutlinedButton(
            onPressed: _loading ? null : () => _load(more: true),
            child: Text(_loading ? 'Yükleniyor…' : 'Daha fazla göster'),
          ),
      ],
    );
  }
}

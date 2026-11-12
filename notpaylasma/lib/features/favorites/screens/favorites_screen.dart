import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/favorite_provider.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/note_feed.dart';
import '../../../shared/widgets/app_status_view.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({required this.onExplore, super.key});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>();
    return PageLayout(
      title: 'Tekrar dönmek istediklerin.',
      subtitle: 'Bu hesaba ait kaydettiğin notlar.',
      children: [
        if (favorites.error != null)
          AppStatusView(
            status: AppStatus.error,
            title: 'Favoriler yüklenemedi',
            message: favorites.error!,
            actionLabel: 'Tekrar dene',
            onAction: favorites.reload,
          )
        else if (favorites.ids.isEmpty)
          AppStatusView(
            title: 'Henüz favorin yok',
            message: 'Notlardaki yer imi simgesine dokunarak buraya ekle.',
            actionLabel: 'Keşif alanına git',
            onAction: onExplore,
          )
        else
          const NoteFeed(favoritesOnly: true),
      ],
    );
  }
}

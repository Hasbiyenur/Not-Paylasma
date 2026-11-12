import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/app_dependencies.dart';
import '../../../shared/widgets/app_brand.dart';

import '../../explore/screens/explore_screen.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../notes/screens/share_note_screen.dart';
import '../../profile/screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) _select(0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const AppBrand(),
          actions: [
            IconButton(
              tooltip: 'Uygulama hakkında',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showAboutDialog(
                context: context,
                applicationName: 'NotPaylaş',
                applicationIcon: const AppLogo(size: 56),
                applicationVersion: context.read<AppDependencies>().isHybrid
                    ? '0.3.0 • Firebase hesap / yerel dosyalar'
                    : context.read<AppDependencies>().isFirebase
                    ? '0.3.0 • Firebase'
                    : context.read<AppDependencies>().isLocalJson
                    ? '0.3.0 • Yerel JSON'
                    : '0.3.0 • Mock demo',
                children: [
                  Text(
                    context.read<AppDependencies>().isHybrid
                        ? 'Kullanıcı hesabı ve profil Firebase Auth/Firestore’da; notlar, favoriler, ek dosyalar ve profil fotoğrafı yerel JSON/dosya alanındadır.'
                        : context.read<AppDependencies>().isFirebase
                        ? 'Hesaplar ve paylaşımlar bağlı Firebase projesinde saklanır.'
                        : context.read<AppDependencies>().isLocalJson
                        ? 'Bilgiler yerel JSON dosyasında, ekler ayrı yerel dosyalarda tutulur. Çıkış yapmak kayıtları silmez. Tarayıcı site verilerini silmek yerel dosyaları kaldırır.'
                        : context.read<AppDependencies>().isPersistent
                        ? 'Hesaplar, notlar, dosyalar, favoriler ve görünüm bu cihazda saklanır. '
                              'Tarayıcı verilerini veya uygulama verilerini silmek kayıtları kaldırır. '
                              'Firebase bağlantısı kullanılmıyor. Demo dosya alanı 64 MiB ile sınırlıdır.'
                        : 'Bellek test modu: yeniden başlatma değişiklikleri sıfırlar. Firebase bağlantısı yoktur.',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              HomeScreen(
                onExplore: () => _select(1),
                onShare: () => _select(2),
              ),
              const ExploreScreen(),
              const ShareNoteScreen(),
              FavoritesScreen(onExplore: () => _select(1)),
              const ProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              key: ValueKey('nav-home'),
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Ana Sayfa',
            ),
            NavigationDestination(
              key: ValueKey('nav-explore'),
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Keşfet',
            ),
            NavigationDestination(
              key: ValueKey('nav-share'),
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Not Paylaş',
            ),
            NavigationDestination(
              key: ValueKey('nav-favorites'),
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Favoriler',
            ),
            NavigationDestination(
              key: ValueKey('nav-profile'),
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

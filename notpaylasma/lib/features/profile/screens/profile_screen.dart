import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/app_dependencies.dart';
import '../../../models/selected_file.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/note_feed.dart';
import '../../../shared/widgets/feedback.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;
    final theme = context.watch<ThemeProvider>();
    return PageLayout(
      title: user.fullName,
      subtitle: user.email,
      children: [
        if (user.photoUrl != null)
          FutureBuilder<SelectedFile>(
            future: context.read<AppDependencies>().files.read(user.photoUrl!),
            builder: (context, snapshot) => Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(
                radius: 44,
                backgroundImage: snapshot.hasData
                    ? MemoryImage(snapshot.data!.copyBytes())
                    : null,
                child: snapshot.hasData ? null : const Icon(Icons.person),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditProfileScreen(),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Profili düzenle'),
            ),
            OutlinedButton.icon(
              onPressed: auth.busy
                  ? null
                  : () async {
                      try {
                        await auth.run(auth.repository.signOut);
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                      }
                    },
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış yap'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (context.read<AppDependencies>().isLocalJson)
          SelectableText(
            'Kayıt yeri: ${context.read<AppDependencies>().dataLocation}',
          ),
        Text('Görünüm', style: Theme.of(context).textTheme.titleLarge),
        Text(
          context.read<AppDependencies>().isPersistent
              ? 'Tercihin bu cihazda korunur.'
              : 'Tercihin bu oturum boyunca korunur.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in [
              (ThemeMode.system, 'Sistem'),
              (ThemeMode.light, 'Açık'),
              (ThemeMode.dark, 'Koyu'),
            ])
              ChoiceChip(
                key: ValueKey('theme-${option.$1.name}'),
                label: Text(option.$2),
                selected: theme.mode == option.$1,
                onSelected: theme.busy
                    ? null
                    : (_) async {
                        try {
                          await theme.setMode(option.$1);
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                        }
                      },
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Paylaştığım notlar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        NoteFeed(userId: user.uid),
      ],
    );
  }
}

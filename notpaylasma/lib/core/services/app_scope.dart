import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/theme_provider.dart';
import 'app_dependencies.dart';

class AppScope extends StatelessWidget {
  const AppScope({required this.dependencies, super.key});
  final AppDependencies dependencies;
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: dependencies),
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(
          initial: dependencies.initialTheme,
          save: dependencies.saveTheme,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => AuthProvider(dependencies.auth, dependencies.files),
      ),
      ChangeNotifierProvider(create: (_) => NoteProvider(dependencies.notes)),
      ChangeNotifierProvider(
        create: (_) =>
            FavoriteProvider(dependencies.favorites, dependencies.auth)
              ..reload(),
      ),
      ChangeNotifierProvider(
        create: (_) => CategoryProvider(dependencies.categories)..load(),
      ),
    ],
    child: const NotPaylasApp(),
  );
}

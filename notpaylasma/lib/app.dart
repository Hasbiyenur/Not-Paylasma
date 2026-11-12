import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/screens/session_gate.dart';
import 'providers/theme_provider.dart';

class NotPaylasApp extends StatelessWidget {
  const NotPaylasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotPaylaş',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: context.watch<ThemeProvider>().mode,
      home: const SessionGate(),
    );
  }
}

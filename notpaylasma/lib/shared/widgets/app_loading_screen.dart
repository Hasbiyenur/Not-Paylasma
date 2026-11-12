import 'package:flutter/material.dart';

import 'app_brand.dart';

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({this.message = 'Uygulama hazırlanıyor…', super.key});

  final String message;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppBrand(large: true),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(message, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

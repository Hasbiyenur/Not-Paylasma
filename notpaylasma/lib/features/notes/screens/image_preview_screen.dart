import 'package:flutter/material.dart';

import '../../../models/selected_file.dart';

class ImagePreviewScreen extends StatelessWidget {
  const ImagePreviewScreen({required this.file, super.key});
  final SelectedFile file;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(file.name)),
    body: SafeArea(
      child: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.memory(
            file.copyBytes(),
            errorBuilder: (_, _, _) => const Text(
              'Görsel görüntülenemedi. Dosyayı indirerek deneyin.',
            ),
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../models/selected_file.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({required this.file, super.key});
  final SelectedFile file;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(file.name)),
    body: const Center(child: Text('PDF dosyasını İndir seçeneğiyle açın.')),
  );
}

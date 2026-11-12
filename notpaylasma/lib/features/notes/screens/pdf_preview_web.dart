import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../models/selected_file.dart';
import '../../../core/services/file_export_web.dart';
import '../../../core/services/web_file_bytes.dart';

class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({required this.file, super.key});
  final SelectedFile file;
  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late final String _url = web.URL.createObjectURL(
    web.Blob(
      [toWebFileBytes(widget.file.bytes)].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    ),
  );
  @override
  void dispose() {
    web.URL.revokeObjectURL(_url);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.file.name),
      actions: [
        IconButton(
          tooltip: 'PDF’yi indir',
          icon: const Icon(Icons.download),
          onPressed: () => downloadToDevice(widget.file),
        ),
      ],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Önizleme desteklenmiyorsa PDF’yi indirip açabilirsiniz.',
          ),
        ),
        Expanded(
          child: HtmlElementView.fromTagName(
            tagName: 'iframe',
            onElementCreated: (element) {
              final frame = element as web.HTMLIFrameElement;
              frame.src = _url;
              frame.title = widget.file.name;
              frame.style.width = '100%';
              frame.style.height = '100%';
              frame.style.border = '0';
            },
          ),
        ),
      ],
    ),
  );
}

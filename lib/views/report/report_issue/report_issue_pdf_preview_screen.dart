import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Экран для просмотра PDF (issues).
class ReportIssuePdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const ReportIssuePdfPreviewScreen({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Предварительный просмотр'),
      ),
      body: PdfPreview(
        build: (format) async => pdfBytes,
      ),
    );
  }
}

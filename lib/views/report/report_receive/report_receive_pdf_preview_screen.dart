import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Экран для просмотра PDF.
/// Принимает байты PDF-файла [pdfBytes].
class ReportReceivePdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const ReportReceivePdfPreviewScreen({super.key, required this.pdfBytes});

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

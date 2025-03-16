import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:wms/models/report.dart';

/// Генерирует PDF-документ на основе списка записей отчёта (issues).
Future<Uint8List> generatePdfIssueReport(
    String title,
    List<ReportEntry> entries, {
      required String responsibleName,
      required String position,
    }) async {
  // Загружаем TTF-шрифты Lato (Regular, Bold, Italic, BoldItalic) из assets
  final regularData = await rootBundle.load('lib/assets/fonts/Lato-Regular.ttf');
  final boldData = await rootBundle.load('lib/assets/fonts/Lato-Bold.ttf');
  final italicData = await rootBundle.load('lib/assets/fonts/Lato-Italic.ttf');
  final boldItalicData = await rootBundle.load('lib/assets/fonts/Lato-BoldItalic.ttf');

  final fontRegular = pw.Font.ttf(regularData);
  final fontBold = pw.Font.ttf(boldData);
  final fontItalic = pw.Font.ttf(italicData);
  final fontBoldItalic = pw.Font.ttf(boldItalicData);

  // Создаём документ PDF и настраиваем тему
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontItalic,
        boldItalic: fontBoldItalic,
      ),
      build: (pw.Context context) {
        return [
          // Заголовок: «Отчет по выдачам»
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Отчет по выдачам',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Должность пользователя
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                position,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),

          // ФИО пользователя
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                responsibleName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),

          // Основной заголовок отчёта (например, "Отчет за день 2025-03-15")
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 30),

          // Таблица с данными
          _buildIssueReportTable(entries),
          pw.SizedBox(height: 50),

          // Внизу — Дата и ФИО/Подпись
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Дата ___________________',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(width: 40),
              pw.Text(
                'ФИО/Подпись _______________________________/__________',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ];
      },
    ),
  );

  // Возвращаем байты готового PDF
  return pdf.save();
}

/// Строит таблицу с нумерацией (№), аналогично приёмкам, но с упором на выдачи.
pw.Widget _buildIssueReportTable(List<ReportEntry> entries) {
  final headers = [
    '№',
    'Продукция',
    'Ячейка',
    'Всего',
    'Дата выдачи',
  ];

  final data = <List<String>>[];
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(entry.recordDate);
    data.add([
      '${i + 1}',
      entry.productName,
      entry.cellName,
      entry.quantity.toString(),
      dateStr,
    ]);
  }

  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    headerAlignments: {
      0: pw.Alignment.center,
      1: pw.Alignment.center,
      2: pw.Alignment.center,
      3: pw.Alignment.center,
      4: pw.Alignment.center,
    },
    cellAlignments: {
      0: pw.Alignment.center,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.center,
      3: pw.Alignment.center,
      4: pw.Alignment.center,
    },
    columnWidths: {
      0: const pw.FlexColumnWidth(0.8),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(2),
    },
    cellHeight: 30,
    border: null,
  );
}

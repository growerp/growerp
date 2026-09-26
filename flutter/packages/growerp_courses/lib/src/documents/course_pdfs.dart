/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Course documents rendered in the app: the slide deck of the modules and
/// the workbook with all lessons. Shown in a print/download preview.

const _accent = PdfColors.blueGrey800;

/// 16:9 presentation page
const slidePageFormat = PdfPageFormat(960, 540);

Future<void> showPdfDialog(
  BuildContext context, {
  required Key key,
  required String title,
  required String fileName,
  required PdfPageFormat pageFormat,
  required Future<Uint8List> Function(PdfPageFormat format) build,
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      key: key,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: dialogContext,
        title: title,
        width: 900,
        height: MediaQuery.of(dialogContext).size.height * 0.9,
        child: PdfPreview(
          pdfFileName: fileName,
          canChangeOrientation: false,
          canChangePageFormat: false,
          initialPageFormat: pageFormat,
          build: build,
        ),
      ),
    ),
  );
}

/// The slides of [modules]: a title slide per module, then its slides.
Future<Uint8List> slidesPdf(
  Course course,
  List<CourseModule> modules,
  PdfPageFormat format,
) async {
  final pdf = pw.Document(title: course.title);
  for (final module in modules) {
    final slides = module.slides ?? [];
    if (slides.isEmpty) continue;
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => pw.Container(
          color: _accent,
          padding: const pw.EdgeInsets.all(60),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                course.title,
                style: const pw.TextStyle(
                  color: PdfColors.grey300,
                  fontSize: 22,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Module ${module.sequenceNum ?? ''}: ${module.title}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 40,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < slides.length; i++) {
      final slide = slides[i];
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(60, 50, 60, 30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  slide.title,
                  style: pw.TextStyle(
                    fontSize: 34,
                    fontWeight: pw.FontWeight.bold,
                    color: _accent,
                  ),
                ),
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 16),
                  height: 3,
                  width: 80,
                  color: _accent,
                ),
                for (final bullet in slide.bullets)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 14),
                    child: pw.Bullet(
                      text: bullet,
                      style: const pw.TextStyle(fontSize: 24),
                      bulletSize: 8,
                      bulletColor: _accent,
                    ),
                  ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${course.title} · ${module.title}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      '${i + 1} / ${slides.length}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
  return pdf.save();
}

/// All lessons of the course as one printable document.
Future<Uint8List> workbookPdf(Course course, PdfPageFormat format) async {
  final pdf = pw.Document(title: course.title);
  pdf.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(48),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${course.title} · ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.Text(
          course.title,
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
          ),
        ),
        pw.SizedBox(height: 12),
        if (course.description?.isNotEmpty ?? false)
          pw.Paragraph(text: course.description!),
        if (course.objectives?.isNotEmpty ?? false) ...[
          pw.Header(level: 2, text: 'What you will learn'),
          ...markdownToPdf(course.objectives!),
        ],
        for (final module in course.modules ?? <CourseModule>[]) ...[
          pw.NewPage(),
          pw.Header(
            level: 0,
            text: 'Module ${module.sequenceNum ?? ''}: ${module.title}',
          ),
          if (module.description?.isNotEmpty ?? false)
            pw.Paragraph(text: module.description!),
          for (final lesson in module.lessons ?? <CourseLesson>[]) ...[
            pw.Header(level: 1, text: lesson.title),
            ...markdownToPdf(lesson.content ?? ''),
            if (lesson.keyPoints?.isNotEmpty ?? false)
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 8, bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  border: pw.Border(
                    left: pw.BorderSide(color: _accent, width: 3),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Key points',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 6),
                    for (final point in lesson.keyPoints!)
                      pw.Bullet(text: point),
                  ],
                ),
              ),
          ],
        ],
      ],
    ),
  );
  return pdf.save();
}

/// A small markdown subset for pdf: headings, bullet and numbered lists,
/// block quotes, code blocks, pipe tables and paragraphs. Inline markup
/// (**bold**, `code`, links) is shown as plain text.
List<pw.Widget> markdownToPdf(String markdown) {
  final widgets = <pw.Widget>[];
  final lines = markdown.replaceAll('\r', '').split('\n');
  final paragraph = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    widgets.add(pw.Paragraph(text: _inline(paragraph.join(' '))));
    paragraph.clear();
  }

  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trim();
    if (trimmed.startsWith('```')) {
      flushParagraph();
      final code = <String>[];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('```')) {
        code.add(lines[i]);
        i++;
      }
      widgets.add(
        pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.grey100,
          child: pw.Text(
            code.join('\n'),
            style: pw.TextStyle(font: pw.Font.courier(), fontSize: 9),
          ),
        ),
      );
    } else if (trimmed.startsWith('|')) {
      flushParagraph();
      final rows = <List<String>>[];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        final cells = lines[i]
            .trim()
            .replaceAll(RegExp(r'^\||\|$'), '')
            .split('|')
            .map((c) => _inline(c.trim()))
            .toList();
        // skip the |---|---| separator row
        if (!cells.every((c) => RegExp(r'^:?-+:?$').hasMatch(c))) {
          rows.add(cells);
        }
        i++;
      }
      if (rows.isNotEmpty) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.TableHelper.fromTextArray(
              headers: rows.first,
              data: rows.skip(1).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ),
        );
      }
      continue;
    } else if (trimmed.isEmpty) {
      flushParagraph();
    } else if (RegExp(r'^#{1,6}\s').hasMatch(trimmed)) {
      flushParagraph();
      final level = trimmed.indexOf(' ');
      widgets.add(
        pw.Header(
          level: level <= 2 ? 2 : 3,
          text: _inline(trimmed.substring(level + 1)),
        ),
      );
    } else if (RegExp(r'^([-*+]|\d+\.)\s').hasMatch(trimmed)) {
      flushParagraph();
      final indent = line.length - line.trimLeft().length;
      widgets.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(left: indent * 4.0),
          child: pw.Bullet(
            text: _inline(trimmed.substring(trimmed.indexOf(' ') + 1)),
          ),
        ),
      );
    } else if (trimmed.startsWith('>')) {
      flushParagraph();
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.only(left: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: PdfColors.grey400, width: 2),
            ),
          ),
          child: pw.Text(
            _inline(trimmed.substring(1).trim()),
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
          ),
        ),
      );
    } else {
      paragraph.add(trimmed);
    }
    i++;
  }
  flushParagraph();
  return widgets;
}

String _inline(String text) => text
    .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1]!)
    .replaceAll(RegExp(r'\*\*|__|`'), '')
    .replaceAllMapped(
      RegExp(r'(^|\s)[*_]([^*_]+)[*_]'),
      (m) => '${m[1]}${m[2]}',
    );

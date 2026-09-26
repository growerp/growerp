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

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../documents/course_pdfs.dart';

/// Asks the backend whether the learner earned the certificate of a course
/// (all lessons done, every quiz passed) and shows it as a printable pdf.
Future<void> showCourseCertificate(
  BuildContext context,
  String courseId,
) async {
  final restClient = context.read<RestClient>();
  CourseCertificate certificate;
  try {
    var result = await restClient.getCourseCertificate(courseId: courseId);
    // a dynamic body can arrive as the raw JSON string
    if (result is String) result = jsonDecode(result);
    certificate = CourseCertificate.fromJson(result['certificate']);
  } catch (e) {
    final message = await getDioError(e);
    if (context.mounted) {
      HelperFunctions.showMessage(context, message, Colors.red);
    }
    return;
  }
  if (!context.mounted) return;
  if (!certificate.eligible) {
    HelperFunctions.showMessage(
      context,
      certificate.reason ?? 'Not completed yet',
      Colors.orange,
    );
    return;
  }
  await showPdfDialog(
    context,
    key: const Key('courseCertificateDialog'),
    title: 'Certificate',
    fileName: 'certificate-${certificate.certificateNo}.pdf',
    pageFormat: PdfPageFormat.a4.landscape,
    build: (format) => certificatePdf(certificate, format),
  );
}

Future<Uint8List> certificatePdf(
  CourseCertificate certificate,
  PdfPageFormat format,
) async {
  final pdf = pw.Document();
  final date = DateFormat.yMMMMd().format(
    (certificate.completedDate ?? DateTime.now()).toLocal(),
  );
  const accent = PdfColors.blueGrey800;
  pdf.addPage(
    pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: accent, width: 4),
        ),
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'CERTIFICATE OF COMPLETION',
              style: pw.TextStyle(
                fontSize: 30,
                fontWeight: pw.FontWeight.bold,
                color: accent,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 32),
            pw.Text(
              'This certifies that',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              certificate.learnerName ?? '',
              style: pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'has successfully completed the course',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              certificate.courseTitle ?? '',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
            if (certificate.estimatedDuration != null) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                '${(certificate.estimatedDuration! / 60).toStringAsFixed(1)} hours of study',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(date, style: const pw.TextStyle(fontSize: 14)),
                    pw.Text(
                      'Date',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      certificate.companyName ?? '',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Certificate ${certificate.certificateNo ?? ''}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return pdf.save();
}

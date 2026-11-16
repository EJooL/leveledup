import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import '../../models/cv_analysis_model.dart';

/// Pure-Dart ATS-Compliant PDF 1.4 Document Compiler & Exporter.
/// Generates a real, single-column, selectable-text PDF resume (using standard
/// Type 1 Helvetica & Helvetica-Bold fonts) and triggers a direct .pdf download/share.
class PdfCvGenerator {
  PdfCvGenerator._();

  /// Generates a binary .pdf file from [ImprovedCV] and triggers download / share
  static Future<void> exportAndDownloadPdf(ImprovedCV cv) async {
    final pdfBytes = buildPdfBytes(cv);
    final sanitizedName = cv.name
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final langSuffix = cv.isIndonesian ? 'ID' : 'EN';
    final fileName =
        '${sanitizedName.isEmpty ? "Candidate" : sanitizedName}_ATS_CV_$langSuffix.pdf';

    final xFile = XFile.fromData(
      pdfBytes,
      name: fileName,
      mimeType: 'application/pdf',
    );

    await Share.shareXFiles(
      [xFile],
      subject: '${cv.name} - ATS Optimized CV ($langSuffix)',
    );
  }

  /// Compiles a standard single-column ATS PDF 1.4 binary document
  static Uint8List buildPdfBytes(ImprovedCV cv) {
    final streamCommands = StringBuffer();
    const double leftMargin = 50.0;
    const double rightMargin = 562.0;
    double cursorY = 735.0;

    void drawRule() {
      cursorY -= 4;
      streamCommands.writeln('0.75 w');
      streamCommands.writeln('0.25 0.25 0.28 RG');
      streamCommands.writeln(
        '${leftMargin.toStringAsFixed(1)} ${cursorY.toStringAsFixed(1)} m ${rightMargin.toStringAsFixed(1)} ${cursorY.toStringAsFixed(1)} l S',
      );
      cursorY -= 14;
    }

    void drawTextLine(
      String text, {
      required bool bold,
      required double fontSize,
      required double lineHeight,
      double indent = 0.0,
    }) {
      if (cursorY < 48) return; // Prevent bottom margin overflow on single page
      final fontKey = bold ? '/F2' : '/F1';
      final escaped = _escapePdfString(text);
      final x = leftMargin + indent;
      streamCommands.writeln('BT');
      streamCommands.writeln('$fontKey ${fontSize.toStringAsFixed(1)} Tf');
      streamCommands.writeln('${x.toStringAsFixed(1)} ${cursorY.toStringAsFixed(1)} Td');
      streamCommands.writeln('($escaped) Tj');
      streamCommands.writeln('ET');
      cursorY -= lineHeight;
    }

    void drawWrappedParagraph(
      String text, {
      required bool bold,
      required double fontSize,
      required double lineHeight,
      int maxCharsPerLine = 88,
      double firstLineIndent = 0.0,
      double subsequentIndent = 0.0,
    }) {
      final lines = _wrapText(text, maxCharsPerLine);
      for (var i = 0; i < lines.length; i++) {
        drawTextLine(
          lines[i],
          bold: bold,
          fontSize: fontSize,
          lineHeight: lineHeight,
          indent: i == 0 ? firstLineIndent : subsequentIndent,
        );
      }
    }

    // 1. Header: Candidate Name & Title
    drawTextLine(
      cv.name.toUpperCase(),
      bold: true,
      fontSize: 18,
      lineHeight: 20,
    );
    drawTextLine(
      cv.title,
      bold: true,
      fontSize: 11.5,
      lineHeight: 16,
    );

    // Contact Info Line
    final contactLine = cv.contact.join('  |  ');
    drawWrappedParagraph(
      contactLine,
      bold: false,
      fontSize: 9.2,
      lineHeight: 13,
      maxCharsPerLine: 98,
    );

    cursorY -= 4;
    drawRule();

    // 2. Executive Summary / Ringkasan Profesional
    final summaryHeading =
        cv.isIndonesian ? 'RINGKASAN PROFESIONAL' : 'EXECUTIVE SUMMARY';
    drawTextLine(
      summaryHeading,
      bold: true,
      fontSize: 10.5,
      lineHeight: 15,
    );
    drawWrappedParagraph(
      cv.summary,
      bold: false,
      fontSize: 9.8,
      lineHeight: 13.5,
      maxCharsPerLine: 90,
    );
    cursorY -= 8;

    // 3. CV Sections (Experience, Education, Skills)
    for (final section in cv.sections) {
      drawRule();
      drawTextLine(
        section.heading.toUpperCase(),
        bold: true,
        fontSize: 10.5,
        lineHeight: 15,
      );

      for (final bullet in section.bullets) {
        drawWrappedParagraph(
          '-  $bullet',
          bold: false,
          fontSize: 9.8,
          lineHeight: 13.5,
          maxCharsPerLine: 86,
          firstLineIndent: 0.0,
          subsequentIndent: 11.0,
        );
        cursorY -= 3;
      }
      cursorY -= 5;
    }

    final contentStream = streamCommands.toString();
    final contentBytes = latin1.encode(contentStream);

    // Assemble PDF 1.4 Objects with exact byte offsets
    final objects = <String>[
      '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
      '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /MediaBox [0 0 612 792] /Contents 6 0 R >>\nendobj\n',
      '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n',
      '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n',
      '6 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n$contentStream\nendstream\nendobj\n',
    ];

    final pdfBuffer = StringBuffer();
    pdfBuffer.write('%PDF-1.4\n');

    final offsets = <int>[];
    for (final obj in objects) {
      offsets.add(latin1.encode(pdfBuffer.toString()).length);
      pdfBuffer.write(obj);
    }

    final xrefOffset = latin1.encode(pdfBuffer.toString()).length;
    pdfBuffer.write('xref\n');
    pdfBuffer.write('0 ${objects.length + 1}\n');
    pdfBuffer.write('0000000000 65535 f \n');
    for (final offset in offsets) {
      final padded = offset.toString().padLeft(10, '0');
      pdfBuffer.write('$padded 00000 n \n');
    }
    pdfBuffer.write(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n',
    );

    return Uint8List.fromList(latin1.encode(pdfBuffer.toString()));
  }

  static List<String> _wrapText(String text, int maxChars) {
    final cleaned = text
        .replaceAll('•', '-')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final words = cleaned.split(' ');
    final lines = <String>[];
    var currentLine = StringBuffer();

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine.write(word);
      } else if (currentLine.length + 1 + word.length <= maxChars) {
        currentLine.write(' $word');
      } else {
        lines.add(currentLine.toString());
        currentLine = StringBuffer(word);
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine.toString());
    }
    return lines.isEmpty ? [''] : lines;
  }

  static String _escapePdfString(String input) {
    // Strip any non-WinAnsi characters and escape PDF parentheses/backslashes
    final buffer = StringBuffer();
    for (final codeUnit in input.codeUnits) {
      if (codeUnit >= 32 && codeUnit <= 126) {
        final ch = String.fromCharCode(codeUnit);
        if (ch == '(' || ch == ')' || ch == r'\') {
          buffer.write('\\$ch');
        } else {
          buffer.write(ch);
        }
      } else {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}


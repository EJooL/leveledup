import 'dart:convert';
import 'dart:typed_data';
import '../../models/cv_analysis_model.dart';
import 'docx_saver_stub.dart'
    if (dart.library.html) 'docx_saver_web.dart'
    if (dart.library.io) 'docx_saver_io.dart';

/// Pure-Dart OOXML (.docx) ATS Resume Compiler & Local File Saver.
/// Matches the modern single-column reference CV format:
/// - Navy bold Title Case header name, slate headline, pipe-separated contact line
/// - Uppercase navy section headers with crisp bottom divider rules
/// - Right-aligned dates on Education / Projects / Experience entry headers
/// - Grouped bold-label skill lines without bullets
/// - Compact two-column bullet grid for Certifications (4+ items)
class DocxCvGenerator {
  DocxCvGenerator._();

  // Reference CV visual tokens
  static const String _fontFamily = 'Arial';
  static const String _colorNavy = '1B3A5C';
  static const String _colorRule = '2E5B88';
  static const String _colorHeadline = '4A5568';
  static const String _colorMuted = '595959';
  static const String _colorBody = '111111';

  // A4 page dimensions in twips (210mm x 297mm) with compact ATS margins
  static const int _pageWidthTwips = 11906;
  static const int _pageHeightTwips = 16838;
  static const int _marginTopTwips = 620;
  static const int _marginBottomTwips = 580;
  static const int _marginLeftTwips = 780;
  static const int _marginRightTwips = 780;
  static const int _contentWidthTwips =
      _pageWidthTwips - _marginLeftTwips - _marginRightTwips; // 10346

  /// Generates a binary .docx file from [ImprovedCV] and saves it locally.
  static Future<String> exportAndDownloadDocx(ImprovedCV cv) async {
    final docxBytes = buildDocxBytes(cv);
    final sanitizedName = cv.name
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final langSuffix = cv.isIndonesian ? 'ID' : 'EN';
    final fileName =
        '${sanitizedName.isEmpty ? "Candidate" : sanitizedName}_ATS_CV_$langSuffix.docx';

    return saveDocxFileLocally(docxBytes, fileName);
  }

  /// Compiles a valid ISO/IEC 29500 OOXML (.docx) Word document in pure Dart.
  static Uint8List buildDocxBytes(ImprovedCV cv) {
    final zip = _PureDartZipBuilder();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    zip.addString('[Content_Types].xml', _buildContentTypesXml());
    zip.addString('_rels/.rels', _buildRootRelsXml());
    zip.addString('word/_rels/document.xml.rels', _buildDocumentRelsXml());
    zip.addString('word/styles.xml', _buildStylesXml());
    zip.addString('docProps/core.xml', _buildCorePropsXml(cv.name, nowIso));
    zip.addString('docProps/app.xml', _buildAppPropsXml());
    zip.addString('word/document.xml', _buildDocumentXml(cv));

    return zip.build();
  }

  static String _buildDocumentXml(ImprovedCV cv) {
    final body = StringBuffer();

    // 1. Header: Name (Navy Bold), Headline (Slate), Contact Line (Muted Gray)
    final displayName = cv.name.trim().isEmpty ? 'Candidate Name' : cv.name.trim();
    body.writeln(_paragraph(
      runs: [
        _run(
          displayName,
          bold: true,
          sizeHalfPt: 40, // 20pt
          color: _colorNavy,
        ),
      ],
      spaceBefore: 0,
      spaceAfter: 40,
      lineSpacing: 240,
    ));

    if (cv.title.trim().isNotEmpty) {
      body.writeln(_paragraph(
        runs: [
          _run(
            cv.title.trim(),
            sizeHalfPt: 19, // 9.5pt
            color: _colorHeadline,
          ),
        ],
        spaceBefore: 0,
        spaceAfter: 30,
        lineSpacing: 240,
      ));
    }

    final cleanContacts = cv.contact
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (cleanContacts.isNotEmpty) {
      body.writeln(_paragraph(
        runs: [
          _run(
            cleanContacts.join('  |  '),
            sizeHalfPt: 17, // 8.5pt
            color: _colorMuted,
          ),
        ],
        spaceBefore: 0,
        spaceAfter: 100,
        lineSpacing: 230,
      ));
    }

    // 2. Summary Section
    if (cv.summary.trim().isNotEmpty) {
      final summaryHeading = cv.isIndonesian ? 'RINGKASAN' : 'SUMMARY';
      body.writeln(_sectionHeading(summaryHeading, isFirst: true));
      body.writeln(_paragraph(
        runs: [
          _run(
            cv.summary.trim(),
            sizeHalfPt: 18, // 9pt
            color: _colorBody,
          ),
        ],
        spaceBefore: 20,
        spaceAfter: 50,
        lineSpacing: 252,
      ));
    }

    // 3. Ordered Sections (Education, Projects, Experience, Skills, Certifications)
    final orderedSections = _orderSectionsLikeReference(cv.sections);
    for (var i = 0; i < orderedSections.length; i++) {
      final section = orderedSections[i];
      final type = section.type;
      body.writeln(_sectionHeading(section.heading.toUpperCase()));

      if (type == 'skills') {
        _writeSkillsSection(body, section);
      } else if (type == 'certifications') {
        _writeCertificationsSection(body, section);
      } else if (section.entries.isNotEmpty) {
        _writeStructuredEntriesSection(body, section.entries);
      } else {
        _writeLegacyBulletsSection(body, section);
      }
    }

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
$body    <w:sectPr>
      <w:pgSz w:w="$_pageWidthTwips" w:h="$_pageHeightTwips"/>
      <w:pgMar w:top="$_marginTopTwips" w:right="$_marginRightTwips" w:bottom="$_marginBottomTwips" w:left="$_marginLeftTwips" w:header="360" w:footer="360" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>''';
  }

  /// Preserves the reference CV section order:
  /// Education -> Projects -> Experience -> Skills -> Certifications -> Any Other
  static List<ImprovedCvSection> _orderSectionsLikeReference(
    List<ImprovedCvSection> sections,
  ) {
    const rank = {
      'education': 0,
      'projects': 1,
      'experience': 2,
      'skills': 3,
      'certifications': 4,
      'generic': 5,
    };
    final indexed = sections.asMap().entries.toList();
    indexed.sort((a, b) {
      final ra = rank[a.value.type] ?? 5;
      final rb = rank[b.value.type] ?? 5;
      if (ra != rb) return ra.compareTo(rb);
      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  static void _writeStructuredEntriesSection(
    StringBuffer body,
    List<ImprovedCvEntry> entries,
  ) {
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isFirst = i == 0;
      if (entry.title.isNotEmpty) {
        body.writeln(_entryHeaderRow(
          title: entry.title,
          date: entry.date,
          spaceBefore: isFirst ? 30 : 70,
          hasFollowingContent:
              entry.subtitle.isNotEmpty || entry.bullets.isNotEmpty,
        ));
      }

      if (entry.subtitle.isNotEmpty) {
        body.writeln(_paragraph(
          runs: [
            _run(
              entry.subtitle,
              sizeHalfPt: 17, // 8.5pt
              color: _colorMuted,
            ),
          ],
          spaceBefore: 0,
          spaceAfter: 25,
          lineSpacing: 240,
          keepNext: entry.bullets.isNotEmpty,
        ));
      }

      for (var j = 0; j < entry.bullets.length; j++) {
        final isLastBullet = j == entry.bullets.length - 1;
        body.writeln(_bulletParagraph(
          entry.bullets[j],
          spaceAfter: isLastBullet ? 35 : 22,
        ));
      }

      // Prevent Word from merging consecutive tables if an entry has no subtitle or bullets
      if (entry.subtitle.isEmpty && entry.bullets.isEmpty && i < entries.length - 1) {
        body.writeln(_paragraph(runs: const [], spaceBefore: 0, spaceAfter: 20, lineSpacing: 120));
      }
    }
  }

  static void _writeSkillsSection(StringBuffer body, ImprovedCvSection section) {
    final groups = <ImprovedCvSkillGroup>[];
    if (section.skillGroups.isNotEmpty) {
      groups.addAll(section.skillGroups);
    } else {
      for (final b in section.bullets) {
        final clean = b.trim();
        if (clean.isEmpty) continue;
        final colonIdx = clean.indexOf(':');
        if (colonIdx > 1 && colonIdx < 40) {
          groups.add(ImprovedCvSkillGroup(
            category: clean.substring(0, colonIdx).trim(),
            items: clean.substring(colonIdx + 1).trim(),
          ));
        } else {
          groups.add(ImprovedCvSkillGroup(category: '', items: clean));
        }
      }
    }

    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final runs = <String>[];
      if (g.category.isNotEmpty) {
        runs.add(_run(
          '${g.category}: ',
          bold: true,
          sizeHalfPt: 18, // 9pt
          color: _colorBody,
        ));
      }
      runs.add(_run(
        g.items,
        sizeHalfPt: 18, // 9pt
        color: _colorBody,
      ));

      body.writeln(_paragraph(
        runs: runs,
        spaceBefore: i == 0 ? 25 : 15,
        spaceAfter: 30,
        lineSpacing: 252,
      ));
    }
  }

  static void _writeCertificationsSection(
    StringBuffer body,
    ImprovedCvSection section,
  ) {
    final items = <String>[];
    if (section.bullets.isNotEmpty) {
      items.addAll(section.bullets.map((e) => e.trim()).where((e) => e.isNotEmpty));
    } else if (section.entries.isNotEmpty) {
      for (final e in section.entries) {
        if (e.title.isNotEmpty) {
          items.add(e.date.isNotEmpty ? '${e.title} — ${e.date}' : e.title);
        }
        items.addAll(e.bullets.map((b) => b.trim()).where((b) => b.isNotEmpty));
      }
    }

    if (items.isEmpty) return;

    // 4+ certifications -> crisp 2-column borderless grid matching reference CV
    if (items.length >= 4) {
      final split = (items.length + 1) ~/ 2;
      final leftItems = items.sublist(0, split);
      final rightItems = items.sublist(split);
      const colWidth = _contentWidthTwips ~/ 2;

      final leftBuf = StringBuffer();
      for (final item in leftItems) {
        leftBuf.writeln(_bulletParagraph(item, sizeHalfPt: 17, spaceAfter: 20));
      }

      final rightBuf = StringBuffer();
      for (final item in rightItems) {
        rightBuf.writeln(_bulletParagraph(item, sizeHalfPt: 17, spaceAfter: 20));
      }
      if (rightItems.isEmpty) {
        rightBuf.writeln(_paragraph(runs: const [], spaceBefore: 0, spaceAfter: 0));
      }

      body.writeln('''    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="$_contentWidthTwips" w:type="dxa"/>
        <w:tblLayout w:type="fixed"/>
        <w:tblBorders>
          <w:top w:val="none" w:sz="0" w:space="0" w:color="auto"/>
          <w:left w:val="none" w:sz="0" w:space="0" w:color="auto"/>
          <w:bottom w:val="none" w:sz="0" w:space="0" w:color="auto"/>
          <w:right w:val="none" w:sz="0" w:space="0" w:color="auto"/>
          <w:insideH w:val="none" w:sz="0" w:space="0" w:color="auto"/>
          <w:insideV w:val="none" w:sz="0" w:space="0" w:color="auto"/>
        </w:tblBorders>
        <w:tblCellMar>
          <w:top w:w="20" w:type="dxa"/>
          <w:left w:w="0" w:type="dxa"/>
          <w:bottom w:w="0" w:type="dxa"/>
          <w:right w:w="120" w:type="dxa"/>
        </w:tblCellMar>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="$colWidth"/>
        <w:gridCol w:w="${_contentWidthTwips - colWidth}"/>
      </w:tblGrid>
      <w:tr>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="$colWidth" w:type="dxa"/>
            <w:vAlign w:val="top"/>
          </w:tcPr>
$leftBuf        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="${_contentWidthTwips - colWidth}" w:type="dxa"/>
            <w:vAlign w:val="top"/>
          </w:tcPr>
$rightBuf        </w:tc>
      </w:tr>
    </w:tbl>''');
      return;
    }

    for (final item in items) {
      body.writeln(_bulletParagraph(item, sizeHalfPt: 17, spaceAfter: 20));
    }
  }

  static void _writeLegacyBulletsSection(
    StringBuffer body,
    ImprovedCvSection section,
  ) {
    final dateHeaderRx = RegExp(
      r'\((?:(?:jan|feb|mar|apr|mei|may|jun|jul|agu|aug|sep|okt|oct|nov|des|dec)[a-z]*\.?\s+)?(?:19|20)\d{2}(?:\s*[-–—]\s*(?:(?:jan|feb|mar|apr|mei|may|jun|jul|agu|aug|sep|okt|oct|nov|des|dec)[a-z]*\.?\s+)?(?:(?:19|20)\d{2}|present|sekarang))?\)',
      caseSensitive: false,
    );

    for (final raw in section.bullets) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final dateMatch = dateHeaderRx.firstMatch(line);
      if (dateMatch != null && line.length < 115 && !line.endsWith('.')) {
        final date = dateMatch.group(0)!.replaceAll(RegExp(r'^\(|\)$'), '').trim();
        final title = line
            .replaceFirst(dateMatch.group(0)!, '')
            .replaceAll(RegExp(r'[\s|,\-–—]+$'), '')
            .trim();
        body.writeln(_entryHeaderRow(
          title: title.isEmpty ? line : title,
          date: date,
          spaceBefore: 40,
          hasFollowingContent: true,
        ));
      } else {
        body.writeln(_bulletParagraph(line));
      }
    }
  }

  static String _sectionHeading(String text, {bool isFirst = false}) {
    final before = isFirst ? 60 : 120;
    return '''    <w:p>
      <w:pPr>
        <w:keepNext/>
        <w:pBdr>
          <w:bottom w:val="single" w:sz="6" w:space="2" w:color="$_colorRule"/>
        </w:pBdr>
        <w:spacing w:before="$before" w:after="55" w:line="240" w:lineRule="auto"/>
      </w:pPr>
      ${_run(text, bold: true, sizeHalfPt: 20, color: _colorNavy)}
    </w:p>''';
  }

  /// Renders a bold left-aligned Entry Title with an optional muted right-aligned Date
  /// using a zero-border 2-column fixed row so long titles wrap cleanly on the left
  /// while keeping the date flush-right on line 1 (matching the reference CV).
  static String _entryHeaderRow({
    required String title,
    required String date,
    int spaceBefore = 45,
    bool hasFollowingContent = true,
  }) {
    if (date.trim().isEmpty) {
      return _paragraph(
        runs: [
          _run(title, bold: true, sizeHalfPt: 18, color: _colorBody),
        ],
        spaceBefore: spaceBefore,
        spaceAfter: 20,
        lineSpacing: 245,
        keepNext: hasFollowingContent,
      );
    }

    const int rightColWidth = 2350;
    const int leftColWidth = _contentWidthTwips - rightColWidth;

    final leftPara = _paragraph(
      runs: [
        _run(title, bold: true, sizeHalfPt: 18, color: _colorBody),
      ],
      spaceBefore: spaceBefore,
      spaceAfter: 18,
      lineSpacing: 245,
      keepNext: hasFollowingContent,
    );

    final rightPara = _paragraph(
      runs: [
        _run(date.trim(), sizeHalfPt: 17, color: _colorMuted),
      ],
      align: 'right',
      spaceBefore: spaceBefore,
      spaceAfter: 18,
      lineSpacing: 245,
      keepNext: hasFollowingContent,
    );

    return '''    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="$_contentWidthTwips" w:type="dxa"/>
        <w:tblLayout w:type="fixed"/>
        <w:tblBorders>
          <w:top w:val="none" w:sz="0" w:space="0" w:color="auto"/>
          <w:left w:val="none" w:sz="0" w:space="0" w:color="auto"/>
          <w:bottom w:val="none" w:sz="0" w:space="0" w:color="auto"/>
          <w:right w:val="none" w:sz="0" w:space="0" w:color="auto"/>
          <w:insideH w:val="none" w:sz="0" w:space="0" w:color="auto"/>
          <w:insideV w:val="none" w:sz="0" w:space="0" w:color="auto"/>
        </w:tblBorders>
        <w:tblCellMar>
          <w:top w:w="0" w:type="dxa"/>
          <w:left w:w="0" w:type="dxa"/>
          <w:bottom w:w="0" w:type="dxa"/>
          <w:right w:w="0" w:type="dxa"/>
        </w:tblCellMar>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="$leftColWidth"/>
        <w:gridCol w:w="$rightColWidth"/>
      </w:tblGrid>
      <w:tr>
        <w:trPr><w:cantSplit/></w:trPr>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="$leftColWidth" w:type="dxa"/>
            <w:vAlign w:val="top"/>
          </w:tcPr>
$leftPara        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="$rightColWidth" w:type="dxa"/>
            <w:vAlign w:val="top"/>
          </w:tcPr>
$rightPara        </w:tc>
      </w:tr>
    </w:tbl>''';
  }

  static String _bulletParagraph(
    String text, {
    int sizeHalfPt = 18,
    int spaceAfter = 24,
  }) {
    final cleanText = text.replaceFirst(RegExp(r'^[•\-*]\s*'), '').trim();
    return '''    <w:p>
      <w:pPr>
        <w:tabs>
          <w:tab w:val="left" w:pos="220"/>
        </w:tabs>
        <w:spacing w:before="0" w:after="$spaceAfter" w:line="252" w:lineRule="auto"/>
        <w:ind w:left="220" w:hanging="150"/>
      </w:pPr>
      ${_run('•', bold: true, sizeHalfPt: sizeHalfPt, color: _colorBody)}
      <w:r><w:tab/></w:r>
      ${_run(cleanText, sizeHalfPt: sizeHalfPt, color: _colorBody)}
    </w:p>''';
  }

  static String _paragraph({
    required List<String> runs,
    String? align,
    int spaceBefore = 0,
    int spaceAfter = 40,
    int lineSpacing = 248,
    bool keepNext = false,
  }) {
    final pPr = StringBuffer();
    if (keepNext) pPr.write('<w:keepNext/>');
    if (align != null) pPr.write('<w:jc w:val="$align"/>');
    pPr.write(
      '<w:spacing w:before="$spaceBefore" w:after="$spaceAfter" w:line="$lineSpacing" w:lineRule="auto"/>',
    );
    return '    <w:p><w:pPr>$pPr</w:pPr>${runs.join()}</w:p>';
  }

  static String _run(
    String text, {
    bool bold = false,
    bool italic = false,
    required int sizeHalfPt,
    required String color,
  }) {
    final escaped = _escapeXml(text);
    final rPr = StringBuffer()
      ..write('<w:rFonts w:ascii="$_fontFamily" w:hAnsi="$_fontFamily" w:cs="$_fontFamily"/>');
    if (bold) rPr.write('<w:b/>');
    if (italic) rPr.write('<w:i/>');
    rPr.write('<w:color w:val="$color"/>');
    rPr.write('<w:sz w:val="$sizeHalfPt"/>');
    rPr.write('<w:szCs w:val="$sizeHalfPt"/>');
    return '<w:r><w:rPr>$rPr</w:rPr><w:t xml:space="preserve">$escaped</w:t></w:r>';
  }

  static String _escapeXml(String input) {
    final buf = StringBuffer();
    for (final rune in input.runes) {
      // Strip illegal XML 1.0 control chars except \t, \n, \r
      if (rune < 0x20 && rune != 0x09 && rune != 0x0A && rune != 0x0D) {
        continue;
      }
      switch (rune) {
        case 0x26: // &
          buf.write('&amp;');
          break;
        case 0x3C: // <
          buf.write('&lt;');
          break;
        case 0x3E: // >
          buf.write('&gt;');
          break;
        case 0x22: // "
          buf.write('&quot;');
          break;
        case 0x27: // '
          buf.write('&apos;');
          break;
        case 0x0A:
        case 0x0D:
          buf.write(' ');
          break;
        default:
          buf.writeCharCode(rune);
      }
    }
    return buf.toString();
  }

  static String _buildContentTypesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';
  }

  static String _buildRootRelsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
  }

  static String _buildDocumentRelsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
  }

  static String _buildStylesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="$_fontFamily" w:hAnsi="$_fontFamily" w:cs="$_fontFamily"/>
        <w:color w:val="$_colorBody"/>
        <w:sz w:val="18"/>
        <w:szCs w:val="18"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="40" w:line="248" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
</w:styles>''';
  }

  static String _buildCorePropsXml(String authorName, String isoTimestamp) {
    final safeAuthor = _escapeXml(
      authorName.trim().isEmpty ? 'LeveledUp Candidate' : authorName.trim(),
    );
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>$safeAuthor - ATS Resume</dc:title>
  <dc:creator>$safeAuthor</dc:creator>
  <cp:lastModifiedBy>LeveledUp ATS CV Optimizer</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$isoTimestamp</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$isoTimestamp</dcterms:modified>
</cp:coreProperties>''';
  }

  static String _buildAppPropsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
  <Application>LeveledUp ATS CV Optimizer</Application>
</Properties>''';
  }
}

/// Minimal, zero-dependency pure-Dart PKZIP (STORE / method 0) archive builder.
/// Produces standard ZIP archives accepted by Word, Google Docs, and LibreOffice.
class _PureDartZipBuilder {
  final List<_ZipEntry> _entries = [];

  static final List<int> _crcTable = _buildCrcTable();

  void addString(String path, String content) {
    final bytes = Uint8List.fromList(utf8.encode(content));
    _entries.add(_ZipEntry(
      nameBytes: Uint8List.fromList(utf8.encode(path)),
      data: bytes,
      crc32: _computeCrc32(bytes),
    ));
  }

  Uint8List build() {
    final out = BytesBuilder(copy: false);
    final centralDir = BytesBuilder(copy: false);
    var offset = 0;

    // DOS timestamp (fixed valid date: 2026-01-01 00:00:00)
    const int dosTime = 0x0000;
    const int dosDate = 0x5C21;
    // General purpose flag: bit 11 (0x0800) = UTF-8 filename encoding
    const int flags = 0x0800;

    for (final entry in _entries) {
      final nameLen = entry.nameBytes.length;
      final dataLen = entry.data.length;

      // Local File Header (30 bytes + filename)
      final lfh = ByteData(30);
      lfh.setUint32(0, 0x04034b50, Endian.little); // signature
      lfh.setUint16(4, 20, Endian.little); // version needed (2.0)
      lfh.setUint16(6, flags, Endian.little);
      lfh.setUint16(8, 0, Endian.little); // compression method: 0 = STORE
      lfh.setUint16(10, dosTime, Endian.little);
      lfh.setUint16(12, dosDate, Endian.little);
      lfh.setUint32(14, entry.crc32, Endian.little);
      lfh.setUint32(18, dataLen, Endian.little); // compressed size
      lfh.setUint32(22, dataLen, Endian.little); // uncompressed size
      lfh.setUint16(26, nameLen, Endian.little);
      lfh.setUint16(28, 0, Endian.little); // extra length

      out.add(lfh.buffer.asUint8List());
      out.add(entry.nameBytes);
      out.add(entry.data);

      // Central Directory Header (46 bytes + filename)
      final cdh = ByteData(46);
      cdh.setUint32(0, 0x02014b50, Endian.little); // signature
      cdh.setUint16(4, 20, Endian.little); // version made by
      cdh.setUint16(6, 20, Endian.little); // version needed
      cdh.setUint16(8, flags, Endian.little);
      cdh.setUint16(10, 0, Endian.little); // compression method: STORE
      cdh.setUint16(12, dosTime, Endian.little);
      cdh.setUint16(14, dosDate, Endian.little);
      cdh.setUint32(16, entry.crc32, Endian.little);
      cdh.setUint32(20, dataLen, Endian.little);
      cdh.setUint32(24, dataLen, Endian.little);
      cdh.setUint16(28, nameLen, Endian.little);
      cdh.setUint16(30, 0, Endian.little); // extra len
      cdh.setUint16(32, 0, Endian.little); // comment len
      cdh.setUint16(34, 0, Endian.little); // disk number start
      cdh.setUint16(36, 0, Endian.little); // internal attrs
      cdh.setUint32(38, 0, Endian.little); // external attrs
      cdh.setUint32(42, offset, Endian.little); // relative offset

      centralDir.add(cdh.buffer.asUint8List());
      centralDir.add(entry.nameBytes);

      offset += 30 + nameLen + dataLen;
    }

    final cdBytes = centralDir.toBytes();
    final cdOffset = offset;
    out.add(cdBytes);

    // End of Central Directory Record (22 bytes)
    final eocd = ByteData(22);
    eocd.setUint32(0, 0x06054b50, Endian.little); // signature
    eocd.setUint16(4, 0, Endian.little); // disk number
    eocd.setUint16(6, 0, Endian.little); // cd start disk
    eocd.setUint16(8, _entries.length, Endian.little); // entries on disk
    eocd.setUint16(10, _entries.length, Endian.little); // total entries
    eocd.setUint32(12, cdBytes.length, Endian.little); // cd size
    eocd.setUint32(16, cdOffset, Endian.little); // cd offset
    eocd.setUint16(20, 0, Endian.little); // comment len
    out.add(eocd.buffer.asUint8List());

    return out.toBytes();
  }

  static List<int> _buildCrcTable() {
    final table = List<int>.filled(256, 0);
    for (var i = 0; i < 256; i++) {
      var c = i;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      }
      table[i] = c;
    }
    return table;
  }

  static int _computeCrc32(Uint8List data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >>> 8);
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}

class _ZipEntry {
  final Uint8List nameBytes;
  final Uint8List data;
  final int crc32;

  _ZipEntry({
    required this.nameBytes,
    required this.data,
    required this.crc32,
  });
}

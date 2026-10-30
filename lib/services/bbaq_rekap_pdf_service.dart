import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ptl_mobile/services/pdf/pdf_template.dart';

import '../models/absensi_bbaq/bbaq_rekap_model.dart';

class AbsensiBbaqRekapPdfService {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const PdfColor primaryColor = PdfColor.fromInt(0xFF0D8B8B);

  static const PdfColor textColor = PdfColor.fromInt(0xFF1E293B);

  static const PdfColor subtitleColor = PdfColor.fromInt(0xFF64748B);

  static const PdfColor borderColor = PdfColor.fromInt(0xFFE2E8F0);

  static const PdfColor lightBackground = PdfColor.fromInt(0xFFF8FAFC);

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  static String formatTanggal(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTanggalPanjang(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  // ============================================================
  // REKAPITULASI
  // ============================================================

  static Future<Uint8List> generateLaporanRekap({
    required List<BbaqRekapModel> data,
    required List<DateTime> tanggalList,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    required DateTime tanggalCetak,
    String namaLembaga = "Pesantren Al-Qur'an Nurul Falah",
    String bidangLembaga = "Bidang BBAQ",
    String namaProgram = "BBAQ",
    String? tahunAjaran,
    required String semester,
    required String namaPengajar,
    String namaAdmin = "Admin LPQ Nurul Falah",
    String judul = "REKAP ABSENSI SANTRI BBAQ",
  }) async {
    final pdf = pw.Document();

    final sortedTanggal = [...tanggalList]..sort();

    final periode =
        '${formatTanggal(dariTanggal)} - '
        '${formatTanggal(sampaiTanggal)}';

    final tahunAjaranText = tahunAjaran == null || tahunAjaran.trim().isEmpty
        ? '-'
        : tahunAjaran.trim();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 28),
        header: (context) {
          return PdfTemplate.buildHeader(
            namaLembaga: namaLembaga,
            bidang: bidangLembaga,
            judul: judul,
            tahunAjaran: tahunAjaranText,
            semester: semester,
          );
        },
        footer: (context) {
          return _buildFooter(context);
        },
        build: (context) {
          return [
            PdfTemplate.buildInfo(
              namaProgram: namaProgram,
              namaPengajar: namaPengajar,
              periode: periode,
              semester: semester,
              tahunAjaran: tahunAjaranText,
              jumlahPertemuan: sortedTanggal.length,
            ),

            pw.SizedBox(height: 12),

            _buildRekapTable(rekapList: data, tanggalList: sortedTanggal),

            pw.SizedBox(height: 14),

            _buildSummary(rekapList: data, tanggalList: sortedTanggal),

            pw.SizedBox(height: 12),

            _buildLegend(),

            pw.SizedBox(height: 8),

            PdfTemplate.buildSignature(
              kota: "Surabaya",
              tanggal: tanggalCetak,
              jabatanPengajar: "Pengajar BBAQ",
              namaPengajar: namaPengajar,
              jabatanAdmin: "Admin LPQ Nurul Falah",
              namaAdmin: namaAdmin,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // LAPORAN PER TANGGAL
  // ============================================================

  static Future<Uint8List> generateLaporanTanggal({
    required List<Map<String, dynamic>> data,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    required DateTime tanggalCetak,
    String namaLembaga = "Pesantren Al-Qur'an Nurul Falah",
    String bidangLembaga = "Bidang BBAQ",
    String namaProgram = "BBAQ",
    String? tahunAjaran,
    required String semester,
    required String namaPengajar,
    String namaAdmin = "Admin LPQ Nurul Falah",
    String judul = "DAFTAR HADIR SANTRI BBAQ",
  }) async {
    final pdf = pw.Document();

    final periode =
        '${formatTanggal(dariTanggal)} - '
        '${formatTanggal(sampaiTanggal)}';

    final tahunAjaranText = tahunAjaran == null || tahunAjaran.trim().isEmpty
        ? '-'
        : tahunAjaran.trim();

    // Grouping berdasarkan tanggal
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final item in data) {
      final pertemuan = item['pertemuan'];

      if (pertemuan is! Map) {
        continue;
      }

      final tanggal = pertemuan['tanggal']?.toString() ?? '';

      if (tanggal.isEmpty) {
        continue;
      }

      grouped.putIfAbsent(tanggal, () => []);

      grouped[tanggal]!.add(item);
    }

    final sortedDates = grouped.keys.toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 28),
        header: (context) {
          return PdfTemplate.buildHeader(
            namaLembaga: namaLembaga,
            bidang: bidangLembaga,
            judul: judul,
            tahunAjaran: tahunAjaranText,
            semester: semester,
          );
        },
        footer: (context) {
          return _buildFooter(context);
        },
        build: (context) {
          final widgets = <pw.Widget>[];

          widgets.add(
            PdfTemplate.buildInfo(
              namaProgram: namaProgram,
              namaPengajar: namaPengajar,
              periode: periode,
              semester: semester,
              tahunAjaran: tahunAjaranText,
              jumlahPertemuan: sortedDates.length,
            ),
          );

          widgets.add(pw.SizedBox(height: 12));

          if (sortedDates.isEmpty) {
            widgets.add(
              _buildEmptyPdfState(
                'Tidak ada data absensi BBAQ pada periode yang dipilih.',
              ),
            );

            return widgets;
          }

          for (int i = 0; i < sortedDates.length; i++) {
            final tanggal = sortedDates[i];

            final items = grouped[tanggal] ?? [];

            widgets.add(_buildTanggalSection(tanggal: tanggal, data: items));

            if (i != sortedDates.length - 1) {
              widgets.add(pw.SizedBox(height: 14));
            }
          }

          widgets.add(pw.SizedBox(height: 8));

          widgets.add(
            PdfTemplate.buildSignature(
              kota: "Surabaya",
              tanggal: tanggalCetak,
              jabatanPengajar: "Pengajar BBAQ",
              namaPengajar: namaPengajar,
              jabatanAdmin: "Admin LPQ Nurul Falah",
              namaAdmin: namaAdmin,
            ),
          );

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // SECTION PER TANGGAL
  // ============================================================

  static pw.Widget _buildTanggalSection({
    required String tanggal,
    required List<Map<String, dynamic>> data,
  }) {
    final parsedDate = DateTime.tryParse(tanggal);

    final tanggalText = parsedDate != null
        ? formatTanggalPanjang(parsedDate)
        : tanggal;

    final first = data.isNotEmpty ? data.first : <String, dynamic>{};

    final pertemuan = first['pertemuan'] is Map
        ? Map<String, dynamic>.from(first['pertemuan'])
        : <String, dynamic>{};

    final pengajar = pertemuan['pengajar'] is Map
        ? Map<String, dynamic>.from(pertemuan['pengajar'])
        : <String, dynamic>{};

    final pengganti = pertemuan['pengganti_pengajar'] is Map
        ? Map<String, dynamic>.from(pertemuan['pengganti_pengajar'])
        : <String, dynamic>{};

    final pengajarNama = pengajar['username']?.toString() ?? '-';

    final penggantiNama = pengganti['nama']?.toString();

    final materi = pertemuan['materi_pembelajaran']?.toString();

    final metode = pertemuan['metode']?.toString();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: pw.BoxDecoration(
            color: lightBackground,
            border: pw.Border.all(color: borderColor, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 4,
                    height: 20,
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'Tanggal: $tanggalText',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text(
                    'Pengajar: $pengajarNama',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: subtitleColor,
                    ),
                  ),
                  if (penggantiNama != null && penggantiNama.isNotEmpty) ...[
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '| Pengganti: $penggantiNama',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                  if (metode != null && metode.isNotEmpty) ...[
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '| Metode: $metode',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                  if (materi != null && materi.isNotEmpty) ...[
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '| Materi: $materi',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        _buildDetailTable(data),
      ],
    );
  }

  // ============================================================
  // DETAIL TABLE (SANTRI & STATUS KHUSUS BBAQ)
  // ============================================================

  static pw.Widget _buildDetailTable(List<Map<String, dynamic>> data) {
    final rows = <pw.TableRow>[];

    // HEADER
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: lightBackground),
        children: [
          _tableHeader('No'),
          _tableHeader('Nama Santri', align: pw.TextAlign.left),
          _tableHeader('Status'),
        ],
      ),
    );

    // DATA
    for (int index = 0; index < data.length; index++) {
      final item = data[index];

      final santriProgram = item['santri_program'] is Map
          ? Map<String, dynamic>.from(item['santri_program'])
          : <String, dynamic>{};

      final santri = santriProgram['santri'] is Map
          ? Map<String, dynamic>.from(santriProgram['santri'])
          : <String, dynamic>{};

      final namaSantri = santri['username']?.toString().trim() ?? '-';

      final status = item['status']?.toString() ?? '-';

      rows.add(
        pw.TableRow(
          children: [
            _tableCell('${index + 1}', align: pw.TextAlign.center),
            _tableCell(namaSantri, align: pw.TextAlign.left, bold: true),
            _statusCell(status),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(35),
        1: pw.FlexColumnWidth(6),
        2: pw.FixedColumnWidth(80),
      },
      children: rows,
    );
  }

  // ============================================================
  // EMPTY PDF STATE
  // ============================================================

  static pw.Widget _buildEmptyPdfState(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: pw.Center(
        child: pw.Text(
          message,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 9, color: subtitleColor),
        ),
      ),
    );
  }

  // ============================================================
  // REKAP TABLE
  // ============================================================

  static pw.Widget _buildRekapTable({
    required List<BbaqRekapModel> rekapList,
    required List<DateTime> tanggalList,
  }) {
    final headers = <pw.Widget>[
      _tableHeader('No'),
      _tableHeader('Nama Santri', align: pw.TextAlign.left),
    ];

    for (final tanggal in tanggalList) {
      headers.add(_tableHeader(DateFormat('dd/MM').format(tanggal)));
    }

    headers.addAll([
      _tableHeader('H'),
      _tableHeader('I'),
      _tableHeader('S'),
      _tableHeader('A'),
      _tableHeader('%'),
    ]);

    final rows = <pw.TableRow>[];

    // HEADER
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: lightBackground),
        children: headers,
      ),
    );

    // DATA
    for (int index = 0; index < rekapList.length; index++) {
      final item = rekapList[index];

      final cells = <pw.Widget>[
        _tableCell('${index + 1}', align: pw.TextAlign.center),
        _tableCell(item.namaSantri, align: pw.TextAlign.left, bold: true),
      ];

      for (final tanggal in tanggalList) {
        final key = _formatDateKey(tanggal);

        final status = item.getStatus(key);

        cells.add(_statusCell(status));
      }

      cells.addAll([
        _tableCell(
          '${item.totalHadir}',
          align: pw.TextAlign.center,
          bold: true,
        ),
        _tableCell('${item.totalIzin}', align: pw.TextAlign.center),
        _tableCell('${item.totalSakit}', align: pw.TextAlign.center),
        _tableCell('${item.totalAlpa}', align: pw.TextAlign.center),
        _tableCell(
          '${item.persentaseKehadiran.toStringAsFixed(0)}%',
          align: pw.TextAlign.center,
          bold: true,
        ),
      ]);

      rows.add(pw.TableRow(children: cells));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: _buildColumnWidths(tanggalList.length),
      children: rows,
    );
  }

  // ============================================================
  // COLUMN WIDTH
  // ============================================================

  static Map<int, pw.TableColumnWidth> _buildColumnWidths(int jumlahTanggal) {
    final result = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(28),
      1: const pw.FlexColumnWidth(3),
    };

    int index = 2;

    for (int i = 0; i < jumlahTanggal; i++) {
      result[index] = const pw.FixedColumnWidth(32);
      index++;
    }

    result[index++] = const pw.FixedColumnWidth(28); // H

    result[index++] = const pw.FixedColumnWidth(28); // I

    result[index++] = const pw.FixedColumnWidth(28); // S

    result[index++] = const pw.FixedColumnWidth(28); // A

    result[index] = const pw.FixedColumnWidth(40); // %

    return result;
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  static pw.Widget _tableHeader(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      alignment: _alignmentFromTextAlign(align),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE CELL
  // ============================================================

  static pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      alignment: _alignmentFromTextAlign(align),
      child: pw.Text(
        text,
        textAlign: align,
        maxLines: 2,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CELL
  // ============================================================

  static pw.Widget _statusCell(String status) {
    final normalized = status.trim().toLowerCase();

    String shortStatus;

    switch (normalized) {
      case 'hadir':
      case 'h':
        shortStatus = 'H';
        break;

      case 'izin':
      case 'i':
        shortStatus = 'I';
        break;

      case 'sakit':
      case 's':
        shortStatus = 'S';
        break;

      case 'alpa':
      case 'a':
        shortStatus = 'A';
        break;

      default:
        shortStatus = '-';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        shortStatus,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _statusColor(shortStatus),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  static PdfColor _statusColor(String status) {
    switch (status) {
      case 'H':
        return const PdfColor.fromInt(0xFF10B981);

      case 'I':
        return const PdfColor.fromInt(0xFF3B82F6);

      case 'S':
        return const PdfColor.fromInt(0xFFF59E0B);

      case 'A':
        return const PdfColor.fromInt(0xFFEF4444);

      default:
        return subtitleColor;
    }
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  static pw.Widget _buildSummary({
    required List<BbaqRekapModel> rekapList,
    required List<DateTime> tanggalList,
  }) {
    int totalHadir = 0;
    int totalIzin = 0;
    int totalSakit = 0;
    int totalAlpa = 0;

    for (final item in rekapList) {
      totalHadir += item.totalHadir;
      totalIzin += item.totalIzin;
      totalSakit += item.totalSakit;
      totalAlpa += item.totalAlpa;
    }

    final totalAbsensi = totalHadir + totalIzin + totalSakit + totalAlpa;

    final persentase = totalAbsensi == 0
        ? 0.0
        : (totalHadir / totalAbsensi) * 100;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: lightBackground,
        border: pw.Border.all(color: borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        children: [
          _summaryItem('Santri', '${rekapList.length}'),
          _summaryItem('Pertemuan', '${tanggalList.length}'),
          _summaryItem('Hadir', '$totalHadir'),
          _summaryItem('Izin', '$totalIzin'),
          _summaryItem('Sakit', '$totalSakit'),
          _summaryItem('Alpa', '$totalAlpa'),
          _summaryItem('Kehadiran', '${persentase.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7, color: subtitleColor),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEGEND
  // ============================================================

  static pw.Widget _buildLegend() {
    return pw.Row(
      children: [
        pw.Text(
          'Keterangan:',
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
        pw.SizedBox(width: 8),
        _legendItem('H', 'Hadir'),
        pw.SizedBox(width: 10),
        _legendItem('I', 'Izin'),
        pw.SizedBox(width: 10),
        _legendItem('S', 'Sakit'),
        pw.SizedBox(width: 10),
        _legendItem('A', 'Alpa'),
        pw.SizedBox(width: 10),
        _legendItem('-', 'Tidak ada data'),
      ],
    );
  }

  static pw.Widget _legendItem(String code, String label) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          code,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: _statusColor(code),
          ),
        ),
        pw.SizedBox(width: 3),
        pw.Text(
          '= $label',
          style: const pw.TextStyle(fontSize: 7, color: subtitleColor),
        ),
      ],
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "Pesantren Al-Qur'an Nurul Falah",
            style: const pw.TextStyle(fontSize: 7, color: subtitleColor),
          ),
          pw.Text(
            'Halaman ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 7, color: subtitleColor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALIGNMENT HELPER
  // ============================================================

  static pw.Alignment _alignmentFromTextAlign(pw.TextAlign align) {
    switch (align) {
      case pw.TextAlign.left:
        return pw.Alignment.centerLeft;

      case pw.TextAlign.right:
        return pw.Alignment.centerRight;

      default:
        return pw.Alignment.center;
    }
  }

  // ============================================================
  // DATE KEY
  // ============================================================

  static String _formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

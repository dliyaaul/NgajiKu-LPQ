import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfTemplate {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF0D8B8B);

  static const PdfColor textColor = PdfColor.fromInt(0xFF1E293B);

  static const PdfColor subtitleColor = PdfColor.fromInt(0xFF64748B);

  // ============================================================
  // HEADER / KOP RESMI
  // ============================================================

  static pw.Widget buildHeader({
    required String namaLembaga,

    required String bidang,

    required String judul,

    required String tahunAjaran,

    required String semester,

    pw.MemoryImage? logo,
  }) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,

          padding: const pw.EdgeInsets.only(bottom: 10),

          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: primaryColor, width: 2),
            ),
          ),

          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,

            children: [
              if (logo != null)
                pw.Container(
                  width: 55,

                  height: 55,

                  margin: const pw.EdgeInsets.only(right: 15),

                  child: pw.Image(logo),
                ),

              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      namaLembaga.toUpperCase(),

                      textAlign: pw.TextAlign.center,

                      style: pw.TextStyle(
                        fontSize: 15,

                        fontWeight: pw.FontWeight.bold,

                        color: textColor,
                      ),
                    ),

                    pw.SizedBox(height: 3),

                    pw.Text(
                      bidang.toUpperCase(),

                      style: pw.TextStyle(
                        fontSize: 10,

                        fontWeight: pw.FontWeight.bold,

                        color: primaryColor,
                      ),
                    ),

                    pw.SizedBox(height: 7),

                    pw.Text(
                      judul,

                      style: pw.TextStyle(
                        fontSize: 13,

                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.SizedBox(height: 5),

                    pw.Text(
                      "$tahunAjaran - $semester",

                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFORMASI LAPORAN
  // ============================================================

  static pw.Widget buildInfo({
    required String namaProgram,

    required String namaPengajar,

    required String periode,

    required String semester,

    required String tahunAjaran,

    required int jumlahPertemuan,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),

      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),

        borderRadius: pw.BorderRadius.circular(5),
      ),

      child: pw.Table(
        children: [
          _infoRow("Program", namaProgram, "Pengajar", namaPengajar),

          _infoRow("Semester", semester, "Tahun Ajaran", tahunAjaran),

          _infoRow("Periode", periode, "Pertemuan", "$jumlahPertemuan kali"),
        ],
      ),
    );
  }

  static pw.TableRow _infoRow(
    String label1,
    String value1,

    String label2,
    String value2,
  ) {
    return pw.TableRow(
      children: [
        _label(label1),

        _separator(),

        _value(value1),

        _label(label2),

        _separator(),

        _value(value2),
      ],
    );
  }

  static pw.Widget _label(String text) {
    return pw.Text(
      text,

      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
    );
  }

  static pw.Widget _separator() {
    return pw.Text(":", style: pw.TextStyle(fontSize: 8));
  }

  static pw.Widget _value(String text) {
    return pw.Text(
      text,

      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
    );
  }

  // ============================================================
  // TANDA TANGAN
  // ============================================================

  static pw.Widget buildSignature({
    required String kota,

    required DateTime tanggal,

    required String jabatanPengajar,

    required String namaPengajar,

    required String jabatanAdmin,

    required String namaAdmin,
  }) {
    final tanggalText = DateFormat("d MMMM yyyy", "id_ID").format(tanggal);

    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,

          child: pw.Text(
            "$kota, $tanggalText",

            style: const pw.TextStyle(fontSize: 9),
          ),
        ),

        pw.SizedBox(height: 25),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,

          children: [
            _signatureBox(jabatanAdmin, namaAdmin),

            _signatureBox(jabatanPengajar, namaPengajar),
          ],
        ),
      ],
    );
  }

  static pw.Widget _signatureBox(String jabatan, String nama) {
    return pw.Column(
      children: [
        pw.Text(
          jabatan,

          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),

        pw.SizedBox(height: 45),

        pw.Container(
          width: 130,

          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.7)),
          ),
        ),

        pw.SizedBox(height: 5),

        pw.Text(
          nama.isEmpty ? "(................................)" : nama,

          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }
}

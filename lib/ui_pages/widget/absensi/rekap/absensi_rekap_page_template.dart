import 'package:flutter/material.dart';

import 'absensi_rekap_filter.dart';
import 'absensi_rekap_page_config.dart';
import 'absensi_rekap_row.dart';
import 'absensi_rekap_summary.dart';
import 'absensi_rekap_table.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _primaryLightColor = Color(0xFFE6F3F3);
const Color _backgroundColor = Color(0xFFF4F6F8);
const Color _cardColor = Colors.white;
const Color _textColor = Color(0xFF1E293B);
const Color _subtitleColor = Color(0xFF64748B);
const Color _borderColor = Color(0xFFE2E8F0);

class AbsensiRekapPageTemplate extends StatelessWidget {
  final AbsensiRekapPageConfig config;

  // =========================
  // DATA PENGAJAR
  // =========================
  final List<Map<String, dynamic>> pengajarList;
  final String? selectedPengajarId;
  final String namaPengajar;

  // =========================
  // FILTER
  // =========================
  final String selectedSemester;
  final DateTime dariTanggal;
  final DateTime sampaiTanggal;
  final DateTime tanggalCetak;

  // =========================
  // DATA REKAP
  // =========================
  final List<DateTime> tanggalList;
  final List<AbsensiRekapRow> rekapList;

  // =========================
  // STATE
  // =========================
  final bool isLoading;
  final bool hasLoaded;
  final bool isExportingPdf;

  /// Menentukan apakah tombol PDF boleh digunakan.
  ///
  /// Nilai ini dikontrol oleh page program masing-masing.
  final bool canExportPdf;

  final String? errorMessage;

  // =========================
  // CALLBACK
  // =========================
  final ValueChanged<String?> onPengajarChanged;
  final ValueChanged<String> onSemesterChanged;
  final ValueChanged<DateTime> onDariTanggalChanged;
  final ValueChanged<DateTime> onSampaiTanggalChanged;
  final ValueChanged<DateTime> onTanggalCetakChanged;
  final VoidCallback onTampilkanRekap;
  final VoidCallback onExportPdf;

  const AbsensiRekapPageTemplate({
    super.key,
    required this.config,

    required this.pengajarList,
    required this.selectedPengajarId,
    required this.namaPengajar,

    required this.selectedSemester,
    required this.dariTanggal,
    required this.sampaiTanggal,
    required this.tanggalCetak,

    required this.tanggalList,
    required this.rekapList,

    required this.isLoading,
    required this.hasLoaded,
    required this.isExportingPdf,
    required this.canExportPdf,
    required this.errorMessage,

    required this.onPengajarChanged,
    required this.onSemesterChanged,
    required this.onDariTanggalChanged,
    required this.onSampaiTanggalChanged,
    required this.onTanggalCetakChanged,
    required this.onTampilkanRekap,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError =
        errorMessage != null && errorMessage!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          config.pageTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding = constraints.maxWidth >= 1000
                ? 32
                : 16;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),

                      AbsensiRekapFilter(
                        pengajarList: pengajarList,
                        selectedPengajarId: selectedPengajarId,
                        namaPengajar: namaPengajar,
                        selectedSemester: selectedSemester,
                        dariTanggal: dariTanggal,
                        sampaiTanggal: sampaiTanggal,
                        tanggalCetak: tanggalCetak,
                        isLoading: isLoading,
                        isExportingPdf: isExportingPdf,
                        canExportPdf: canExportPdf,
                        onPengajarChanged: onPengajarChanged,
                        onSemesterChanged: onSemesterChanged,
                        onDariTanggalChanged: onDariTanggalChanged,
                        onSampaiTanggalChanged: onSampaiTanggalChanged,
                        onTanggalCetakChanged: onTanggalCetakChanged,
                        onTampilkanRekap: onTampilkanRekap,
                        onExportPdf: onExportPdf,
                      ),

                      const SizedBox(height: 18),

                      // =========================
                      // ERROR
                      // =========================
                      if (hasError) ...[
                        _buildError(),
                        const SizedBox(height: 18),
                      ],

                      // =========================
                      // LOADING
                      // =========================
                      if (isLoading)
                        _buildLoadingState()
                      // =========================
                      // HASIL REKAP
                      // =========================
                      else if (hasLoaded && !hasError) ...[
                        _buildSummary(),
                        const SizedBox(height: 18),
                        AbsensiRekapTable(
                          rekapList: rekapList,
                          tanggalList: tanggalList,
                          title: config.tableTitle,
                        ),
                      ]
                      // =========================
                      // BELUM ADA REKAP
                      // =========================
                      else if (!hasError)
                        _buildEmptyState(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryLightColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(config.icon, color: _primaryColor, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.headerTitle,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  config.headerSubtitle,
                  style: const TextStyle(
                    color: _subtitleColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final int jumlahSantri = rekapList.length;
    final int jumlahPertemuan = tanggalList.length;

    final int totalHadir = rekapList.fold(
      0,
      (total, row) => total + row.totalHadir,
    );

    final int totalIzin = rekapList.fold(
      0,
      (total, row) => total + row.totalIzin,
    );

    final int totalSakit = rekapList.fold(
      0,
      (total, row) => total + row.totalSakit,
    );

    final int totalAlpa = rekapList.fold(
      0,
      (total, row) => total + row.totalAlpa,
    );

    final int totalAbsensi = totalHadir + totalIzin + totalSakit + totalAlpa;

    final double persentaseKehadiran = totalAbsensi == 0
        ? 0
        : (totalHadir / totalAbsensi) * 100;

    return AbsensiRekapSummary(
      jumlahSantri: jumlahSantri,
      jumlahPertemuan: jumlahPertemuan,
      totalHadir: totalHadir,
      persentaseKehadiran: persentaseKehadiran,
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat rekap absensi...',
            style: TextStyle(
              color: _textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Mohon tunggu sebentar.',
            style: TextStyle(color: _subtitleColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _primaryLightColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.assessment_outlined,
              color: _primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            config.emptyTitle,
            style: const TextStyle(
              color: _textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              config.emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _subtitleColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

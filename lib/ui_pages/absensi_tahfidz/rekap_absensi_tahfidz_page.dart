import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/absensi_tahfidz/absensi_tahfidz_rekap_model.dart';

import 'package:ptl_mobile/state_management/app_setting_provider.dart';
import 'package:ptl_mobile/state_management/absensi_tahfidz_rekap_provider.dart';

import 'package:ptl_mobile/services/tahfidz_rekap_pdf_service.dart';

import 'package:ptl_mobile/ui_pages/widget/absensi/rekap/absensi_rekap_page_config.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/rekap/absensi_rekap_page_template.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/rekap/absensi_rekap_row.dart';

class RekapAbsensiTahfidzPage extends StatefulWidget {
  /// ID program yang dipilih.
  final String programId;

  /// ID kelas pengajaran yang dipilih.
  final String kelasPengajaranId;

  const RekapAbsensiTahfidzPage({
    super.key,
    required this.programId,
    required this.kelasPengajaranId,
  });

  @override
  State<RekapAbsensiTahfidzPage> createState() =>
      _RekapAbsensiTahfidzPageState();
}

class _RekapAbsensiTahfidzPageState extends State<RekapAbsensiTahfidzPage> {
  late final AbsensiTahfidzRekapProvider _provider;

  String _selectedSemester = 'Semester Ganjil';

  DateTime _tanggalCetak = DateTime.now();

  bool _hasLoaded = false;
  bool _isExportingPdf = false;
  bool _rekapSudahDitampilkan = false;

  @override
  void initState() {
    super.initState();

    _provider = AbsensiTahfidzRekapProvider();

    // Inisialisasi scope rekap berdasarkan program dan kelas pengajaran.
    _provider.setProgramDanKelas(
      programId: widget.programId,
      kelasPengajaranId: widget.kelasPengajaranId,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPengajar();
    });
  }

  /// Memuat daftar pengajar sesuai program dan kelas pengajaran.
  Future<void> _loadPengajar() async {
    await _provider.loadPengajarByProgram(
      widget.programId,
      widget.kelasPengajaranId,
    );
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  /// Menghapus hasil rekap yang sedang ditampilkan.
  ///
  /// Dipanggil ketika filter pengajar, semester, atau tanggal berubah.
  void _invalidateRekap() {
    setState(() {
      _hasLoaded = false;
      _rekapSudahDitampilkan = false;
    });

    _provider.clearData();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AbsensiTahfidzRekapProvider>.value(
      value: _provider,
      child: Consumer<AbsensiTahfidzRekapProvider>(
        builder: (context, provider, child) {
          return AbsensiRekapPageTemplate(
            config: _config,

            // Data pengajar sudah dibatasi program dan kelas.
            pengajarList: provider.pengajarList,
            selectedPengajarId: provider.selectedPengajarId,
            namaPengajar: provider.namaPengajar,

            selectedSemester: _selectedSemester,

            dariTanggal: provider.dariTanggal,
            sampaiTanggal: provider.sampaiTanggal,
            tanggalCetak: _tanggalCetak,

            tanggalList: provider.tanggalList,

            rekapList: _mapRekapList(provider.rekapList, provider.tanggalList),

            isLoading: provider.isLoading,
            hasLoaded: _hasLoaded,
            isExportingPdf: _isExportingPdf,

            canExportPdf:
                _rekapSudahDitampilkan && provider.rekapList.isNotEmpty,

            errorMessage: provider.errorMessage,

            // Filter pengajar.
            onPengajarChanged: (value) {
              _provider.setPengajar(value);
              _invalidateRekap();
            },

            // Filter semester.
            onSemesterChanged: (value) {
              setState(() {
                _selectedSemester = value;
              });

              _invalidateRekap();
            },

            // Filter tanggal awal.
            onDariTanggalChanged: (value) {
              _provider.setDariTanggal(value);
              _invalidateRekap();
            },

            // Filter tanggal akhir.
            onSampaiTanggalChanged: (value) {
              _provider.setSampaiTanggal(value);
              _invalidateRekap();
            },

            // Tanggal cetak PDF.
            onTanggalCetakChanged: (value) {
              setState(() {
                _tanggalCetak = value;
              });
            },

            onTampilkanRekap: _tampilkanRekap,
            onExportPdf: _showExportOptions,
          );
        },
      ),
    );
  }

  /// Konfigurasi tampilan halaman rekap.
  AbsensiRekapPageConfig get _config {
    return const AbsensiRekapPageConfig(
      pageTitle: 'Rekap Absensi Tahfidz',
      headerTitle: 'Laporan & Rekapitulasi',
      headerSubtitle:
          'Pantau rekapitulasi kehadiran santri Tahfidz berdasarkan pengajar dan rentang tanggal.',
      namaProgram: 'Tahfidz',
      bidang: 'Bidang Tahfidz',
      judulPdf: 'REKAP ABSENSI SANTRI TAHFIDZ',
      icon: Icons.menu_book_outlined,
      tableTitle: 'Rekap Kehadiran Santri Tahfidz',
    );
  }

  /// Mengubah model rekap menjadi row yang digunakan template.
  List<AbsensiRekapRow> _mapRekapList(
    List<AbsensiTahfidzRekapModel> source,
    List<DateTime> tanggalList,
  ) {
    return source.map((item) {
      final Map<String, String> statusByDate = {};

      for (final tanggal in tanggalList) {
        final key = _formatDateKey(tanggal);

        statusByDate[key] = item.statusPerTanggal[key] ?? '-';
      }

      return AbsensiRekapRow(
        namaSantri: item.namaSantri,
        statusByDate: statusByDate,
        totalHadir: item.totalHadir,
        totalIzin: item.totalIzin,
        totalSakit: item.totalSakit,
        totalAlpa: item.totalAlpa,
        persentaseKehadiran: item.persentaseKehadiran,
      );
    }).toList();
  }

  /// Menampilkan rekap sesuai filter yang dipilih.
  Future<void> _tampilkanRekap() async {
    FocusScope.of(context).unfocus();

    // Provider sudah menyimpan programId dan kelasPengajaranId.
    await _provider.loadRekap();

    if (!mounted) return;

    final berhasil = _provider.errorMessage == null;

    setState(() {
      _hasLoaded = true;
      _rekapSudahDitampilkan = berhasil;
    });

    if (!berhasil) {
      _showMessage(_provider.errorMessage!);
    }
  }

  /// Menampilkan pilihan jenis laporan PDF.
  Future<void> _showExportOptions() async {
    if (_isExportingPdf) return;

    if (!_rekapSudahDitampilkan || _provider.rekapList.isEmpty) {
      _showMessage('Tampilkan rekap terlebih dahulu sebelum mencetak PDF.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih Jenis Laporan',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const Divider(height: 1),

                ListTile(
                  leading: _buildExportIcon(Icons.calendar_view_day_outlined),
                  title: const Text('Laporan Kehadiran per Tanggal'),
                  subtitle: const Text(
                    'Menampilkan detail absensi setiap tanggal.',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _exportPerTanggal();
                  },
                ),

                ListTile(
                  leading: _buildExportIcon(Icons.table_chart_outlined),
                  title: const Text('Laporan Rekapitulasi'),
                  subtitle: const Text('Menampilkan rekap seluruh santri.'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _exportRekapitulasi();
                  },
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Icon untuk pilihan export PDF.
  Widget _buildExportIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE6F3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFF0D8B8B), size: 20),
    );
  }

  /// Export PDF rekapitulasi.
  Future<void> _exportRekapitulasi() async {
    if (_isExportingPdf) return;

    if (!_rekapSudahDitampilkan || _provider.rekapList.isEmpty) {
      _showMessage('Tampilkan rekap terlebih dahulu sebelum mencetak PDF.');
      return;
    }

    setState(() {
      _isExportingPdf = true;
    });

    try {
      final settingsProvider = context.read<AppSettingProvider>();

      final String? tahunAjaran = _getTahunAjaran(settingsProvider);

      final pdfData = await AbsensiTahfidzRekapPdfService.exportRekapitulasi(
        rekapList: _provider.rekapList,
        tanggalList: _provider.tanggalList,
        namaPengajar: _provider.namaPengajar,
        dariTanggal: _provider.dariTanggal,
        sampaiTanggal: _provider.sampaiTanggal,
        semester: _selectedSemester,
        tanggalCetak: _tanggalCetak,
        tahunAjaran: tahunAjaran,
      );

      await Printing.layoutPdf(onLayout: (_) async => pdfData);
    } catch (e) {
      _showMessage('Gagal membuat PDF: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  /// Export PDF detail absensi per tanggal.
  Future<void> _exportPerTanggal() async {
    if (_isExportingPdf) return;

    if (!_rekapSudahDitampilkan) {
      _showMessage('Tampilkan rekap terlebih dahulu sebelum mencetak PDF.');
      return;
    }

    setState(() {
      _isExportingPdf = true;
    });

    try {
      // Provider akan mengambil detail sesuai program,
      // kelas pengajaran, pengajar, dan rentang tanggal.
      final detail = await _provider.loadDetailAbsensi();

      if (!mounted) return;

      if (detail.isEmpty) {
        _showMessage('Tidak ada data absensi untuk dicetak.');
        return;
      }

      final settingsProvider = context.read<AppSettingProvider>();

      final String? tahunAjaran = _getTahunAjaran(settingsProvider);

      final pdfData = await AbsensiTahfidzRekapPdfService.exportPerTanggal(
        detailList: detail,
        namaPengajar: _provider.namaPengajar,
        dariTanggal: _provider.dariTanggal,
        sampaiTanggal: _provider.sampaiTanggal,
        semester: _selectedSemester,
        tanggalCetak: _tanggalCetak,
        tahunAjaran: tahunAjaran,
      );

      await Printing.layoutPdf(onLayout: (_) async => pdfData);
    } catch (e) {
      _showMessage('Gagal membuat PDF: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  /// Mengambil tahun ajaran dari AppSettingProvider.
  String? _getTahunAjaran(AppSettingProvider provider) {
    try {
      final dynamic value = provider.tahunAjaran;

      if (value == null) {
        return null;
      }

      return value.toString();
    } catch (_) {
      return null;
    }
  }

  /// Menampilkan pesan kepada pengguna.
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// Format tanggal untuk key status absensi.
  String _formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

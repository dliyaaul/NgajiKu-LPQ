import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/absensi_tarjamah/tarjamah_rekap_model.dart';

import 'package:ptl_mobile/state_management/absensi_tarjamah_rekap_provider.dart';
import 'package:ptl_mobile/state_management/app_setting_provider.dart';

import 'package:ptl_mobile/services/tarjamah_rekap_pdf_service.dart';

import 'package:ptl_mobile/ui_pages/widget/absensi/rekap/absensi_rekap_page_config.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/rekap/absensi_rekap_page_template.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/rekap/absensi_rekap_row.dart';

class AbsensiTarjamahRekapPage extends StatefulWidget {
  final String programId;
  final String kelasPengajaranId;

  const AbsensiTarjamahRekapPage({
    super.key,
    required this.programId,
    required this.kelasPengajaranId,
  });

  @override
  State<AbsensiTarjamahRekapPage> createState() =>
      _AbsensiTarjamahRekapPageState();
}

class _AbsensiTarjamahRekapPageState extends State<AbsensiTarjamahRekapPage> {
  late final AbsensiTarjamahRekapProvider _provider;

  String _selectedSemester = 'Semester Ganjil';

  DateTime _tanggalCetak = DateTime.now();

  bool _hasLoaded = false;
  bool _rekapSudahDitampilkan = false;
  bool _isExportingPdf = false;

  // ============================================================
  // INVALIDATE REKAP
  // ============================================================

  void _invalidateRekap() {
    setState(() {
      _hasLoaded = false;
      _rekapSudahDitampilkan = false;
    });

    _provider.clearData();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _provider = AbsensiTarjamahRekapProvider(
      kelasPengajaranId: widget.kelasPengajaranId,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // ============================================================
  // LOAD INITIAL DATA
  // ============================================================

  Future<void> _loadInitialData() async {
    await _provider.loadPengajarByProgram(widget.programId);

    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AbsensiTarjamahRekapProvider>.value(
      value: _provider,
      child: Consumer2<AbsensiTarjamahRekapProvider, AppSettingProvider>(
        builder: (context, provider, settingProvider, child) {
          return AbsensiRekapPageTemplate(
            config: _config,

            // ==================================================
            // PENGAJAR
            // ==================================================
            pengajarList: provider.pengajarList,

            selectedPengajarId: provider.selectedPengajarId,

            namaPengajar: provider.namaPengajar,

            // ==================================================
            // FILTER
            // ==================================================
            selectedSemester: _selectedSemester,

            dariTanggal: provider.dariTanggal,

            sampaiTanggal: provider.sampaiTanggal,

            tanggalCetak: _tanggalCetak,

            // ==================================================
            // DATA REKAP
            // ==================================================
            tanggalList: provider.tanggalList,

            rekapList: _mapRekapList(provider.rekapList, provider.tanggalList),

            // ==================================================
            // STATE
            // ==================================================
            isLoading: provider.isLoading,

            hasLoaded: _hasLoaded,

            isExportingPdf: _isExportingPdf,

            // PDF HANYA AKTIF APABILA REKAP
            // SUDAH BERHASIL DITAMPILKAN
            canExportPdf:
                _rekapSudahDitampilkan && provider.rekapList.isNotEmpty,

            errorMessage: provider.errorMessage,

            // ==================================================
            // FILTER CALLBACK
            // ==================================================
            onPengajarChanged: (value) {
              provider.setPengajar(value);
              _invalidateRekap();
            },

            onSemesterChanged: (value) {
              setState(() {
                _selectedSemester = value;
              });

              _invalidateRekap();
            },

            onDariTanggalChanged: (value) {
              provider.setDariTanggal(value);
              _invalidateRekap();
            },

            onSampaiTanggalChanged: (value) {
              provider.setSampaiTanggal(value);
              _invalidateRekap();
            },

            onTanggalCetakChanged: (value) {
              setState(() {
                _tanggalCetak = value;
              });
            },

            // ==================================================
            // ACTION
            // ==================================================
            onTampilkanRekap: _tampilkanRekap,

            onExportPdf: _showExportOptions,
          );
        },
      ),
    );
  }

  // ============================================================
  // CONFIG
  // ============================================================

  AbsensiRekapPageConfig get _config {
    return const AbsensiRekapPageConfig(
      pageTitle: 'Rekap Absensi Tarjamah',
      headerTitle: 'Laporan & Rekapitulasi',
      headerSubtitle:
          'Pantau rekapitulasi kehadiran santri Tarjamah berdasarkan pengajar dan rentang tanggal.',
      namaProgram: 'Tarjamah',
      bidang: 'Bidang Tarjamah',
      judulPdf: 'REKAP ABSENSI SANTRI TARJAMAH',
      icon: Icons.translate_outlined,
      tableTitle: 'Rekap Kehadiran Santri Tarjamah',
    );
  }

  // ============================================================
  // MAP MODEL TARJAMAH → SHARED ROW
  // ============================================================

  List<AbsensiRekapRow> _mapRekapList(
    List<TarjamahRekapModel> source,
    List<DateTime> tanggalList,
  ) {
    return source.map((item) {
      final statusByDate = <String, String>{};

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

  // ============================================================
  // TAMPILKAN REKAP
  // ============================================================

  Future<void> _tampilkanRekap() async {
    FocusScope.of(context).unfocus();

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

  // ============================================================
  // SHOW EXPORT OPTIONS (SAMAKAN DENGAN BBAQ)
  // ============================================================

  Future<void> _showExportOptions() async {
    if (_isExportingPdf) {
      return;
    }

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

                // ============================================
                // PER TANGGAL (RENTANG TANGGAL)
                // ============================================
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

                // ============================================
                // REKAPITULASI
                // ============================================
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

  // ============================================================
  // EXPORT ICON
  // ============================================================

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

  // ============================================================
  // EXPORT REKAPITULASI
  // ============================================================

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

      final String tahunAjaran = _getTahunAjaran(settingsProvider);

      final pdfData = await AbsensiTarjamahRekapPdfService.generateLaporanRekap(
        data: _provider.rekapList,
        tanggalList: _provider.tanggalList,
        dariTanggal: _provider.dariTanggal,
        sampaiTanggal: _provider.sampaiTanggal,
        tanggalCetak: _tanggalCetak,

        // =========================
        // IDENTITAS LAPORAN
        // =========================
        namaLembaga: 'Pesantren Al-Qur\'an Nurul Falah',

        bidangLembaga: 'Bidang Tarjamah',

        namaProgram: 'Tarjamah',

        // =========================
        // INFORMASI REKAP
        // =========================
        tahunAjaran: tahunAjaran,

        semester: _selectedSemester,

        namaPengajar: _provider.namaPengajar,
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

  // ============================================================
  // EXPORT PER TANGGAL (SEPANJANG RENTANG TANGGAL)
  // ============================================================

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
      final detail = await _provider.loadDetailAbsensi();

      if (!mounted) return;

      if (detail.isEmpty) {
        _showMessage('Tidak ada data absensi untuk dicetak.');
        return;
      }

      final settingsProvider = context.read<AppSettingProvider>();

      final String tahunAjaran = _getTahunAjaran(settingsProvider);

      final pdfData =
          await AbsensiTarjamahRekapPdfService.generateLaporanTanggal(
            data: detail,

            dariTanggal: _provider.dariTanggal,

            sampaiTanggal: _provider.sampaiTanggal,

            tanggalCetak: _tanggalCetak,

            // =========================
            // IDENTITAS LAPORAN
            // =========================
            namaLembaga: 'Pesantren Al-Qur\'an Nurul Falah',

            bidangLembaga: 'Bidang Tarjamah',

            namaProgram: 'Tarjamah',

            // =========================
            // INFORMASI REKAP
            // =========================
            tahunAjaran: tahunAjaran,

            semester: _selectedSemester,

            namaPengajar: _provider.namaPengajar,
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

  // ============================================================
  // TAHUN AJARAN
  // ============================================================

  String _getTahunAjaran(AppSettingProvider provider) {
    try {
      final dynamic value = provider.tahunAjaran;

      if (value == null) {
        return '';
      }

      return value.toString();
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ============================================================
  // FORMAT DATE KEY
  // ============================================================

  String _formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

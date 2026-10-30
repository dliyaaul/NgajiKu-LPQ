import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/absensi_tarjamah/tarjamah_pertemuan_model.dart';
import 'package:ptl_mobile/models/santri_program/santri_program_model.dart';
import 'package:ptl_mobile/services/tarjamah_pertemuan_service.dart';
import 'package:ptl_mobile/state_management/absensi_tarjamah_provider.dart';

import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_page_config.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_page_template.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_pertemuan_item.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_santri_item.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_summary.dart';

class AbsensiTarjamahDetailPage extends StatefulWidget {
  final String programId;
  final String pertemuanId;

  const AbsensiTarjamahDetailPage({
    super.key,
    required this.programId,
    required this.pertemuanId,
  });

  @override
  State<AbsensiTarjamahDetailPage> createState() =>
      _AbsensiTarjamahDetailPageState();
}

class _AbsensiTarjamahDetailPageState extends State<AbsensiTarjamahDetailPage> {
  // ============================================================
  // CONFIG
  // ============================================================

  static const AbsensiDetailPageConfig _config = AbsensiDetailPageConfig(
    title: 'Absensi Tarjamah',
    pertemuanTitle: 'Pertemuan Tarjamah',
    searchHint: 'Cari nama santri...',
    pertemuanIcon: Icons.menu_book_rounded,
    saveButtonLabel: 'Simpan Absensi',
    savingButtonLabel: 'Menyimpan...',
    emptySantriTitle: 'Belum ada santri pada kelas ini.',
    emptySantriDescription:
        'Belum ada santri yang terdaftar pada Kelas Pengajaran pertemuan ini.',
    filteredSantriTitle: 'Santri tidak ditemukan',
    errorTitle: 'Gagal Memuat Absensi Tarjamah',
  );

  // ============================================================
  // STATE
  // ============================================================

  TarjamahPertemuanModel? _pertemuan;

  bool _isLoadingPertemuan = true;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoadingPertemuan = true;
      });
    }

    try {
      final service = TarjamahPertemuanService();

      final pertemuan = await service.getPertemuanById(widget.pertemuanId);

      if (!mounted) return;

      setState(() {
        _pertemuan = pertemuan;
        _isLoadingPertemuan = false;
      });

      await context.read<AbsensiTarjamahProvider>().loadData(
        programId: widget.programId,
        pertemuanId: widget.pertemuanId,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingPertemuan = false;
      });

      _showMessage(
        'Gagal memuat data: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveAbsensi() async {
    final pertemuan = _pertemuan;

    if (pertemuan == null) {
      _showMessage('Data pertemuan tidak ditemukan.');
      return;
    }

    final provider = context.read<AbsensiTarjamahProvider>();

    if (!provider.canInputAttendance) {
      _showMessage(
        'Waktu pengisian absensi telah berakhir. '
        'Absensi hanya dapat diisi maksimal 1 hari '
        'sejak pertemuan dibuat.',
      );
      return;
    }

    if (provider.isSaving) {
      return;
    }

    final success = await provider.saveAll();

    if (!mounted) return;

    if (success) {
      _showMessage('Absensi Tarjamah berhasil disimpan.', isError: false);
    } else if (provider.errorMessage != null) {
      _showMessage(provider.errorMessage!);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: isError ? _config.alpaColor : _config.primaryColor,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<AbsensiTarjamahProvider>(
      builder: (context, provider, child) {
        final pertemuan = _pertemuan;

        if (pertemuan == null) {
          return AbsensiDetailPageTemplate(
            config: _config,
            pertemuan: _buildEmptyPertemuan(),
            santri: const [],
            summary: const AbsensiDetailSummary(),
            isLoading: _isLoadingPertemuan || provider.isLoading,
            isSaving: provider.isSaving,
            errorMessage: provider.errorMessage,
            canInputAttendance: false,
            getStatus: (_) => 'Alpa',
            onChangeStatus: ({required santriId, required status}) {},
            onSave: null,
            onRefresh: _loadData,
            onRetry: _loadData,
          );
        }

        return AbsensiDetailPageTemplate(
          config: _config,

          // ======================================================
          // PERTEMUAN
          // ======================================================
          pertemuan: _mapPertemuan(pertemuan),

          // ======================================================
          // SANTRI
          // ======================================================
          santri: provider.santri.map(_mapSantri).toList(),

          // ======================================================
          // SUMMARY
          // ======================================================
          summary: AbsensiDetailSummary(
            hadir: provider.jumlahHadir,
            izin: provider.jumlahIzin,
            sakit: provider.jumlahSakit,
            alpa: provider.jumlahAlpa,
          ),

          // ======================================================
          // STATE
          // ======================================================
          isLoading: _isLoadingPertemuan || provider.isLoading,

          isSaving: provider.isSaving,

          errorMessage: provider.errorMessage,

          canInputAttendance: provider.canInputAttendance,

          // ======================================================
          // STATUS
          // ======================================================
          getStatus: provider.getStatus,

          onChangeStatus: ({required santriId, required status}) {
            provider.changeStatus(santriProgramId: santriId, status: status);
          },

          // ======================================================
          // ACTION
          // ======================================================
          onSave: _saveAbsensi,

          onRefresh: _loadData,

          onRetry: _loadData,
        );
      },
    );
  }

  // ============================================================
  // MAPPING PERTEMUAN
  // ============================================================

  AbsensiDetailPertemuanItem _mapPertemuan(TarjamahPertemuanModel pertemuan) {
    return AbsensiDetailPertemuanItem(
      id: pertemuan.id,
      tanggal: pertemuan.tanggal,
      // Pengajar utama.
      pengajar: pertemuan.namaPengajar ?? 'Belum dipilih',
      // Pengganti hanya diisi jika memang ada.
      pengganti: pertemuan.hasPengganti
          ? pertemuan.namaPengajarPengganti
          : null,
      hasPengganti: pertemuan.hasPengganti,
      metode: pertemuan.metode,
      materi: pertemuan.materiPembelajaran,
      createdAt: pertemuan.createdAt,
    );
  }

  // ============================================================
  // MAPPING SANTRI
  // ============================================================

  AbsensiDetailSantriItem _mapSantri(SantriProgramModel santriProgram) {
    return AbsensiDetailSantriItem(
      id: santriProgram.id,
      nama: _getNamaSantri(santriProgram),
    );
  }

  // ============================================================
  // EMPTY PERTEMUAN
  // ============================================================

  AbsensiDetailPertemuanItem _buildEmptyPertemuan() {
    final now = DateTime.now();

    return AbsensiDetailPertemuanItem(
      id: widget.pertemuanId,
      tanggal: now,
      pengajar: '-',
      metode: '-',
      createdAt: now,
    );
  }

  // ============================================================
  // SANTRI HELPER
  // ============================================================

  String _getNamaSantri(SantriProgramModel santriProgram) {
    final username = santriProgram.santri?.username;

    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }

    return 'Tanpa Nama';
  }
}

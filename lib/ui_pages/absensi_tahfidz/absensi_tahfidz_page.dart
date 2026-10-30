import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/absensi_tahfidz/tahfidz_pertemuan_model.dart';

import 'package:ptl_mobile/state_management/loading_provider.dart';
import 'package:ptl_mobile/state_management/santri_program_provider.dart';
import 'package:ptl_mobile/state_management/tahfidz_pertemuan_provider.dart';

import 'package:ptl_mobile/ui_pages/absensi_tahfidz/absensi_tahfidz_detail_page.dart';
import 'package:ptl_mobile/ui_pages/absensi_tahfidz/rekap_absensi_tahfidz_page.dart';
import 'package:ptl_mobile/ui_pages/absensi_tahfidz/tahfidz_pertemuan_form_page.dart';

import 'package:ptl_mobile/ui_pages/widget/absensi/absensi_page_template.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/absensi_page_config.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/absensi_pertemuan_item.dart';

class AbsensiTahfidzPage extends StatefulWidget {
  /// ID program Tahfidz.
  final String programId;

  /// ID kelas pengajaran yang dipilih.
  final String kelasPengajaranId;

  const AbsensiTahfidzPage({
    super.key,
    required this.programId,
    required this.kelasPengajaranId,
  });

  @override
  State<AbsensiTahfidzPage> createState() => _AbsensiTahfidzPageState();
}

class _AbsensiTahfidzPageState extends State<AbsensiTahfidzPage> {
  // ============================================================
  // PROVIDER
  // ============================================================

  late final TahfidzPertemuanProvider _provider;

  late final SantriProgramProvider _santriProgramProvider;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _provider = TahfidzPertemuanProvider();

    _santriProgramProvider = SantriProgramProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadData();
    });
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    final loadingProvider = context.read<LoadingProvider>();

    await Future.wait([
      // Memuat pertemuan sesuai program dan kelas pengajaran.
      _provider.loadData(
        programId: widget.programId,
        kelasPengajaranId: widget.kelasPengajaranId,
      ),

      // Memuat santri sesuai program dan kelas pengajaran.
      _santriProgramProvider.loadByProgramAndKelasPengajaran(
        programId: widget.programId,
        kelasPengajaranId: widget.kelasPengajaranId,
        loadingProvider: loadingProvider,
      ),
    ]);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _provider.dispose();

    _santriProgramProvider.dispose();

    super.dispose();
  }

  // ============================================================
  // TOTAL SANTRI
  // ============================================================

  int get _totalSantri {
    return _santriProgramProvider.items
        .map((item) => item.santriId)
        .toSet()
        .length;
  }

  // ============================================================
  // CREATE PERTEMUAN
  // ============================================================

  Future<void> _openCreatePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TahfidzPertemuanFormPage(
          programId: widget.programId,
          kelasPengajaranId: widget.kelasPengajaranId,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  // ============================================================
  // DETAIL / ABSENSI
  // ============================================================

  Future<void> _openDetail(TahfidzPertemuanModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AbsensiTahfidzDetailPage(
          programId: widget.programId,
          kelasPengajaranId: widget.kelasPengajaranId,
          pertemuanId: item.id,
          tanggalPertemuan: item.tanggal,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  // ============================================================
  // EDIT PERTEMUAN
  // ============================================================

  Future<void> _editPertemuan(TahfidzPertemuanModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TahfidzPertemuanFormPage(
          programId: widget.programId,
          kelasPengajaranId: widget.kelasPengajaranId,
          pertemuan: item,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  // ============================================================
  // DELETE PERTEMUAN
  // ============================================================

  Future<void> _deletePertemuan(TahfidzPertemuanModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Hapus Pertemuan'),
          content: const Text(
            'Apakah Anda yakin ingin '
            'menghapus pertemuan Tahfidz ini?\n\n'
            'Data absensi pada pertemuan '
            'tersebut juga akan ikut terhapus.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await _provider.deletePertemuan(item);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Pertemuan berhasil dihapus.'
                : (_provider.error ?? 'Gagal menghapus pertemuan.'),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  // ============================================================
  // REKAP ABSENSI
  // ============================================================

  void _openRekap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RekapAbsensiTahfidzPage(
          // Parameter program.
          programId: widget.programId,

          // Parameter kelas pengajaran.
          kelasPengajaranId: widget.kelasPengajaranId,
        ),
      ),
    );
  }

  // ============================================================
  // PAGE CONFIG
  // ============================================================

  AbsensiPageConfig get _config {
    return const AbsensiPageConfig(
      title: 'Absensi Tahfidz',
      subtitle: 'Daftar Pertemuan Tahfidz',
      primaryColor: Color(0xFF0D8B8B),
      backgroundColor: Color(0xFFF8FAFA),
      primaryLight: Color(0xFFE6F4F4),
      textColor: Color(0xFF263238),
      subtitleColor: Color(0xFF607D8B),
      searchHint: 'Cari tanggal, pengajar, materi...',
      emptyTitle: 'Belum Ada Pertemuan',
      emptyDescription:
          'Buat pertemuan Tahfidz pertama '
          'untuk mulai mencatat absensi.',
      filteredEmptyTitle: 'Pertemuan Tidak Ditemukan',
      filteredEmptyDescription:
          'Tidak ada pertemuan Tahfidz yang '
          'sesuai dengan pencarian atau filter.',
      addButtonLabel: 'Pertemuan Baru',
      addButtonIcon: Icons.add_rounded,
      emptyIcon: Icons.event_note_outlined,
      showAddButton: true,
    );
  }

  // ============================================================
  // MAPPING MODEL
  // ============================================================

  List<AbsensiPertemuanItem> _buildItems(TahfidzPertemuanProvider provider) {
    return provider.pertemuan.map((item) {
      final canEdit = provider.canEdit(item);

      final canDelete = provider.canDelete(item);

      // Batas input absensi:
      // 24 jam sejak pertemuan dibuat.
      final batasWaktu = item.createdAt.toLocal().add(
        const Duration(hours: 24),
      );

      final canInputAttendance = DateTime.now().isBefore(batasWaktu);

      return AbsensiPertemuanItem(
        id: item.id,

        tanggal: item.tanggal,

        pengajarId: item.pengajarId,

        pengajar: item.namaPengajar ?? 'Pengajar Belum Set',

        materi: item.materiPembelajaran,

        // Metode Tahfidz ditampilkan sebagai PBM.
        pbm: item.metode,

        pengganti: item.namaPenggantiPengajar,

        hasPengganti: item.menggunakanPengganti,

        createdAt: item.createdAt,

        batasWaktu: batasWaktu,

        canInputAttendance: canInputAttendance,

        canEdit: canEdit,

        // Tidak ada lagi Jam Mulai.
        additionalInfo: const [],

        // ======================================================
        // ACTION
        // ======================================================
        onOpen: () {
          _openDetail(item);
        },

        onEdit: canEdit
            ? () {
                _editPertemuan(item);
              }
            : null,

        onDelete: canDelete
            ? () {
                _deletePertemuan(item);
              }
            : null,
      );
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _provider),
        ChangeNotifierProvider.value(value: _santriProgramProvider),
      ],
      child: Consumer2<TahfidzPertemuanProvider, SantriProgramProvider>(
        builder: (context, provider, santriProvider, child) {
          final items = _buildItems(provider);

          return AbsensiPageTemplate(
            config: _config,

            items: items,

            isLoading: provider.isLoading,

            errorMessage: provider.error,

            // ==================================================
            // TOTAL SANTRI
            // ==================================================
            totalSantri: _totalSantri,

            // ==================================================
            // REFRESH
            // ==================================================
            onRefresh: () async {
              await _loadData();
            },

            // ==================================================
            // ADD
            // ==================================================
            onAdd: provider.isSaving ? null : _openCreatePage,

            // ==================================================
            // RETRY
            // ==================================================
            onRetry: () {
              _loadData();
            },

            // ==================================================
            // APP BAR ACTION
            // ==================================================
            appBarActions: [
              IconButton(
                tooltip: 'Rekap Absensi',
                onPressed: _openRekap,
                icon: const Icon(Icons.bar_chart_rounded),
              ),
            ],
          );
        },
      ),
    );
  }
}

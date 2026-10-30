import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/absensi_tarjamah/tarjamah_pertemuan_model.dart';

import 'package:ptl_mobile/state_management/loading_provider.dart';
import 'package:ptl_mobile/state_management/pengajar_pengganti_provider.dart';
import 'package:ptl_mobile/state_management/santri_program_provider.dart';
import 'package:ptl_mobile/state_management/tarjamah_pertemuan_provider.dart';

import 'package:ptl_mobile/ui_pages/absensi_tarjamah/absensi_tarjamah_detail_page.dart';
import 'package:ptl_mobile/ui_pages/absensi_tarjamah/absensi_tarjamah_rekap_page.dart';
import 'package:ptl_mobile/ui_pages/absensi_tarjamah/tarjamah_pertemuan_form_page.dart';

import 'package:ptl_mobile/ui_pages/widget/absensi/absensi_page_template.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/absensi_page_config.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/absensi_pertemuan_item.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _backgroundColor = Color(0xFFF4F6F8);
const Color _textColor = Color(0xFF263238);
const Color _secondaryTextColor = Color(0xFF607D8B);

class AbsensiTarjamahPage extends StatefulWidget {
  final String programId;
  final String kelasPengajaranId;

  const AbsensiTarjamahPage({
    super.key,
    required this.programId,
    required this.kelasPengajaranId,
  });

  @override
  State<AbsensiTarjamahPage> createState() => _AbsensiTarjamahPageState();
}

class _AbsensiTarjamahPageState extends State<AbsensiTarjamahPage> {
  // ============================================================
  // PROVIDER
  // ============================================================

  late final TarjamahPertemuanProvider _provider;
  late final SantriProgramProvider _santriProgramProvider;
  late final PengajarPenggantiProvider _pengajarPenggantiProvider;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _provider = TarjamahPertemuanProvider();
    _santriProgramProvider = SantriProgramProvider();
    _pengajarPenggantiProvider = PengajarPenggantiProvider();

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
      _provider.loadData(programId: widget.programId),
      _santriProgramProvider.loadByProgram(widget.programId, loadingProvider),
      _pengajarPenggantiProvider.loadAll(hanyaAktif: true),
    ]);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _provider.dispose();
    _santriProgramProvider.dispose();
    _pengajarPenggantiProvider.dispose();
    super.dispose();
  }

  // ============================================================
  // TOTAL SANTRI
  // ============================================================

  int get _totalSantri {
    return _santriProgramProvider.items
        .where((item) => item.kelasPengajaranId == widget.kelasPengajaranId)
        .map((item) => item.santriId)
        .toSet()
        .length;
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<void> _openCreatePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TarjamahPertemuanFormPage(
          programId: widget.programId,
          initialKelasPengajaranId: widget.kelasPengajaranId,
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

  Future<void> _openDetail(TarjamahPertemuanModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AbsensiTarjamahDetailPage(
          programId: widget.programId,
          pertemuanId: item.id,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _editPertemuan(TarjamahPertemuanModel item) async {
    if (!item.canEdit) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pertemuan sudah lebih dari 24 jam dan tidak dapat diedit.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TarjamahPertemuanFormPage(
          programId: widget.programId,
          pertemuan: item,
          initialKelasPengajaranId: widget.kelasPengajaranId,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deletePertemuan(TarjamahPertemuanModel item) async {
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
            'menghapus pertemuan Tarjamah ini?\n\n'
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

    try {
      await _provider.deletePertemuan(item.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pertemuan berhasil dihapus.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _primaryColor,
          ),
        );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus pertemuan: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // ============================================================
  // REKAP
  // ============================================================

  void _openRekap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AbsensiTarjamahRekapPage(
          programId: widget.programId,
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
      title: 'Absensi Tarjamah',
      subtitle: 'Daftar Pertemuan Tarjamah',
      primaryColor: _primaryColor,
      backgroundColor: _backgroundColor,
      primaryLight: Color(0xFFE6F5F5),
      textColor: _textColor,
      subtitleColor: _secondaryTextColor,
      searchHint: 'Cari tanggal, pengajar, materi...',
      emptyTitle: 'Belum Ada Pertemuan',
      emptyDescription:
          'Buat pertemuan Tarjamah pertama '
          'untuk mulai mencatat absensi.',
      filteredEmptyTitle: 'Pertemuan Tidak Ditemukan',
      filteredEmptyDescription:
          'Tidak ada pertemuan Tarjamah yang '
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

  List<AbsensiPertemuanItem> _buildItems(TarjamahPertemuanProvider provider) {
    // Data provider masih mengambil seluruh pertemuan program.
    // Halaman ini hanya menampilkan pertemuan milik kelas terpilih.
    final pertemuanKelas = provider.pertemuan
        .where((item) => item.kelasPengajaranId == widget.kelasPengajaranId)
        .toList();

    return pertemuanKelas.map((item) {
      // Batas input/edit:
      // 24 jam sejak pertemuan dibuat.
      final batasWaktu = item.createdAt.toLocal().add(
        const Duration(hours: 24),
      );

      final canInputAttendance = DateTime.now().isBefore(batasWaktu);

      return AbsensiPertemuanItem(
        // ======================================================
        // IDENTITAS
        // ======================================================
        id: item.id,

        tanggal: item.tanggal,

        pengajarId: item.pengajarId,

        pengajar: item.namaPengajarAktif,

        // ======================================================
        // INFORMASI PERTEMUAN
        // ======================================================
        materi: item.materiPembelajaran,

        // Metode Tarjamah ditampilkan sebagai PBM.
        pbm: item.metode,

        pengganti: item.namaPengajarPengganti,

        hasPengganti: item.hasPengganti,

        // ======================================================
        // BATAS WAKTU
        // ======================================================
        createdAt: item.createdAt,

        batasWaktu: batasWaktu,

        // ======================================================
        // PERMISSION
        // ======================================================
        canInputAttendance: canInputAttendance,

        canEdit: item.canEdit,

        // ======================================================
        // ACTION
        // ======================================================
        onOpen: () {
          _openDetail(item);
        },

        onEdit: item.canEdit
            ? () {
                _editPertemuan(item);
              }
            : null,

        onDelete: item.canEdit
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
        ChangeNotifierProvider.value(value: _pengajarPenggantiProvider),
      ],
      child: Consumer2<TarjamahPertemuanProvider, SantriProgramProvider>(
        builder: (context, provider, santriProvider, child) {
          final items = _buildItems(provider);

          return AbsensiPageTemplate(
            config: _config,

            // ==================================================
            // ITEMS
            // ==================================================
            items: items,

            // ==================================================
            // LOADING
            // ==================================================
            isLoading: provider.isLoading,

            errorMessage: provider.errorMessage,

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
            onAdd: _openCreatePage,

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

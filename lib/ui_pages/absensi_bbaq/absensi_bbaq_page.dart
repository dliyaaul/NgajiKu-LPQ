import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/models/kelas/kelas_pengajaran_model.dart';
import 'package:ptl_mobile/services/kelas_pengajaran_service.dart';

import 'package:ptl_mobile/models/absensi_bbaq/bbaq_pertemuan_model.dart';
import 'package:ptl_mobile/state_management/absensi_bbaq_provider.dart';

import 'package:ptl_mobile/ui_pages/absensi_bbaq/absensi_bbaq_detail_page.dart';
import 'package:ptl_mobile/ui_pages/absensi_bbaq/bbaq_pertemuan_form_page.dart';
import 'package:ptl_mobile/ui_pages/absensi_bbaq/rekap_absensi_bbaq_page.dart';

import 'package:ptl_mobile/ui_pages/widget/absensi/absensi_page_template.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/absensi_page_config.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/absensi_pertemuan_item.dart';
import 'package:ptl_mobile/services/attendance_web_handoff_service.dart';

// Palet Warna Tema Aplikasi (Teal Modern)
const Color _primaryColor = Color(0xFF0D8B8B);
const Color _primaryDark = Color(0xFF085D5D);
const Color _primaryLight = Color(0xFFE6F5F5);
const Color _backgroundColor = Color(0xFFF8FAFC);
const Color _textColor = Color(0xFF1E293B);
const Color _secondaryTextColor = Color(0xFF64748B);

class AbsensiBbaqPage extends StatefulWidget {
  final String programId;

  const AbsensiBbaqPage({super.key, required this.programId});

  @override
  State<AbsensiBbaqPage> createState() => _AbsensiBbaqPageState();
}

class _AbsensiBbaqPageState extends State<AbsensiBbaqPage> {
  final KelasPengajaranService _kelasService = KelasPengajaranService();
  List<KelasPengajaranModel> _kelas = [];
  final Map<String, int> _jumlahSantri = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKelas();
  }

  Future<void> _loadKelas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final kelas = await _kelasService.getByProgram(widget.programId);
      final counts = <String, int>{};
      for (final item in kelas) {
        try {
          final rows = await Supabase.instance.client
              .from('santri_programs')
              .select('id')
              .eq('program_id', widget.programId)
              .eq('kelas_pengajaran_id', item.id);
          counts[item.id] = (rows as List).length;
        } catch (_) {
          counts[item.id] = 0;
        }
      }
      if (!mounted) return;
      setState(() {
        _kelas = kelas;
        _jumlahSantri
          ..clear()
          ..addAll(counts);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openKelas(KelasPengajaranModel kelas) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AbsensiBbaqKelasPertemuanPage(
          programId: widget.programId,
          kelasPengajaranId: kelas.id,
          namaKelas: kelas.namaKelas,
        ),
      ),
    );
    if (mounted) await _loadKelas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Absensi BBAQ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Muat ulang kelas',
              onPressed: _isLoading ? null : _loadKelas,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primaryColor,
        backgroundColor: Colors.white,
        onRefresh: _loadKelas,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _secondaryTextColor),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadKelas,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_kelas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: _primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.class_outlined,
                    size: 48,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Belum Ada Kelas Pengajaran',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Buat kelas pengajaran terlebih dahulu untuk mulai mengelola pertemuan dan absensi BBAQ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _secondaryTextColor, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Modern Banner Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryColor, _primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pilih Kelas Pengajaran',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Buka kelas di bawah untuk melihat, mengedit, dan mencatat absensi pertemuan santri.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ..._kelas.map((kelas) {
          final jenis = kelas.namaJenisKelas;
          final pengajar = kelas.namaPengajar;
          final aktif = kelas.aktif;
          final jumlahSantri = _jumlahSantri[kelas.id] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 0,
              child: InkWell(
                onTap: () => _openKelas(kelas),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade200.withOpacity(0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: _primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    kelas.namaKelas,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: _textColor,
                                    ),
                                  ),
                                ),
                                if (!aktif)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Nonaktif',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (jenis != null && jenis.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                jenis,
                                style: const TextStyle(
                                  color: _secondaryTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                _ClassInfoChip(
                                  icon: Icons.people_alt_outlined,
                                  label: '$jumlahSantri santri',
                                ),
                                _ClassInfoChip(
                                  icon: Icons.person_outline_rounded,
                                  label: (pengajar == null || pengajar.isEmpty)
                                      ? 'Belum ada pengajar'
                                      : pengajar,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: _primaryColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ClassInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ClassInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _secondaryTextColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AbsensiBbaqKelasPertemuanPage extends StatefulWidget {
  final String programId;
  final String kelasPengajaranId;
  final String namaKelas;

  const AbsensiBbaqKelasPertemuanPage({
    super.key,
    required this.programId,
    required this.kelasPengajaranId,
    required this.namaKelas,
  });

  @override
  State<AbsensiBbaqKelasPertemuanPage> createState() =>
      _AbsensiBbaqKelasPertemuanPageState();
}

class _AbsensiBbaqKelasPertemuanPageState
    extends State<AbsensiBbaqKelasPertemuanPage> {
  final AttendanceWebHandoffService _webHandoff = AttendanceWebHandoffService();
  late final BbaqPertemuanProvider _provider;
  int _totalSantriKelas = 0;

  final AbsensiPageConfig _pageConfig = const AbsensiPageConfig(
    title: 'Pertemuan BBAQ',
    subtitle: 'Kelola pertemuan dan presensi kelas',
    primaryColor: _primaryColor,
    backgroundColor: _backgroundColor,
    primaryLight: _primaryLight,
    textColor: _textColor,
    subtitleColor: _secondaryTextColor,
    searchHint: 'Cari tanggal, pengajar, materi...',
    emptyTitle: 'Belum Ada Pertemuan',
    emptyDescription:
        'Belum ada pertemuan untuk kelas pengajaran yang dipilih.',
    filteredEmptyTitle: 'Tidak Ada Pertemuan Ditemukan',
    filteredEmptyDescription:
        'Tidak ada data pertemuan yang sesuai dengan pencarian atau filter.',
    addButtonLabel: 'Pertemuan Baru',
    addButtonIcon: Icons.add_rounded,
    emptyIcon: Icons.event_note_rounded,
    showAddButton: true,
  );

  @override
  void initState() {
    super.initState();
    _provider = BbaqPertemuanProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await _loadKelasData(widget.kelasPengajaranId);
  }

  Future<void> _loadKelasData(String kelasId) async {
    await _provider.loadData(
      programId: widget.programId,
      kelasPengajaranId: kelasId,
    );
    await _loadSantriCount(kelasId);
  }

  Future<void> _loadSantriCount(String kelasId) async {
    try {
      final response = await Supabase.instance.client
          .from('santri_programs')
          .select('id')
          .eq('program_id', widget.programId)
          .eq('kelas_pengajaran_id', kelasId);

      if (!mounted) return;
      setState(() => _totalSantriKelas = (response as List).length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _totalSantriKelas = 0);
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<BbaqPertemuanProvider>(
        builder: (context, provider, child) {
          final items = _buildItems(context, provider.pertemuan);

          return AbsensiPageTemplate(
            config: _pageConfig,
            items: items,
            totalSantri: _totalSantriKelas,
            additionalHeader: _buildKelasHeader(),
            isLoading: provider.isLoading,
            errorMessage: provider.errorMessage,
            appBarActions: [
              IconButton(
                tooltip: 'Rekap Absensi',
                onPressed: _openRekap,
                icon: const Icon(Icons.bar_chart_rounded),
              ),
            ],
            onRefresh: () async {
              await provider.refresh();
              await _loadSantriCount(widget.kelasPengajaranId);
            },
            onRetry: () async {
              await _loadData();
            },
            onAdd: _handleAddPertemuan,
          );
        },
      ),
    );
  }

  Widget _buildKelasHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueGrey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.groups_2_rounded,
                color: _primaryColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.namaKelas,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 14,
                        color: _secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_totalSantriKelas santri terdaftar',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AbsensiPertemuanItem> _buildItems(
    BuildContext context,
    List<BbaqPertemuanModel> pertemuan,
  ) {
    return pertemuan.map((item) {
      return AbsensiPertemuanItem(
        id: item.id,
        tanggal: item.tanggal,
        pengajarId: item.pengajarId,
        pengajar: item.namaPengajar ?? 'Pengajar belum tersedia',
        materi: item.materiPembelajaran,
        pbm: item.metode,
        pengganti: item.namaPenggantiPengajar,
        hasPengganti: item.penggantiPengajarId != null,
        createdAt: item.createdAt,
        batasWaktu: item.batasAbsensi,
        canEdit: item.canEdit,
        canInputAttendance: item.canInputAbsensi,
        // Tetap menggunakan navigasi absensi yang lama.
        onOpen: () => _openAbsensi(item),
        // Akan dihubungkan ke browser pada tahap berikutnya.
        onOpenWeb: () => _openAbsensiWeb(item),
        onEdit: () => _editPertemuan(item),
        onDelete: () => _deletePertemuan(item),
      );
    }).toList();
  }

  Future<void> _openAbsensi(BbaqPertemuanModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AbsensiBbaqDetailPage(programId: widget.programId, pertemuan: item),
      ),
    );

    if (result == true && mounted) {
      await _provider.refresh();
    }
  }

  Future<void> _editPertemuan(BbaqPertemuanModel item) async {
    if (!item.canEdit) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pertemuan sudah lebih dari 24 jam dan tidak dapat diedit.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BbaqPertemuanFormPage(programId: widget.programId, pertemuan: item),
      ),
    );

    if (result == true && mounted) {
      await _provider.refresh();
    }
  }

  Future<void> _deletePertemuan(BbaqPertemuanModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Hapus Pertemuan?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Pertemuan tanggal ${_formatTanggal(item.tanggal)} beserta data absensi santri di dalamnya akan dihapus secara permanen.',
            style: const TextStyle(color: _textColor, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: TextButton.styleFrom(foregroundColor: _secondaryTextColor),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pertemuan berhasil dihapus.'),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus pertemuan: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _handleAddPertemuan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BbaqPertemuanFormPage(
          programId: widget.programId,
          initialKelasPengajaranId: widget.kelasPengajaranId,
        ),
      ),
    );

    if (result == true && mounted) {
      await _provider.refresh();
    }
  }

  void _openRekap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RekapAbsensiBbaqPage(
          programId: widget.programId,
          kelasPengajaranId: widget.kelasPengajaranId,
        ),
      ),
    );
  }

  String _formatTanggal(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  Future<void> _openAbsensiWeb(BbaqPertemuanModel item) async {
    try {
      await _webHandoff.openAttendanceWeb(pertemuanId: item.id);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuka absensi Web: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:ptl_mobile/models/absensi_bbaq/bbaq_pertemuan_model.dart';
import 'package:ptl_mobile/services/absensi_bbaq_detail_service.dart';

import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_page_config.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_page_template.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_pertemuan_item.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_santri_item.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_summary.dart';

const Color _primaryColor = Color(0xFF0D8B8B);

class AbsensiBbaqDetailPage extends StatefulWidget {
  final String programId;
  final BbaqPertemuanModel pertemuan;

  const AbsensiBbaqDetailPage({
    super.key,
    required this.programId,
    required this.pertemuan,
  });

  @override
  State<AbsensiBbaqDetailPage> createState() => _AbsensiBbaqDetailPageState();
}

class _AbsensiBbaqDetailPageState extends State<AbsensiBbaqDetailPage> {
  final AbsensiBbaqDetailService _service = AbsensiBbaqDetailService();

  String _selectedFilter = 'Semua';

  List<Map<String, dynamic>> _santri = [];

  Map<String, String> _status = {};

  bool _isLoading = true;
  bool _isSaving = false;

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final kelasPengajaranId = widget.pertemuan.kelasPengajaranId;
      if (kelasPengajaranId == null || kelasPengajaranId.trim().isEmpty) {
        throw Exception(
          'Pertemuan ini belum terhubung dengan Kelas Pengajaran. '
          'Hubungkan pertemuan ke kelas terlebih dahulu sebelum mengisi absensi.',
        );
      }

      final data = await _service.getDetailAbsensi(
        widget.pertemuan.id,
        widget.programId,
        kelasPengajaranId: kelasPengajaranId,
      );

      final Map<String, String> status = {};

      for (final item in data) {
        final santriProgramId = item['id'].toString();

        final absensi = item['absensi'];

        if (absensi is Map && absensi['status'] != null) {
          status[santriProgramId] = _normalizeStatus(
            absensi['status'].toString(),
          );
        } else {
          status[santriProgramId] = 'Belum Absen';
        }
      }

      if (!mounted) return;

      setState(() {
        _santri = data;
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _normalizeStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'hadir':
        return 'Hadir';

      case 'izin':
        return 'Izin';

      case 'sakit':
        return 'Sakit';

      case 'alpa':
      case 'alpha':
        return 'Alpa';

      default:
        return 'Belum Absen';
    }
  }

  void _changeStatus(String santriProgramId, String status) {
    if (!_canInputAbsensi) {
      _showMessage(
        'Batas waktu pengisian absensi sudah berakhir.',
        isError: true,
      );
      return;
    }

    setState(() {
      _status[santriProgramId] = status;
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveAbsensi() async {
    if (_isSaving) return;

    if (!_canInputAbsensi) {
      _showMessage(
        'Batas waktu pengisian absensi sudah berakhir.',
        isError: true,
      );
      return;
    }

    if (_status.isEmpty) {
      _showMessage('Tidak ada data santri untuk diproses.', isError: true);
      return;
    }

    final confirmed = await _showConfirmationDialog();

    if (!confirmed || !mounted) {
      return;
    }

    // Cek ulang setelah dialog ditutup.
    if (!_canInputAbsensi) {
      _showMessage(
        'Batas waktu pengisian absensi sudah berakhir.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data = <Map<String, dynamic>>[];

      for (final entry in _status.entries) {
        final santriProgramId = entry.key;
        final status = entry.value;

        // Sertakan status Belum Absen agar service dapat menghapus
        // absensi lama ketika pengguna memang mereset status santri.
        data.add({
          'bbaq_pertemuan_id': widget.pertemuan.id,
          'santri_program_id': santriProgramId,
          'status': status,
        });
      }

      await _service.saveAbsensiBatch(
        data,
        createdAt: widget.pertemuan.createdAt,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absensi BBAQ berhasil disimpan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  // ============================================================
  // CONFIRMATION
  // ============================================================

  Future<bool> _showConfirmationDialog() async {
    final jumlah = _status.values
        .where((status) => status != 'Belum Absen')
        .length;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text(
                'Simpan Absensi?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Text(
                'Apakah Anda yakin ingin menyimpan '
                '$jumlah data absensi BBAQ?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  // ============================================================
  // LOCK
  // ============================================================

  bool get _canInputAbsensi {
    // UI menggunakan timestamp pertemuan pada model untuk menampilkan
    // status batas waktu. Service tetap memvalidasi ulang dari database
    // sebelum melakukan penyimpanan.
    return widget.pertemuan.canInputAbsensi;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final santriItems = _santri.map((item) {
      final santriData = item['santri'];

      final nama = santriData is Map
          ? santriData['username']?.toString() ??
                santriData['email']?.toString() ??
                'Tanpa Nama'
          : 'Tanpa Nama';

      return AbsensiDetailSantriItem(id: item['id'].toString(), nama: nama);
    }).toList();

    return AbsensiDetailPageTemplate(
      config: _buildConfig(),

      pertemuan: _buildPertemuanItem(),

      santri: santriItems,

      isLoading: _isLoading,

      isSaving: _isSaving,

      errorMessage: _errorMessage,

      canInputAttendance: _canInputAbsensi,

      selectedFilter: _selectedFilter,

      onFilterChanged: (value) {
        setState(() {
          _selectedFilter = value;
        });
      },

      onRefresh: _refresh,

      onRetry: _loadData,

      onSave: _saveAbsensi,

      summary: _buildSummary(),

      getStatus: (santriId) {
        return _status[santriId] ?? 'Belum Absen';
      },

      onChangeStatus: ({required santriId, required status}) {
        _changeStatus(santriId, status);
      },

      santriItemBuilder: (context, santriItem, status) {
        return _buildBbaqSantriCard(santriItem, status);
      },
    );
  }

  // ============================================================
  // CONFIG
  // ============================================================

  AbsensiDetailPageConfig _buildConfig() {
    return const AbsensiDetailPageConfig(
      title: 'Absensi BBAQ',
      pertemuanTitle: 'Pertemuan BBAQ',
      searchHint: 'Cari nama santri...',
      pertemuanIcon: Icons.menu_book_rounded,
      saveButtonLabel: 'Simpan Absensi',
      savingButtonLabel: 'Menyimpan...',
      emptySantriTitle: 'Belum ada data santri',
      emptySantriDescription: 'Tidak terdapat santri yang dapat diabsen.',
    );
  }

  // ============================================================
  // PERTEMUAN
  // ============================================================

  AbsensiDetailPertemuanItem _buildPertemuanItem() {
    return AbsensiDetailPertemuanItem(
      id: widget.pertemuan.id,
      tanggal: widget.pertemuan.tanggal,
      pengajar: widget.pertemuan.namaPengajar ?? 'Pengajar',
      pengganti: widget.pertemuan.namaPenggantiPengajar,
      hasPengganti: widget.pertemuan.namaPenggantiPengajar != null,
      metode: widget.pertemuan.metode,
      materi: widget.pertemuan.materiPembelajaran,
      createdAt: widget.pertemuan.createdAt,

      // Batas input mengikuti aturan 24 jam sejak pertemuan dibuat.
      batasWaktuOverride: widget.pertemuan.batasAbsensi,
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  AbsensiDetailSummary _buildSummary() {
    int hadir = 0;
    int izin = 0;
    int sakit = 0;
    int alpa = 0;
    int belumAbsen = 0;

    for (final status in _status.values) {
      switch (_normalizeStatus(status)) {
        case 'Hadir':
          hadir++;
          break;

        case 'Izin':
          izin++;
          break;

        case 'Sakit':
          sakit++;
          break;

        case 'Alpa':
          alpa++;
          break;

        default:
          belumAbsen++;
          break;
      }
    }

    return AbsensiDetailSummary(
      hadir: hadir,
      izin: izin,
      sakit: sakit,
      alpa: alpa,
      belumAbsen: belumAbsen,
    );
  }

  // ============================================================
  // SANTRI CARD
  // ============================================================

  Widget _buildBbaqSantriCard(
    AbsensiDetailSantriItem santriItem,
    String status,
  ) {
    final normalizedStatus = _normalizeStatus(status);

    final canEdit = _canInputAbsensi && !_isSaving;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSantriHeader(santriItem.nama),

            const SizedBox(height: 14),

            AbsensiDetailPageTemplate.buildStatusSelector(
              santriId: santriItem.id,
              selectedStatus: normalizedStatus,
              isDisabled: !canEdit,
              onChangeStatus: ({required santriId, required status}) {
                _changeStatus(santriId, status);
              },
              config: const AbsensiDetailPageConfig(
                title: 'Absensi BBAQ',
                pertemuanTitle: 'Pertemuan BBAQ',
                primaryColor: _primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSantriHeader(String nama) {
    final initial = nama.trim().isEmpty
        ? '?'
        : nama.trim().substring(0, 1).toUpperCase();

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFCCFBF1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                'Pencatatan Kehadiran BBAQ',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

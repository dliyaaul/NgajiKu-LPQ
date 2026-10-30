import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/models/absensi_tahfidz/daftar_surat.dart';
import 'package:ptl_mobile/models/santri_program/santri_program_model.dart';
import 'package:ptl_mobile/state_management/absensi_tahfidz_provider.dart';

import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_page_config.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_page_template.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_pertemuan_item.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_santri_item.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/detail/absensi_detail_summary.dart';

class AbsensiTahfidzDetailPage extends StatefulWidget {
  final String programId;
  final String kelasPengajaranId;
  final String pertemuanId;
  final DateTime? tanggalPertemuan;

  const AbsensiTahfidzDetailPage({
    super.key,
    required this.programId,
    required this.kelasPengajaranId,
    required this.pertemuanId,
    this.tanggalPertemuan,
  });

  @override
  State<AbsensiTahfidzDetailPage> createState() =>
      _AbsensiTahfidzDetailPageState();
}

class _AbsensiTahfidzDetailPageState extends State<AbsensiTahfidzDetailPage> {
  String _selectedFilter = 'Semua';

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

    final provider = context.read<AbsensiTahfidzProvider>();

    await provider.loadAbsensi(
      programId: widget.programId,
      kelasPengajaranId: widget.kelasPengajaranId,
      pertemuanId: widget.pertemuanId,
      tanggalPertemuan: widget.tanggalPertemuan,
    );
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveAbsensi() async {
    final provider = context.read<AbsensiTahfidzProvider>();

    if (!provider.canInputAbsensi) {
      _showMessage(
        'Batas waktu pengisian absensi sudah berakhir.',
        isError: true,
      );
      return;
    }

    final validationError = provider.validateAll();

    if (validationError != null) {
      _showMessage(validationError, isError: true);
      return;
    }

    final confirmed = await _showConfirmationDialog();

    if (!confirmed || !mounted) {
      return;
    }

    // Cek ulang setelah dialog ditutup.
    if (!provider.canInputAbsensi) {
      _showMessage(
        'Batas waktu pengisian absensi sudah berakhir.',
        isError: true,
      );
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      _showMessage('Sesi pengguna tidak ditemukan.', isError: true);
      return;
    }

    final success = await provider.saveAll(createdBy: currentUser.id);

    if (!mounted) return;

    if (!success) {
      _showMessage(provider.error ?? 'Gagal menyimpan absensi.', isError: true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Absensi Tahfidz berhasil disimpan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  Future<bool> _showConfirmationDialog() async {
    final provider = context.read<AbsensiTahfidzProvider>();

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
                '${provider.santri.length} data absensi Tahfidz?',
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
                    backgroundColor: const Color(0xFF0D9488),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<AbsensiTahfidzProvider>(
      builder: (context, provider, _) {
        final santriItems = provider.santri.map((santri) {
          return AbsensiDetailSantriItem(
            id: santri.id,
            nama:
                santri.santri?.username ?? santri.santri?.email ?? 'Tanpa Nama',
          );
        }).toList();

        return AbsensiDetailPageTemplate(
          config: _buildConfig(),
          pertemuan: _buildPertemuanItem(provider),
          santri: santriItems,
          isLoading: provider.isLoading,
          isSaving: provider.isSaving,
          errorMessage: provider.error,
          canInputAttendance: provider.canInputAbsensi,
          selectedFilter: _selectedFilter,
          onFilterChanged: (value) {
            setState(() {
              _selectedFilter = value;
            });
          },
          onRefresh: _refresh,
          onRetry: _loadData,
          onSave: _saveAbsensi,
          summary: AbsensiDetailSummary(
            hadir: provider.totalHadir,
            izin: provider.totalIzin,
            sakit: provider.totalSakit,
            alpa: provider.totalAlpha,
            belumAbsen: provider.totalBelumAbsen,
          ),
          getStatus: (santriId) {
            return provider.getAttendance(santriId)?.status ?? 'Belum Absen';
          },
          onChangeStatus: ({required santriId, required status}) {
            provider.setStatus(santriId, status);
          },
          santriItemBuilder: (context, santriItem, status) {
            return _buildTahfidzSantriCard(santriItem, provider);
          },
        );
      },
    );
  }

  // ============================================================
  // CONFIG
  // ============================================================

  AbsensiDetailPageConfig _buildConfig() {
    return const AbsensiDetailPageConfig(
      title: 'Absensi Tahfidz',
      pertemuanTitle: 'Pertemuan Tahfidz',
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

  AbsensiDetailPertemuanItem _buildPertemuanItem(
    AbsensiTahfidzProvider provider,
  ) {
    final pertemuan = provider.pertemuan;

    final fallbackTanggal = widget.tanggalPertemuan ?? DateTime.now();

    if (pertemuan == null) {
      return AbsensiDetailPertemuanItem(
        id: widget.pertemuanId,
        tanggal: fallbackTanggal,
        pengajar: 'Pengajar',
        metode: 'Tahfidz',
        createdAt: fallbackTanggal,
      );
    }

    return AbsensiDetailPertemuanItem(
      id: pertemuan.id,
      tanggal: pertemuan.tanggal,
      pengajar: pertemuan.namaPengajar ?? 'Pengajar',
      pengganti: pertemuan.namaPenggantiPengajar,
      hasPengganti: pertemuan.menggunakanPengganti,
      metode: pertemuan.metode,
      materi: pertemuan.materiPembelajaran,
      createdAt: pertemuan.createdAt,
      batasWaktuOverride: provider.batasAbsensi,
    );
  }

  // ============================================================
  // TAHFIDZ CARD
  // ============================================================

  Widget _buildTahfidzSantriCard(
    AbsensiDetailSantriItem santriItem,
    AbsensiTahfidzProvider provider,
  ) {
    final santri = provider.santri
        .where((item) => item.id == santriItem.id)
        .firstOrNull;

    if (santri == null) {
      return const SizedBox.shrink();
    }

    final attendance = provider.getAttendance(santri.id);

    return _TahfidzSantriCard(
      santri: santri,
      attendance: attendance,
      canEdit: provider.canInputAbsensi,
      isSaving: provider.isSaving,
      onStatusChanged: (value) {
        provider.setStatus(santri.id, value);
      },
      onJenisTahfidzChanged: (value) {
        provider.setJenisTahfidz(santri.id, value);
      },
      onSuratChanged: (value) {
        provider.setSurat(santri.id, value);
      },
      onAyatMulaiChanged: (value) {
        provider.setAyatMulai(santri.id, int.tryParse(value));
      },
      onAyatSelesaiChanged: (value) {
        provider.setAyatSelesai(santri.id, int.tryParse(value));
      },
      onKeteranganChanged: (value) {
        provider.setKeterangan(santri.id, value);
      },
    );
  }
}

class _TahfidzSantriCard extends StatefulWidget {
  final SantriProgramModel santri;
  final TahfidzAttendanceState? attendance;

  final bool canEdit;
  final bool isSaving;

  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onJenisTahfidzChanged;
  final ValueChanged<String?> onSuratChanged;
  final ValueChanged<String> onAyatMulaiChanged;
  final ValueChanged<String> onAyatSelesaiChanged;
  final ValueChanged<String> onKeteranganChanged;

  const _TahfidzSantriCard({
    required this.santri,
    required this.attendance,
    required this.canEdit,
    required this.isSaving,
    required this.onStatusChanged,
    required this.onJenisTahfidzChanged,
    required this.onSuratChanged,
    required this.onAyatMulaiChanged,
    required this.onAyatSelesaiChanged,
    required this.onKeteranganChanged,
  });

  @override
  State<_TahfidzSantriCard> createState() => _TahfidzSantriCardState();
}

class _TahfidzSantriCardState extends State<_TahfidzSantriCard> {
  late final TextEditingController _ayatMulaiController;
  late final TextEditingController _ayatSelesaiController;
  late final TextEditingController _keteranganController;

  static const Color primaryColor = Color(0xFF0D9488);

  static const Color textColor = Color(0xFF0F172A);

  static const Color secondaryColor = Color(0xFF64748B);

  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();

    _ayatMulaiController = TextEditingController(
      text: _formatAyat(widget.attendance?.ayatMulai),
    );

    _ayatSelesaiController = TextEditingController(
      text: _formatAyat(widget.attendance?.ayatSelesai),
    );

    _keteranganController = TextEditingController(
      text: widget.attendance?.keterangan ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _TahfidzSantriCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final attendance = widget.attendance;

    final ayatMulai = _formatAyat(attendance?.ayatMulai);

    final ayatSelesai = _formatAyat(attendance?.ayatSelesai);

    final keterangan = attendance?.keterangan ?? '';

    if (_ayatMulaiController.text != ayatMulai) {
      _ayatMulaiController.value = TextEditingValue(
        text: ayatMulai,
        selection: TextSelection.collapsed(offset: ayatMulai.length),
      );
    }

    if (_ayatSelesaiController.text != ayatSelesai) {
      _ayatSelesaiController.value = TextEditingValue(
        text: ayatSelesai,
        selection: TextSelection.collapsed(offset: ayatSelesai.length),
      );
    }

    if (_keteranganController.text != keterangan) {
      _keteranganController.value = TextEditingValue(
        text: keterangan,
        selection: TextSelection.collapsed(offset: keterangan.length),
      );
    }
  }

  @override
  void dispose() {
    _ayatMulaiController.dispose();
    _ayatSelesaiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  String _formatAyat(int? value) {
    return value == null ? '' : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final nama =
        widget.santri.santri?.username ??
        widget.santri.santri?.email ??
        'Tanpa Nama';

    final attendance = widget.attendance;

    final normalizedStatus = TahfidzAttendanceState.normalizeStatus(
      attendance?.status ?? 'Belum Absen',
    );

    final isHadir = normalizedStatus == 'Hadir';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
            _buildHeader(nama),

            const SizedBox(height: 14),

            AbsensiDetailPageTemplate.buildStatusSelector(
              santriId: widget.santri.id,
              selectedStatus: normalizedStatus,
              isDisabled: !widget.canEdit || widget.isSaving,
              onChangeStatus: ({required santriId, required status}) {
                widget.onStatusChanged(status);
              },
              config: const AbsensiDetailPageConfig(
                title: 'Absensi Tahfidz',
                pertemuanTitle: 'Pertemuan Tahfidz',
                primaryColor: primaryColor,
              ),
            ),

            if (isHadir) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: borderColor),
              const SizedBox(height: 16),

              const Text(
                'Detail Setoran',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 12),

              _buildJenisTahfidz(),

              const SizedBox(height: 12),

              _buildSurat(),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildAyatField(
                      label: 'Ayat Mulai',
                      controller: _ayatMulaiController,
                      onChanged: widget.onAyatMulaiChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAyatField(
                      label: 'Ayat Selesai',
                      controller: _ayatSelesaiController,
                      onChanged: widget.onAyatSelesaiChanged,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildKeterangan(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String nama) {
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
            _getInitial(nama),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: primaryColor,
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
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Pencatatan Setoran Tahfidz',
                style: TextStyle(fontSize: 11.5, color: secondaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJenisTahfidz() {
    const options = ['Ziyadah', 'Murojaah'];

    final current = widget.attendance?.jenisTahfidz;

    return DropdownButtonFormField<String>(
      initialValue: options.contains(current) ? current : null,
      isExpanded: true,
      style: const TextStyle(fontSize: 13, color: textColor),
      decoration: _modernInputDecoration(
        hint: 'Pilih jenis setoran',
        label: 'Jenis Setoran',
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: secondaryColor,
      ),
      items: options.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: !widget.canEdit || widget.isSaving
          ? null
          : (value) {
              if (value != null) {
                widget.onJenisTahfidzChanged(value);
              }
            },
    );
  }

  Widget _buildSurat() {
    final current = widget.attendance?.surat;

    String? selectedValue;

    for (final surat in daftarSurat) {
      final value = _getSuratValue(surat);

      if (value == current) {
        selectedValue = value;
        break;
      }
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      style: const TextStyle(fontSize: 13, color: textColor),
      decoration: _modernInputDecoration(
        hint: 'Pilih surat Al-Qur\'an',
        label: 'Nama Surat',
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: secondaryColor,
      ),
      items: daftarSurat.map((surat) {
        final value = _getSuratValue(surat);

        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: !widget.canEdit || widget.isSaving
          ? null
          : widget.onSuratChanged,
    );
  }

  String _getSuratValue(dynamic surat) {
    if (surat is String) {
      return surat;
    }

    try {
      return surat.nama.toString();
    } catch (_) {}

    try {
      return surat.name.toString();
    } catch (_) {}

    return surat.toString();
  }

  Widget _buildAyatField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      enabled: widget.canEdit && !widget.isSaving,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13, color: textColor),
      decoration: _modernInputDecoration(hint: '0', label: label),
      onChanged: onChanged,
    );
  }

  Widget _buildKeterangan() {
    return TextFormField(
      controller: _keteranganController,
      enabled: widget.canEdit && !widget.isSaving,
      maxLines: 2,
      style: const TextStyle(fontSize: 13, color: textColor),
      decoration: _modernInputDecoration(
        hint: 'Tambahkan catatan setoran jika ada...',
        label: 'Keterangan / Catatan',
      ),
      onChanged: widget.onKeteranganChanged,
    );
  }

  InputDecoration _modernInputDecoration({
    required String hint,
    required String label,
  }) {
    final enabled = widget.canEdit && !widget.isSaving;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        fontSize: 12,
        color: secondaryColor,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  String _getInitial(String nama) {
    if (nama.trim().isEmpty) {
      return '?';
    }

    return nama.trim().substring(0, 1).toUpperCase();
  }
}

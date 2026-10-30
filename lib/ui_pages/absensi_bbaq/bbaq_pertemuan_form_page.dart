import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/absensi_bbaq/bbaq_pertemuan_model.dart';
import 'package:ptl_mobile/models/pengajar_pengganti/pengajar_pengganti_model.dart';
import 'package:ptl_mobile/models/kelas/kelas_pengajaran_model.dart';
import 'package:ptl_mobile/services/absensi_bbaq_service.dart';
import 'package:ptl_mobile/services/kelas_pengajaran_service.dart';
import 'package:ptl_mobile/state_management/pengajar_pengganti_provider.dart';
import 'package:ptl_mobile/state_management/pengajar_program_provider.dart';

// Palette Warna Modern & Fresh
const Color _primaryColor = Color(0xFF0D8B8B);
const Color _primaryLight = Color(0xFFE6F4F4);
const Color _accentOrange = Color(0xFFFF9F43);
const Color _backgroundColor = Color(0xFFF4F7F6);
const Color _cardBorderColor = Color(0xFFE2E8F0);

class BbaqPertemuanFormPage extends StatelessWidget {
  final String programId;
  final BbaqPertemuanModel? pertemuan;
  final String? initialKelasPengajaranId;

  const BbaqPertemuanFormPage({
    super.key,
    required this.programId,
    this.pertemuan,
    this.initialKelasPengajaranId,
  });

  bool get isEdit => pertemuan != null;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PengajarProgramProvider()),
        ChangeNotifierProvider(create: (_) => PengajarPenggantiProvider()),
      ],
      child: _BbaqPertemuanFormView(
        programId: programId,
        pertemuan: pertemuan,
        initialKelasPengajaranId: initialKelasPengajaranId,
      ),
    );
  }
}

// ============================================================================
// VIEW
// ============================================================================

class _BbaqPertemuanFormView extends StatefulWidget {
  final String programId;
  final BbaqPertemuanModel? pertemuan;

  const _BbaqPertemuanFormView({
    required this.programId,
    required this.pertemuan,
    String? initialKelasPengajaranId,
  });

  bool get isEdit => pertemuan != null;

  @override
  State<_BbaqPertemuanFormView> createState() => _BbaqPertemuanFormViewState();
}

class _BbaqPertemuanFormViewState extends State<_BbaqPertemuanFormView> {
  final _formKey = GlobalKey<FormState>();
  final AbsensiBbaqService _service = AbsensiBbaqService();
  final KelasPengajaranService _kelasService = KelasPengajaranService();
  final TextEditingController _materiController = TextEditingController();

  List<KelasPengajaranModel> _kelasPengajaran = [];
  String? _kelasPengajaranId;
  String? _kelasError;

  DateTime _tanggal = DateTime.now();
  String? _pengajarId;
  String? _penggantiPengajarId;
  String _metode = 'Offline';

  bool _isSaving = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _materiController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final pengajarProvider = context.read<PengajarProgramProvider>();
    final penggantiProvider = context.read<PengajarPenggantiProvider>();

    _kelasError = null;

    try {
      await Future.wait([
        pengajarProvider.loadPengajarByProgram(widget.programId),
        penggantiProvider.loadAll(hanyaAktif: true),
      ]);
    } catch (_) {
      // Error pengajar tetap ditampilkan melalui state provider yang tersedia.
    }

    try {
      _kelasPengajaran = await _kelasService.getByProgram(widget.programId);
    } catch (e) {
      _kelasError = e.toString().replaceFirst('Exception: ', '');
    }

    if (widget.pertemuan != null) {
      final item = widget.pertemuan!;
      _tanggal = item.tanggal;
      _kelasPengajaranId = item.kelasPengajaranId;
      _pengajarId = item.pengajarId;
      _penggantiPengajarId = item.penggantiPengajarId;
      _materiController.text = item.materiPembelajaran ?? '';
      _metode = item.metode;
    }

    if (!mounted) return;
    setState(() => _isInitializing = false);
  }

  Future<void> _pickTanggal() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'PILIH TANGGAL PERTEMUAN',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _tanggal = selected);
  }

  Future<void> _showSelectionBottomSheet({
    required String title,
    required List<_SelectionItem> items,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
    bool allowClear = false,
  }) async {
    final result = await showModalBottomSheet<_SelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SelectionBottomSheet(
          title: title,
          items: items,
          selectedValue: selectedValue,
          allowClear: allowClear,
        );
      },
    );

    if (result == null) return;
    if (result.isClear) {
      onSelected(null);
    } else if (result.value != null) {
      onSelected(result.value);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_kelasPengajaranId == null || _kelasPengajaranId!.isEmpty) {
      _showSnackBar('Kelas pengajaran wajib dipilih.', isError: true);
      return;
    }

    final kelasTerpilih = _kelasPengajaran.where(
      (kelas) => kelas.id == _kelasPengajaranId,
    );
    if (kelasTerpilih.isEmpty ||
        kelasTerpilih.first.programId != widget.programId) {
      _showSnackBar(
        'Kelas tidak valid untuk program ini. Muat ulang daftar kelas.',
        isError: true,
      );
      return;
    }

    if (_pengajarId == null || _pengajarId!.isEmpty) {
      _showSnackBar('Pengajar utama wajib dipilih.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _service.currentUserId;
      final model = BbaqPertemuanModel(
        id: widget.pertemuan?.id ?? '',
        programId: widget.programId,
        kelasPengajaranId: _kelasPengajaranId,
        tanggal: _tanggal,
        pengajarId: _pengajarId,
        penggantiPengajarId: _penggantiPengajarId,
        materiPembelajaran: _materiController.text.trim().isEmpty
            ? null
            : _materiController.text.trim(),
        metode: _metode,
        createdBy: widget.pertemuan?.createdBy ?? userId,
        createdAt: widget.pertemuan?.createdAt ?? DateTime.now(),
      );

      if (widget.isEdit) {
        await _service.updatePertemuan(model);
      } else {
        await _service.createPertemuan(model);
      }

      if (!mounted) return;
      _showSnackBar(
        widget.isEdit
            ? 'Pertemuan berhasil diperbarui.'
            : 'Pertemuan berhasil ditambahkan.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final item = widget.pertemuan;
    if (item == null || _isSaving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hapus Pertemuan?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Data pertemuan ini akan dihapus secara permanen. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      await _service.deletePertemuan(item.id);
      if (!mounted) return;
      _showSnackBar('Pertemuan berhasil dihapus.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getKelasName(String? id) {
    if (id == null || id.isEmpty) return '';
    for (final kelas in _kelasPengajaran) {
      if (kelas.id == id) return kelas.namaKelas;
    }
    return '';
  }

  String _getPengajarName(List<Map<String, dynamic>> list, String? id) {
    if (id == null || id.isEmpty) return '';
    for (final item in list) {
      if (item['id']?.toString() == id) {
        return item['username']?.toString() ?? '-';
      }
    }
    return '';
  }

  String _getPenggantiName(List<PengajarPenggantiModel> list, String? id) {
    if (id == null || id.isEmpty) return '';
    for (final item in list) {
      if (item.id == id) return item.nama;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.isEdit ? 'Edit Pertemuan' : 'Tambah Pertemuan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          if (widget.isEdit)
            IconButton(
              tooltip: 'Hapus Pertemuan',
              onPressed: _isSaving ? null : _delete,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _buildBody(),
      bottomNavigationBar: _isInitializing ? null : _buildBottomButton(),
    );
  }

  Widget _buildBody() {
    if (_kelasError != null) {
      return _buildErrorState(
        'Gagal memuat daftar kelas: $_kelasError',
        onRetry: () async {
          setState(() => _isInitializing = true);
          await _initialize();
        },
      );
    }

    return Consumer2<PengajarProgramProvider, PengajarPenggantiProvider>(
      builder: (context, pengajarProvider, penggantiProvider, child) {
        if (pengajarProvider.isLoadingPengajar || penggantiProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryColor),
          );
        }

        if (pengajarProvider.errorMessage != null) {
          return _buildErrorState(
            pengajarProvider.errorMessage!,
            onRetry: () async {
              await pengajarProvider.loadPengajarByProgram(widget.programId);
              await penggantiProvider.loadAll(hanyaAktif: true);
            },
          );
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildHeaderBanner(),
              const SizedBox(height: 20),
              _buildFormContent(pengajarProvider, penggantiProvider),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit ? 'Ubah Pertemuan BBAQ' : 'Pertemuan BBAQ Baru',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEdit
                      ? 'Perbarui tanggal dan informasi pengajar'
                      : 'Lengkapi tanggal dan informasi pengajar',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(
    PengajarProgramProvider pengajarProvider,
    PengajarPenggantiProvider penggantiProvider,
  ) {
    final pengajar = pengajarProvider.pengajarByProgram;
    final pengganti = penggantiProvider.itemsAktif;
    final selectedPengajarName = _getPengajarName(pengajar, _pengajarId);
    final selectedPenggantiName = _getPenggantiName(
      pengganti,
      _penggantiPengajarId,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== KELAS PENGAJARAN ====================
          const _SectionTitle(title: 'KELAS PENGAJARAN'),
          const SizedBox(height: 8),
          FormField<String>(
            initialValue: _kelasPengajaranId,
            validator: (_) =>
                (_kelasPengajaranId == null || _kelasPengajaranId!.isEmpty)
                ? 'Kelas pengajaran wajib dipilih'
                : null,
            builder: (state) {
              final selectedKelasName = _getKelasName(_kelasPengajaranId);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownTile(
                    label: selectedKelasName.isNotEmpty
                        ? selectedKelasName
                        : 'Pilih Kelas Pengajaran',
                    isSelected: selectedKelasName.isNotEmpty,
                    icon: Icons.groups_2_rounded,
                    hasError: state.hasError,
                    onTap: _isSaving || _kelasPengajaran.isEmpty
                        ? null
                        : () {
                            final items = _kelasPengajaran.map((kelas) {
                              final jenis = kelas.namaJenisKelas;
                              final suffix = jenis == null || jenis.isEmpty
                                  ? ''
                                  : ' • $jenis';
                              return _SelectionItem(
                                id: kelas.id,
                                name: '${kelas.namaKelas}$suffix',
                              );
                            }).toList();

                            _showSelectionBottomSheet(
                              title: 'Pilih Kelas Pengajaran',
                              items: items,
                              selectedValue: _kelasPengajaranId,
                              onSelected: (value) {
                                if (value == null) return;
                                setState(() => _kelasPengajaranId = value);
                                state.didChange(value);
                              },
                            );
                          },
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 8),
                      child: Text(
                        state.errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (_kelasPengajaran.isEmpty) ...[
                    const SizedBox(height: 8),
                    _buildWarningBox(
                      'Belum ada kelas pengajaran untuk program ini. Tambahkan kelas terlebih dahulu.',
                    ),
                  ],
                ],
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: _cardBorderColor, height: 1),
          ),

          // ==================== TANGGAL ====================
          const _SectionTitle(title: 'TANGGAL PERTEMUAN'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateTile(
                  title: 'Tanggal',
                  value: _formatDate(_tanggal),
                  icon: Icons.calendar_month_rounded,
                  onTap: _isSaving ? null : _pickTanggal,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: _cardBorderColor, height: 1),
          ),

          // ==================== PENGAJAR UTAMA ====================
          const _SectionTitle(title: 'PENGAJAR UTAMA'),
          const SizedBox(height: 8),
          FormField<String>(
            initialValue: _pengajarId,
            validator: (_) => (_pengajarId == null || _pengajarId!.isEmpty)
                ? 'Pengajar utama wajib dipilih'
                : null,
            builder: (state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownTile(
                    label: selectedPengajarName.isNotEmpty
                        ? selectedPengajarName
                        : 'Pilih Pengajar Utama',
                    isSelected: selectedPengajarName.isNotEmpty,
                    icon: Icons.person_rounded,
                    hasError: state.hasError,
                    onTap: _isSaving || pengajar.isEmpty
                        ? null
                        : () {
                            final items = pengajar.map((i) {
                              return _SelectionItem(
                                id: i['id']?.toString() ?? '',
                                name: i['username']?.toString() ?? '-',
                              );
                            }).toList();

                            _showSelectionBottomSheet(
                              title: 'Pilih Pengajar Utama',
                              items: items,
                              selectedValue: _pengajarId,
                              onSelected: (val) {
                                if (val == null) return;
                                setState(() => _pengajarId = val);
                                state.didChange(val);
                              },
                            );
                          },
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 8),
                      child: Text(
                        state.errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          if (pengajar.isEmpty) ...[
            const SizedBox(height: 8),
            _buildWarningBox(
              'Belum ada pengajar di program ini. Silakan tambahkan pengajar terlebih dahulu.',
            ),
          ],

          const SizedBox(height: 20),

          // ==================== PENGAJAR PENGGANTI ====================
          const _SectionTitle(title: 'PENGAJAR PENGGANTI (OPSIONAL)'),
          const SizedBox(height: 8),
          _buildDropdownTile(
            label: selectedPenggantiName.isNotEmpty
                ? selectedPenggantiName
                : 'Tidak Ada Pengganti',
            isSelected: selectedPenggantiName.isNotEmpty,
            icon: Icons.swap_horizontal_circle_rounded,
            iconColor: _accentOrange,
            onTap: _isSaving
                ? null
                : () {
                    final items = pengganti.map((i) {
                      return _SelectionItem(id: i.id, name: i.nama);
                    }).toList();

                    _showSelectionBottomSheet(
                      title: 'Pilih Pengganti Pengajar',
                      items: items,
                      selectedValue: _penggantiPengajarId,
                      allowClear: true,
                      onSelected: (val) {
                        setState(() => _penggantiPengajarId = val);
                      },
                    );
                  },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: _cardBorderColor, height: 1),
          ),

          // ==================== METODE ====================
          const _SectionTitle(title: 'METODE PEMBELAJARAN'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  label: 'Offline',
                  icon: Icons.location_on_rounded,
                  isSelected: _metode == 'Offline',
                  onTap: () => setState(() => _metode = 'Offline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChoiceChip(
                  label: 'Online',
                  icon: Icons.videocam_rounded,
                  isSelected: _metode == 'Online',
                  onTap: () => setState(() => _metode = 'Online'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ==================== MATERI ====================
          const _SectionTitle(title: 'MATERI PEMBELAJARAN'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _materiController,
            enabled: !_isSaving,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Tuliskan poin-poin atau judul materi yang dibahas...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _cardBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primaryColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: _primaryColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String label,
    required bool isSelected,
    required IconData icon,
    Color iconColor = _primaryColor,
    bool hasError = false,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasError ? Colors.redAccent : _cardBorderColor,
            width: hasError ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : Colors.grey.shade500,
                ),
              ),
            ),
            Icon(
              Icons.unfold_more_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primaryColor : _cardBorderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: _accentOrange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.isEdit ? 'Simpan Perubahan' : 'Simpan Pertemuan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER COMPONENTS
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Color(0xFF64748B),
      ),
    );
  }
}

class _SelectionItem {
  final String id;
  final String name;
  const _SelectionItem({required this.id, required this.name});
}

class _SelectionResult {
  final String? value;
  final bool isClear;

  const _SelectionResult._({this.value, this.isClear = false});

  factory _SelectionResult.selected(String value) =>
      _SelectionResult._(value: value);

  factory _SelectionResult.clear() => const _SelectionResult._(isClear: true);
}

class _SelectionBottomSheet extends StatefulWidget {
  final String title;
  final List<_SelectionItem> items;
  final String? selectedValue;
  final bool allowClear;

  const _SelectionBottomSheet({
    required this.title,
    required this.items,
    required this.selectedValue,
    this.allowClear = false,
  });

  @override
  State<_SelectionBottomSheet> createState() => _SelectionBottomSheetState();
}

class _SelectionBottomSheetState extends State<_SelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<_SelectionItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List<_SelectionItem>.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filteredItems = q.isEmpty
          ? List.from(widget.items)
          : widget.items
                .where((i) => i.name.toLowerCase().contains(q))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (widget.items.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _filterItems,
                decoration: InputDecoration(
                  hintText: 'Cari nama...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  fillColor: const Color(0xFFF1F5F9),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          const Divider(height: 1, color: _cardBorderColor),
          Expanded(
            child: _filteredItems.isEmpty && !widget.allowClear
                ? Center(
                    child: Text(
                      'Data tidak ditemukan',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:
                        _filteredItems.length + (widget.allowClear ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (widget.allowClear && index == 0) {
                        final isSelected = widget.selectedValue == null;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade100,
                            child: const Icon(
                              Icons.block_rounded,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                          title: const Text('Tidak ada pengganti'),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: _primaryColor,
                                )
                              : null,
                          onTap: () =>
                              Navigator.pop(context, _SelectionResult.clear()),
                        );
                      }

                      final actualIndex = widget.allowClear ? index - 1 : index;
                      final item = _filteredItems[actualIndex];
                      final isSelected = widget.selectedValue == item.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? _primaryLight
                              : const Color(0xFFF1F5F9),
                          child: Icon(
                            Icons.person_rounded,
                            color: isSelected
                                ? _primaryColor
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? _primaryColor
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: _primaryColor,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(
                            context,
                            _SelectionResult.selected(item.id),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

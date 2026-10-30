import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../models/kelas/kelas_type_model.dart';
import '../../../../models/kelas/kelas_pengajaran_model.dart';
import '../../../../state_management/loading_provider.dart';
import '../../../../state_management/kelas_type_provider.dart';
import '../../../../state_management/program_provider.dart';
import '../../../../services/kelas_pengajaran_service.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _backgroundColor = Color(0xFFF8FAFA);
const Color _textColor = Color(0xFF263238);
const Color _secondaryTextColor = Color(0xFF607D8B);

class KelasTypePage extends StatefulWidget {
  const KelasTypePage({super.key});

  @override
  State<KelasTypePage> createState() => _KelasTypePageState();
}

class _KelasTypePageState extends State<KelasTypePage> {
  final KelasPengajaranService _kelasService = KelasPengajaranService();

  final Map<String, List<KelasPengajaranModel>> _kelasByType = {};
  final Set<String> _expandedTypes = {};

  bool _isLoadingPage = true;
  bool _isLoadingClasses = false;
  String? _pageError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPage = true;
      _pageError = null;
    });

    try {
      final loadingProvider = context.read<LoadingProvider>();

      await context.read<KelasTypeProvider>().loadAll(loadingProvider);

      if (!mounted) return;

      await context.read<ProgramProvider>().loadAll(loadingProvider);

      if (!mounted) return;

      await _loadClasses();
    } catch (e) {
      if (mounted) {
        setState(() {
          _pageError = _cleanError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPage = false);
      }
    }
  }

  Future<void> _loadClasses() async {
    if (mounted) {
      setState(() {
        _isLoadingClasses = true;
        _pageError = null;
      });
    }

    try {
      final classes = await _kelasService.getAll();

      final grouped = <String, List<KelasPengajaranModel>>{};

      for (final kelas in classes) {
        grouped.putIfAbsent(kelas.kelasTypeId, () => []).add(kelas);
      }

      if (!mounted) return;

      setState(() {
        _kelasByType
          ..clear()
          ..addAll(grouped);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _pageError = _cleanError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  Future<void> _refreshData() async {
    final loadingProvider = context.read<LoadingProvider>();

    await context.read<KelasTypeProvider>().refresh(loadingProvider);

    if (!mounted) return;

    await context.read<ProgramProvider>().refresh(loadingProvider);

    if (!mounted) return;

    await _loadClasses();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : _primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Jenis Kelas',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah jenis kelas',
        onPressed: () => _showTypeForm(),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Consumer<KelasTypeProvider>(
        builder: (context, provider, child) {
          if (_isLoadingPage) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );
          }

          if (_pageError != null && !provider.hasData) {
            return _buildError(_pageError!);
          }

          if (!provider.hasData) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            color: _primaryColor,
            onRefresh: _refreshData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _buildSummary(provider.items.length),
                const SizedBox(height: 16),

                if (_pageError != null) ...[
                  _buildInlineError(_pageError!),
                  const SizedBox(height: 12),
                ],

                for (final kelasType in provider.items)
                  _buildTypeCard(kelasType, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(int totalJenis) {
    final totalKelas = _kelasByType.values.fold<int>(
      0,
      (total, list) => total + list.length,
    );

    final totalAktif = _kelasByType.values
        .expand((list) => list)
        .where((kelas) => kelas.aktif)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              icon: Icons.category_outlined,
              label: 'Jenis kelas',
              value: '$totalJenis',
            ),
          ),
          Container(width: 1, height: 48, color: Colors.grey.shade200),
          Expanded(
            child: _summaryItem(
              icon: Icons.school_outlined,
              label: 'Kelas pengajaran',
              value: '$totalKelas',
            ),
          ),
          Container(width: 1, height: 48, color: Colors.grey.shade200),
          Expanded(
            child: _summaryItem(
              icon: Icons.check_circle_outline,
              label: 'Kelas aktif',
              value: '$totalAktif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: _primaryColor, size: 21),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: _secondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildTypeCard(KelasTypeModel kelasType, KelasTypeProvider provider) {
    final classes = _kelasByType[kelasType.id] ?? [];
    final isExpanded = _expandedTypes.contains(kelasType.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedTypes.remove(kelasType.id);
                } else {
                  _expandedTypes.add(kelasType.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.layers_outlined,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kelasType.nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${classes.length} kelas pengajaran',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Aksi jenis kelas',
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showTypeForm(kelas: kelasType);
                      } else if (value == 'delete') {
                        _confirmDeleteType(kelasType, provider);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 10),
                            Text('Edit jenis kelas'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text(
                              'Hapus jenis kelas',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: _secondaryTextColor,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),

            if (_isLoadingClasses)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryColor,
                  ),
                ),
              )
            else if (classes.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Belum ada kelas pengajaran',
                      style: TextStyle(
                        fontSize: 13,
                        color: _secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tambahkan kelas untuk jenis ini.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Column(
                  children: [
                    for (final kelas in classes) _buildTeachingClassCard(kelas),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showTeachingClassForm(kelasType),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah kelas pengajaran'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: BorderSide(
                      color: _primaryColor.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeachingClassCard(KelasPengajaranModel kelas) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              size: 20,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kelas.namaKelas,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    kelas.namaProgram ?? 'Program tidak tersedia',
                    if (kelas.namaPengajar != null &&
                        kelas.namaPengajar!.isNotEmpty)
                      kelas.namaPengajar!,
                  ].join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _secondaryTextColor,
                  ),
                ),
                if (kelas.lembagaId != null) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Kelas lembaga',
                    style: TextStyle(fontSize: 10, color: _secondaryTextColor),
                  ),
                ],
                const SizedBox(height: 7),
                _statusBadge(kelas.aktif),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Aksi kelas',
            onSelected: (value) async {
              if (value == 'edit') {
                final type = context
                    .read<KelasTypeProvider>()
                    .items
                    .where((item) => item.id == kelas.kelasTypeId)
                    .firstOrNull;

                if (type != null) {
                  _showTeachingClassForm(type, kelas: kelas);
                }
              } else if (value == 'toggle') {
                await _toggleClassStatus(kelas);
              } else if (value == 'delete') {
                await _confirmDeleteTeachingClass(kelas);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      kelas.aktif
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                    const SizedBox(width: 10),
                    Text(kelas.aktif ? 'Nonaktifkan' : 'Aktifkan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool aktif) {
    final color = aktif ? _primaryColor : _secondaryTextColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        aktif ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _refreshData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Icon(
            Icons.layers_outlined,
            size: 60,
            color: _secondaryTextColor,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Belum ada jenis kelas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Tambahkan jenis kelas terlebih dahulu, '
                'kemudian tambahkan kelas pengajarannya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _secondaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ),
          IconButton(
            tooltip: 'Coba lagi',
            onPressed: _loadClasses,
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Icon(
            Icons.cloud_off_outlined,
            size: 56,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat data',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _secondaryTextColor),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM JENIS KELAS
  // ============================================================

  Future<void> _showTypeForm({KelasTypeModel? kelas}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KelasTypeFormSheet(kelas: kelas),
    );

    if (result == true && mounted) {
      _showMessage(
        kelas == null
            ? 'Jenis kelas berhasil ditambahkan.'
            : 'Jenis kelas berhasil diperbarui.',
      );
    }
  }

  Future<void> _confirmDeleteType(
    KelasTypeModel kelas,
    KelasTypeProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus jenis kelas?'),
        content: Text(
          'Jenis kelas "${kelas.nama}" akan dihapus. '
          'Penghapusan dapat ditolak jika masih digunakan oleh kelas pengajaran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await provider.delete(
      kelas.id,
      loadingProvider: context.read<LoadingProvider>(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _kelasByType.remove(kelas.id);
        _expandedTypes.remove(kelas.id);
      });
    }

    _showMessage(
      success
          ? 'Jenis kelas berhasil dihapus.'
          : provider.errorMessage ?? 'Gagal menghapus jenis kelas.',
      isError: !success,
    );
  }

  // ============================================================
  // FORM KELAS PENGAJARAN
  // ============================================================

  Future<void> _showTeachingClassForm(
    KelasTypeModel kelasType, {
    KelasPengajaranModel? kelas,
  }) async {
    final programs = context.read<ProgramProvider>().items;

    if (programs.isEmpty) {
      _showMessage(
        'Daftar program belum tersedia. Muat ulang halaman.',
        isError: true,
      );
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KelasPengajaranFormSheet(
        kelasType: kelasType,
        kelas: kelas,
        programs: programs,
        service: _kelasService,
      ),
    );

    if (result != true || !mounted) return;

    await _loadClasses();

    if (!mounted) return;

    _showMessage(
      kelas == null
          ? 'Kelas pengajaran berhasil ditambahkan.'
          : 'Kelas pengajaran berhasil diperbarui.',
    );
  }

  Future<void> _toggleClassStatus(KelasPengajaranModel kelas) async {
    try {
      await _kelasService.setActive(id: kelas.id, aktif: !kelas.aktif);

      await _loadClasses();

      if (!mounted) return;

      _showMessage(
        kelas.aktif
            ? 'Kelas berhasil dinonaktifkan.'
            : 'Kelas berhasil diaktifkan.',
      );
    } catch (e) {
      _showMessage(_cleanError(e), isError: true);
    }
  }

  Future<void> _confirmDeleteTeachingClass(KelasPengajaranModel kelas) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus kelas pengajaran?'),
        content: Text(
          'Kelas "${kelas.namaKelas}" akan dihapus. '
          'Kelas yang masih memiliki pendaftaran santri atau riwayat '
          'perpindahan tidak dapat dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _kelasService.delete(kelas.id);

      await _loadClasses();

      if (!mounted) return;

      _showMessage('Kelas pengajaran berhasil dihapus.');
    } catch (e) {
      _showMessage(_cleanError(e), isError: true);
    }
  }
}

// ================================================================
// BOTTOM SHEET FORM JENIS KELAS
// ================================================================

class _KelasTypeFormSheet extends StatefulWidget {
  final KelasTypeModel? kelas;

  const _KelasTypeFormSheet({required this.kelas});

  @override
  State<_KelasTypeFormSheet> createState() => _KelasTypeFormSheetState();
}

class _KelasTypeFormSheetState extends State<_KelasTypeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.kelas?.nama ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<KelasTypeProvider>();
    final loading = context.read<LoadingProvider>();

    final success = widget.kelas == null
        ? await provider.create(
            nama: _namaController.text.trim(),
            loadingProvider: loading,
          )
        : await provider.update(
            KelasTypeModel(
              id: widget.kelas!.id,
              nama: _namaController.text.trim(),
            ),
            loadingProvider: loading,
          );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal menyimpan jenis kelas.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Consumer<KelasTypeProvider>(
              builder: (context, provider, child) {
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.kelas == null
                            ? 'Tambah Jenis Kelas'
                            : 'Edit Jenis Kelas',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _namaController,
                        autofocus: true,
                        enabled: !provider.isSaving,
                        decoration: InputDecoration(
                          labelText: 'Nama jenis kelas',
                          hintText: 'Contoh: Reguler',
                          prefixIcon: const Icon(Icons.layers_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama jenis kelas wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: provider.isSaving ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                          ),
                          child: provider.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.kelas == null
                                      ? 'Tambah Jenis Kelas'
                                      : 'Simpan Perubahan',
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// BOTTOM SHEET FORM KELAS PENGAJARAN
// ================================================================

class _KelasPengajaranFormSheet extends StatefulWidget {
  final KelasTypeModel kelasType;
  final KelasPengajaranModel? kelas;
  final List<dynamic> programs;
  final KelasPengajaranService service;

  const _KelasPengajaranFormSheet({
    required this.kelasType,
    required this.kelas,
    required this.programs,
    required this.service,
  });

  @override
  State<_KelasPengajaranFormSheet> createState() =>
      _KelasPengajaranFormSheetState();
}

class _KelasPengajaranFormSheetState extends State<_KelasPengajaranFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  late final TextEditingController _namaController;

  String? _programId;
  String? _pengajarId;
  String? _lembagaId;

  List<Map<String, dynamic>> _pengajarList = [];
  List<Map<String, dynamic>> _lembagaList = [];
  // Map lembaga_id -> id kelas pengajaran yang sudah menggunakan lembaga tersebut.
  final Map<String, String> _kelasIdByLembaga = {};

  bool _loadingReferences = true;
  bool _saving = false;
  String? _errorMessage;

  bool get _isLembaga =>
      widget.kelasType.nama.trim().toLowerCase() == 'lembaga';

  @override
  void initState() {
    super.initState();

    _namaController = TextEditingController(
      text: widget.kelas?.namaKelas ?? '',
    );

    _programId =
        widget.kelas?.programId ??
        (widget.programs.isNotEmpty ? widget.programs.first.id : null);

    _pengajarId = widget.kelas?.pengajarId;
    _lembagaId = widget.kelas?.lembagaId;

    _loadReferences();
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    try {
      final results = await Future.wait([
        _supabase
            .from('profiles')
            .select('id, username')
            .eq('role', 'pengajar')
            .order('username'),
        _supabase
            .from('lembaga')
            .select('id, nama_lembaga, program_id')
            .order('nama_lembaga'),
        // Ambil lembaga yang sudah terhubung dengan kelas pengajaran.
        _supabase
            .from('kelas_pengajaran')
            .select('id, lembaga_id')
            .not('lembaga_id', 'is', null),
      ]);

      if (!mounted) return;

      final kelasByLembaga = <String, String>{};
      for (final row in results[2] as List) {
        final item = Map<String, dynamic>.from(row as Map);
        final lembagaId = item['lembaga_id']?.toString();
        final kelasId = item['id']?.toString();

        if (lembagaId != null && kelasId != null) {
          kelasByLembaga[lembagaId] = kelasId;
        }
      }

      setState(() {
        _pengajarList = List<Map<String, dynamic>>.from(results[0] as List);
        _lembagaList = List<Map<String, dynamic>>.from(results[1] as List);
        _kelasIdByLembaga
          ..clear()
          ..addAll(kelasByLembaga);
        _loadingReferences = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingReferences = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> get _availableLembaga {
    if (_programId == null) return [];

    return _lembagaList.where((item) {
      final lembagaId = item['id']?.toString();
      final programSesuai = item['program_id']?.toString() == _programId;

      if (lembagaId == null || !programSesuai) return false;

      final kelasYangMenggunakan = _kelasIdByLembaga[lembagaId];

      // Saat edit, lembaga yang sedang dipakai kelas ini tetap bisa dipilih.
      // Lembaga yang sudah dipakai kelas lain tidak ditampilkan.
      final belumDipakai = kelasYangMenggunakan == null;
      final dipakaiKelasIni =
          widget.kelas != null && kelasYangMenggunakan == widget.kelas!.id;

      return belumDipakai || dipakaiKelasIni;
    }).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_programId == null) {
      setState(() => _errorMessage = 'Pilih program terlebih dahulu.');
      return;
    }

    if (_isLembaga && _lembagaId == null) {
      setState(() => _errorMessage = 'Pilih lembaga terlebih dahulu.');
      return;
    }

    if (_isLembaga && _pengajarId == null) {
      setState(() => _errorMessage = 'Pilih pengajar untuk kelas lembaga.');
      return;
    }

    // Validasi ulang sebelum menyimpan. Constraint unik di database tetap
    // menjadi perlindungan utama terhadap penyimpanan bersamaan.
    if (_isLembaga && _lembagaId != null) {
      final kelasYangMenggunakan = _kelasIdByLembaga[_lembagaId!];
      final dipakaiKelasLain =
          kelasYangMenggunakan != null &&
          (widget.kelas == null || kelasYangMenggunakan != widget.kelas!.id);

      if (dipakaiKelasLain) {
        setState(() {
          _errorMessage =
              'Lembaga ini sudah memiliki kelas pengajaran. Pilih lembaga lain.';
        });
        return;
      }
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      if (widget.kelas == null) {
        await widget.service.create(
          programId: _programId!,
          kelasTypeId: widget.kelasType.id,
          namaKelas: _namaController.text.trim(),
          pengajarId: _pengajarId,
          lembagaId: _isLembaga ? _lembagaId : null,
        );
      } else {
        await widget.service.update(
          id: widget.kelas!.id,
          programId: _programId!,
          kelasTypeId: widget.kelasType.id,
          namaKelas: _namaController.text.trim(),
          pengajarId: _pengajarId,
          lembagaId: _isLembaga ? _lembagaId : null,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final rawError = e.toString();
      final normalizedError = rawError.toLowerCase();
      final isDuplicateLembaga =
          normalizedError.contains('uq_kelas_pengajaran_lembaga_id') ||
          (normalizedError.contains('duplicate key') &&
              normalizedError.contains('lembaga_id')) ||
          (normalizedError.contains('23505') &&
              normalizedError.contains('lembaga'));

      setState(() {
        _errorMessage = isDuplicateLembaga
            ? 'Lembaga ini sudah memiliki kelas pengajaran. Silakan pilih lembaga lain.'
            : rawError.replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programs = widget.programs;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.kelas == null
                        ? 'Tambah Kelas Pengajaran'
                        : 'Edit Kelas Pengajaran',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Jenis kelas: ${widget.kelasType.nama}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _namaController,
                    enabled: !_saving,
                    decoration: _decoration(
                      'Nama kelas',
                      icon: Icons.menu_book_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama kelas wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: programs.any((p) => p.id == _programId)
                        ? _programId
                        : null,
                    isExpanded: true,
                    decoration: _decoration(
                      'Program',
                      icon: Icons.school_outlined,
                    ),
                    items: programs.map<DropdownMenuItem<String>>((program) {
                      return DropdownMenuItem<String>(
                        value: program.id.toString(),
                        child: Text(
                          program.nama.toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            setState(() {
                              _programId = value;

                              final validLembaga = _availableLembaga.any(
                                (item) => item['id']?.toString() == _lembagaId,
                              );

                              if (!validLembaga) {
                                _lembagaId = null;
                              }
                            });
                          },
                    validator: (value) =>
                        value == null ? 'Pilih program.' : null,
                  ),
                  const SizedBox(height: 16),

                  if (_loadingReferences)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(color: _primaryColor),
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      value:
                          _pengajarList.any(
                            (item) => item['id']?.toString() == _pengajarId,
                          )
                          ? _pengajarId
                          : null,
                      isExpanded: true,
                      decoration: _decoration(
                        _isLembaga
                            ? 'Pengajar (wajib untuk kelas lembaga)'
                            : 'Pengajar (opsional)',
                        icon: Icons.person_outline,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Belum ditentukan'),
                        ),
                        ..._pengajarList.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text(
                              (item['username'] ?? 'Tanpa nama').toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _pengajarId = value),
                      validator: (value) {
                        if (_isLembaga && value == null) {
                          return 'Pengajar wajib dipilih untuk kelas lembaga.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_isLembaga) ...[
                    if (_availableLembaga.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          _programId == null
                              ? 'Pilih program terlebih dahulu.'
                              : 'Tidak ada lembaga yang tersedia untuk program ini, atau semua lembaga sudah memiliki kelas pengajaran.',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      value:
                          _availableLembaga.any(
                            (item) => item['id']?.toString() == _lembagaId,
                          )
                          ? _lembagaId
                          : null,
                      isExpanded: true,
                      decoration: _decoration(
                        'Lembaga',
                        icon: Icons.apartment_outlined,
                      ),
                      items: _availableLembaga.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(
                            (item['nama_lembaga'] ?? 'Tanpa nama').toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _lembagaId = value),
                      validator: (value) {
                        if (_isLembaga && value == null) {
                          return 'Pilih lembaga yang sesuai dengan program.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _saving || _loadingReferences ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.kelas == null
                                  ? 'Tambah Kelas'
                                  : 'Simpan Perubahan',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

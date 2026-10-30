import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/state_management/lembaga_provider.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';
import 'package:ptl_mobile/state_management/program_provider.dart';

import 'package:ptl_mobile/models/lembaga/lembaga_model.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/lembaga/lembaga_detail_page.dart';
import 'package:ptl_mobile/models/kelas/kelas_pengajaran_model.dart';
import 'package:ptl_mobile/services/kelas_pengajaran_service.dart';

class LembagaPage extends StatefulWidget {
  const LembagaPage({super.key});

  @override
  State<LembagaPage> createState() => _LembagaPageState();
}

class _LembagaPageState extends State<LembagaPage> {
  static const Color primaryColor = Color(0xFF0D8B8B);

  final KelasPengajaranService _kelasService = KelasPengajaranService();

  Map<String, KelasPengajaranModel> _kelasByLembaga = {};
  String? _kelasLoadError;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterProgramId;
  String? _filterPengajarId;
  String? _filterPbm;
  String? _expandedLembagaId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LembagaModel> _filterLembaga(List<LembagaModel> items) {
    final query = _searchQuery.trim().toLowerCase();

    return items.where((lembaga) {
      final matchesSearch =
          query.isEmpty ||
          lembaga.namaLembaga.toLowerCase().contains(query) ||
          (lembaga.alamat?.toLowerCase().contains(query) ?? false);

      final matchesProgram =
          _filterProgramId == null || lembaga.programId == _filterProgramId;

      final matchesPbm =
          _filterPbm == null ||
          lembaga.pbmType.toLowerCase() == _filterPbm!.toLowerCase();

      final kelas = _kelasByLembaga[lembaga.id];
      final matchesPengajar =
          _filterPengajarId == null || kelas?.pengajarId == _filterPengajarId;

      return matchesSearch && matchesProgram && matchesPbm && matchesPengajar;
    }).toList();
  }

  List<MapEntry<String, String>> get _pengajarOptions {
    final options = <String, String>{};
    for (final kelas in _kelasByLembaga.values) {
      final id = kelas.pengajarId;
      final nama = kelas.namaPengajar?.trim();
      if (id != null && id.isNotEmpty && nama != null && nama.isNotEmpty) {
        options[id] = nama;
      }
    }
    final entries = options.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    return entries;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final lembagaProvider = context.read<LembagaProvider>();
    final programProvider = context.read<ProgramProvider>();
    final loadingProvider = context.read<LoadingProvider>();

    await Future.wait([
      lembagaProvider.loadAll(loadingProvider),
      if (!programProvider.hasData) programProvider.loadAll(loadingProvider),
    ]);

    try {
      final kelasList = await _kelasService.getAll();

      if (!mounted) return;

      final kelasMap = <String, KelasPengajaranModel>{};

      for (final kelas in kelasList) {
        final lembagaId = kelas.lembagaId;

        if (lembagaId != null) {
          kelasMap[lembagaId] = kelas;
        }
      }

      setState(() {
        _kelasByLembaga = kelasMap;
        _kelasLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _kelasLoadError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Daftar Lembaga',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: false,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 3,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showLembagaForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Lembaga',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<LembagaProvider>(
        builder: (context, provider, child) {
          if (provider.errorMessage != null && provider.items.isEmpty) {
            return _buildErrorState(context, provider.errorMessage!);
          }

          if (!provider.hasData) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: _loadInitialData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _buildSummary(provider.items),
                const SizedBox(height: 16),
                _buildFilters(provider),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Daftar Lembaga',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ),
                    Text(
                      '${_filterLembaga(provider.items).length} dari ${provider.items.length}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_filterLembaga(provider.items).isEmpty)
                  _buildNoFilterResults()
                else
                  ..._filterLembaga(
                    provider.items,
                  ).map((lembaga) => _buildLembagaCard(context, lembaga)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(LembagaProvider provider) {
    final programProvider = context.watch<ProgramProvider>();
    final pengajarOptions = _pengajarOptions;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari nama atau alamat lembaga...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterProgramId,
                  isExpanded: true,
                  decoration: _filterDecoration('Program'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua program'),
                    ),
                    ...programProvider.items.map(
                      (program) => DropdownMenuItem<String>(
                        value: program.id,
                        child: Text(
                          program.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _filterProgramId = value;
                    _expandedLembagaId = null;
                  }),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterPbm,
                  isExpanded: true,
                  decoration: _filterDecoration('PBM'),
                  items: const [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua PBM'),
                    ),
                    DropdownMenuItem(value: 'Offline', child: Text('Offline')),
                    DropdownMenuItem(value: 'Online', child: Text('Online')),
                  ],
                  onChanged: (value) => setState(() {
                    _filterPbm = value;
                    _expandedLembagaId = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _filterPengajarId,
            isExpanded: true,
            decoration: _filterDecoration('Pengajar'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua pengajar'),
              ),
              ...pengajarOptions.map(
                (pengajar) => DropdownMenuItem<String>(
                  value: pengajar.key,
                  child: Text(
                    pengajar.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() {
              _filterPengajarId = value;
              _expandedLembagaId = null;
            }),
          ),
          if (_searchQuery.isNotEmpty ||
              _filterProgramId != null ||
              _filterPengajarId != null ||
              _filterPbm != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _filterProgramId = null;
                    _filterPengajarId = null;
                    _filterPbm = null;
                    _expandedLembagaId = null;
                  });
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                label: const Text('Reset filter'),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildNoFilterResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 38, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          const Text(
            'Lembaga tidak ditemukan',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba ubah kata pencarian atau pilihan filter.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<LembagaModel> items) {
    final offline = items
        .where((item) => item.pbmType.toLowerCase() == 'offline')
        .length;

    final online = items.length - offline;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manajemen Lembaga',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '${items.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Total lembaga terdaftar',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  Icons.meeting_room_outlined,
                  'Offline',
                  offline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryItem(Icons.language_rounded, 'Online', online),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String label, int value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD ITEM
  // ============================================================

  Widget _buildLembagaCard(BuildContext context, LembagaModel lembaga) {
    final isExpanded = _expandedLembagaId == lembaga.id;
    final isOffline = lembaga.pbmType.toLowerCase() == 'offline';
    final programProvider = context.watch<ProgramProvider>();

    String? programName;
    if (lembaga.programId != null) {
      for (final program in programProvider.items) {
        if (program.id == lembaga.programId) {
          programName = program.nama;
          break;
        }
      }
    }

    final kelas = _kelasByLembaga[lembaga.id];
    final pengajarName = kelas?.namaPengajar?.trim();
    final hasPengajar = pengajarName != null && pengajarName.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? primaryColor.withOpacity(0.45)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _expandedLembagaId = isExpanded ? null : lembaga.id;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.account_balance_outlined,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lembaga.namaLembaga,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isOffline
                                    ? Colors.orange.shade50
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                isOffline ? 'Offline' : 'Online',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isOffline
                                      ? Colors.orange.shade800
                                      : Colors.blue.shade800,
                                ),
                              ),
                            ),
                            if (programName != null) ...[
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  programName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Aksi lembaga',
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showLembagaForm(context, lembaga: lembaga);
                      } else if (value == 'delete') {
                        _confirmDelete(context, lembaga);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 19),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 19,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (programName != null)
                    _buildMetaItem(
                      icon: Icons.menu_book_outlined,
                      label: 'Program',
                      value: programName,
                    ),
                  if (programName != null) const SizedBox(height: 9),
                  _buildMetaItem(
                    icon: Icons.school_outlined,
                    label: 'Kelas',
                    value: kelas?.namaKelas ?? 'Belum dibuat',
                  ),
                  const SizedBox(height: 9),
                  _buildMetaItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Pengajar',
                    value: hasPengajar ? pengajarName : 'Belum ditentukan',
                  ),
                  if (_kelasLoadError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Informasi kelas belum dapat dimuat.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                  if (lembaga.alamat != null &&
                      lembaga.alamat!.trim().isNotEmpty) ...[
                    const SizedBox(height: 9),
                    _buildMetaItem(
                      icon: Icons.location_on_outlined,
                      label: 'Alamat',
                      value: lembaga.alamat!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LembagaDetailPage(lembaga: lembaga),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: const Text('Detail Lembaga'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATES (EMPTY & ERROR)
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Lembaga',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan tambahkan data lembaga baru untuk memulai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showLembagaForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Lembaga'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.shade300,
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
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FORM DIALOG
  // ============================================================

  // ============================================================
  // FORM DIALOG (RESPONSIF & TANPA OVERFLOW)
  // ============================================================

  void _showLembagaForm(BuildContext context, {LembagaModel? lembaga}) {
    final isEdit = lembaga != null;

    final namaController = TextEditingController(
      text: lembaga?.namaLembaga ?? '',
    );
    final alamatController = TextEditingController(text: lembaga?.alamat ?? '');

    String selectedPbmType = lembaga?.pbmType ?? 'Offline';
    String? selectedProgramId = lembaga?.programId;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final lembagaProvider = dialogContext.watch<LembagaProvider>();
            final programProvider = dialogContext.watch<ProgramProvider>();

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Dialog
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isEdit
                                  ? Icons.edit_note_rounded
                                  : Icons.add_business_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEdit ? 'Edit Lembaga' : 'Tambah Lembaga',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: lembagaProvider.isSaving
                                ? null
                                : () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, color: Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Form Core
                      Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Nama Lembaga
                            TextFormField(
                              controller: namaController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Nama Lembaga',
                                hintText: 'Contoh: Pesantren Nurul Falah',
                                prefixIcon: const Icon(
                                  Icons.account_balance_outlined,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama lembaga wajib diisi';
                                }
                                if (value.trim().length < 3) {
                                  return 'Minimal 3 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 2. Jenis PBM (Custom Choice Chip)
                            Text(
                              'Jenis PBM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: ['Offline', 'Online'].map((type) {
                                final isSelected = selectedPbmType == type;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: type == 'Offline' ? 8.0 : 0,
                                      left: type == 'Online' ? 8.0 : 0,
                                    ),
                                    child: InkWell(
                                      onTap: lembagaProvider.isSaving
                                          ? null
                                          : () {
                                              setState(() {
                                                selectedPbmType = type;
                                              });
                                            },
                                      borderRadius: BorderRadius.circular(10),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor.withOpacity(0.1)
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryColor
                                                : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            type,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? primaryColor
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // 3. Dropdown Program
                            DropdownButtonFormField<String>(
                              value: selectedProgramId,
                              isExpanded:
                                  true, // Mencegah teks menu meluap ke kanan
                              decoration: InputDecoration(
                                labelText: 'Program',
                                prefixIcon: const Icon(
                                  Icons.menu_book_outlined,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items: programProvider.items
                                  .map(
                                    (program) => DropdownMenuItem<String>(
                                      value: program.id,
                                      child: Text(
                                        program.nama,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: lembagaProvider.isSaving
                                  ? null
                                  : (val) =>
                                        setState(() => selectedProgramId = val),
                              validator: (value) => value == null
                                  ? 'Program wajib dipilih'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // 4. Input Alamat
                            TextFormField(
                              controller: alamatController,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Alamat (Opsional)',
                                hintText: 'Masukkan alamat lembaga',
                                alignLabelWithHint: true,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(bottom: 24),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    size: 20,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: lembagaProvider.isSaving
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: Text(
                              'Batal',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: lembagaProvider.isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate())
                                      return;

                                    final nama = namaController.text.trim();
                                    final alamat = alamatController.text.trim();

                                    bool success;

                                    if (isEdit) {
                                      final updated = LembagaModel(
                                        id: lembaga.id,
                                        namaLembaga: nama,
                                        pbmType: selectedPbmType,
                                        alamat: alamat.isEmpty ? null : alamat,
                                        programId: selectedProgramId,
                                        // Pertahankan kolom legacy; pengajar dikelola di kelas pengajaran.
                                        pengajarId: lembaga.pengajarId,
                                        createdAt: lembaga.createdAt,
                                      );
                                      success = await lembagaProvider.update(
                                        updated,
                                        loadingProvider: dialogContext
                                            .read<LoadingProvider>(),
                                      );
                                    } else {
                                      success = await lembagaProvider.create(
                                        namaLembaga: nama,
                                        pbmType: selectedPbmType,
                                        alamat: alamat.isEmpty ? null : alamat,
                                        programId: selectedProgramId,
                                        loadingProvider: dialogContext
                                            .read<LoadingProvider>(),
                                      );
                                    }

                                    if (!context.mounted) return;

                                    if (success) {
                                      Navigator.pop(dialogContext);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEdit
                                                ? 'Lembaga berhasil diperbarui'
                                                : 'Lembaga berhasil ditambahkan',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      final error =
                                          lembagaProvider.errorMessage ??
                                          'Terjadi kesalahan';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            child: lembagaProvider.isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(isEdit ? 'Simpan Perubahan' : 'Simpan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  void _confirmDelete(BuildContext context, LembagaModel lembaga) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Hapus Lembaga',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah kamu yakin ingin menghapus "${lembaga.namaLembaga}"? Data tidak dapat dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final provider = context.read<LembagaProvider>();
                final success = await provider.delete(
                  lembaga.id,
                  loadingProvider: context.read<LoadingProvider>(),
                );
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Lembaga dihapus'
                          : provider.errorMessage ?? 'Gagal menghapus',
                    ),
                    backgroundColor: success
                        ? Colors.green
                        : const Color.fromARGB(255, 8, 6, 6),
                  ),
                );
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}

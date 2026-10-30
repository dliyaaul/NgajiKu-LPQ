import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/santri_program/santri_program_model.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';
import 'package:ptl_mobile/ui_pages/widget/santri_program_create_form.dart';
import 'package:ptl_mobile/ui_pages/widget/santri_program_edit_form.dart';

import 'package:ptl_mobile/state_management/lembaga_provider.dart';
import 'package:ptl_mobile/state_management/profile_provider.dart';
import 'package:ptl_mobile/state_management/program_provider.dart';
import 'package:ptl_mobile/state_management/kelas_type_provider.dart';
import 'package:ptl_mobile/state_management/santri_program_provider.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _backgroundColor = Color(0xFFF8FAFA);
const Color _textColor = Color(0xFF263238);
const Color _secondaryTextColor = Color(0xFF607D8B);

class SantriProgramPage extends StatefulWidget {
  const SantriProgramPage({super.key});

  @override
  State<SantriProgramPage> createState() => _SantriProgramPageState();
}

class _SantriProgramPageState extends State<SantriProgramPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // ============================================================
  // EXPAND CARD
  // ============================================================

  String? _expandedId;

  // ============================================================
  // FILTER
  // ============================================================

  String _selectedSumber = 'Semua';

  String? _selectedProgram;
  String? _selectedPbm;
  String? _selectedKelasType;
  String? _selectedPengajar;
  String? _selectedKelasPengajaran;

  final Set<String> _expandedProgramIds = {};
  final Set<String> _expandedClassIds = {};

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    final santriProgramProvider = context.read<SantriProgramProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final programProvider = context.read<ProgramProvider>();
    final loadingProvider = context.read<LoadingProvider>();
    final kelasTypeProvider = context.read<KelasTypeProvider>();
    final lembagaProvider = context.read<LembagaProvider>();

    await Future.wait([
      santriProgramProvider.loadAll(loadingProvider),
      profileProvider.loadSantri(loadingProvider),
      profileProvider.loadPengajar(loadingProvider),
      programProvider.loadAll(loadingProvider),
      kelasTypeProvider.loadAll(loadingProvider),
      lembagaProvider.loadAll(loadingProvider),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER DATA
  // ============================================================

  List<SantriProgramModel> _filteredItems(List<SantriProgramModel> items) {
    return items.where((item) {
      final santriName = item.santri?.username.toLowerCase() ?? '';
      final pengajarName = item.pengajar?.username.toLowerCase() ?? '';
      final programName = item.program?.nama.toLowerCase() ?? '';
      final kelasTypeName = item.kelasType?.nama.toLowerCase() ?? '';
      final kelasName = item.kelasPengajaran?.namaKelas.toLowerCase() ?? '';
      final lembagaName = item.lembaga?.namaLembaga.toLowerCase() ?? '';
      final pbm = item.defaultPbm.toLowerCase();

      final matchesSearch =
          _searchQuery.isEmpty ||
          santriName.contains(_searchQuery) ||
          pengajarName.contains(_searchQuery) ||
          programName.contains(_searchQuery) ||
          kelasTypeName.contains(_searchQuery) ||
          kelasName.contains(_searchQuery) ||
          lembagaName.contains(_searchQuery) ||
          pbm.contains(_searchQuery);

      final sumber = item.lembaga == null ? 'Individu' : 'Lembaga';

      final matchesSumber =
          _selectedSumber == 'Semua' || sumber == _selectedSumber;

      final matchesProgram =
          _selectedProgram == null || item.programId == _selectedProgram;

      final matchesPbm =
          _selectedPbm == null || item.defaultPbm == _selectedPbm;

      final matchesKelasType =
          _selectedKelasType == null || item.kelasTypeId == _selectedKelasType;

      final matchesKelasPengajaran =
          _selectedKelasPengajaran == null ||
          item.kelasPengajaranId == _selectedKelasPengajaran;

      final matchesPengajar =
          _selectedPengajar == null || item.pengajarId == _selectedPengajar;

      return matchesSearch &&
          matchesSumber &&
          matchesProgram &&
          matchesPbm &&
          matchesKelasType &&
          matchesKelasPengajaran &&
          matchesPengajar;
    }).toList();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedSumber != 'Semua') count++;
    if (_selectedProgram != null) count++;
    if (_selectedPbm != null) count++;
    if (_selectedKelasType != null) count++;
    if (_selectedKelasPengajaran != null) count++;
    if (_selectedPengajar != null) count++;
    return count;
  }

  bool get _hasActiveFilter => _activeFilterCount > 0;

  void _resetFilters() {
    setState(() {
      _selectedSumber = 'Semua';
      _selectedProgram = null;
      _selectedPbm = null;
      _selectedKelasType = null;
      _selectedPengajar = null;
      _expandedId = null;
      _selectedKelasPengajaran = null;
      _expandedProgramIds.clear();
      _expandedClassIds.clear();
    });
  }

  void _toggleCard(String id) {
    setState(() {
      _expandedId = (_expandedId == id) ? null : id;
    });
  }

  Future<void> _showCreateForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SantriProgramCreateForm()),
    );

    if (result == true && mounted) {
      await context.read<SantriProgramProvider>().loadAll(
        context.read<LoadingProvider>(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program santri berhasil ditambahkan'),
          backgroundColor: _primaryColor,
        ),
      );
    }
  }

  Future<void> _showEditForm(SantriProgramModel item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SantriProgramEditForm(existing: item)),
    );

    if (result == true && mounted) {
      await context.read<SantriProgramProvider>().loadAll(
        context.read<LoadingProvider>(),
      );

      if (!mounted) return;

      setState(() {
        _expandedId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program santri berhasil diperbarui'),
          backgroundColor: _primaryColor,
        ),
      );
    }
  }

  Future<void> _deleteItem(SantriProgramModel item) async {
    final santriName = item.santri?.username ?? 'Santri';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Program Santri'),
          content: Text(
            'Apakah Anda yakin ingin menghapus program untuk "$santriName"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<SantriProgramProvider>();
    final success = await provider.delete(
      item.id,
      loadingProvider: context.read<LoadingProvider>(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _expandedId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program santri berhasil dihapus')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal menghapus program santri',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Program Santri',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<SantriProgramProvider>(
        builder: (context, provider, _) {
          final items = _filteredItems(provider.items);

          return RefreshIndicator(
            color: _primaryColor,
            onRefresh: _loadData,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    isMobile ? 16 : 24,
                    isMobile ? 16 : 24,
                    100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        isMobile: isMobile,
                        totalData: provider.items.length,
                      ),
                      const SizedBox(height: 18),
                      _buildSearchAndAction(isMobile: isMobile),
                      const SizedBox(height: 14),
                      _buildFilterSummary(),
                      const SizedBox(height: 16),
                      if (provider.errorMessage != null)
                        _buildError(provider.errorMessage!)
                      else if (items.isEmpty)
                        _buildEmpty()
                      else
                        _buildExpandableList(items, isMobile),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateForm,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Program',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader({required bool isMobile, required int totalData}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school_rounded, color: _primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Program Santri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalData data program santri',
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalData',
                style: const TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndAction({required bool isMobile}) {
    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari santri, program, kelas, atau pengajar...',
        hintStyle: const TextStyle(color: _secondaryTextColor, fontSize: 13),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _secondaryTextColor,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () => _searchController.clear(),
                icon: const Icon(Icons.clear_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );

    final filterButton = OutlinedButton.icon(
      onPressed: () => _showFilterSheet(isMobile),
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Filter'),
          if (_activeFilterCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_activeFilterCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _activeFilterCount > 0 ? _primaryColor : _textColor,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: _activeFilterCount > 0 ? _primaryColor : Colors.grey.shade300,
        ),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: filterButton),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 10),
        filterButton,
      ],
    );
  }

  Widget _buildFilterSummary() {
    if (!_hasActiveFilter) return const SizedBox.shrink();

    final chips = <Widget>[];

    if (_selectedSumber != 'Semua') {
      chips.add(
        _buildActiveFilterChip(
          label: _selectedSumber,
          onRemove: () => setState(() => _selectedSumber = 'Semua'),
        ),
      );
    }

    if (_selectedProgram != null) {
      final programProvider = context.read<ProgramProvider>();
      String label = 'Program';
      for (final item in programProvider.items) {
        if (item.id == _selectedProgram) {
          label = item.nama;
          break;
        }
      }
      chips.add(
        _buildActiveFilterChip(
          label: label,
          onRemove: () => setState(() => _selectedProgram = null),
        ),
      );
    }

    if (_selectedPbm != null) {
      chips.add(
        _buildActiveFilterChip(
          label: _selectedPbm!,
          onRemove: () => setState(() => _selectedPbm = null),
        ),
      );
    }

    if (_selectedKelasType != null) {
      final kelasProvider = context.read<KelasTypeProvider>();
      String label = 'Jenis Kelas';
      for (final item in kelasProvider.items) {
        if (item.id == _selectedKelasType) {
          label = item.nama;
          break;
        }
      }
      chips.add(
        _buildActiveFilterChip(
          label: label,
          onRemove: () => setState(() => _selectedKelasType = null),
        ),
      );
    }

    if (_selectedKelasPengajaran != null) {
      final allItems = context.read<SantriProgramProvider>().items;
      String label = 'Kelas Operasional';

      for (final item in allItems) {
        if (item.kelasPengajaranId == _selectedKelasPengajaran) {
          label = item.kelasPengajaran?.namaKelas ?? label;
          break;
        }
      }

      chips.add(
        _buildActiveFilterChip(
          label: label,
          onRemove: () {
            setState(() => _selectedKelasPengajaran = null);
          },
        ),
      );
    }

    if (_selectedPengajar != null) {
      final profileProvider = context.read<ProfileProvider>();
      String label = 'Pengajar';
      for (final item in profileProvider.pengajar) {
        if (item.id == _selectedPengajar) {
          label = item.username;
          break;
        }
      }
      chips.add(
        _buildActiveFilterChip(
          label: label,
          onRemove: () => setState(() => _selectedPengajar = null),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          ...chips,
          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.restart_alt_rounded, size: 17),
            label: const Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.close_rounded, size: 15, color: _primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet(bool isMobile) async {
    final allItems = context.read<SantriProgramProvider>().items;

    final classMap = <String, String>{};

    for (final item in allItems) {
      final id = item.kelasPengajaranId;
      final name = item.kelasPengajaran?.namaKelas;

      if (id != null && name != null && name.trim().isNotEmpty) {
        classMap[id] = name;
      }
    }

    final kelasOptions =
        classMap.entries
            .map((entry) => _PickerOption(id: entry.key, label: entry.value))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterPanel(
          selectedSumber: _selectedSumber,
          selectedProgram: _selectedProgram,
          selectedPbm: _selectedPbm,
          selectedKelasType: _selectedKelasType,
          selectedPengajar: _selectedPengajar,
          isMobile: isMobile,
          selectedKelasPengajaran: _selectedKelasPengajaran,
          kelasPengajaranOptions: kelasOptions,
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedSumber = result['sumber'] as String;
      _selectedProgram = result['program'] as String?;
      _selectedPbm = result['pbm'] as String?;
      _selectedKelasType = result['kelasType'] as String?;
      _selectedPengajar = result['pengajar'] as String?;
      _selectedKelasPengajaran = result['kelasPengajaran'] as String?;
      _expandedId = null;
      _expandedProgramIds.clear();
      _expandedClassIds.clear();
    });
  }

  Widget _buildExpandableList(List<SantriProgramModel> items, bool isMobile) {
    final grouped = <String, List<SantriProgramModel>>{};

    for (final item in items) {
      grouped.putIfAbsent(item.programId, () => []).add(item);
    }

    final programGroups = grouped.entries.toList()
      ..sort((a, b) {
        final nameA = a.value.first.program?.nama ?? '';
        final nameB = b.value.first.program?.nama ?? '';
        return nameA.compareTo(nameB);
      });

    return Column(
      children: programGroups.map((entry) {
        return _buildProgramGroup(entry.key, entry.value, isMobile);
      }).toList(),
    );
  }

  Widget _buildProgramGroup(
    String programId,
    List<SantriProgramModel> items,
    bool isMobile,
  ) {
    final programName = items.first.program?.nama ?? 'Program lainnya';
    final isExpanded = _expandedProgramIds.contains(programId);

    final classGroups = <String, List<SantriProgramModel>>{};

    for (final item in items) {
      // Jika kelas operasional belum ditentukan, kelompokkan
      // berdasarkan jenis kelas agar datanya tetap terlihat.
      final classKey =
          item.kelasPengajaranId ?? 'belum-ditentukan-${item.kelasTypeId}';

      classGroups.putIfAbsent(classKey, () => []).add(item);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedProgramIds.remove(programId);
                } else {
                  _expandedProgramIds.add(programId);
                }
              });
            },
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 15 : 19),
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
                      Icons.menu_book_rounded,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          programName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${items.length} pendaftaran • '
                          '${classGroups.length} kelompok kelas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 10 : 16,
                0,
                isMobile ? 10 : 16,
                14,
              ),
              child: Column(
                children: classGroups.entries.map((classEntry) {
                  return _buildClassGroup(
                    programId,
                    classEntry.key,
                    classEntry.value,
                    isMobile,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassGroup(
    String programId,
    String classKey,
    List<SantriProgramModel> items,
    bool isMobile,
  ) {
    final first = items.first;
    final className =
        first.kelasPengajaran?.namaKelas ??
        '${first.kelasType?.nama ?? 'Kelas'} • Belum ditentukan';

    final expansionKey = '$programId::$classKey';
    final isExpanded = _expandedClassIds.contains(expansionKey);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedClassIds.remove(expansionKey);
                } else {
                  _expandedClassIds.add(expansionKey);
                }
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: 13,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.groups_2_outlined,
                      color: _primaryColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          className,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${items.length} santri',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                children: items.map((item) {
                  return _buildExpandableCard(
                    item,
                    _expandedId == item.id,
                    isMobile,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableCard(
    SantriProgramModel item,
    bool isExpanded,
    bool isMobile,
  ) {
    final santriName = item.santri?.username ?? 'Santri';
    final programName = item.program?.nama ?? '-';
    final isLembaga = item.lembaga != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? _primaryColor.withValues(alpha: 0.35)
              : Colors.grey.shade200,
          width: isExpanded ? 1.2 : 1,
        ),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _toggleCard(item.id),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 18,
                vertical: 13,
              ),
              child: Row(
                children: [
                  _buildAvatar(santriName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          santriName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 14,
                              color: _secondaryTextColor,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                programName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPbmBadge(item.defaultPbm),
                  const SizedBox(width: 5),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: isExpanded
                ? _buildExpandedContent(item, isLembaga)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(SantriProgramModel item, bool isLembaga) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),
          _buildDetailItem(
            icon: Icons.groups_outlined,
            label: 'Sumber',
            value: isLembaga ? 'Lembaga' : 'Individu',
          ),
          if (item.lembaga != null)
            _buildDetailItem(
              icon: Icons.business_outlined,
              label: 'Lembaga',
              value: item.lembaga!.namaLembaga,
            ),
          _buildDetailItem(
            icon: Icons.menu_book_outlined,
            label: 'Program',
            value: item.program?.nama ?? '-',
          ),
          _buildDetailItem(
            icon: Icons.class_outlined,
            label: 'Jenis Kelas',
            value: item.kelasType?.nama ?? '-',
          ),
          _buildDetailItem(
            icon: Icons.person_outline_rounded,
            label: 'Pengajar',
            value: item.pengajar?.username ?? '-',
          ),
          _buildDetailItem(
            icon: Icons.wifi_rounded,
            label: 'PBM',
            value: item.defaultPbm,
            showDivider: false,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEditForm(item),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryColor,
                  side: BorderSide(
                    color: _primaryColor.withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _deleteItem(item),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: _primaryColor),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: _textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withValues(alpha: 0.16),
            _primaryColor.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(name),
        style: const TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '?';

    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _buildPbmBadge(String pbm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        pbm,
        style: const TextStyle(
          color: _primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final hasSearch = _searchQuery.isNotEmpty;
    final hasFilter = _hasActiveFilter;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            hasSearch || hasFilter
                ? Icons.filter_alt_off_rounded
                : Icons.school_outlined,
            size: 52,
            color: _secondaryTextColor,
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch || hasFilter
                ? 'Data tidak ditemukan'
                : 'Belum ada program santri',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch || hasFilter
                ? 'Coba ubah kata pencarian atau filter yang digunakan.'
                : 'Silakan tambahkan program santri baru.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _secondaryTextColor),
          ),
          if (hasSearch || hasFilter) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _resetFilters();
                });
              },
              child: const Text('Reset pencarian & filter'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FILTER PANEL
// ============================================================================

class _FilterPanel extends StatefulWidget {
  final String selectedSumber;
  final String? selectedProgram;
  final String? selectedPbm;
  final String? selectedKelasType;
  final String? selectedPengajar;
  final bool isMobile;
  final String? selectedKelasPengajaran;
  final List<_PickerOption> kelasPengajaranOptions;

  const _FilterPanel({
    required this.selectedSumber,
    required this.selectedProgram,
    required this.selectedPbm,
    required this.selectedKelasType,
    required this.selectedPengajar,
    required this.isMobile,
    required this.selectedKelasPengajaran,
    required this.kelasPengajaranOptions,
  });

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late String _sumber;
  String? _program;
  String? _pbm;
  String? _kelasType;
  String? _pengajar;
  String? _kelasPengajaran;

  @override
  void initState() {
    super.initState();
    _sumber = widget.selectedSumber;
    _program = widget.selectedProgram;
    _pbm = widget.selectedPbm;
    _kelasType = widget.selectedKelasType;
    _pengajar = widget.selectedPengajar;
    _kelasPengajaran = widget.selectedKelasPengajaran;
  }

  void _apply() {
    Navigator.pop(context, {
      'sumber': _sumber,
      'program': _program,
      'pbm': _pbm,
      'kelasType': _kelasType,
      'pengajar': _pengajar,
      'kelasPengajaran': _kelasPengajaran,
    });
  }

  void _reset() {
    setState(() {
      _sumber = 'Semua';
      _program = null;
      _pbm = null;
      _kelasType = null;
      _pengajar = null;
      _kelasPengajaran = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    if (widget.isMobile) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: content,
      );
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 700),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final programProvider = context.read<ProgramProvider>();
    final kelasTypeProvider = context.read<KelasTypeProvider>();
    final profileProvider = context.read<ProfileProvider>();

    String selectedProgramText = 'Semua Program';
    if (_program != null) {
      final found = programProvider.items.where((e) => e.id == _program);
      if (found.isNotEmpty) selectedProgramText = found.first.nama;
    }

    String selectedKelasText = 'Semua Jenis Kelas';
    if (_kelasType != null) {
      final found = kelasTypeProvider.items.where((e) => e.id == _kelasType);
      if (found.isNotEmpty) selectedKelasText = found.first.nama;
    }

    String selectedPengajarText = 'Semua Pengajar';
    if (_pengajar != null) {
      final found = profileProvider.pengajar.where((e) => e.id == _pengajar);
      if (found.isNotEmpty) selectedPengajarText = found.first.username;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isMobile)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

        // HEADER PANEL
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: _primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Program',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sesuaikan opsi untuk memfilter data',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: Colors.grey.shade200),

        // BODY PANEL
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Sumber Program'),
                const SizedBox(height: 10),
                _buildChoiceRow(
                  values: const ['Semua', 'Individu', 'Lembaga'],
                  selected: _sumber,
                  onSelected: (value) {
                    setState(() {
                      _sumber = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // TRIGGER PICKER PROGRAM
                _buildModalSelectorTile(
                  label: 'Program',
                  icon: Icons.auto_stories_rounded,
                  selectedValueText: selectedProgramText,
                  isSelected: _program != null,
                  onTap: () {
                    final options = [
                      const _PickerOption(id: null, label: 'Semua Program'),
                      ...programProvider.items.map(
                        (e) => _PickerOption(id: e.id, label: e.nama),
                      ),
                    ];

                    _showCustomPickerBottomSheet(
                      title: 'Pilih Program',
                      options: options,
                      currentSelectedId: _program,
                      onSelected: (id) => setState(() => _program = id),
                    );
                  },
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('Metode PBM'),
                const SizedBox(height: 10),
                _buildChoiceRow(
                  values: const ['Offline', 'Online'],
                  selected: _pbm,
                  allowAll: true,
                  onSelected: (value) {
                    setState(() {
                      _pbm = value;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // TRIGGER PICKER KELAS
                _buildModalSelectorTile(
                  label: 'Jenis Kelas',
                  icon: Icons.door_front_door_rounded,
                  selectedValueText: selectedKelasText,
                  isSelected: _kelasType != null,
                  onTap: () {
                    final options = [
                      const _PickerOption(id: null, label: 'Semua Jenis Kelas'),
                      ...kelasTypeProvider.items.map(
                        (e) => _PickerOption(id: e.id, label: e.nama),
                      ),
                    ];

                    _showCustomPickerBottomSheet(
                      title: 'Pilih Jenis Kelas',
                      options: options,
                      currentSelectedId: _kelasType,
                      onSelected: (id) => setState(() => _kelasType = id),
                    );
                  },
                ),

                const SizedBox(height: 20),

                _buildModalSelectorTile(
                  label: 'Kelas Operasional',
                  icon: Icons.meeting_room_outlined,
                  selectedValueText: _kelasPengajaran == null
                      ? 'Semua Kelas'
                      : widget.kelasPengajaranOptions
                                .where((e) => e.id == _kelasPengajaran)
                                .map((e) => e.label)
                                .firstOrNull ??
                            'Kelas terpilih',
                  isSelected: _kelasPengajaran != null,
                  onTap: () {
                    _showCustomPickerBottomSheet(
                      title: 'Pilih Kelas Operasional',
                      options: [
                        const _PickerOption(id: null, label: 'Semua Kelas'),
                        ...widget.kelasPengajaranOptions,
                      ],
                      currentSelectedId: _kelasPengajaran,
                      onSelected: (id) {
                        setState(() => _kelasPengajaran = id);
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                // TRIGGER PICKER PENGAJAR
                _buildModalSelectorTile(
                  label: 'Pengajar',
                  icon: Icons.badge_rounded,
                  selectedValueText: selectedPengajarText,
                  isSelected: _pengajar != null,
                  onTap: () {
                    final options = [
                      const _PickerOption(id: null, label: 'Semua Pengajar'),
                      ...profileProvider.pengajar.map(
                        (e) => _PickerOption(id: e.id, label: e.username),
                      ),
                    ];

                    _showCustomPickerBottomSheet(
                      title: 'Pilih Pengajar',
                      options: options,
                      currentSelectedId: _pengajar,
                      onSelected: (id) => setState(() => _pengajar = id),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // BOTTOM ACTION BUTTONS
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _secondaryTextColor,
                    side: BorderSide(color: Colors.grey.shade300),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    minimumSize: const Size(0, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Terapkan Filter',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _textColor,
      ),
    );
  }

  Widget _buildChoiceRow({
    required List<String> values,
    required String? selected,
    required ValueChanged<String?> onSelected,
    bool allowAll = false,
  }) {
    final allValues = allowAll ? ['Semua', ...values] : values;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allValues.map((value) {
        final isSelected = value == 'Semua'
            ? selected == null
            : selected == value;

        return ChoiceChip(
          label: Text(value),
          selected: isSelected,
          onSelected: (_) {
            if (value == 'Semua') {
              onSelected(null);
            } else {
              onSelected(value);
            }
          },
          labelStyle: TextStyle(
            color: isSelected ? _primaryColor : _textColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
          backgroundColor: Colors.grey.shade100,
          selectedColor: _primaryColor.withValues(alpha: 0.12),
          side: BorderSide(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: isSelected ? 1.5 : 0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModalSelectorTile({
    required String label,
    required IconData icon,
    required String selectedValueText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryColor.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _primaryColor : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryColor.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? _primaryColor : _secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedValueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected ? _primaryColor : _textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryColor.withValues(alpha: 0.10)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: isSelected ? _primaryColor : _secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomPickerBottomSheet({
    required String title,
    required List<_PickerOption> options,
    required String? currentSelectedId,
    required ValueChanged<String?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CustomPickerSheet(
          title: title,
          options: options,
          currentSelectedId: currentSelectedId,
          onSelected: onSelected,
        );
      },
    );
  }
}

class _PickerOption {
  final String? id;
  final String label;

  const _PickerOption({required this.id, required this.label});
}

class _CustomPickerSheet extends StatefulWidget {
  final String title;
  final List<_PickerOption> options;
  final String? currentSelectedId;
  final ValueChanged<String?> onSelected;

  const _CustomPickerSheet({
    required this.title,
    required this.options,
    required this.currentSelectedId,
    required this.onSelected,
  });

  @override
  State<_CustomPickerSheet> createState() => _CustomPickerSheetState();
}

class _CustomPickerSheetState extends State<_CustomPickerSheet> {
  final TextEditingController _pickerSearchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _pickerSearchController.addListener(() {
      setState(() {
        _query = _pickerSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _pickerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = widget.options.where((option) {
      return option.label.toLowerCase().contains(_query);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          if (widget.options.length > 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _pickerSearchController,
                decoration: InputDecoration(
                  hintText: 'Cari kata kunci...',
                  hintStyle: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: _secondaryTextColor,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          onPressed: () => _pickerSearchController.clear(),
                          icon: const Icon(Icons.clear_rounded, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade200),
          Flexible(
            child: filteredOptions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(36.0),
                    child: Text(
                      'Opsi tidak ditemukan',
                      style: TextStyle(color: _secondaryTextColor),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = filteredOptions[index];
                      final isSelected = option.id == widget.currentSelectedId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              widget.onSelected(option.id);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _primaryColor.withValues(alpha: 0.08)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? _primaryColor
                                      : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? _primaryColor
                                            : _textColor,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: _primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

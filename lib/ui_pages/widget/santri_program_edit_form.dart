import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/santri_program/santri_program_model.dart';
import 'package:ptl_mobile/models/kelas/kelas_pengajaran_model.dart';
import 'package:ptl_mobile/services/kelas_pengajaran_service.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';
import 'package:ptl_mobile/state_management/profile_provider.dart';
import 'package:ptl_mobile/state_management/program_provider.dart';
import 'package:ptl_mobile/state_management/kelas_type_provider.dart';
import 'package:ptl_mobile/state_management/lembaga_provider.dart';
import 'package:ptl_mobile/state_management/santri_program_provider.dart';
import 'package:ptl_mobile/state_management/pengajar_program_provider.dart';
import 'package:ptl_mobile/models/kelas/riwayat_kelas_santri_model.dart';
import 'package:ptl_mobile/services/riwayat_kelas_santri_service.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _textColor = Color(0xFF263238);
const Color _labelColor = Color(0xFF455A64);

class SantriProgramEditForm extends StatefulWidget {
  final SantriProgramModel existing;

  const SantriProgramEditForm({super.key, required this.existing});

  @override
  State<SantriProgramEditForm> createState() => _SantriProgramEditFormState();
}

class _SantriProgramEditFormState extends State<SantriProgramEditForm> {
  final _formKey = GlobalKey<FormState>();

  String? _santriId;
  String? _programId;
  String? _kelasTypeId;
  String? _kelasPengajaranId;
  List<KelasPengajaranModel> _kelasPengajaranItems = [];
  bool _isLoadingKelasPengajaran = false;
  String? _kelasPengajaranLoadError;
  String? _pengajarId;
  String? _lembagaId;

  String _sumberProgram = 'Individu';
  String _defaultPbm = 'Offline';

  final List<String> _pbmTypes = ['Offline', 'Online'];

  @override
  void initState() {
    super.initState();
    _loadKelasPengajaran();

    _santriId = widget.existing.santriId;
    _programId = widget.existing.programId;
    _kelasTypeId = widget.existing.kelasTypeId;
    _kelasPengajaranId = widget.existing.kelasPengajaranId;
    _pengajarId = widget.existing.pengajarId;
    _lembagaId = widget.existing.lembagaId;

    _sumberProgram = widget.existing.lembagaId != null ? 'Lembaga' : 'Individu';

    _defaultPbm = widget.existing.defaultPbm.isNotEmpty
        ? widget.existing.defaultPbm
        : 'Offline';

    if (_sumberProgram == 'Individu' && _programId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        context.read<PengajarProgramProvider>().loadPengajarByProgram(
          _programId!,
        );
      });
    }
  }

  Future<void> _loadKelasPengajaran() async {
    setState(() {
      _isLoadingKelasPengajaran = true;
      _kelasPengajaranLoadError = null;
    });
    try {
      final items = await KelasPengajaranService().getActive();
      if (!mounted) return;
      setState(() => _kelasPengajaranItems = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _kelasPengajaranLoadError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingKelasPengajaran = false);
    }
  }

  List<KelasPengajaranModel> get _kelasPengajaranFiltered {
    if (_programId == null || _kelasTypeId == null) return [];
    return _kelasPengajaranItems.where((kelas) {
      if (kelas.programId != _programId || kelas.kelasTypeId != _kelasTypeId) {
        return false;
      }
      if (_sumberProgram == 'Lembaga') {
        return _lembagaId != null && kelas.lembagaId == _lembagaId;
      }
      return kelas.lembagaId == null;
    }).toList();
  }

  void _onKelasPengajaranChanged(String? id) {
    if (id == null) return;
    final matches = _kelasPengajaranItems.where((item) => item.id == id);
    if (matches.isEmpty) return;
    final kelas = matches.first;
    setState(() {
      _kelasPengajaranId = kelas.id;
      _kelasTypeId = kelas.kelasTypeId;
      _pengajarId = kelas.pengajarId;
      _lembagaId = kelas.lembagaId;
    });
  }

  Widget _buildKelasPengajaranPicker() {
    final options = _kelasPengajaranFiltered;
    final selected = _kelasPengajaranItems.where(
      (item) => item.id == _kelasPengajaranId,
    );
    return _buildPickerField<String>(
      label: 'Kelas Pengajaran',
      value: _kelasPengajaranId,
      hint: _isLoadingKelasPengajaran
          ? 'Memuat kelas...'
          : _programId == null || _kelasTypeId == null
          ? 'Pilih program dan jenis kelas terlebih dahulu'
          : options.isEmpty
          ? 'Belum ada kelas yang sesuai'
          : 'Pilih kelas pengajaran',
      icon: Icons.meeting_room_outlined,
      displayValue: selected.isEmpty ? null : selected.first.namaKelas,
      onTap: _isLoadingKelasPengajaran || options.isEmpty
          ? null
          : () => _showCustomBottomSheet<String>(
              title: 'Pilih Kelas Pengajaran',
              selectedValue: _kelasPengajaranId,
              items: options
                  .map(
                    (kelas) => BottomSheetItem<String>(
                      value: kelas.id,
                      title: kelas.namaKelas,
                      icon: Icons.meeting_room_outlined,
                    ),
                  )
                  .toList(),
              onSelected: _onKelasPengajaranChanged,
            ),
      validator: (_) {
        if (_kelasPengajaranId == null || _kelasPengajaranId!.isEmpty) {
          return _kelasPengajaranLoadError == null
              ? 'Kelas pengajaran wajib dipilih'
              : 'Gagal memuat kelas. Muat ulang halaman dan coba lagi';
        }
        return null;
      },
    );
  }

  // ============================================================
  // CUSTOM BOTTOM SHEET PICKER
  // ============================================================

  Future<void> _showCustomBottomSheet<T>({
    required String title,
    required List<BottomSheetItem<T>> items,
    required T? selectedValue,
    required Function(T) onSelected,
  }) async {
    final result = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CustomSelectionBottomSheet<T>(
          title: title,
          items: items,
          selectedValue: selectedValue,
        );
      },
    );

    if (result != null) {
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final santriProvider = context.watch<ProfileProvider>();
    final programProvider = context.watch<ProgramProvider>();
    final kelasTypeProvider = context.watch<KelasTypeProvider>();
    final lembagaProvider = context.watch<LembagaProvider>();
    final santriProgramProvider = context.watch<SantriProgramProvider>();
    final pengajarProgramProvider = context.watch<PengajarProgramProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Edit Program Santri',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        iconTheme: const IconThemeData(color: _textColor),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Data Program'),

                    const SizedBox(height: 16),

                    // Santri Picker
                    _buildPickerField<String>(
                      label: 'Santri',
                      value: _santriId,
                      hint: 'Pilih santri',
                      icon: Icons.person_outline,
                      displayValue: santriProvider.santri
                          .where((s) => s.id == _santriId)
                          .map((s) => s.username)
                          .firstOrNull,
                      onTap: () {
                        _showCustomBottomSheet<String>(
                          title: 'Pilih Santri',
                          selectedValue: _santriId,
                          items: santriProvider.santri
                              .map(
                                (s) => BottomSheetItem<String>(
                                  value: s.id,
                                  title: s.username,
                                  icon: Icons.person_outline,
                                ),
                              )
                              .toList(),
                          onSelected: (value) {
                            setState(() {
                              _santriId = value;
                            });
                          },
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Santri wajib dipilih';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildSourceSelector(),

                    if (_sumberProgram == 'Lembaga') ...[
                      const SizedBox(height: 16),

                      // Lembaga Picker
                      _buildPickerField<String>(
                        label: 'Lembaga',
                        value: _lembagaId,
                        hint: 'Pilih lembaga',
                        icon: Icons.business_outlined,
                        displayValue: lembagaProvider.items
                            .where((l) => l.id == _lembagaId)
                            .map((l) => l.namaLembaga)
                            .firstOrNull,
                        onTap: () {
                          _showCustomBottomSheet<String>(
                            title: 'Pilih Lembaga',
                            selectedValue: _lembagaId,
                            items: lembagaProvider.items
                                .map(
                                  (l) => BottomSheetItem<String>(
                                    value: l.id,
                                    title: l.namaLembaga,
                                    icon: Icons.business_outlined,
                                  ),
                                )
                                .toList(),
                            onSelected: _onLembagaChanged,
                          );
                        },
                        validator: (value) {
                          if (_sumberProgram == 'Lembaga' &&
                              (value == null || value.isEmpty)) {
                            return 'Lembaga wajib dipilih';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 16),

                    if (_sumberProgram == 'Lembaga')
                      _buildReadonlyInfo(
                        label: 'Program',
                        value: _getProgramName(programProvider),
                        icon: Icons.menu_book_outlined,
                      )
                    else
                      _buildPickerField<String>(
                        label: 'Program',
                        value: _programId,
                        hint: 'Pilih program',
                        icon: Icons.menu_book_outlined,
                        displayValue: programProvider.items
                            .where((p) => p.id == _programId)
                            .map((p) => p.nama)
                            .firstOrNull,
                        onTap: () {
                          _showCustomBottomSheet<String>(
                            title: 'Pilih Program',
                            selectedValue: _programId,
                            items: programProvider.items
                                .map(
                                  (p) => BottomSheetItem<String>(
                                    value: p.id,
                                    title: p.nama,
                                    icon: Icons.menu_book_outlined,
                                  ),
                                )
                                .toList(),
                            onSelected: _onProgramChanged,
                          );
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Program wajib dipilih';
                          }
                          return null;
                        },
                      ),

                    const SizedBox(height: 16),

                    if (_sumberProgram == 'Lembaga')
                      _buildReadonlyInfo(
                        label: 'Jenis Kelas',
                        value: _getKelasTypeName(kelasTypeProvider),
                        icon: Icons.class_outlined,
                      )
                    else
                      _buildPickerField<String>(
                        label: 'Jenis Kelas',
                        value: _kelasTypeId,
                        hint: 'Pilih jenis kelas',
                        icon: Icons.class_outlined,
                        displayValue: kelasTypeProvider.items
                            .where((k) => k.id == _kelasTypeId)
                            .map((k) => k.nama)
                            .firstOrNull,
                        onTap: () {
                          final filteredList = kelasTypeProvider.items
                              .where(
                                (kelas) =>
                                    kelas.nama.toLowerCase() != 'lembaga',
                              )
                              .toList();

                          _showCustomBottomSheet<String>(
                            title: 'Pilih Jenis Kelas',
                            selectedValue: _kelasTypeId,
                            items: filteredList
                                .map(
                                  (k) => BottomSheetItem<String>(
                                    value: k.id,
                                    title: k.nama,
                                    icon: Icons.class_outlined,
                                  ),
                                )
                                .toList(),
                            onSelected: (value) {
                              setState(() {
                                _kelasTypeId = value;
                                _kelasPengajaranId = null;
                              });
                            },
                          );
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jenis kelas wajib dipilih';
                          }
                          return null;
                        },
                      ),

                    _buildKelasPengajaranPicker(),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _showRiwayatKelas,
                        icon: const Icon(Icons.history, size: 18),
                        label: const Text('Lihat Riwayat Kelas'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: const BorderSide(color: _primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_sumberProgram == 'Lembaga' ||
                        _kelasPengajaranId != null)
                      _buildReadonlyInfo(
                        label: 'Pengajar',
                        value: _getPengajarName(santriProvider),
                        icon: Icons.co_present_outlined,
                      )
                    else
                      _buildPengajarPicker(pengajarProgramProvider),

                    const SizedBox(height: 16),

                    if (_sumberProgram == 'Lembaga')
                      _buildReadonlyInfo(
                        label: 'PBM',
                        value: _defaultPbm,
                        icon: Icons.location_on_outlined,
                      )
                    else
                      _buildPickerField<String>(
                        label: 'PBM',
                        value: _defaultPbm,
                        hint: 'Pilih PBM',
                        icon: Icons.location_on_outlined,
                        displayValue: _defaultPbm,
                        onTap: () {
                          _showCustomBottomSheet<String>(
                            title: 'Pilih Metode PBM',
                            selectedValue: _defaultPbm,
                            items: _pbmTypes
                                .map(
                                  (type) => BottomSheetItem<String>(
                                    value: type,
                                    title: type,
                                    icon: type == 'Offline'
                                        ? Icons.location_on_outlined
                                        : Icons.language,
                                  ),
                                )
                                .toList(),
                            onSelected: (value) {
                              setState(() {
                                _defaultPbm = value;
                              });
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 28),

                    _buildSubmitButton(
                      isSaving: santriProgramProvider.isSaving,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onProgramChanged(String? programId) async {
    if (programId == null) return;

    setState(() {
      _programId = programId;
      _pengajarId = null;
      _kelasPengajaranId = null;
    });

    final pengajarProgramProvider = context.read<PengajarProgramProvider>();

    await pengajarProgramProvider.loadPengajarByProgram(programId);

    if (!mounted) return;
  }

  Widget _buildPengajarPicker(PengajarProgramProvider provider) {
    final isLoading = provider.isLoadingPengajar;
    final hasProgram = _programId != null;
    final items = provider.pengajarByProgram;

    final hint = !hasProgram
        ? 'Pilih program terlebih dahulu'
        : isLoading
        ? 'Memuat pengajar...'
        : items.isEmpty
        ? 'Tidak ada pengajar pada program ini'
        : 'Pilih pengajar';

    String? displayValue;
    if (_pengajarId != null) {
      final selected = items.where((p) => p['id']?.toString() == _pengajarId);
      if (selected.isNotEmpty) {
        displayValue = selected.first['username']?.toString();
      }
    }

    return _buildPickerField<String>(
      label: 'Pengajar',
      value: _pengajarId,
      hint: hint,
      icon: Icons.co_present_outlined,
      displayValue: displayValue,
      onTap: (!hasProgram || isLoading || items.isEmpty)
          ? null
          : () {
              _showCustomBottomSheet<String>(
                title: 'Pilih Pengajar',
                selectedValue: _pengajarId,
                items: items
                    .map(
                      (p) => BottomSheetItem<String>(
                        value: p['id']?.toString() ?? '',
                        title: p['username']?.toString() ?? '-',
                        icon: Icons.person_outline,
                      ),
                    )
                    .toList(),
                onSelected: (value) {
                  setState(() {
                    _pengajarId = value;
                    _kelasPengajaranId = null;
                  });
                },
              );
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pengajar wajib dipilih';
        }
        return null;
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: _primaryColor,
      ),
    );
  }

  Widget _buildSourceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Sumber Program'),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _buildSourceOption(
                title: 'Individu',
                icon: Icons.person_outline,
                selected: _sumberProgram == 'Individu',
                onTap: () {
                  context
                      .read<PengajarProgramProvider>()
                      .clearPengajarByProgram();

                  setState(() {
                    _sumberProgram = 'Individu';
                    _lembagaId = null;
                    _programId = null;
                    _pengajarId = null;
                    _kelasTypeId = null;
                    _kelasPengajaranId = null;
                    _defaultPbm = 'Offline';
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSourceOption(
                title: 'Lembaga',
                icon: Icons.business_outlined,
                selected: _sumberProgram == 'Lembaga',
                onTap: () {
                  context
                      .read<PengajarProgramProvider>()
                      .clearPengajarByProgram();

                  setState(() {
                    _sumberProgram = 'Lembaga';
                    _lembagaId = null;
                    _programId = null;
                    _pengajarId = null;
                    _kelasTypeId = null;
                    _kelasPengajaranId = null;
                    _defaultPbm = 'Offline';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onLembagaChanged(String? lembagaId) {
    if (lembagaId == null) return;

    final lembagaProvider = context.read<LembagaProvider>();
    final kelasTypeProvider = context.read<KelasTypeProvider>();

    final lembaga = lembagaProvider.items.firstWhere(
      (item) => item.id == lembagaId,
    );

    final kelasLembaga = kelasTypeProvider.items.where(
      (item) => item.nama.toLowerCase() == 'lembaga',
    );

    if (kelasLembaga.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jenis kelas "Lembaga" belum tersedia.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (lembaga.programId == null || lembaga.pengajarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Data program atau pengajar pada lembaga belum lengkap.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _lembagaId = lembaga.id;
      _kelasPengajaranId = null;
      _programId = lembaga.programId;
      _pengajarId = lembaga.pengajarId;
      _defaultPbm = lembaga.pbmType;
      _kelasTypeId = kelasLembaga.first.id;
    });
  }

  String _getProgramName(ProgramProvider provider) {
    if (_programId == null) return '-';
    try {
      return provider.items.firstWhere((item) => item.id == _programId).nama;
    } catch (_) {
      return '-';
    }
  }

  String _getKelasTypeName(KelasTypeProvider provider) {
    if (_kelasTypeId == null) return '-';
    try {
      return provider.items.firstWhere((item) => item.id == _kelasTypeId).nama;
    } catch (_) {
      return '-';
    }
  }

  String _getPengajarName(ProfileProvider provider) {
    if (_pengajarId == null) return '-';
    try {
      return provider.pengajar
          .firstWhere((item) => item.id == _pengajarId)
          .username;
    } catch (_) {
      return '-';
    }
  }

  Widget _buildSourceOption({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? _primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _primaryColor : const Color(0xFFECEFF1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? _primaryColor : const Color(0xFF607D8B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? _primaryColor : _textColor,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, size: 18, color: _primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: _labelColor,
      ),
    );
  }

  Widget _buildReadonlyInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E7E7)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF607D8B)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline,
                size: 17,
                color: Color(0xFF90A4AE),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Picker Trigger Field menggantikan Dropdown
  Widget _buildPickerField<T>({
    required String label,
    required T? value,
    required String hint,
    required IconData icon,
    required String? displayValue,
    required VoidCallback? onTap,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),

        FormField<T>(
          initialValue: value,
          validator: validator,
          builder: (state) {
            final hasError = state.hasError;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasError
                            ? Colors.redAccent
                            : const Color(0xFFECEFF1),
                        width: hasError ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: const Color(0xFF607D8B)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            displayValue ?? hint,
                            style: TextStyle(
                              fontSize: 14,
                              color: displayValue != null
                                  ? _textColor
                                  : Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
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
      ],
    );
  }

  Widget _buildSubmitButton({required bool isSaving}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isSaving ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryColor.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Simpan Perubahan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _showRiwayatKelas() async {
    final future = RiwayatKelasSantriService().getBySantriProgram(
      widget.existing.id,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.history, color: _primaryColor),
              SizedBox(width: 10),
              Expanded(child: Text('Riwayat Kelas Santri')),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: FutureBuilder<List<RiwayatKelasSantriModel>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Riwayat kelas gagal dimuat.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Belum ada riwayat kelas untuk pendaftaran ini.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final asal =
                          item.namaKelasAsal ??
                          (item.kelasAsalId == null
                              ? 'Pendaftaran awal'
                              : 'Kelas sebelumnya');
                      final tujuan =
                          item.namaKelasTujuan ??
                          (item.kelasTujuanId == null
                              ? 'Tidak ada kelas'
                              : 'Kelas tujuan');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.kelasAsalId == null
                                ? 'Penempatan awal'
                                : 'Perpindahan kelas',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.meeting_room_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text('$asal → $tujuan')),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Berlaku mulai: ${_formatTanggalRiwayat(item.berlakuMulai)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _labelColor,
                            ),
                          ),
                          if (item.alasan != null &&
                              item.alasan!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Alasan: ${item.alasan}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  String _formatTanggalRiwayat(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_sumberProgram == 'Lembaga') {
      if (_lembagaId == null ||
          _programId == null ||
          _kelasTypeId == null ||
          _pengajarId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Data lembaga belum lengkap. Silakan pilih lembaga kembali.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    final provider = context.read<SantriProgramProvider>();
    final loadingProvider = context.read<LoadingProvider>();

    final data = SantriProgramModel(
      id: widget.existing.id,
      santriId: _santriId!,
      programId: _programId!,
      kelasTypeId: _kelasTypeId!,
      kelasPengajaranId: _kelasPengajaranId!,
      pengajarId: _pengajarId,
      lembagaId: _sumberProgram == 'Lembaga' ? _lembagaId : null,
      defaultPbm: _defaultPbm,
      createdAt: widget.existing.createdAt,
    );

    final success = await provider.update(
      data,
      loadingProvider: loadingProvider,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal memperbarui program santri',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

// ============================================================
// HELPER MODELS & CUSTOM BOTTOM SHEET WIDGET
// ============================================================

class BottomSheetItem<T> {
  final T value;
  final String title;
  final IconData? icon;

  BottomSheetItem({required this.value, required this.title, this.icon});
}

class _CustomSelectionBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<BottomSheetItem<T>> items;
  final T? selectedValue;

  const _CustomSelectionBottomSheet({
    required this.title,
    required this.items,
    required this.selectedValue,
  });

  @override
  State<_CustomSelectionBottomSheet<T>> createState() =>
      __CustomSelectionBottomSheetState<T>();
}

class __CustomSelectionBottomSheetState<T>
    extends State<_CustomSelectionBottomSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<BottomSheetItem<T>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where(
              (item) => item.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header title & close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          // Search Field jika opsi lebih dari 5
          if (widget.items.length > 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filterItems,
                decoration: InputDecoration(
                  hintText: 'Cari...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          const Divider(height: 1),

          // List options
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Pilihan tidak ditemukan',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 64),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = widget.selectedValue == item.value;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? _primaryColor.withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          child: Icon(
                            item.icon ?? Icons.label_outline,
                            color: isSelected
                                ? _primaryColor
                                : Colors.grey.shade600,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? _primaryColor : _textColor,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: _primaryColor,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, item.value),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

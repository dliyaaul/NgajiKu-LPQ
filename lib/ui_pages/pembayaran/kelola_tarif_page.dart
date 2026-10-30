import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/models/pembayaran/pembayaran_tarif_model.dart';
import 'package:ptl_mobile/state_management/pembayaran/pembayaran_tarif_provider.dart';
import 'package:ptl_mobile/utils/pembayaran_format.dart';

class KelolaTarifPage extends StatefulWidget {
  const KelolaTarifPage({super.key});

  @override
  State<KelolaTarifPage> createState() => _KelolaTarifPageState();
}

class _KelolaTarifPageState extends State<KelolaTarifPage> {
  static const _regulerId = '12539687-7c5a-4a53-8064-26673ed22c31';
  static const _privatId = '1f1e32c6-5d16-4fec-9f7e-80e48a555bd8';
  static const _lembagaId = '501fd6e7-3560-4c8e-b89a-58e3d62d8d0f';

  static const _primary = Color(0xFF0D8B8B);
  static const _background = Color(0xFFF8FAFA);

  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _lembaga = [];
  List<Map<String, dynamic>> _santriPrograms = [];
  Map<String, String> _namaSantri = {};

  bool _loadingReferensi = true;
  bool _loadingData = true;
  String? _error;
  String _filterJenis = 'semua';
  String _filterStatus = 'aktif';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _muatSemua();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _muatSemua() async {
    if (!mounted) return;

    setState(() {
      _loadingData = true;
      _error = null;
    });

    try {
      await Future.wait([
        context.read<PembayaranTarifProvider>().loadData(),
        _muatReferensi(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
      }
    }
  }

  Future<void> _muatReferensi() async {
    setState(() => _loadingReferensi = true);

    try {
      final db = Supabase.instance.client;

      final results = await Future.wait([
        db.from('programs').select('id, nama').order('nama'),
        db
            .from('lembaga')
            .select('id, nama_lembaga, program_id')
            .order('nama_lembaga'),
        db
            .from('santri_programs')
            .select('id, santri_id, program_id, kelas_type_id'),
        db.from('profiles').select('id, username'),
      ]);

      final programs = List<Map<String, dynamic>>.from(results[0]);
      final lembaga = List<Map<String, dynamic>>.from(results[1]);
      final santriPrograms = List<Map<String, dynamic>>.from(results[2]);
      final profiles = List<Map<String, dynamic>>.from(results[3]);

      final namaSantri = <String, String>{};
      for (final profile in profiles) {
        namaSantri[profile['id'].toString()] = (profile['username'] ?? 'Santri')
            .toString();
      }

      if (!mounted) return;

      setState(() {
        _programs = programs;
        _lembaga = lembaga;
        _santriPrograms = santriPrograms;
        _namaSantri = namaSantri;
      });
    } catch (e) {
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _loadingReferensi = false);
      }
    }
  }

  String _namaJenis(String id) {
    if (id == _regulerId) return 'Reguler';
    if (id == _privatId) return 'Privat';
    if (id == _lembagaId) return 'Lembaga';
    return 'Tidak diketahui';
  }

  String _namaProgram(String? id) {
    if (id == null) return 'Semua program';

    for (final item in _programs) {
      if (item['id'].toString() == id) {
        return (item['nama'] ?? '-').toString();
      }
    }

    return '-';
  }

  String _namaLembaga(String? id) {
    if (id == null) return '-';

    for (final item in _lembaga) {
      if (item['id'].toString() == id) {
        return (item['nama_lembaga'] ?? '-').toString();
      }
    }
    return '-';
  }

  String _namaSantriProgram(String? id) {
    if (id == null) return '-';

    for (final item in _santriPrograms) {
      if (item['id'].toString() == id) {
        final santriId = item['santri_id']?.toString();
        final nama = _namaSantri[santriId] ?? 'Santri';
        final program = _namaProgram(item['program_id']?.toString());
        return '$nama • $program';
      }
    }
    return '-';
  }

  List<PembayaranTarifModel> _filterItems(List<PembayaranTarifModel> items) {
    final keyword = _searchController.text.trim().toLowerCase();

    return items.where((item) {
      _namaJenis(item.kelasTypeId).toLowerCase();

      final target = item.kelasTypeId == _privatId
          ? _namaSantriProgram(item.santriProgramId)
          : item.kelasTypeId == _lembagaId
          ? '${_namaLembaga(item.lembagaId)} ${_namaProgram(item.programId)}'
          : _namaProgram(item.programId);

      final cocokPencarian =
          keyword.isEmpty ||
          item.namaTarif.toLowerCase().contains(keyword) ||
          target.toLowerCase().contains(keyword);

      final cocokJenis =
          _filterJenis == 'semua' || item.kelasTypeId == _filterJenis;

      final cocokStatus =
          _filterStatus == 'semua' ||
          (_filterStatus == 'aktif' && item.aktif) ||
          (_filterStatus == 'nonaktif' && !item.aktif);

      return cocokPencarian && cocokJenis && cocokStatus;
    }).toList();
  }

  Future<void> _bukaForm({PembayaranTarifModel? tarif}) async {
    if (_loadingReferensi) {
      _pesan('Data referensi masih dimuat.');
      return;
    }

    final hasil = await showModalBottomSheet<PembayaranTarifModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormTarifSheet(
        tarif: tarif,
        programs: _programs,
        lembaga: _lembaga,
        santriPrograms: _santriPrograms,
        namaSantri: _namaSantri,
        namaProgram: _namaProgram,
      ),
    );

    if (hasil == null || !mounted) return;

    try {
      final provider = context.read<PembayaranTarifProvider>();

      if (tarif == null) {
        await provider.tambah(hasil);
      } else {
        await provider.ubah(tarif.id, hasil);
      }

      if (!mounted) return;
      _pesan(
        tarif == null
            ? 'Tarif berhasil ditambahkan.'
            : 'Tarif berhasil diperbarui.',
      );
    } catch (e) {
      if (!mounted) return;
      _pesan('Gagal menyimpan tarif: $e');
    }
  }

  Future<void> _ubahStatus(PembayaranTarifModel tarif) async {
    final aktifBaru = !tarif.aktif;
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(aktifBaru ? 'Aktifkan tarif?' : 'Nonaktifkan tarif?'),
        content: Text(
          'Tarif "${tarif.namaTarif}" akan '
          '${aktifBaru ? 'diaktifkan' : 'dinonaktifkan'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, lanjutkan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    try {
      await context.read<PembayaranTarifProvider>().ubahStatus(
        id: tarif.id,
        aktif: aktifBaru,
      );

      if (!mounted) return;
      _pesan(aktifBaru ? 'Tarif diaktifkan.' : 'Tarif dinonaktifkan.');
    } catch (e) {
      if (!mounted) return;
      _pesan('Gagal mengubah status tarif: $e');
    }
  }

  void _pesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Kelola Tarif',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _muatSemua,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadingReferensi ? null : () => _bukaForm(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Tarif'),
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : Consumer<PembayaranTarifProvider>(
              builder: (context, provider, _) {
                final items = _filterItems(provider.items);

                return RefreshIndicator(
                  onRefresh: _muatSemua,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _buildRingkasan(provider.items),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari nama tarif atau target...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFilter(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Daftar Tarif',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${items.length} tarif',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (items.isEmpty)
                        _buildKosong()
                      else
                        ...items.map(_buildTarifCard),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _muatSemua, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }

  Widget _buildRingkasan(List<PembayaranTarifModel> items) {
    final aktif = items.where((e) => e.aktif).length;
    final nonaktif = items.length - aktif;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Tarif',
            value: '${items.length}',
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Aktif',
            value: '$aktif',
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Nonaktif',
            value: '$nonaktif',
            icon: Icons.pause_circle_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Tarif',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chipJenis('Semua', 'semua'),
              _chipJenis('Reguler', _regulerId),
              _chipJenis('Privat', _privatId),
              _chipJenis('Lembaga', _lembagaId),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'aktif', label: Text('Aktif')),
            ButtonSegment(value: 'nonaktif', label: Text('Nonaktif')),
            ButtonSegment(value: 'semua', label: Text('Semua')),
          ],
          selected: {_filterStatus},
          onSelectionChanged: (values) {
            setState(() => _filterStatus = values.first);
          },
        ),
      ],
    );
  }

  Widget _chipJenis(String label, String value) {
    final selected = _filterJenis == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filterJenis = value),
        selectedColor: _primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? _primary : Colors.black87,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTarifCard(PembayaranTarifModel tarif) {
    final jenis = _namaJenis(tarif.kelasTypeId);

    final target = tarif.kelasTypeId == _privatId
        ? _namaSantriProgram(tarif.santriProgramId)
        : tarif.kelasTypeId == _lembagaId
        ? '${_namaLembaga(tarif.lembagaId)} • '
              '${_namaProgram(tarif.programId)}'
        : _namaProgram(tarif.programId);

    final satuan = tarif.satuan == 'bulan' ? '/ bulan' : '/ pertemuan';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jenis,
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tarif.aktif
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tarif.aktif ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      color: tarif.aktif ? Colors.green.shade700 : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _bukaForm(tarif: tarif);
                    } else if (value == 'status') {
                      _ubahStatus(tarif);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Ubah Tarif'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          tarif.aktif
                              ? Icons.pause_circle_outline
                              : Icons.check_circle_outline,
                        ),
                        title: Text(tarif.aktif ? 'Nonaktifkan' : 'Aktifkan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tarif.namaTarif,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  size: 17,
                  color: Colors.grey,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    target,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${formatRupiah(tarif.nominal)} $satuan',
              style: const TextStyle(
                fontSize: 18,
                color: _primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Berlaku mulai ${formatTanggal(tarif.berlakuMulai)}'
              '${tarif.berlakuSampai == null ? ' • Tanpa batas akhir' : ' sampai ${formatTanggal(tarif.berlakuSampai!)}'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKosong() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'Tarif tidak ditemukan',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          const Text(
            'Coba ubah filter atau tambahkan tarif baru.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0D8B8B), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _FormTarifSheet extends StatefulWidget {
  final PembayaranTarifModel? tarif;
  final List<Map<String, dynamic>> programs;
  final List<Map<String, dynamic>> lembaga;
  final List<Map<String, dynamic>> santriPrograms;
  final Map<String, String> namaSantri;
  final String Function(String?) namaProgram;

  const _FormTarifSheet({
    required this.tarif,
    required this.programs,
    required this.lembaga,
    required this.santriPrograms,
    required this.namaSantri,
    required this.namaProgram,
  });

  @override
  State<_FormTarifSheet> createState() => _FormTarifSheetState();
}

class _FormTarifSheetState extends State<_FormTarifSheet> {
  static const _regulerId = '12539687-7c5a-4a53-8064-26673ed22c31';
  static const _privatId = '1f1e32c6-5d16-4fec-9f7e-80e48a555bd8';
  static const _lembagaId = '501fd6e7-3560-4c8e-b89a-58e3d62d8d0f';

  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nominalController = TextEditingController();

  late String _kelasTypeId;
  String? _programId;
  String? _santriProgramId;
  String? _lembagaIdValue;
  late DateTime _berlakuMulai;
  DateTime? _berlakuSampai;
  bool _aktif = true;

  @override
  void initState() {
    super.initState();

    final tarif = widget.tarif;
    _kelasTypeId = tarif?.kelasTypeId ?? _regulerId;
    _namaController.text = tarif?.namaTarif ?? '';
    _nominalController.text = tarif?.nominal.toStringAsFixed(0) ?? '';
    _programId = tarif?.programId;
    _santriProgramId = tarif?.santriProgramId;
    _lembagaIdValue = tarif?.lembagaId;
    _berlakuMulai = tarif?.berlakuMulai ?? DateTime.now();
    _berlakuSampai = tarif?.berlakuSampai;
    _aktif = tarif?.aktif ?? true;

    _sinkronkanTarget();
  }

  void _sinkronkanTarget() {
    if (_kelasTypeId == _regulerId) {
      _programId = null;
      _santriProgramId = null;
      _lembagaIdValue = null;
    } else if (_kelasTypeId == _privatId) {
      _programId = null;
      _lembagaIdValue = null;
    } else if (_kelasTypeId == _lembagaId) {
      _santriProgramId = null;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _santriPrivat {
    return widget.santriPrograms.where((item) {
      return item['kelas_type_id']?.toString() == _privatId;
    }).toList();
  }

  bool get _adaSantriPrivat => _santriPrivat.isNotEmpty;

  /// Program yang terhubung ke lembaga terpilih melalui lembaga.program_id.
  List<Map<String, dynamic>> get _programLembaga {
    if (_lembagaIdValue == null) return [];

    final lembagaTerpilih = widget.lembaga.firstWhere(
      (item) => item['id'].toString() == _lembagaIdValue,
      orElse: () => <String, dynamic>{},
    );

    final programId = lembagaTerpilih['program_id']?.toString();
    if (programId == null || programId.isEmpty) return [];

    return widget.programs.where((program) {
      return program['id'].toString() == programId;
    }).toList();
  }

  Future<void> _pilihTanggalMulai() async {
    final tanggal = await showDatePicker(
      context: context,
      initialDate: _berlakuMulai,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (tanggal != null) setState(() => _berlakuMulai = tanggal);
  }

  Future<void> _pilihTanggalSampai() async {
    final tanggal = await showDatePicker(
      context: context,
      initialDate: _berlakuSampai ?? _berlakuMulai,
      firstDate: _berlakuMulai,
      lastDate: DateTime(2100),
    );

    if (tanggal != null) setState(() => _berlakuSampai = tanggal);
  }

  String _namaTargetPrivat(Map<String, dynamic> item) {
    final nama = widget.namaSantri[item['santri_id']?.toString()] ?? 'Santri';
    final program = widget.namaProgram(item['program_id']?.toString());
    return '$nama • $program';
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    if (_kelasTypeId == _privatId) {
      if (!_adaSantriPrivat) {
        _pesan(
          'Tarif Privat tidak dapat dibuat karena belum ada '
          'data santri Privat.',
        );
        return;
      }

      if (_santriProgramId == null) {
        _pesan('Pilih santri Privat terlebih dahulu.');
        return;
      }
    }

    if (_kelasTypeId == _lembagaId) {
      if (_lembagaIdValue == null) {
        _pesan('Pilih lembaga terlebih dahulu.');
        return;
      }

      final programLembaga = _programLembaga;
      if (programLembaga.isEmpty) {
        _pesan('Lembaga yang dipilih belum memiliki program.');
        return;
      }

      final programValid = programLembaga.any(
        (program) => program['id'].toString() == _programId,
      );
      if (!programValid) {
        _pesan('Program harus sesuai dengan program milik lembaga.');
        return;
      }
    }

    final nominal = double.tryParse(
      _nominalController.text.trim().replaceAll('.', '').replaceAll(',', '.'),
    );

    if (nominal == null || nominal <= 0) {
      _pesan('Nominal tarif harus lebih besar dari nol.');
      return;
    }

    if (_berlakuSampai != null && _berlakuSampai!.isBefore(_berlakuMulai)) {
      _pesan('Tanggal akhir tidak boleh sebelum tanggal mulai.');
      return;
    }

    final tarifLama = widget.tarif;

    final tarif = PembayaranTarifModel(
      id: tarifLama?.id ?? '',
      namaTarif: _namaController.text.trim(),
      kelasTypeId: _kelasTypeId,

      // Reguler adalah tarif umum, bukan tarif per program.
      programId: _kelasTypeId == _regulerId ? null : _programId,

      santriProgramId: _kelasTypeId == _privatId ? _santriProgramId : null,

      lembagaId: _kelasTypeId == _lembagaId ? _lembagaIdValue : null,

      nominal: nominal,
      satuan: _kelasTypeId == _regulerId ? 'bulan' : 'pertemuan',
      berlakuMulai: _berlakuMulai,
      berlakuSampai: _berlakuSampai,
      aktif: _aktif,
      createdBy: tarifLama?.createdBy,
      createdAt: tarifLama?.createdAt,
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, tarif);
  }

  void _pesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tarif != null;

    return Padding(
      padding: EdgeInsets.only(
        top: 40,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isEdit ? 'Ubah Tarif' : 'Tambah Tarif Baru',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _kelasTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Tarif',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: _regulerId, child: Text('Reguler')),
                    DropdownMenuItem(value: _privatId, child: Text('Privat')),
                    DropdownMenuItem(value: _lembagaId, child: Text('Lembaga')),
                  ],
                  onChanged: isEdit
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _kelasTypeId = value;
                            _programId = null;
                            _santriProgramId = null;
                            _lembagaIdValue = null;
                            _sinkronkanTarget();
                          });
                        },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Tarif',
                    hintText: 'Contoh: Tarif BBAQ Reguler',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tarif wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                if (_kelasTypeId == _privatId) ...[
                  if (_adaSantriPrivat)
                    _dropdownSantriPrivat()
                  else
                    _buildSantriPrivatKosong(),
                ],
                if (_kelasTypeId == _lembagaId) ...[
                  _dropdownLembaga(),
                  const SizedBox(height: 14),
                  _dropdownProgramLembaga(),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nominalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nominal Tarif',
                    prefixText: 'Rp ',
                    suffixText: _kelasTypeId == _regulerId
                        ? '/ bulan'
                        : '/ pertemuan',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nominal wajib diisi.';
                    }

                    final parsed = double.tryParse(
                      value.trim().replaceAll('.', '').replaceAll(',', '.'),
                    );

                    if (parsed == null || parsed < 0) {
                      return 'Masukkan nominal yang valid.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _tanggalField(
                  label: 'Berlaku Mulai',
                  value: formatTanggal(_berlakuMulai),
                  onTap: _pilihTanggalMulai,
                ),
                const SizedBox(height: 12),
                _tanggalField(
                  label: 'Berlaku Sampai (Opsional)',
                  value: _berlakuSampai == null
                      ? 'Tanpa batas akhir'
                      : formatTanggal(_berlakuSampai!),
                  onTap: _pilihTanggalSampai,
                  onClear: _berlakuSampai == null
                      ? null
                      : () => setState(() => _berlakuSampai = null),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tarif aktif'),
                  subtitle: const Text(
                    'Tarif aktif dapat digunakan saat membuat tagihan.',
                  ),
                  value: _aktif,
                  activeThumbColor: const Color(0xFF0D8B8B),
                  onChanged: (value) => setState(() => _aktif = value),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _simpan,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D8B8B),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Tarif'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdownLembaga() {
    return DropdownButtonFormField<String>(
      value: _lembagaIdValue,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Lembaga',
        border: OutlineInputBorder(),
      ),
      items: widget.lembaga.map((item) {
        return DropdownMenuItem<String>(
          value: item['id'].toString(),
          child: Text(
            (item['nama_lembaga'] ?? '-').toString(),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _lembagaIdValue = value;
          _programId = null;

          if (value != null) {
            final lembagaTerpilih = widget.lembaga.firstWhere(
              (item) => item['id'].toString() == value,
              orElse: () => <String, dynamic>{},
            );
            _programId = lembagaTerpilih['program_id']?.toString();
          }
        });
      },
      validator: (value) => value == null ? 'Lembaga wajib dipilih.' : null,
    );
  }

  Widget _dropdownSantriPrivat() {
    final data = _santriPrivat;

    return DropdownButtonFormField<String>(
      value: data.any((e) => e['id'].toString() == _santriProgramId)
          ? _santriProgramId
          : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Santri Privat',
        border: OutlineInputBorder(),
      ),
      items: data.map((item) {
        return DropdownMenuItem<String>(
          value: item['id'].toString(),
          child: Text(_namaTargetPrivat(item), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _santriProgramId = value),
      validator: (value) =>
          value == null ? 'Pilih data santri-program privat.' : null,
    );
  }

  Widget _tanggalField({
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClear != null)
                IconButton(
                  tooltip: 'Hapus tanggal akhir',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
              const Icon(Icons.calendar_month_outlined),
              const SizedBox(width: 12),
            ],
          ),
        ),
        child: Text(value),
      ),
    );
  }

  Widget _buildSantriPrivatKosong() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data santri Privat belum tersedia',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Tambahkan atau daftarkan santri ke jenis kelas '
                  'Privat terlebih dahulu sebelum membuat tarif.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownProgramLembaga() {
    final programs = _programLembaga;

    return DropdownButtonFormField<String>(
      key: ValueKey('program-lembaga-$_lembagaIdValue-$_programId'),
      value: programs.any((item) => item['id'].toString() == _programId)
          ? _programId
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Program Lembaga',
        border: const OutlineInputBorder(),
        helperText: _lembagaIdValue == null
            ? 'Pilih lembaga untuk melihat programnya.'
            : programs.isEmpty
            ? 'Lembaga ini belum memiliki program.'
            : 'Program mengikuti data pada lembaga terpilih.',
      ),
      items: programs.map((program) {
        return DropdownMenuItem<String>(
          value: program['id'].toString(),
          child: Text(
            program['nama']?.toString() ?? '-',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: programs.isEmpty
          ? null
          : (value) {
              setState(() => _programId = value);
            },
      validator: (value) {
        if (_kelasTypeId != _lembagaId) return null;
        if (_lembagaIdValue == null) {
          return 'Pilih lembaga terlebih dahulu.';
        }
        if (programs.isEmpty) {
          return 'Lembaga belum memiliki program.';
        }
        if (value == null ||
            !programs.any((program) => program['id'].toString() == value)) {
          return 'Program harus sesuai dengan lembaga terpilih.';
        }
        return null;
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PembayaranRekeningPage extends StatefulWidget {
  const PembayaranRekeningPage({super.key});

  @override
  State<PembayaranRekeningPage> createState() => _PembayaranRekeningPageState();
}

class _PembayaranRekeningPageState extends State<PembayaranRekeningPage> {
  static const Color _primary = Color(0xFF0D8B8B);
  static const Color _background = Color(0xFFF8FAFA);

  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await _supabase
          .from('pembayaran_rekening')
          .select()
          .order('nama_bank');

      if (!mounted) return;

      setState(() {
        _items = response
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _pesan(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _tambahRekening() async {
    final result = await _bukaForm();

    if (result == null || !mounted) return;

    try {
      await _supabase.from('pembayaran_rekening').insert({
        'nama_bank': result['nama_bank'],
        'nomor_rekening': result['nomor_rekening'],
        'nama_pemilik': result['nama_pemilik'],
        'keterangan': result['keterangan'],
        'aktif': result['aktif'],
      });

      if (!mounted) return;

      _pesan('Rekening berhasil ditambahkan.');
      await _loadData();
    } catch (e) {
      _pesan('Gagal menambahkan rekening: $e');
    }
  }

  Future<void> _editRekening(Map<String, dynamic> item) async {
    final result = await _bukaForm(item: item);

    if (result == null || !mounted) return;

    try {
      await _supabase
          .from('pembayaran_rekening')
          .update({
            'nama_bank': result['nama_bank'],
            'nomor_rekening': result['nomor_rekening'],
            'nama_pemilik': result['nama_pemilik'],
            'keterangan': result['keterangan'],
            'aktif': result['aktif'],
          })
          .eq('id', item['id']);

      if (!mounted) return;

      _pesan('Rekening berhasil diperbarui.');
      await _loadData();
    } catch (e) {
      _pesan('Gagal memperbarui rekening: $e');
    }
  }

  Future<void> _ubahStatus(Map<String, dynamic> item) async {
    final aktif = item['aktif'] == true;
    final statusBaru = !aktif;

    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          statusBaru ? 'Aktifkan rekening?' : 'Nonaktifkan rekening?',
        ),
        content: Text(
          statusBaru
              ? 'Rekening ${item['nama_bank']} akan tersedia untuk pengajuan pembayaran.'
              : 'Rekening ${item['nama_bank']} tidak akan tersedia untuk pengajuan pembayaran baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: _primary),
            child: Text(statusBaru ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );

    if (setuju != true || !mounted) return;

    try {
      await _supabase
          .from('pembayaran_rekening')
          .update({'aktif': statusBaru})
          .eq('id', item['id']);

      if (!mounted) return;

      _pesan(
        statusBaru
            ? 'Rekening berhasil diaktifkan.'
            : 'Rekening berhasil dinonaktifkan.',
      );

      await _loadData();
    } catch (e) {
      _pesan('Gagal mengubah status rekening: $e');
    }
  }

  Future<Map<String, dynamic>?> _bukaForm({Map<String, dynamic>? item}) async {
    final formKey = GlobalKey<FormState>();

    final namaBankController = TextEditingController(
      text: item?['nama_bank']?.toString() ?? '',
    );
    final nomorRekeningController = TextEditingController(
      text: item?['nomor_rekening']?.toString() ?? '',
    );
    final namaPemilikController = TextEditingController(
      text: item?['nama_pemilik']?.toString() ?? '',
    );
    final keteranganController = TextEditingController(
      text: item?['keterangan']?.toString() ?? '',
    );

    bool aktif = item == null ? true : item['aktif'] == true;

    try {
      return await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item == null ? 'Tambah Rekening' : 'Edit Rekening',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF263238),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Isi informasi rekening tujuan pembayaran.',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: namaBankController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration('Nama bank'),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Nama bank wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: nomorRekeningController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Nomor rekening'),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Nomor rekening wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: namaPemilikController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              'Nama pemilik rekening',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Nama pemilik wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: keteranganController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              'Keterangan (opsional)',
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: _primary,
                            title: const Text(
                              'Rekening aktif',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Rekening aktif dapat dipilih untuk pembayaran.',
                            ),
                            value: aktif,
                            onChanged: (value) {
                              setSheetState(() => aktif = value);
                            },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                Navigator.pop(sheetContext, {
                                  'nama_bank': namaBankController.text.trim(),
                                  'nomor_rekening': nomorRekeningController.text
                                      .trim(),
                                  'nama_pemilik': namaPemilikController.text
                                      .trim(),
                                  'keterangan':
                                      keteranganController.text.trim().isEmpty
                                      ? null
                                      : keteranganController.text.trim(),
                                  'aktif': aktif,
                                });
                              },
                              child: Text(
                                item == null
                                    ? 'Simpan Rekening'
                                    : 'Simpan Perubahan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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
          );
        },
      );
    } finally {
      namaBankController.dispose();
      nomorRekeningController.dispose();
      namaPemilikController.dispose();
      keteranganController.dispose();
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFAFCFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E7E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E7E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aktifCount = _items.where((e) => e['aktif'] == true).length;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Rekening Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahRekening,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Rekening'),
      ),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null && _items.isEmpty
          ? _statusView()
          : RefreshIndicator(
              color: _primary,
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rekening tujuan',
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Kelola rekening pembayaran',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Total rekening',
                          _items.length.toString(),
                          Icons.account_balance_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Rekening aktif',
                          aktifCount.toString(),
                          Icons.check_circle_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    _errorBanner(),
                    const SizedBox(height: 12),
                  ],
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 54,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Belum ada rekening',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Tambahkan rekening agar dapat dipilih saat pengajuan pembayaran.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final item in _items) _rekeningCard(item),
                ],
              ),
            ),
    );
  }

  Widget _rekeningCard(Map<String, dynamic> item) {
    final aktif = item['aktif'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EEEE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6F5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: _primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nama_bank']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item['nomor_rekening']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'a.n. ${item['nama_pemilik'] ?? '-'}',
                        style: const TextStyle(
                          color: Color(0xFF607D8B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editRekening(item);
                    } else if (value == 'status') {
                      _ubahStatus(item);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit rekening'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          aktif
                              ? Icons.toggle_off_outlined
                              : Icons.toggle_on_outlined,
                        ),
                        title: Text(aktif ? 'Nonaktifkan' : 'Aktifkan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (item['keterangan'] != null &&
                item['keterangan'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                item['keterangan'].toString(),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: aktif
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF2F4F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    aktif ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      color: aktif ? const Color(0xFF2E7D32) : Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _editRekening(item),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: _primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _statusView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.black45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat rekening',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadData, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE4E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Gagal memuat ulang data: $_error',
        style: const TextStyle(color: Color(0xFFB42318)),
      ),
    );
  }
}

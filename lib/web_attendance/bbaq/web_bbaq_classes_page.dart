import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/models/kelas/kelas_pengajaran_model.dart';
import 'package:ptl_mobile/services/kelas_pengajaran_service.dart';
import 'web_bbaq_meetings_page.dart';

class WebBbaqClassesPage extends StatefulWidget {
  const WebBbaqClassesPage({super.key});

  @override
  State<WebBbaqClassesPage> createState() => _WebBbaqClassesPageState();
}

class _WebBbaqClassesPageState extends State<WebBbaqClassesPage> {
  final KelasPengajaranService _kelasService = KelasPengajaranService();

  List<KelasPengajaranModel> _kelas = [];
  final Map<String, int> _jumlahSantri = {};

  bool _isLoading = true;
  String? _error;
  String? _programId;

  static const Color _primary = Color(0xFF0D8B8B);

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
      // Cari program BBAQ berdasarkan nama program.
      final program = await Supabase.instance.client
          .from('programs')
          .select('id, nama')
          .ilike('nama', 'BBAQ')
          .maybeSingle();

      if (program == null) {
        throw Exception('Program BBAQ tidak ditemukan di tabel programs.');
      }

      final programId = program['id'].toString();
      final kelas = await _kelasService.getByProgram(programId);

      final counts = <String, int>{};

      // Ambil jumlah santri untuk setiap kelas.
      for (final item in kelas) {
        final rows = await Supabase.instance.client
            .from('santri_programs')
            .select('id')
            .eq('program_id', programId)
            .eq('kelas_pengajaran_id', item.id);

        counts[item.id] = (rows as List).length;
      }

      if (!mounted) return;

      setState(() {
        _programId = programId;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F8),
      appBar: AppBar(
        title: const Text(
          'Kelas Pengajaran BBAQ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _isLoading ? null : _loadKelas,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadKelas,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_kelas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadKelas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.class_outlined, size: 56, color: _primary),
            SizedBox(height: 16),
            Text(
              'Belum Ada Kelas BBAQ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Belum ditemukan kelas pengajaran untuk program ini.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadKelas,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pilih Kelas Pengajaran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_kelas.length} kelas ditemukan',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._kelas.map((kelas) {
            final jumlahSantri = _jumlahSantri[kelas.id] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F4F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_rounded, color: _primary),
                ),
                title: Text(
                  kelas.namaKelas,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${kelas.namaJenisKelas ?? 'Jenis kelas belum tersedia'}'
                    '\n${kelas.namaPengajar ?? 'Belum ada pengajar'}'
                    '\n$jumlahSantri santri',
                  ),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  final programId = _programId;
                  if (programId == null) return;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WebBbaqMeetingsPage(
                        programId: programId,
                        kelasPengajaranId: kelas.id,
                        namaKelas: kelas.namaKelas,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

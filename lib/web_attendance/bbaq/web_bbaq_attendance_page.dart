import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ptl_mobile/models/absensi_bbaq/bbaq_pertemuan_model.dart';
import 'package:ptl_mobile/services/absensi_bbaq_detail_service.dart';

class WebBbaqAttendancePage extends StatefulWidget {
  final String programId;
  final BbaqPertemuanModel pertemuan;
  final String namaKelas;

  const WebBbaqAttendancePage({
    super.key,
    required this.programId,
    required this.pertemuan,
    required this.namaKelas,
  });

  @override
  State<WebBbaqAttendancePage> createState() => _WebBbaqAttendancePageState();
}

class _WebBbaqAttendancePageState extends State<WebBbaqAttendancePage> {
  final _service = AbsensiBbaqDetailService();

  List<Map<String, dynamic>> _santri = [];
  Map<String, String> _status = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _filter = 'Semua';
  String _search = '';

  bool get _canInput => widget.pertemuan.canInputAbsensi;

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
      final kelasId = widget.pertemuan.kelasPengajaranId;
      if (kelasId == null || kelasId.trim().isEmpty) {
        throw Exception('Pertemuan belum terhubung dengan kelas pengajaran.');
      }

      final data = await _service.getDetailAbsensi(
        widget.pertemuan.id,
        widget.programId,
        kelasPengajaranId: kelasId,
      );

      final status = <String, String>{};
      for (final item in data) {
        final id = item['id'].toString();
        final absensi = item['absensi'];
        final raw = absensi is Map ? absensi['status']?.toString() : null;
        status[id] = _normalize(raw ?? 'Belum Absen');
      }

      if (!mounted) return;
      setState(() {
        _santri = data;
        _status = status;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _normalize(String value) {
    switch (value.trim().toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'izin':
        return 'Izin';
      case 'sakit':
        return 'Sakit';
      case 'alpa':
      case 'alpha':
        return 'Alpha';
      default:
        return 'Belum Absen';
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    if (!_canInput) {
      _message('Batas waktu input absensi telah berakhir.', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan absensi?'),
        content: Text(
          'Simpan status absensi untuk ${_status.values.where((s) => s != 'Belum Absen').length} santri?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final payload = _status.entries
          .map(
            (entry) => {
              'bbaq_pertemuan_id': widget.pertemuan.id,
              'santri_program_id': entry.key,
              'status': entry.value,
            },
          )
          .toList();

      await _service.saveAbsensiBatch(
        payload,
        createdAt: widget.pertemuan.createdAt,
      );

      if (!mounted) return;
      _message('Absensi berhasil disimpan.');
      await _loadData();
    } catch (e) {
      if (mounted) {
        _message(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hadir = _status.values.where((s) => s == 'Hadir').length;
    final izin = _status.values.where((s) => s == 'Izin').length;
    final sakit = _status.values.where((s) => s == 'Sakit').length;
    final alpha = _status.values.where((s) => s == 'Alpha').length;
    final belum = _status.values.where((s) => s == 'Belum Absen').length;

    final filtered = _santri.where((item) {
      final profile = item['santri'];
      final nama = profile is Map
          ? (profile['username'] ?? profile['email'] ?? 'Tanpa Nama').toString()
          : 'Tanpa Nama';

      final matchSearch = nama.toLowerCase().contains(_search.toLowerCase());
      final current = _status[item['id'].toString()] ?? 'Belum Absen';
      final matchFilter =
          _filter == 'Semua' ||
          (_filter == 'Belum Absen'
              ? current == 'Belum Absen'
              : current == _filter);

      return matchSearch && matchFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Absensi BBAQ • ${widget.namaKelas}'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 44,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(widget.pertemuan.tanggal),
                        ),
                        const SizedBox(height: 8),
                        Text('Materi: ${widget.pertemuan.materiPembelajaran}'),
                        const SizedBox(height: 8),
                        Text(
                          'Hadir $hadir  •  Izin $izin  •  Sakit $sakit  •  Alpha $alpha  •  Belum $belum',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _canInput
                              ? 'Input absensi masih dibuka'
                              : 'Waktu input absensi telah berakhir',
                          style: TextStyle(
                            color: _canInput ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Cari nama santri',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        'Semua',
                        'Hadir',
                        'Izin',
                        'Sakit',
                        'Alpha',
                        'Belum Absen',
                      ].map((value) {
                        return ChoiceChip(
                          label: Text(value),
                          selected: _filter == value,
                          onSelected: (_) => setState(() => _filter = value),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Tidak ada santri yang cocok.')),
                  ),
                ...filtered.map((item) {
                  final id = item['id'].toString();
                  final profile = item['santri'];
                  final nama = profile is Map
                      ? (profile['username'] ??
                                profile['email'] ??
                                'Tanpa Nama')
                            .toString()
                      : 'Tanpa Nama';
                  final selected = _status[id] ?? 'Belum Absen';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                [
                                      'Hadir',
                                      'Izin',
                                      'Sakit',
                                      'Alpha',
                                      'Belum Absen',
                                    ]
                                    .map(
                                      (value) => ChoiceChip(
                                        label: Text(value),
                                        selected: selected == value,
                                        onSelected: (!_canInput || _saving)
                                            ? null
                                            : (_) => setState(
                                                () => _status[id] = value,
                                              ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: (!_canInput || _saving || _status.isEmpty)
                        ? null
                        : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan Absensi'),
                  ),
                ),
              ],
            ),
    );
  }
}

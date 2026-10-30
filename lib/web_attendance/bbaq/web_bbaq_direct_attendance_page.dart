import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/models/absensi_bbaq/bbaq_pertemuan_model.dart';
import 'package:ptl_mobile/services/absensi_bbaq_service.dart';

import 'web_bbaq_attendance_page.dart';

class WebBbaqDirectAttendancePage extends StatefulWidget {
  final String pertemuanId;

  const WebBbaqDirectAttendancePage({super.key, required this.pertemuanId});

  @override
  State<WebBbaqDirectAttendancePage> createState() =>
      _WebBbaqDirectAttendancePageState();
}

class _WebBbaqDirectAttendancePageState
    extends State<WebBbaqDirectAttendancePage> {
  final AbsensiBbaqService _service = AbsensiBbaqService();

  bool _loading = true;
  String? _error;
  BbaqPertemuanModel? _pertemuan;
  String? _namaKelas;

  @override
  void initState() {
    super.initState();
    _loadPertemuan();
  }

  Future<void> _loadPertemuan() async {
    try {
      final pertemuan = await _service.getPertemuanById(widget.pertemuanId);

      if (pertemuan == null) {
        throw Exception('Pertemuan BBAQ tidak ditemukan.');
      }

      final kelasId = pertemuan.kelasPengajaranId;

      if (kelasId == null || kelasId.trim().isEmpty) {
        throw Exception(
          'Pertemuan ini belum terhubung dengan kelas pengajaran.',
        );
      }

      final kelas = await Supabase.instance.client
          .from('kelas_pengajaran')
          .select('nama_kelas')
          .eq('id', kelasId)
          .maybeSingle();

      if (kelas == null) {
        throw Exception('Data kelas pengajaran tidak ditemukan.');
      }

      if (!mounted) return;

      setState(() {
        _pertemuan = pertemuan;
        _namaKelas = kelas['nama_kelas']?.toString() ?? 'Kelas BBAQ';
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Absensi BBAQ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadPertemuan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pertemuan = _pertemuan!;

    return WebBbaqAttendancePage(
      programId: pertemuan.programId,
      pertemuan: pertemuan,
      namaKelas: _namaKelas!,
    );
  }
}

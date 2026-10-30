import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ptl_mobile/models/absensi_bbaq/bbaq_pertemuan_model.dart';
import 'package:ptl_mobile/services/absensi_bbaq_service.dart';
import 'web_bbaq_attendance_page.dart';

class WebBbaqMeetingsPage extends StatefulWidget {
  final String programId;
  final String kelasPengajaranId;
  final String namaKelas;

  const WebBbaqMeetingsPage({
    super.key,
    required this.programId,
    required this.kelasPengajaranId,
    required this.namaKelas,
  });

  @override
  State<WebBbaqMeetingsPage> createState() => _WebBbaqMeetingsPageState();
}

class _WebBbaqMeetingsPageState extends State<WebBbaqMeetingsPage> {
  final AbsensiBbaqService _service = AbsensiBbaqService();

  List<BbaqPertemuanModel> _pertemuan = [];
  bool _isLoading = true;
  String? _error;

  static const Color _primary = Color(0xFF0D8B8B);

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getPertemuanByKelas(
        kelasPengajaranId: widget.kelasPengajaranId,
      );

      if (!mounted) return;

      setState(() {
        _pertemuan = data;
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

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration == Duration.zero) return 'Waktu input berakhir';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) return '$hours jam $minutes menit';
    return '$minutes menit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F8),
      appBar: AppBar(
        title: Text(
          widget.namaKelas,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _isLoading ? null : _loadMeetings,
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
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadMeetings,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMeetings,
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
                  Icons.event_note_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pertemuan BBAQ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.namaKelas} • ${_pertemuan.length} pertemuan',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_pertemuan.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.event_busy_outlined, size: 52, color: _primary),
                  SizedBox(height: 12),
                  Text(
                    'Belum Ada Pertemuan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Belum ada pertemuan untuk kelas ini.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._pertemuan.map(_buildMeetingCard),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(BbaqPertemuanModel item) {
    final canInput = item.canInputAbsensi;
    final remaining = item.remainingAbsensiTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    color: const Color(0xFFE2F4F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: _primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(item.tanggal),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.namaPengajar ?? 'Pengajar belum tersedia',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Icon(
                  canInput ? Icons.check_circle_outline : Icons.lock_clock,
                  color: canInput ? _primary : Colors.orange.shade700,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow('Materi', item.materiPembelajaran ?? '-'),
            _infoRow('Metode', item.metode),
            _infoRow(
              'Status absensi',
              canInput
                  ? 'Tersedia • ${_formatTimeRemaining(remaining)}'
                  : 'Waktu input berakhir',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WebBbaqAttendancePage(
                        programId: widget.programId,
                        pertemuan: item,
                        namaKelas: widget.namaKelas,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('Lihat Absensi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

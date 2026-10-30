import 'package:flutter/material.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/absen/buat_absensi_ptl_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ==========================================
// HALAMAN REKAP ABSENSI PTL
// ==========================================

class PtlAbsensiPage extends StatefulWidget {
  const PtlAbsensiPage({super.key});

  @override
  State<PtlAbsensiPage> createState() => _PtlAbsensiPageState();
}

class _PtlAbsensiPageState extends State<PtlAbsensiPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoadingRekap = true;

  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _riwayatAbsensi = [];

  @override
  void initState() {
    super.initState();
    _fetchRekapAbsensi();
  }

  // ==========================================
  // FETCH DATA ABSENSI BERDASARKAN TANGGAL
  // ==========================================

  Future<void> _fetchRekapAbsensi() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRekap = true;
    });

    try {
      final startDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      final endDate = startDate.add(const Duration(days: 1));

      final startString = DateFormat('yyyy-MM-dd').format(startDate);

      final endString = DateFormat('yyyy-MM-dd').format(endDate);

      debugPrint('======================================');
      debugPrint('REKAP ABSENSI PTL');
      debugPrint('Tanggal: $startString');
      debugPrint('======================================');

      final response = await _supabase
          .from('absensi')
          .select(
            'id, user_id, created_by, kegiatan, tanggal, '
            'created_at, status, catatan',
          )
          .eq('program', 'PTL')
          .gte('tanggal', startString)
          .lt('tanggal', endString)
          .order('created_at', ascending: true)
          .limit(1000);

      final List<dynamic> data = response as List<dynamic>;

      // ==========================================
      // AMBIL SEMUA ID PROFILE
      // ==========================================

      final Set<String> profileIds = {};

      for (final item in data) {
        if (item['user_id'] != null) {
          profileIds.add(item['user_id'].toString());
        }

        if (item['created_by'] != null) {
          profileIds.add(item['created_by'].toString());
        }
      }

      // ==========================================
      // AMBIL NAMA PROFILE
      // ==========================================

      final Map<String, String> profileNames = {};

      if (profileIds.isNotEmpty) {
        final profilesResponse = await _supabase
            .from('profiles')
            .select('id, username')
            .inFilter('id', profileIds.toList());

        for (final profile in profilesResponse) {
          final id = profile['id']?.toString();

          if (id != null) {
            profileNames[id] = profile['username']?.toString() ?? 'Tanpa Nama';
          }
        }
      }

      // ==========================================
      // MAPPING DATA
      // ==========================================

      final mappedData = data.map<Map<String, dynamic>>((item) {
        final userId = item['user_id']?.toString();
        final createdBy = item['created_by']?.toString();

        return {
          'id': item['id'],
          'user_id': userId,
          'created_by': createdBy,

          'nama': profileNames[userId] ?? 'Santri PTL',

          'created_by_nama': profileNames[createdBy] ?? 'Tidak diketahui',

          'kegiatan': item['kegiatan'] ?? '-',
          'tanggal': item['tanggal'] ?? '-',
          'created_at': item['created_at'],

          'status': item['status'] ?? '-',
          'catatan': item['catatan'] ?? '',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _riwayatAbsensi = mappedData;
        _isLoadingRekap = false;
      });
    } catch (e) {
      debugPrint('ERROR REKAP ABSENSI: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingRekap = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat rekap absensi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // PILIH TANGGAL
  // ==========================================

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });

    await _fetchRekapAbsensi();
  }

  // ==========================================
  // FORMAT CREATED AT
  // ==========================================

  String _formatCreatedAt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(value.toString());

      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return '-';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  // ==========================================
  // GROUPING KEGIATAN
  // ==========================================

  Map<String, List<Map<String, dynamic>>> _groupByKegiatan() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in _riwayatAbsensi) {
      final kegiatan = item['kegiatan']?.toString() ?? 'Tanpa Kegiatan';

      grouped.putIfAbsent(kegiatan, () => []);
      grouped[kegiatan]!.add(item);
    }

    return grouped;
  }

  // ==========================================
  // SUMMARY
  // ==========================================

  int _countStatus(String status) {
    return _riwayatAbsensi
        .where((item) => item['status']?.toString() == status)
        .length;
  }

  int _countSantri() {
    final ids = <String>{};

    for (final item in _riwayatAbsensi) {
      final id = item['user_id']?.toString();

      if (id != null && id.isNotEmpty) {
        ids.add(id);
      }
    }

    return ids.length;
  }

  // ==========================================
  // BUAT ABSENSI
  // ==========================================

  void _openBuatAbsensiDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BuatAbsensiPtlDialog(),
    ).then((val) {
      if (val == true) {
        _fetchRekapAbsensi();
      }
    });
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByKegiatan();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),

      appBar: AppBar(
        title: const Text(
          'Rekap Absensi PTL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D8B8B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingRekap ? null : _fetchRekapAbsensi,
          ),
        ],
      ),

      body: _isLoadingRekap
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRekapAbsensi,
              color: const Color(0xFF0D8B8B),
              child: grouped.isEmpty
                  ? _buildEmptyState()
                  : _buildRekapContent(grouped),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBuatAbsensiDialog,
        backgroundColor: const Color(0xFF0D8B8B),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text(
          'Buat Absensi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ==========================================
  // CONTENT
  // ==========================================

  Widget _buildRekapContent(Map<String, List<Map<String, dynamic>>> grouped) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildDateSelector(),

        const SizedBox(height: 16),

        _buildSummary(),

        const SizedBox(height: 24),

        Row(
          children: [
            const Icon(Icons.event_note_rounded, color: Color(0xFF0D8B8B)),
            const SizedBox(width: 8),
            Text(
              'Kegiatan Hari Ini',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${grouped.length} kegiatan',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...grouped.entries.map(
          (entry) => _buildKegiatanCard(entry.key, entry.value),
        ),
      ],
    );
  }

  // ==========================================
  // DATE SELECTOR
  // ==========================================

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0D8B8B).withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF0D8B8B),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Rekap',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SUMMARY
  // ==========================================

  Widget _buildSummary() {
    final total = _riwayatAbsensi.length;
    final hadir = _countStatus('Hadir');
    final izin = _countStatus('Izin');
    final sakit = _countStatus('Sakit');
    final alpha = _countStatus('Alpha');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Absensi',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _summaryItem(
                      Icons.groups_rounded,
                      'Santri',
                      '${_countSantri()}',
                      const Color(0xFF0D8B8B),
                    ),
                  ),
                  Expanded(
                    child: _summaryItem(
                      Icons.assignment_rounded,
                      'Absensi',
                      '$total',
                      Colors.indigo,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _summaryItem(
                      Icons.check_circle_rounded,
                      'Hadir',
                      '$hadir',
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _summaryItem(
                      Icons.info_rounded,
                      'Izin',
                      '$izin',
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _summaryItem(
                      Icons.sick_rounded,
                      'Sakit',
                      '$sakit',
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _summaryItem(
                      Icons.cancel_rounded,
                      'Alpha',
                      '$alpha',
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ==========================================
  // CARD KEGIATAN
  // ==========================================

  Widget _buildKegiatanCard(String kegiatan, List<Map<String, dynamic>> data) {
    final hadir = data.where((item) => item['status'] == 'Hadir').length;

    final izin = data.where((item) => item['status'] == 'Izin').length;

    final sakit = data.where((item) => item['status'] == 'Sakit').length;

    final alpha = data.where((item) => item['status'] == 'Alpha').length;

    final createdAt = data.isNotEmpty ? data.first['created_at'] : null;

    final createdBy = data.isNotEmpty
        ? data.first['created_by_nama']
        : 'Tidak diketahui';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailAbsensiPtlPage(
                kegiatan: kegiatan,
                tanggal: _selectedDate,
                data: data,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D8B8B).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: Color(0xFF0D8B8B),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kegiatan,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${data.length} santri • '
                          '${_formatCreatedAt(createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _statusMini('Hadir', hadir, Colors.green),
                  _statusMini('Izin', izin, Colors.orange),
                  _statusMini('Sakit', sakit, Colors.blue),
                  _statusMini('Alpha', alpha, Colors.red),
                ],
              ),

              const SizedBox(height: 9),

              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Dibuat oleh: $createdBy',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusMini(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D8B8B).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      size: 45,
                      color: Color(0xFF0D8B8B),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Belum Ada Absensi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Belum ada data absensi PTL '
                    'pada ${_formatDate(_selectedDate)}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 18),

                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Pilih Tanggal Lain'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// DETAIL ABSENSI PTL PER KEGIATAN
// ==========================================

class DetailAbsensiPtlPage extends StatefulWidget {
  final String kegiatan;
  final DateTime tanggal;
  final List<Map<String, dynamic>> data;

  const DetailAbsensiPtlPage({
    super.key,
    required this.kegiatan,
    required this.tanggal,
    required this.data,
  });

  @override
  State<DetailAbsensiPtlPage> createState() => _DetailAbsensiPtlPageState();
}

class _DetailAbsensiPtlPageState extends State<DetailAbsensiPtlPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCreatedAt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(value.toString());

      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return '-';
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    if (_searchQuery.isEmpty) {
      return widget.data;
    }

    return widget.data.where((item) {
      final nama = item['nama']?.toString().toLowerCase() ?? '';

      return nama.contains(_searchQuery);
    }).toList();
  }

  int _countStatus(String status) {
    return widget.data.where((item) => item['status'] == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final data = _filteredData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),

      appBar: AppBar(
        title: Text(
          widget.kegiatan,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D8B8B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),

      body: Column(
        children: [
          // ======================================
          // HEADER DETAIL
          // ======================================
          Container(
            width: double.infinity,
            color: const Color(0xFF0D8B8B),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(widget.tanggal),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),

                const SizedBox(height: 4),

                if (widget.data.isNotEmpty)
                  Text(
                    'Dibuat ${_formatCreatedAt(widget.data.first['created_at'])}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // ======================================
          // SUMMARY DETAIL
          // ======================================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _detailSummary(
                    'Hadir',
                    _countStatus('Hadir'),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _detailSummary(
                    'Izin',
                    _countStatus('Izin'),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _detailSummary(
                    'Sakit',
                    _countStatus('Sakit'),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _detailSummary(
                    'Alpha',
                    _countStatus('Alpha'),
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // ======================================
          // SEARCH
          // ======================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama santri...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF0D8B8B),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0D8B8B)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ======================================
          // TOTAL
          // ======================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${data.length} santri',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // ======================================
          // LIST SANTRI
          // ======================================
          Expanded(
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'Santri tidak ditemukan.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];

                      return _buildSantriCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailSummary(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSantriCard(Map<String, dynamic> item) {
    final nama = item['nama']?.toString() ?? 'Tanpa Nama';

    final status = item['status']?.toString() ?? '-';

    final catatan = item['catatan']?.toString() ?? '';

    final createdBy = item['created_by_nama']?.toString() ?? 'Tidak diketahui';

    Color statusColor;

    switch (status) {
      case 'Hadir':
        statusColor = Colors.green;
        break;
      case 'Izin':
        statusColor = Colors.orange;
        break;
      case 'Sakit':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: const Color(0xFF0D8B8B).withOpacity(0.10),
                  child: Text(
                    nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF0D8B8B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (catatan.isNotEmpty) ...[
              const SizedBox(height: 9),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  'Ket: $catatan',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
            ],

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Dibuat oleh: $createdBy',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

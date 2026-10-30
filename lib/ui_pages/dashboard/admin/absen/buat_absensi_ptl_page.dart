import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuatAbsensiPtlDialog extends StatefulWidget {
  const BuatAbsensiPtlDialog({super.key});

  @override
  State<BuatAbsensiPtlDialog> createState() => _BuatAbsensiPtlDialogState();
}

class _BuatAbsensiPtlDialogState extends State<BuatAbsensiPtlDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  DateTime _selectedDate = DateTime.now();
  String? _selectedKegiatan;

  final List<String> _kegiatanList = [
    'Sholat Lail',
    'Sholat Subuh',
    'Kajian Tafsir Jalalain',
    'Setoran Pagi',
    'Sholat Dhuhur',
    'Sholat Ashar',
    'Kajian Kitab / Madin',
    'Sholat Maghrib',
    'Sholat Isya',
  ];

  List<Map<String, dynamic>> _santriPtlList = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _fetchSantriPtl();
  }

  @override
  void dispose() {
    _searchController.dispose();

    for (final santri in _santriPtlList) {
      final controller = santri['catatan_controller'];
      if (controller is TextEditingController) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  // ==========================================================
  // FETCH SANTRI PTL
  // ==========================================================

  Future<void> _fetchSantriPtl() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('profiles')
          .select('id, username, program')
          .eq('program', 'PTL')
          .order('username', ascending: true);

      final List<Map<String, dynamic>> santri = [];

      for (final item in response) {
        santri.add({
          'id': item['id'],
          'username': item['username'] ?? 'Tanpa Nama',
          'program': item['program'] ?? 'PTL',
          'status': 'Hadir',
          'catatan_controller': TextEditingController(),
        });
      }

      if (!mounted) return;

      setState(() {
        _santriPtlList = santri;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR FETCH SANTRI PTL: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data santri PTL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================================
  // PILIH TANGGAL
  // ==========================================================

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
  }

  // ==========================================================
  // FILTER SANTRI
  // ==========================================================

  List<Map<String, dynamic>> get _filteredSantri {
    if (_searchQuery.isEmpty) {
      return _santriPtlList;
    }

    return _santriPtlList.where((santri) {
      final nama = santri['username']?.toString().toLowerCase() ?? '';
      return nama.contains(_searchQuery);
    }).toList();
  }

  // ==========================================================
  // UBAH STATUS
  // ==========================================================

  void _setStatus(Map<String, dynamic> santri, String status) {
    setState(() {
      santri['status'] = status;

      if (status == 'Hadir' || status == 'Alpha') {
        final controller =
            santri['catatan_controller'] as TextEditingController;
        controller.clear();
      }
    });
  }

  // ==========================================================
  // SIMPAN ABSENSI
  // ==========================================================

  Future<void> _simpanAbsensi() async {
    FocusScope.of(context).unfocus(); // Clear keyboard sebelum simpan

    if (_selectedKegiatan == null || _selectedKegiatan!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kegiatan terlebih dahulu')),
      );
      return;
    }

    if (_santriPtlList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data santri PTL tidak ditemukan')),
      );
      return;
    }

    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login tidak ditemukan')),
      );
      return;
    }

    // Validasi catatan untuk Izin dan Sakit
    for (final santri in _santriPtlList) {
      final status = santri['status']?.toString();
      final controller = santri['catatan_controller'] as TextEditingController;

      if ((status == 'Izin' || status == 'Sakit') &&
          controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catatan wajib diisi untuk ${santri['username']}'),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final createdAt = DateTime.now().toIso8601String();
      final tanggal = _selectedDate.toIso8601String().split('T').first;

      final payload = _santriPtlList.map((santri) {
        final controller =
            santri['catatan_controller'] as TextEditingController;
        final status = santri['status']?.toString() ?? 'Hadir';

        return {
          'user_id': santri['id'],
          'created_by': currentUser.id,
          'tanggal': tanggal,
          'kegiatan': _selectedKegiatan,
          'program': 'PTL',
          'status': status,
          'catatan': (status == 'Izin' || status == 'Sakit')
              ? controller.text.trim()
              : null,
          'created_at': createdAt,
        };
      }).toList();

      await _supabase.from('absensi').insert(payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absensi PTL berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('ERROR SIMPAN ABSENSI PTL: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan absensi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final filteredSantri = _filteredSantri;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // GestureDetector untuk menutup keyboard saat klik area mana saja
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0D8B8B),
                        ),
                      )
                    : AnimatedPadding(
                        padding: EdgeInsets.only(bottom: bottomInset),
                        duration: const Duration(milliseconds: 150),
                        child: SingleChildScrollView(
                          // Menutup keyboard saat user scroll daftar
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTanggal(),
                              const SizedBox(height: 14),
                              _buildKegiatan(),
                              const SizedBox(height: 18),
                              _buildSearch(),
                              const SizedBox(height: 12),
                              _buildJumlahSantri(filteredSantri.length),
                              const SizedBox(height: 10),

                              ...filteredSantri.map(
                                (santri) => _buildSantriCard(santri),
                              ),

                              if (filteredSantri.isEmpty) _buildEmptySearch(),
                            ],
                          ),
                        ),
                      ),
              ),

              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D8B8B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat Absensi PTL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Isi kehadiran santri berdasarkan kegiatan',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TANGGAL
  // ==========================================================

  Widget _buildTanggal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal Kegiatan',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isSaving ? null : _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D8B8B).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: Color(0xFF0D8B8B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // KEGIATAN
  // ==========================================================

  Widget _buildKegiatan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kegiatan',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedKegiatan,
          decoration: InputDecoration(
            hintText: 'Pilih kegiatan',
            prefixIcon: const Icon(
              Icons.event_note_rounded,
              color: Color(0xFF0D8B8B),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 13,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          items: _kegiatanList.map((kegiatan) {
            return DropdownMenuItem<String>(
              value: kegiatan,
              child: Text(kegiatan),
            );
          }).toList(),
          onChanged: _isSaving
              ? null
              : (value) {
                  setState(() {
                    _selectedKegiatan = value;
                  });
                },
        ),
      ],
    );
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari nama santri...',
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D8B8B)),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_rounded, size: 20),
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
    );
  }

  // ==========================================================
  // JUMLAH SANTRI
  // ==========================================================

  Widget _buildJumlahSantri(int jumlah) {
    return Row(
      children: [
        const Icon(Icons.groups_rounded, size: 17, color: Color(0xFF0D8B8B)),
        const SizedBox(width: 6),
        Text(
          '$jumlah santri',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CARD SANTRI (DESAIN DIPERBAGUS)
  // ==========================================================

  Widget _buildSantriCard(Map<String, dynamic> santri) {
    final nama = santri['username']?.toString() ?? 'Tanpa Nama';
    final status = santri['status']?.toString() ?? 'Hadir';
    final controller = santri['catatan_controller'] as TextEditingController;

    Color statusColor;
    switch (status) {
      case 'Izin':
        statusColor = Colors.orange.shade700;
        break;
      case 'Sakit':
        statusColor = Colors.blue.shade700;
        break;
      case 'Alpha':
        statusColor = Colors.red.shade700;
        break;
      case 'Hadir':
      default:
        statusColor = Colors.green.shade700;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status != 'Hadir'
              ? statusColor.withOpacity(0.5)
              : Colors.grey.shade200,
          width: status != 'Hadir' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0D8B8B).withOpacity(0.12),
                  child: Text(
                    nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF0D8B8B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // SELEKSI STATUS
            Row(
              children: [
                _statusButton(
                  santri,
                  'Hadir',
                  Colors.green.shade700,
                  Icons.check_circle_rounded,
                  status == 'Hadir',
                ),
                const SizedBox(width: 6),
                _statusButton(
                  santri,
                  'Izin',
                  Colors.orange.shade700,
                  Icons.info_rounded,
                  status == 'Izin',
                ),
                const SizedBox(width: 6),
                _statusButton(
                  santri,
                  'Sakit',
                  Colors.blue.shade700,
                  Icons.sick_rounded,
                  status == 'Sakit',
                ),
                const SizedBox(width: 6),
                _statusButton(
                  santri,
                  'Alpha',
                  Colors.red.shade700,
                  Icons.cancel_rounded,
                  status == 'Alpha',
                ),
              ],
            ),

            // FIELD CATATAN
            if (status == 'Izin' || status == 'Sakit') ...[
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Catatan $status',
                  hintText: 'Masukkan alasan...',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            setState(() {
                              controller.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: statusColor),
                  ),
                ),
                onChanged: (val) {
                  // Memastikan tombol clear muncul/hilang realtime
                  setState(() {});
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // STATUS BUTTON
  // ==========================================================

  Widget _statusButton(
    Map<String, dynamic> santri,
    String label,
    Color color,
    IconData icon,
    bool selected,
  ) {
    return Expanded(
      child: InkWell(
        onTap: _isSaving ? null : () => _setStatus(santri, label),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? color : Colors.grey.shade500,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY SEARCH
  // ==========================================================

  Widget _buildEmptySearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Santri tidak ditemukan',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BOTTOM BUTTON
  // ==========================================================

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _simpanAbsensi,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D8B8B),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: Text(
            _isSaving ? 'Menyimpan...' : 'Simpan Absensi',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

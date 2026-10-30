import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptl_mobile/state_management/pengajar_program_provider.dart';
import 'package:ptl_mobile/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// HALAMAN UTAMA: DAFTAR PENGAJAR
// ============================================================================

class PengajarPage extends StatefulWidget {
  const PengajarPage({super.key});

  @override
  State<PengajarPage> createState() => _PengajarPageState();
}

class _PengajarPageState extends State<PengajarPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _pengajarList = [];
  List<Map<String, dynamic>> _filteredList = [];

  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _fetchPengajar();
    _searchController.addListener(_filterPengajar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // FETCH PENGAJAR
  // ==========================================================================

  Future<void> _fetchPengajar() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('profiles')
          .select('id, username, role, no_hp, alamat, created_at')
          .order('created_at', ascending: false);

      final filtered = List<Map<String, dynamic>>.from(response).where((user) {
        final role = (user['role'] ?? '').toString().toLowerCase();

        return role == 'pengajar' || role == 'ustadz' || role == 'ustadzah';
      }).toList();

      if (!mounted) return;

      setState(() {
        _pengajarList = filtered;
        _filteredList = filtered;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showSnackBar('Gagal memuat data pengajar: $e', isError: true);
    }
  }

  // ==========================================================================
  // SEARCH
  // ==========================================================================

  void _filterPengajar() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredList = _pengajarList.where((item) {
        final username = (item['username'] ?? '').toString().toLowerCase();

        final noHp = (item['no_hp'] ?? '').toString().toLowerCase();

        final alamat = (item['alamat'] ?? '').toString().toLowerCase();

        return username.contains(query) ||
            noHp.contains(query) ||
            alamat.contains(query);
      }).toList();
    });
  }

  // ==========================================================================
  // SNACKBAR
  // ==========================================================================

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==========================================================================
  // DELETE
  // ==========================================================================

  Future<void> _deletePengajar(String id, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Data Pengajar'),
        content: Text('Apakah Anda yakin ingin menghapus data "`$username"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Hapus relasi pengajar-program terlebih dahulu.
      final programProvider = context.read<PengajarProgramProvider>();

      final programs = await programProvider.loadByPengajar(id);

      await _supabase.from('pengajar_programs').delete().eq('pengajar_id', id);

      // Hapus profile.
      await _supabase.from('profiles').delete().eq('id', id);

      _showSnackBar('Data pengajar berhasil dihapus');

      await _fetchPengajar();
    } catch (e) {
      _showSnackBar('Gagal menghapus data: $e', isError: true);
    }
  }

  // ==========================================================================
  // EDIT PENGAJAR
  // ==========================================================================

  Future<void> showEditDialog(Map<String, dynamic> pengajar) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditPengajarDialog(pengajar: pengajar),
    );

    if (result == true) {
      await _fetchPengajar();
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text(
            'Manajemen Pengajar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF0D8B8B),
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Data',
              onPressed: _fetchPengajar,
            ),
          ],
        ),

        body: Column(
          children: [
            // ==================================================================
            // SUMMARY
            // ==================================================================
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D8B8B), Color(0xFF00BFA5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D8B8B).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Pengajar Registered',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_pengajarList.length} Pengajar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ==================================================================
            // SEARCH
            // ==================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari pengajar (Nama, HP, Alamat)...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF90A4AE),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF0D8B8B),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================================
            // LIST
            // ==================================================================
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0D8B8B),
                      ),
                    )
                  : _filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchController.text.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.people_outline_rounded,
                            size: 64,
                            color: const Color(0xFFCFD8DC),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'Pengajar tidak ditemukan'
                                : 'Belum ada data pengajar',
                            style: const TextStyle(
                              color: Color(0xFF78909C),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPengajar,
                      color: const Color(0xFF0D8B8B),
                      child: ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];

                          return PengajarCard(
                            pengajar: item,
                            onEdit: () {
                              showEditDialog(item);
                            },
                            onDelete: () {
                              _deletePengajar(
                                item['id'].toString(),
                                item['username'] ?? 'Tanpa Nama',
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),

        // ======================================================================
        // ADD
        // ======================================================================
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF0D8B8B),
          elevation: 3,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TambahPengajarPage(),
              ),
            );

            if (result == true) {
              await _fetchPengajar();
            }
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// ============================================================================
// CARD PENGAJAR
// ============================================================================

class PengajarCard extends StatefulWidget {
  final Map<String, dynamic> pengajar;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PengajarCard({
    super.key,
    required this.pengajar,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<PengajarCard> createState() => _PengajarCardState();
}

class _PengajarCardState extends State<PengajarCard> {
  List<PengajarProgramItem> _programs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final provider = context.read<PengajarProgramProvider>();

      await provider.loadByPengajar(widget.pengajar['id'].toString());

      if (!mounted) return;

      setState(() {
        _programs = provider.programByPengajar
            .map(
              (item) => PengajarProgramItem(
                id: item.programId,
                nama: item.namaProgram ?? 'Program',
              ),
            )
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.pengajar['username'] ?? 'Tanpa Nama';

    final noHp = widget.pengajar['no_hp'] ?? '-';

    final alamat = widget.pengajar['alamat'] ?? '-';

    final role = (widget.pengajar['role'] ?? 'Pengajar').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEFF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================================================================
            // AVATAR
            // ================================================================
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE0F2F1),
              child: Text(
                username.toString().isNotEmpty
                    ? username.toString()[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  color: Color(0xFF0D8B8B),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ================================================================
            // DETAIL
            // ================================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          username.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF263238),
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D8B8B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ==========================================================
                  // NO HP
                  // ==========================================================
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Color(0xFF78909C),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        noHp.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF546E7A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ==========================================================
                  // ALAMAT
                  // ==========================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF78909C),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          alamat.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF546E7A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ==========================================================
                  // PROGRAM
                  // ==========================================================
                  const Text(
                    'Program Mengajar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF78909C),
                    ),
                  ),

                  const SizedBox(height: 5),

                  if (_isLoading)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0D8B8B),
                      ),
                    )
                  else if (_programs.isEmpty)
                    const Text(
                      'Belum ada program',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB0BEC5),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: _programs.map((program) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFB2DFDB)),
                          ),
                          child: Text(
                            program.nama,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00695C),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            // ================================================================
            // MENU
            // ================================================================
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF78909C),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  widget.onEdit();
                } else if (value == 'delete') {
                  widget.onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF1976D2),
                      ),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 8),
                      Text('Hapus'),
                    ],
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

// ============================================================================
// MODEL SEDERHANA UNTUK CHIP PROGRAM
// ============================================================================

class PengajarProgramItem {
  final String id;
  final String nama;

  PengajarProgramItem({required this.id, required this.nama});
}

// ============================================================================
// DIALOG EDIT
// ============================================================================

class EditPengajarDialog extends StatefulWidget {
  final Map<String, dynamic> pengajar;

  const EditPengajarDialog({super.key, required this.pengajar});

  @override
  State<EditPengajarDialog> createState() => _EditPengajarDialogState();
}

class _EditPengajarDialogState extends State<EditPengajarDialog> {
  final _formKey = GlobalKey<FormState>();

  final _supabase = Supabase.instance.client;

  late final TextEditingController _usernameController;

  late final TextEditingController _noHpController;

  late final TextEditingController _alamatController;

  bool _isLoadingProgram = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _programList = [];

  Set<String> _selectedProgramIds = {};

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController(
      text: widget.pengajar['username'] ?? '',
    );

    _noHpController = TextEditingController(
      text: widget.pengajar['no_hp'] ?? '',
    );

    _alamatController = TextEditingController(
      text: widget.pengajar['alamat'] ?? '',
    );

    _loadPrograms();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // LOAD SEMUA PROGRAM + PROGRAM MILIK PENGAJAR
  // ==========================================================================

  Future<void> _loadPrograms() async {
    try {
      final response = await _supabase
          .from('programs')
          .select('id, nama, deskripsi')
          .order('nama');

      final programProvider = context.read<PengajarProgramProvider>();

      await programProvider.loadByPengajar(widget.pengajar['id'].toString());

      final currentPrograms = programProvider.programByPengajar;

      if (!mounted) return;

      setState(() {
        _programList = List<Map<String, dynamic>>.from(response);

        _selectedProgramIds = currentPrograms
            .map((item) => item.programId)
            .toSet();

        _isLoadingProgram = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingProgram = false;
      });

      _showError('Gagal memuat program: $e');
    }
  }

  // ==========================================================================
  // SAVE
  // ==========================================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final pengajarId = widget.pengajar['id'].toString();

      // ------------------------------------------------------------
      // UPDATE PROFILE
      // ------------------------------------------------------------

      await _supabase
          .from('profiles')
          .update({
            'username': _usernameController.text.trim(),
            'no_hp': _noHpController.text.trim(),
            'alamat': _alamatController.text.trim(),
          })
          .eq('id', pengajarId);

      // ------------------------------------------------------------
      // SYNC PROGRAM
      // ------------------------------------------------------------

      final provider = context.read<PengajarProgramProvider>();

      final success = await provider.syncPrograms(
        pengajarId: pengajarId,
        programIds: _selectedProgramIds.toList(),
      );

      if (!success) {
        throw Exception(
          provider.errorMessage ?? 'Gagal menyimpan program pengajar.',
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pengajar berhasil diperbarui.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError('Gagal memperbarui data: `$e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: Color(0xFF0D8B8B)),
          SizedBox(width: 8),
          Text('Edit Data Pengajar'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ============================================================
                // NAMA
                // ============================================================
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Nama / Username',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),

                const SizedBox(height: 12),

                // ============================================================
                // NO HP
                // ============================================================
                TextFormField(
                  controller: _noHpController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'No. HP',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ============================================================
                // ALAMAT
                // ============================================================
                TextFormField(
                  controller: _alamatController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Alamat',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ============================================================
                // PROGRAM
                // ============================================================
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Program yang Diajar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF455A64),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                _buildProgramSelector(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D8B8B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // ==========================================================================
  // PROGRAM SELECTOR
  // ==========================================================================

  Widget _buildProgramSelector() {
    if (_isLoadingProgram) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D8B8B)),
        ),
      );
    }

    if (_programList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Belum ada program yang tersedia.',
          style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: _programList.map((program) {
          final id = program['id'].toString();

          final nama = program['nama']?.toString() ?? 'Tanpa Nama';

          final selected = _selectedProgramIds.contains(id);

          return CheckboxListTile(
            value: selected,
            activeColor: const Color(0xFF0D8B8B),
            title: Text(
              nama,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            subtitle:
                program['deskripsi'] != null &&
                    program['deskripsi'].toString().isNotEmpty
                ? Text(
                    program['deskripsi'].toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF78909C),
                    ),
                  )
                : null,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedProgramIds.add(id);
                } else {
                  _selectedProgramIds.remove(id);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// TAMBAH PENGAJAR
// ============================================================================

class TambahPengajarPage extends StatefulWidget {
  const TambahPengajarPage({super.key});

  @override
  State<TambahPengajarPage> createState() => _TambahPengajarPageState();
}

class _TambahPengajarPageState extends State<TambahPengajarPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final TextEditingController _noHpController = TextEditingController();

  final TextEditingController _alamatController = TextEditingController();

  final _supabase = Supabase.instance.client;

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Program
  bool _isLoadingProgram = true;

  List<Map<String, dynamic>> _programList = [];

  Set<String> _selectedProgramIds = {};

  @override
  void initState() {
    super.initState();

    _loadPrograms();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // LOAD PROGRAM
  // ==========================================================================

  Future<void> _loadPrograms() async {
    try {
      final response = await _supabase
          .from('programs')
          .select('id, nama, deskripsi')
          .order('nama');

      if (!mounted) return;

      setState(() {
        _programList = List<Map<String, dynamic>>.from(response);

        _isLoadingProgram = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingProgram = false;
      });

      _showErrorSnackBar('Gagal memuat program: $e');
    }
  }

  // ==========================================================================
  // SUBMIT
  // ==========================================================================

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final tempClient = SupabaseClient(
        AppConstants.supabaseUrl,
        AppConstants.supabaseAnonKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );

      final email = _emailController.text.trim();

      final password = _passwordController.text;

      final username = _usernameController.text.trim();

      // ============================================================
      // CREATE AUTH
      // ============================================================

      final AuthResponse res = await tempClient.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'role': 'pengajar'},
      );

      final newUserId = res.user?.id;

      if (newUserId == null) {
        throw Exception('Gagal mendapatkan ID akun pengajar.');
      }

      // ============================================================
      // CREATE PROFILE
      // ============================================================

      await _supabase.from('profiles').upsert({
        'id': newUserId,
        'username': username,
        'role': 'pengajar',
        'no_hp': _noHpController.text.trim(),
        'alamat': _alamatController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // ============================================================
      // SIMPAN PROGRAM
      // ============================================================

      if (_selectedProgramIds.isNotEmpty) {
        final provider = context.read<PengajarProgramProvider>();

        final success = await provider.createMany(
          pengajarId: newUserId,
          programIds: _selectedProgramIds.toList(),
        );

        if (!success) {
          throw Exception(
            provider.errorMessage ?? 'Gagal menyimpan program pengajar.',
          );
        }
      }

      // ============================================================
      // SELESAI
      // ============================================================

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Akun & profil pengajar berhasil dibuat!'),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } on AuthException catch (error) {
      if (mounted) {
        _showErrorSnackBar('Gagal membuat akun: ${error.message}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ==========================================================================
  // ERROR
  // ==========================================================================

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text(
            'Tambah Pengajar Baru',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF0D8B8B),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0.5,
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================================
                // ACCOUNT
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFECEFF1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.person_add_rounded,
                            color: Color(0xFF0D8B8B),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Informasi Akun & Profil',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D8B8B),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      _buildTextField(
                        controller: _usernameController,
                        label: 'Nama Lengkap (beserta Gelar)',
                        hint: 'Contoh: Ustadz Ahmad, S.Pd.I',
                        icon: Icons.person_outline_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama lengkap wajib diisi';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Login',
                        hint: 'Contoh: ustadz.ahmad@gmail.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Email wajib diisi';
                          }

                          final emailRegExp = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );

                          if (!emailRegExp.hasMatch(val.trim())) {
                            return 'Format email tidak valid';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password Login',
                        hint: 'Min. 6 karakter',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Password wajib diisi';
                          }

                          if (val.length < 6) {
                            return 'Password minimal 6 karakter';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Konfirmasi Password',
                        hint: 'Ulangi password di atas',
                        icon: Icons.lock_reset_rounded,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Konfirmasi password wajib diisi';
                          }

                          if (val != _passwordController.text) {
                            return 'Password tidak cocok';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _noHpController,
                        label: 'No. HP / WhatsApp',
                        hint: 'Contoh: 081234567890',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (val) => val == null || val.isEmpty
                            ? 'No. HP wajib diisi'
                            : null,
                      ),

                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _alamatController,
                        label: 'Alamat Lengkap',
                        hint: 'Masukkan alamat tempat tinggal',
                        icon: Icons.home_work_outlined,
                        maxLines: 3,
                        validator: (val) => val == null || val.isEmpty
                            ? 'Alamat wajib diisi'
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ============================================================
                // PROGRAM
                // ============================================================
                _buildProgramCard(),

                const SizedBox(height: 24),

                // ============================================================
                // BUTTON
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D8B8B),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Simpan Data Pengajar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
  }

  // ==========================================================================
  // PROGRAM CARD
  // ==========================================================================

  Widget _buildProgramCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEFF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.library_books_outlined, color: Color(0xFF0D8B8B)),
              SizedBox(width: 8),
              Text(
                'Program yang Diajar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D8B8B),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          const Text(
            'Pilih satu atau beberapa program yang diajar oleh pengajar.',
            style: TextStyle(fontSize: 12, color: Color(0xFF78909C)),
          ),

          const SizedBox(height: 10),

          if (_isLoadingProgram)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D8B8B)),
            )
          else if (_programList.isEmpty)
            const Text(
              'Belum ada program tersedia.',
              style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
            )
          else
            Column(
              children: _programList.map((program) {
                final id = program['id'].toString();

                final nama = program['nama']?.toString() ?? 'Tanpa Nama';

                final selected = _selectedProgramIds.contains(id);

                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: selected,
                  activeColor: const Color(0xFF0D8B8B),
                  title: Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle:
                      program['deskripsi'] != null &&
                          program['deskripsi'].toString().isNotEmpty
                      ? Text(
                          program['deskripsi'].toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF78909C),
                          ),
                        )
                      : null,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedProgramIds.add(id);
                      } else {
                        _selectedProgramIds.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TEXT FIELD
  // ==========================================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF455A64),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: isPassword ? obscureText : false,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0BEC5)),
            prefixIcon: Icon(icon, color: const Color(0xFF90A4AE), size: 20),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF90A4AE),
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
            ),
          ),
        ),
      ],
    );
  }
}

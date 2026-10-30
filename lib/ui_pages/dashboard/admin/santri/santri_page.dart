import 'package:flutter/material.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/santri/create_santri.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/santri/edit_santri.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _backgroundColor = Color(0xFFF4F6F8);
const Color _textColor = Color(0xFF1E293B);
const Color _secondaryTextColor = Color(0xFF64748B);
const Color _borderColor = Color(0xFFE2E8F0);

class SantriPage extends StatefulWidget {
  const SantriPage({super.key});

  @override
  State<SantriPage> createState() => _SantriPageState();
}

class _SantriPageState extends State<SantriPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _santriList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _fetchSantri();
  }

  Future<void> _fetchSantri() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'santri')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _santriList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat data: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat data: $e', isError: true);
    }
  }

  List<Map<String, dynamic>> get _filteredSantriList {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _santriList;

    return _santriList.where((santri) {
      final nama = _value(santri['username']).toLowerCase();
      final nik = _value(santri['nik']).toLowerCase();
      final email = _value(santri['email']).toLowerCase();
      final noHp = _value(santri['no_hp']).toLowerCase();

      return nama.contains(query) ||
          nik.contains(query) ||
          email.contains(query) ||
          noHp.contains(query);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    FocusScope.of(context).unfocus();
  }

  Future<void> _addSantri() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TambahSantriPage()),
    );
    if (result == true) await _loadData();
  }

  Future<void> _editSantri(Map<String, dynamic> santri) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditSantriPage(santri: santri)),
    );
    if (result == true) await _loadData();
  }

  Future<void> _deleteSantri(String id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus data "$nama"?\n\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: _secondaryTextColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('profiles').delete().eq('id', id);
      if (!mounted) return;
      _showSnackBar('Data santri berhasil dihapus');
      await _loadData();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menghapus data: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menghapus data: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2E7D32),
      ),
    );
  }

  String _value(dynamic value) => value?.toString() ?? '';

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Data Santri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: _primaryColor,
          onPressed: _addSantri,
          elevation: 3,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
        body: Column(
          children: [
            _buildHeaderSummary(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildSantriList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 12,
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
                'Total Santri Terdaftar',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '${_santriList.length} Santri',
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
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: _textColor),
              decoration: InputDecoration(
                hintText: 'Cari nama, NIK, email, atau HP...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _primaryColor,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _isLoading ? null : _loadData,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: const Icon(Icons.refresh_rounded, color: _primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSantriList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    final list = _filteredSantriList;

    if (list.isEmpty) {
      return RefreshIndicator(
        color: _primaryColor,
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.person_search_rounded,
                    size: 48,
                    color: Color(0xFFCBD5E1),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tidak ada data santri.',
                    style: TextStyle(color: _secondaryTextColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _buildSantriCard(list[index]);
        },
      ),
    );
  }

  Widget _buildSantriCard(Map<String, dynamic> item) {
    final id = _value(item['id']);
    final nama = item['username'] ?? 'Tanpa Nama';
    final nik = item['nik'] ?? '-';
    final email = item['email'] ?? '-';
    final noHp = item['no_hp'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: Text(
                    _getInitials(nama.toString()),
                    style: const TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama.toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIK: $nik',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: _borderColor),
            ),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: _secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    email.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: _secondaryTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: _secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  noHp.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: _primaryColor,
                  bgColor: _primaryColor.withOpacity(0.08),
                  onTap: () => _editSantri(item),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Hapus',
                  color: Colors.redAccent,
                  bgColor: Colors.redAccent.withOpacity(0.08),
                  onTap: () => _deleteSantri(id, nama.toString()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

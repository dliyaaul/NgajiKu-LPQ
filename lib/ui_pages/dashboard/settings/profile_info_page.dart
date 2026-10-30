import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ptl_mobile/state_management/auth_provider.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _backgroundColor = Color(0xFFF8FAFA);
const Color _textColor = Color(0xFF263238);
const Color _secondaryTextColor = Color(0xFF607D8B);

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  bool _isUploading = false;

  int _cacheBuster = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    final picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) return;

    if (response.file != null) {
      // Jika ada file yang tertinggal karena activity sempat tertutup OS
      final file = File(response.file!.path);
      // Jalankan logika upload dengan file ini
    }
  }

  // Fungsi untuk upload foto ke Supabase Storage
  Future<void> _updateAvatar(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    try {
      // Dipanggil di awal sebelum proses async lain
      pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    } catch (e) {
      debugPrint("Error ImagePicker: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kamera/galeri: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Jika pengguna membatalkan pilihan gambar
    if (pickedFile == null) {
      debugPrint("Pengguna membatalkan pemilih gambar.");
      return;
    }

    // Tampilkan loading indikator setelah gambar dipastikan terpilih
    setState(() => _isUploading = true);

    try {
      final file = File(pickedFile.path);
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 0.5) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ukuran foto terlalu besar! Maksimal 0,5 MB (500 KB).',
              ),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final fileExt = pickedFile.path.split('.').last;
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      if (context.mounted) {
        context.read<AuthProvider>().updateAvatarUrl(publicUrl);

        setState(() {
          _cacheBuster = DateTime.now().millisecondsSinceEpoch;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      debugPrint("Error Upload: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Foto Profil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ukuran file maksimal: 0,5 MB',
              style: TextStyle(fontSize: 12, color: _secondaryTextColor),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _updateAvatar(context, ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _updateAvatar(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.userProfile ?? {};
    final String role = (userProfile['role'] ?? 'santri')
        .toString()
        .toLowerCase();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Informasi Profil Saya',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(context, userProfile, role),
            const SizedBox(height: 20),
            if (role == 'admin') ...[
              _buildAdminSection(userProfile),
            ] else if (role == 'pengajar' || role == 'ustadz') ...[
              _buildPengajarSection(userProfile),
            ] else ...[
              _buildSantriSection(userProfile),
            ],
            const SizedBox(height: 20),
            _buildGeneralAccountSection(userProfile),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic> profile,
    String role,
  ) {
    final String username = profile['username'] ?? 'Pengguna';
    final String rawAvatarUrl = profile['avatar_url'] ?? '';

    // Ganti timestamp dynamic dengan variabel _cacheBuster
    final String? avatarUrl = rawAvatarUrl.isNotEmpty
        ? '$rawAvatarUrl?v=$_cacheBuster'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : () => _showImageSourceDialog(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  // Menggunakan key unik agar Flutter merender ulang widget gambarnya
                  key: ValueKey(avatarUrl),
                  /*backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,*/
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            // Hilangkan cache bawaan Flutter untuk tes
                            headers: const {'Cache-Control': 'no-cache'},
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const CircularProgressIndicator();
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error memuat gambar: $error');
                              return const Icon(Icons.error, color: Colors.red);
                            },
                          ),
                        )
                      : Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                ),
                if (_isUploading)
                  const Positioned.fill(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                Positioned(
                  bottom: 0,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            username,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildRoleBadge(role),
        ],
      ),
    );
  }

  // Bagian widget lainnya (Badge, Section, Row) tetap sama seperti sebelumnya...
  Widget _buildRoleBadge(String role) {
    Color badgeColor;
    String label;
    switch (role) {
      case 'admin':
        badgeColor = Colors.purple;
        label = 'ADMINISTRATOR';
        break;
      case 'pengajar':
      case 'ustadz':
        badgeColor = const Color(0xFF0288D1);
        label = 'PENGAJAR / USTADZ';
        break;
      default:
        badgeColor = _primaryColor;
        label = 'SANTRI';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSantriSection(Map<String, dynamic> profile) => _buildCardGroup(
    title: 'DATA SANTRI',
    children: [
      _buildInfoRow('Nama / Username', profile['username']),
      _buildInfoRow('No. Handphone / WhatsApp', profile['nohp']),
      _buildInfoRow('Alamat', profile['alamat']),
    ],
  );
  Widget _buildPengajarSection(Map<String, dynamic> profile) => _buildCardGroup(
    title: 'DATA PENGAJAR',
    children: [
      _buildInfoRow('Nama / Username', profile['username']),
      _buildInfoRow('No. Handphone', profile['nohp']),
      _buildInfoRow('Alamat Domisili', profile['alamat']),
    ],
  );
  Widget _buildAdminSection(Map<String, dynamic> profile) => _buildCardGroup(
    title: 'DATA ADMINISTRATOR',
    children: [
      _buildInfoRow('ID Pengelola', profile['id']),
      _buildInfoRow('Username', profile['username']),
      _buildInfoRow('No. Handphone Operasional', profile['nohp']),
      _buildInfoRow('Alamat Kantor/Domisili', profile['alamat']),
    ],
  );
  Widget _buildGeneralAccountSection(Map<String, dynamic> profile) {
    String formattedDate = profile['created_at'] != null
        ? profile['created_at'].toString().split('T').first
        : '-';
    return _buildCardGroup(
      title: 'INFORMASI AKUN',
      children: [
        _buildInfoRow('Status Akun', 'Aktif', isSuccessText: true),
        _buildInfoRow('Terdaftar Sejak', formattedDate),
      ],
    );
  }

  Widget _buildCardGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    dynamic rawValue, {
    bool isSuccessText = false,
  }) {
    final String value =
        (rawValue == null || rawValue.toString().trim().isEmpty)
        ? '-'
        : rawValue.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSuccessText ? Colors.green : _textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

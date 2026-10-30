import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state_management/app_setting_provider.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _backgroundColor = Color(0xFFF8FAFA);
const Color _textColor = Color(0xFF263238);
const Color _secondaryTextColor = Color(0xFF607D8B);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // State sederhana untuk pengaturan
  bool _isDarkMode = false;
  bool _isPushNotificationEnabled = true;
  String _selectedLanguage = 'Bahasa Indonesia';
  String _selectedFontSize = 'Sedang';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _textColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // 1. KATEGORI: AKUN & KEAMANAN
          _buildSectionHeader('Akun & Keamanan'),
          _buildListTile(
            icon: Icons.person_outline_rounded,
            title: 'Informasi Profil Saya',
            subtitle: 'Lihat Detail Profil & Data Akun',
            onTap: () {
              Navigator.pushNamed(context, '/profile-info');
            },
          ),
          _buildListTile(
            icon: Icons.lock_outline_rounded,
            title: 'Ubah Password',
            subtitle: 'Perbarui kata sandi akun kamu',
            onTap: () {
              // TODO: Navigasi ke Halaman Ubah Password
            },
          ),

          const SizedBox(height: 16),

          // 2. KATEGORI: AKADEMIK
          _buildSectionHeader('Akademik'),
          _buildTahunAjaranTile(),

          const SizedBox(height: 16),

          // 2. KATEGORI: TAMPILAN & APLIKASI
          _buildSectionHeader('Tampilan & Preferensi'),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Tema / Mode Tampilan',
            subtitle: _isDarkMode ? 'Mode Gelap' : 'Mode Terang',
            value: _isDarkMode,
            onChanged: (val) => setState(() => _isDarkMode = val),
          ),
          _buildListTile(
            icon: Icons.language_rounded,
            title: 'Bahasa (Language)',
            trailingText: _selectedLanguage,
            onTap: _showLanguageDialog,
          ),
          _buildListTile(
            icon: Icons.format_size_rounded,
            title: 'Ukuran Teks (Font Size)',
            trailingText: _selectedFontSize,
            onTap: _showFontSizeDialog,
          ),

          const SizedBox(height: 16),

          // 3. KATEGORI: NOTIFIKASI
          _buildSectionHeader('Notifikasi'),
          _buildSwitchTile(
            icon: Icons.notifications_none_rounded,
            title: 'Pengaturan Notifikasi Push',
            subtitle: 'Terima notifikasi perizinan & pengumuman',
            value: _isPushNotificationEnabled,
            onChanged: (val) =>
                setState(() => _isPushNotificationEnabled = val),
          ),

          const SizedBox(height: 16),

          // 4. KATEGORI: BANTUAN & INFORMASI
          _buildSectionHeader('Bantuan & Informasi'),
          _buildListTile(
            icon: Icons.support_agent_rounded,
            title: 'Hubungi Kami / Customer Service',
            subtitle: 'Bantuan teknis via WhatsApp/Email',
            onTap: () {
              // TODO: Buka WhatsApp / Email CS
            },
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Kebijakan Privasi (Privacy Policy)',
            onTap: () {
              // TODO: Buka Kebijakan Privasi
            },
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: 'Syarat & Ketentuan (Terms of Service)',
            onTap: () {
              // TODO: Buka Syarat & Ketentuan
            },
          ),
          _buildListTile(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi (About App)',
            subtitle: 'Versi 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'PTL Mobile',
                applicationVersion: '1.0.0',
                applicationIcon: const CircleAvatar(
                  backgroundColor: _primaryColor,
                  child: Icon(Icons.mosque, color: Colors.white),
                ),
                children: const [
                  Text(
                    'Aplikasi Pengelolaan Santri dan Asrama Pondok Tahfidz Lengkong (PTL).',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Header Kategori
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _primaryColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ListTile Standar dengan Icon Container
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: _secondaryTextColor,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 12,
                  color: _secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB0BEC5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Switch ListTile untuk Toggle On/Off
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Colors.white,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: _primaryColor,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: _secondaryTextColor),
        ),
      ),
    );
  }

  // Dialog Pilihan Bahasa
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Bahasa', style: TextStyle(fontSize: 15)),
        children: ['Bahasa Indonesia', 'English'].map((lang) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedLanguage = lang);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(lang, style: const TextStyle(fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Dialog Pilihan Ukuran Teks
  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ukuran Teks', style: TextStyle(fontSize: 15)),
        children: ['Kecil', 'Sedang', 'Besar'].map((size) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedFontSize = size);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(size, style: const TextStyle(fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTahunAjaranTile() {
    return Consumer<AppSettingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            color: Colors.white,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              title: const Text(
                'Tahun Ajaran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              subtitle: const Text(
                'Memuat tahun ajaran...',
                style: TextStyle(fontSize: 11, color: _secondaryTextColor),
              ),
              trailing: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryColor,
                ),
              ),
            ),
          );
        }

        if (provider.errorMessage != null) {
          return Container(
            color: Colors.white,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              title: const Text(
                'Tahun Ajaran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              subtitle: Text(
                provider.errorMessage!,
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.loadSettings,
              ),
            ),
          );
        }

        return _buildListTile(
          icon: Icons.school_outlined,
          title: 'Tahun Ajaran',
          subtitle: 'Tahun ajaran yang digunakan pada aplikasi',
          trailingText: provider.tahunAjaran,
          onTap: () => _showTahunAjaranDialog(provider),
        );
      },
    );
  }

  Future<void> _showTahunAjaranDialog(AppSettingProvider provider) async {
    final controller = TextEditingController(
      text: provider.tahunAjaran == '-' ? '' : provider.tahunAjaran,
    );

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tahun Ajaran',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Tahun Ajaran',
              hintText: 'Contoh: 2026/2027',
              prefixIcon: const Icon(Icons.school_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tahun ajaran wajib diisi.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!_isValidTahunAjaran(value)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Format tahun ajaran tidak valid. '
                        'Contoh: 2026/2027.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    // Jangan langsung melakukan update provider ketika dialog
    // baru saja dipop.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    controller.dispose();

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    await _simpanTahunAjaran(provider, result);
  }

  bool _isValidTahunAjaran(String value) {
    final regex = RegExp(r'^\d{4}/\d{4}$');

    if (!regex.hasMatch(value)) {
      return false;
    }

    final parts = value.split('/');

    final tahunAwal = int.tryParse(parts[0]);
    final tahunAkhir = int.tryParse(parts[1]);

    if (tahunAwal == null || tahunAkhir == null) {
      return false;
    }

    return tahunAkhir == tahunAwal + 1;
  }

  Future<void> _simpanTahunAjaran(
    AppSettingProvider provider,
    String value,
  ) async {
    final success = await provider.updateTahunAjaran(value);

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tahun ajaran berhasil diperbarui menjadi $value.'),
          backgroundColor: _primaryColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal memperbarui tahun ajaran.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

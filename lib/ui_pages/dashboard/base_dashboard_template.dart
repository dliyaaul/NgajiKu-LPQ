import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptl_mobile/state_management/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ptl_mobile/services/attendance_web_test_service.dart';

class BaseDashboardTemplate extends StatelessWidget {
  final String userName;
  final String roleLabel;
  final String? avatarUrl;
  final Widget body;
  final List<Widget>? appBarActions;

  const BaseDashboardTemplate({
    super.key,
    required this.userName,
    required this.roleLabel,
    this.avatarUrl,
    required this.body,
    this.appBarActions,
  });

  static const Color primary = Color(0xFF0D8B8B);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF78909C);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F8F8);

  String get _initial {
    final name = userName.trim();
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: Color(0xFFD32F2F),
            size: 28,
          ),
        ),
        title: const Text(
          'Keluar dari akun?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin mengakhiri sesi saat ini?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.6, color: textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              foregroundColor: textPrimary,
              side: const BorderSide(color: Color(0xFFE0E7E7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              await context.read<AuthProvider>().logout();

              if (!context.mounted) return;

              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminSessionDialog(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final user = supabase.auth.currentUser;

    String? role;
    String? errorMessage;

    if (user != null) {
      try {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        role = profile?['role']?.toString();
      } catch (e) {
        errorMessage = 'Gagal mengambil role pengguna.';
      }
    }

    if (!context.mounted) return;

    final hasSession = session != null;
    final hasToken = session?.accessToken.isNotEmpty ?? false;
    final isExpired = session?.isExpired ?? true;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user_outlined),
            SizedBox(width: 10),
            Expanded(child: Text('Informasi Sesi')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sessionInfoRow(
                'Status sesi',
                hasSession ? 'Tersedia' : 'Tidak tersedia',
              ),
              _sessionInfoRow(
                'Access token',
                hasToken ? 'Tersedia' : 'Tidak tersedia',
              ),
              _sessionInfoRow('Token kedaluwarsa', isExpired ? 'Ya' : 'Tidak'),
              _sessionInfoRow('Role', role ?? 'Tidak diketahui'),
              _sessionInfoRow('User ID', user?.id ?? '-'),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(errorMessage, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              const Text(
                'Token tidak ditampilkan demi keamanan.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _sessionInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          const Text(': '),
          Expanded(
            flex: 5,
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({double radius = 17}) {
    final String? rawUrl = avatarUrl?.trim();

    final bool hasAvatar = rawUrl != null && rawUrl.isNotEmpty;

    // Cache-buster dibuat stabil, tidak berubah setiap build.
    final String? imageUrl = hasAvatar
        ? '$rawUrl${rawUrl.contains('?') ? '&' : '?'}v=1'
        : null;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primary.withValues(alpha: 0.30), width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE0F2F1),
        child: ClipOval(
          child: imageUrl != null
              ? Image.network(
                  imageUrl,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Gagal memuat avatar dashboard: $error');
                    return _buildInitial(radius);
                  },
                )
              : _buildInitial(radius),
        ),
      ),
    );
  }

  Widget _buildInitial(double radius) {
    return Center(
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Menu profil',
      offset: const Offset(0, 48),
      elevation: 8,
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (value) async {
        if (value == 'settings') {
          Navigator.pushNamed(context, '/settings');
        } else if (value == 'logout') {
          _showLogoutDialog(context);
        } else if (value == 'check_session') {
          _showAdminSessionDialog(context);
        } else if (value == 'test_handoff') {
          await AttendanceWebTestService.testHandoff();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 190,
            child: Row(
              children: [
                _buildAvatar(radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        roleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 12),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: textSecondary),
              SizedBox(width: 12),
              Text('Pengaturan'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: Color(0xFFD32F2F)),
              SizedBox(width: 12),
              Text(
                'Keluar',
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const PopupMenuItem<String>(
          value: 'check_session',
          child: Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 20, color: primary),
              SizedBox(width: 12),
              Text('Cek Sesi Admin'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'test_handoff',
          child: Row(
            children: [
              Icon(Icons.bug_report_outlined, size: 20),
              SizedBox(width: 12),
              Text('Tes Web Handoff'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(left: 4, right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Assalamu’alaikum,',
              style: TextStyle(
                fontSize: 11,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              userName.trim().isEmpty ? 'Pengguna' : userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
        actions:
            appBarActions ??
            [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  tooltip: 'Notifikasi',
                  onPressed: () {
                    // Hubungkan ke halaman notifikasi ketika tersedia.
                  },
                  icon: const Icon(Icons.notifications_none_rounded, size: 24),
                  style: IconButton.styleFrom(foregroundColor: textSecondary),
                ),
              ),
              _buildProfileMenu(context),
            ],
      ),
      body: body,
    );
  }
}

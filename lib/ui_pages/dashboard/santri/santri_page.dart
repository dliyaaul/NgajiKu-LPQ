import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ptl_mobile/state_management/santri_program_provider.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';
import 'package:ptl_mobile/models/santri_program/santri_program_model.dart';
import 'package:ptl_mobile/ui_pages/dashboard/base_dashboard_template.dart';
import 'package:ptl_mobile/state_management/auth_provider.dart';

import 'detail_program_pembelajaran_page.dart';

class SantriPage extends StatefulWidget {
  final String userName;

  const SantriPage({super.key, required this.userName});

  @override
  State<SantriPage> createState() => _SantriPageState();
}

class _SantriPageState extends State<SantriPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadProgramSantri();
    });
  }

  Future<void> _loadProgramSantri() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || !mounted) return;
    await context.read<SantriProgramProvider>().loadBySantri(
      userId,
      context.read<LoadingProvider>(),
    );
  }

  static const Color primary = Color(0xFF0D8B8B);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF78909C);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.userProfile;

    final String displayName =
        profile?['username']?.toString() ?? widget.userName;

    final String? avatarUrl = profile?['avatar_url']?.toString();

    return BaseDashboardTemplate(
      userName: displayName,
      roleLabel: 'SANTRI',
      avatarUrl: avatarUrl,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Sambutan
                    _buildWelcomeSection(displayName),

                    const SizedBox(height: 20),

                    // 2. Program Pembelajaran
                    _buildProgramCard(context),

                    const SizedBox(height: 20),

                    // 3. Ringkasan Absensi
                    _buildAttendanceSummary(),

                    const SizedBox(height: 24),

                    // 4. Menu Utama
                    _buildSectionTitle(
                      'Menu Utama',
                      'Akses informasi pembelajaran Anda',
                    ),

                    const SizedBox(height: 14),

                    _buildMainMenu(context, isWide),

                    const SizedBox(height: 24),

                    // 5. Jadwal Pembelajaran
                    _buildSectionTitle(
                      'Jadwal Pembelajaran',
                      'Jadwal pertemuan Anda',
                    ),

                    const SizedBox(height: 14),

                    _buildScheduleCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // WELCOME SECTION
  // ============================================================

  Widget _buildWelcomeSection(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selamat datang di NgajiKu 👋',
          style: TextStyle(fontSize: 14, color: textSecondary),
        ),

        const SizedBox(height: 6),

        Text(
          name.isEmpty ? 'Santri' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Semoga Allah memudahkan langkah kita '
          'dalam menuntut ilmu Al-Qur’an.',
          style: TextStyle(fontSize: 13, height: 1.6, color: textSecondary),
        ),
      ],
    );
  }

  // ============================================================
  // PROGRAM CARD
  // ============================================================

  Widget _buildProgramCard(BuildContext context) {
    final programProvider = context.watch<SantriProgramProvider>();
    final programs = programProvider.items;

    Widget buildProgramItem(SantriProgramModel item) {
      final namaProgram = item.program?.nama ?? 'Program';
      final namaKelas =
          item.kelasPengajaran?.namaKelas ??
          item.kelasType?.nama ??
          'Kelas belum ditentukan';
      final namaJenisKelas = item.kelasType?.nama;
      final namaPengajar =
          item.kelasPengajaran?.namaPengajar ??
          item.pengajar?.username ??
          'Belum ditentukan';

      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DetailProgramPembelajaranPage(programSantri: item),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaProgram,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          namaJenisKelas ?? 'Program pembelajaran',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Program Aktif',
                      style: TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.white.withOpacity(0.25)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      namaKelas,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      namaPengajar,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (programProvider.errorMessage != null &&
        programProvider.errorMessage!.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Program belum dapat dimuat',
              style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              programProvider.errorMessage!,
              style: const TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadProgramSantri,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (programs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: primary, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum ada program',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Silakan hubungi admin untuk informasi program.',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < programs.length; i++) ...[
          buildProgramItem(programs[i]),
          if (i != programs.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ============================================================
  // ATTENDANCE SUMMARY
  // ============================================================

  Widget _buildAttendanceSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.calendar_month_rounded,
            title: 'Pertemuan',
            value: '8',
            description: 'Total pertemuan',
            iconColor: primary,
            iconBackground: const Color(0xFFE0F2F1),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildSummaryCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Kehadiran',
            value: '92%',
            description: 'Persentase hadir',
            iconColor: const Color(0xFF2E7D32),
            iconBackground: const Color(0xFFE8F5E9),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            description,
            style: const TextStyle(fontSize: 10, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: textSecondary),
        ),
      ],
    );
  }

  // ============================================================
  // MAIN MENU
  // ============================================================

  Widget _buildMainMenu(BuildContext context, bool isWide) {
    final menus = [
      _MenuItem(
        title: 'Program',
        subtitle: 'Program belajar',
        icon: Icons.menu_book_rounded,
        color: primary,
        background: const Color(0xFFE0F2F1),
      ),

      _MenuItem(
        title: 'Absensi',
        subtitle: 'Riwayat hadir',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF1976D2),
        background: const Color(0xFFE3F2FD),
      ),

      _MenuItem(
        title: 'Tagihan',
        subtitle: 'Pembayaran',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFFEF6C00),
        background: const Color(0xFFFFF3E0),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menus.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 2.1 : 0.95,
      ),
      itemBuilder: (context, index) {
        final menu = menus[index];

        return _buildMenuCard(context, menu, isWide);
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuItem menu, bool isWide) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu ${menu.title} akan dikembangkan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isWide ? 16 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EEEE)),
        ),
        child: isWide
            ? Row(
                children: [
                  _buildMenuIcon(menu),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          menu.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuIcon(menu),

                  const SizedBox(height: 10),

                  Text(
                    menu.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    menu.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: textSecondary),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMenuIcon(_MenuItem menu) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: menu.background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(menu.icon, color: menu.color, size: 23),
    );
  }

  // ============================================================
  // SCHEDULE
  // ============================================================

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Text(
                  'SAB',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  '31',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BBAQ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),

                SizedBox(height: 6),

                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: textSecondary,
                    ),

                    SizedBox(width: 5),

                    Text(
                      '08.00 - 09.00 WIB',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),

                SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: textSecondary,
                    ),

                    SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        'Tempat pembelajaran',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right_rounded, color: textSecondary),
        ],
      ),
    );
  }
}

// ============================================================
// MENU MODEL
// ============================================================

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
  });
}

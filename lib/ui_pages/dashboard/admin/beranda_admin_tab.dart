import 'package:flutter/material.dart';

import 'package:ptl_mobile/ui_pages/dashboard/admin/absen/absensi_main_page.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/lembaga/lembaga_page.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/manajemen_lpq.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/santri_program_page.dart';
import 'package:ptl_mobile/ui_pages/pembayaran/generate_tagihan_page.dart';
import 'package:ptl_mobile/ui_pages/pembayaran/kelola_tarif_page.dart';
import 'package:ptl_mobile/ui_pages/pembayaran/pembayaran_rekening_page.dart';
import 'package:ptl_mobile/ui_pages/pembayaran/tagihan_page.dart';
import 'package:ptl_mobile/ui_pages/pembayaran/verifikasi_pembayaran_page.dart';

class BerandaAdminTab extends StatelessWidget {
  const BerandaAdminTab({super.key});

  static const Color primary = Color(0xFF0D8B8B);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF78909C);
  static const Color borderColor = Color(0xFFE8EEEE);
  static const Color background = Color(0xFFF5F8F8);

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = <_QuickActionData>[
      _QuickActionData(
        label: 'Manajemen LPQ',
        icon: Icons.apartment_rounded,
        onTap: () => _openPage(context, const ManajemenLpqPage()),
      ),
      _QuickActionData(
        label: 'Kelola Lembaga',
        icon: Icons.account_balance_rounded,
        onTap: () => _openPage(context, const LembagaPage()),
      ),
      _QuickActionData(
        label: 'Program Santri',
        icon: Icons.menu_book_rounded,
        onTap: () => _openPage(context, const SantriProgramPage()),
      ),
      _QuickActionData(
        label: 'Absensi Santri',
        icon: Icons.fact_check_outlined,
        onTap: () => _openPage(context, const AbsensiMainPage()),
      ),
      _QuickActionData(
        label: 'Kelola Pembayaran',
        icon: Icons.receipt_long_rounded,
        onTap: () => _openPage(context, const TagihanPage()),
      ),
      _QuickActionData(
        label: 'Verifikasi Pembayaran',
        icon: Icons.verified_outlined,
        onTap: () => _openPage(context, const VerifikasiPembayaranPage()),
      ),
      _QuickActionData(
        label: 'Kelola Tarif',
        icon: Icons.payments_outlined,
        onTap: () => _openPage(context, const KelolaTarifPage()),
      ),
      _QuickActionData(
        label: 'Generate Tagihan',
        icon: Icons.post_add_rounded,
        onTap: () => _openPage(context, const GenerateTagihanPage()),
      ),
      _QuickActionData(
        label: 'Rekening Pembayaran',
        icon: Icons.account_balance_wallet_outlined,
        onTap: () => _openPage(context, const PembayaranRekeningPage()),
      ),
      _QuickActionData(
        label: 'Pengumuman',
        icon: Icons.campaign_outlined,
        onTap: () {
          // Hubungkan ketika halaman pengumuman tersedia.
        },
      ),
      _QuickActionData(
        label: 'Cetak Laporan',
        icon: Icons.print_outlined,
        onTap: () {
          // Hubungkan ketika halaman laporan tersedia.
        },
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        const _WelcomeCard(),
        const SizedBox(height: 24),

        const _SectionHeader(
          title: 'Ringkasan',
          subtitle: 'Gambaran umum aktivitas lembaga',
        ),
        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 4 : 2;

            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 4 ? 1.35 : 1.42,
              children: const [
                _StatCard(
                  title: 'Total Santri',
                  value: '342',
                  subtitle: 'Aktif terdaftar',
                  icon: Icons.school_rounded,
                  accent: Color(0xFF0D8B8B),
                  iconBackground: Color(0xFFE0F2F1),
                ),
                _StatCard(
                  title: 'Total Pengajar',
                  value: '28',
                  subtitle: 'Ustadz & ustadzah',
                  icon: Icons.record_voice_over_rounded,
                  accent: Color(0xFF1976D2),
                  iconBackground: Color(0xFFE3F2FD),
                ),
                _StatCard(
                  title: 'SPP Lunas',
                  value: '85%',
                  subtitle: '290 dari 342 santri',
                  icon: Icons.check_circle_rounded,
                  accent: Color(0xFF2E7D32),
                  iconBackground: Color(0xFFE8F5E9),
                ),
                _StatCard(
                  title: 'Menunggu Verifikasi',
                  value: '12',
                  subtitle: 'Bukti transfer',
                  icon: Icons.pending_actions_rounded,
                  accent: Color(0xFFE07820),
                  iconBackground: Color(0xFFFFF3E0),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        const _SectionHeader(
          title: 'Menu Operasional',
          subtitle: 'Akses cepat pengelolaan NgajiKu',
        ),
        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 5
                : constraints.maxWidth >= 600
                ? 4
                : 3;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickActions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 112,
              ),
              itemBuilder: (context, index) {
                final item = quickActions[index];

                return _QuickActionCard(
                  icon: item.icon,
                  label: item.label,
                  onTap: item.onTap,
                );
              },
            );
          },
        ),

        const SizedBox(height: 28),

        const _SectionHeader(
          title: 'Aktivitas Terbaru',
          subtitle: 'Contoh tampilan riwayat transaksi',
          trailing: null,
        ),
        const SizedBox(height: 14),

        const _ActivityCard(
          title: 'Pembayaran SPP',
          subtitle: 'Ahmad Fauzi • Kelas 8A',
          amount: 'Rp450.000',
          time: '10 menit lalu',
          status: 'Lunas',
          statusColor: Color(0xFF2E7D32),
          statusBackground: Color(0xFFE8F5E9),
          icon: Icons.receipt_long_rounded,
        ),

        const SizedBox(height: 10),

        const _ActivityCard(
          title: 'Verifikasi pembayaran',
          subtitle: 'Menunggu pemeriksaan admin',
          amount: '12 transaksi',
          time: 'Ringkasan status',
          status: 'Perlu dicek',
          statusColor: Color(0xFFE07820),
          statusBackground: Color(0xFFFFF3E0),
          icon: Icons.fact_check_outlined,
        ),

        const SizedBox(height: 20),

        const Center(
          child: Text(
            'NgajiKu • Administrasi LPQ',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF90A4AE),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF087F80), Color(0xFF0D9995)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D8B8B).withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -18,
            child: Icon(
              Icons.mosque_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: const Text(
                  'PANEL ADMINISTRATOR',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selamat datang di\nNgajiKu',
                style: TextStyle(
                  fontSize: 25,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Kelola administrasi lembaga dengan lebih '
                'mudah, teratur, dan terintegrasi.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF78909C)),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color iconBackground;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.018),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF78909C),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
                color: accent,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              height: 1.3,
              color: Color(0xFF90A4AE),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE8EEEE)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F4F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF0D8B8B), size: 22),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF455A64),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String time;
  final String status;
  final Color statusColor;
  final Color statusBackground;
  final IconData icon;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F4F2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFF0D8B8B), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF78909C),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$amount • $time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF455A64),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

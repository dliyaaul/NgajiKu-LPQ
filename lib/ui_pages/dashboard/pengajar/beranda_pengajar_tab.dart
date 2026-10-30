import 'package:flutter/material.dart';

class BerandaPengajarTab extends StatelessWidget {
  const BerandaPengajarTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Grid Statistik
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: const [
            _StatCard(
              title: 'Total Santri',
              value: '342',
              subtitle: 'Aktif Terdaftar',
              icon: Icons.school_rounded,
              color: Color(0xFF0D8B8B),
            ),
            _StatCard(
              title: 'Total Pengajar',
              value: '28',
              subtitle: 'Ustadz & Ustadzah',
              icon: Icons.record_voice_over_rounded,
              color: Color(0xFF0288D1),
            ),
            _StatCard(
              title: 'SPP Lunas (Bulan Ini)',
              value: '85%',
              subtitle: '290 / 342 Santri',
              icon: Icons.check_circle_rounded,
              color: Color(0xFF2E7D32),
            ),
            _StatCard(
              title: 'Menunggu Verifikasi',
              value: '12',
              subtitle: 'Bukti Transfer',
              icon: Icons.pending_actions_rounded,
              color: Color(0xFFE65100),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Akses Cepat / Menu Operasional Utama
        const Text(
          'Menu Utama & Aksi Cepat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 8,
          children: [
            _QuickActionButton(
              icon: Icons.person_add_rounded,
              label: 'Tambah Santri',
              onTap: () {},
            ),
            _QuickActionButton(
              icon: Icons.receipt_long_rounded,
              label: 'Tagih SPP',
              onTap: () {},
            ),
            _QuickActionButton(
              icon: Icons.campaign_rounded,
              label: 'Pengumuman',
              onTap: () {},
            ),
            _QuickActionButton(
              icon: Icons.print_rounded,
              label: 'Cetak Laporan',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Aktivitas Terakhir
        const Text(
          'Aktivitas Terbaru',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 12),
        const _ActivityTile(
          title: 'Pembayaran SPP - Ahmad Fauzi',
          subtitle: 'Kelas 8A • Rp 450.000',
          time: '10 menit lalu',
          status: 'Lunas',
          statusColor: Colors.green,
        ),
      ],
    );
  }
}

// Widget Kartu Statistik
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEFF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF78909C)),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFFB0BEC5)),
          ),
        ],
      ),
    );
  }
}

// Widget Button Akses Cepat
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D8B8B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0D8B8B)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF455A64)),
          ),
        ],
      ),
    );
  }
}

// Widget List Item Aktivitas
class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String status;
  final Color statusColor;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECEFF1)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$subtitle • $time',
          style: const TextStyle(fontSize: 11, color: Color(0xFF78909C)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ),
    );
  }
}

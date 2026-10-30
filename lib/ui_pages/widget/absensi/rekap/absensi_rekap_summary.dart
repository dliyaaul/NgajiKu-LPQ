import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _primaryLightColor = Color(0xFFE6F3F3);
const Color _cardColor = Colors.white;
const Color _textColor = Color(0xFF1E293B);
const Color _subtitleColor = Color(0xFF64748B);
const Color _borderColor = Color(0xFFE2E8F0);

class AbsensiRekapSummary extends StatelessWidget {
  final int jumlahSantri;
  final int jumlahPertemuan;
  final int totalHadir;
  final double persentaseKehadiran;

  const AbsensiRekapSummary({
    super.key,
    required this.jumlahSantri,
    required this.jumlahPertemuan,
    required this.totalHadir,
    required this.persentaseKehadiran,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 700;

        if (isWide) {
          return _buildWideLayout();
        }

        return _buildMobileLayout();
      },
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.groups_outlined,
            title: 'Jumlah Santri',
            value: jumlahSantri.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.event_available_outlined,
            title: 'Pertemuan',
            value: jumlahPertemuan.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.check_circle_outline,
            title: 'Total Hadir',
            value: totalHadir.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.percent_outlined,
            title: 'Kehadiran',
            value: '${persentaseKehadiran.toStringAsFixed(1)}%',
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.groups_outlined,
                title: 'Jumlah Santri',
                value: jumlahSantri.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.event_available_outlined,
                title: 'Pertemuan',
                value: jumlahPertemuan.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.check_circle_outline,
                title: 'Total Hadir',
                value: totalHadir.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.percent_outlined,
                title: 'Kehadiran',
                value: '${persentaseKehadiran.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primaryLightColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryColor, size: 21),
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
                  style: const TextStyle(color: _subtitleColor, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

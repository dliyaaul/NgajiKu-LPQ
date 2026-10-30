import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'absensi_page_config.dart';
import 'absensi_pertemuan_item.dart';

class AbsensiPertemuanCard extends StatelessWidget {
  final AbsensiPertemuanItem item;
  final bool isExpanded;
  final VoidCallback onToggle;
  final AbsensiPageConfig config;

  const AbsensiPertemuanCard({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.onToggle,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final tanggal = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(item.tanggal);

    final bool isOnline = item.pbm.toLowerCase() == 'online';

    final createdAtLocal = item.createdAt.toLocal();

    final batasWaktu = item.batasWaktu?.toLocal();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? config.primaryColor.withOpacity(0.6)
              : Colors.grey.shade200,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? config.primaryColor.withOpacity(0.08)
                : Colors.black.withOpacity(0.02),
            blurRadius: isExpanded ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            _buildHeader(context, tanggal, isOnline),
            _buildBody(context, createdAtLocal, batasWaktu),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context, String tanggal, bool isOnline) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ====================================================
            // ICON
            // ====================================================
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isExpanded ? config.primaryColor : config.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: isExpanded ? Colors.white : config.primaryColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // ====================================================
            // TITLE + BADGES
            // ====================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tanggal,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: config.textColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // PBM
                      _buildBadge(
                        label: item.pbm,
                        backgroundColor: isOnline
                            ? Colors.blue.shade50
                            : Colors.green.shade50,
                        textColor: isOnline
                            ? Colors.blue.shade700
                            : Colors.green.shade800,
                      ),

                      // PENGGANTI
                      if (item.hasPengganti)
                        _buildBadge(
                          label: 'Pengganti',
                          backgroundColor: Colors.amber.shade50,
                          textColor: Colors.amber.shade900,
                        ),

                      // STATUS
                      _buildBadge(
                        label: item.canInputAttendance ? 'Aktif' : 'Terkunci',
                        backgroundColor: item.canInputAttendance
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        textColor: item.canInputAttendance
                            ? Colors.green.shade800
                            : Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ====================================================
            // ARROW
            // ====================================================
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isExpanded ? config.primaryColor : config.subtitleColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _buildBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
    BuildContext context,
    DateTime createdAt,
    DateTime? batasWaktu,
  ) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity),

      secondChild: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // ==================================================
            // PENGAJAR
            // ==================================================
            _buildInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Pengajar',
              value: item.pengajar,
            ),

            // ==================================================
            // MATERI
            // ==================================================
            if (item.materi != null && item.materi!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),

              _buildInfoRow(
                icon: Icons.menu_book_rounded,
                label: 'Materi',
                value: item.materi!,
              ),
            ],

            // ==================================================
            // PENGGANTI
            // ==================================================
            if (item.hasPengganti &&
                item.pengganti != null &&
                item.pengganti!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),

              _buildInfoRow(
                icon: Icons.swap_horiz_rounded,
                label: 'Pengganti',
                value: item.pengganti!,
                valueColor: Colors.amber.shade900,
              ),
            ],

            // ==================================================
            // ADDITIONAL INFO
            // ==================================================
            for (final info in item.additionalInfo) ...[
              const SizedBox(height: 8),

              _buildInfoRow(
                icon: info.icon,
                label: info.label,
                value: info.value,
                valueColor: info.valueColor,
              ),
            ],

            // ==================================================
            // DIBUAT
            // ==================================================
            const SizedBox(height: 8),

            _buildInfoRow(
              icon: Icons.access_time_rounded,
              label: 'Dibuat',
              value: DateFormat(
                'dd MMM yyyy, HH:mm',
                'id_ID',
              ).format(createdAt),
            ),

            // ==================================================
            // BATAS WAKTU
            // ==================================================
            if (batasWaktu != null) ...[
              const SizedBox(height: 8),

              _buildInfoRow(
                icon: Icons.timer_outlined,
                label: 'Batas',
                value: DateFormat(
                  'dd MMM yyyy, HH:mm',
                  'id_ID',
                ).format(batasWaktu),
                valueColor: item.canInputAttendance
                    ? Colors.green.shade700
                    : Colors.redAccent,
              ),

              const SizedBox(height: 10),

              _buildTimeStatus(),
            ],

            const SizedBox(height: 16),

            // ==================================================
            // ACTION
            // ==================================================
            _buildActions(context),
          ],
        ),
      ),

      crossFadeState: isExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,

      duration: const Duration(milliseconds: 200),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: config.subtitleColor),

        const SizedBox(width: 8),

        SizedBox(
          width: 65,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: config.subtitleColor),
          ),
        ),

        Text(': ', style: TextStyle(fontSize: 12, color: config.subtitleColor)),

        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: valueColor ?? config.textColor,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TIME STATUS
  // ============================================================

  Widget _buildTimeStatus() {
    final active = item.canInputAttendance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            active ? Icons.schedule_rounded : Icons.lock_clock_outlined,
            size: 17,
            color: active ? Colors.green.shade700 : Colors.redAccent,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              active
                  ? 'Pertemuan dan pengisian absensi masih dapat dilakukan sampai batas waktu yang ditentukan.'
                  : 'Batas waktu pertemuan telah berakhir. Edit dan pengisian absensi dikunci.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: active ? Colors.green.shade800 : Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        // ========================================================
        // BUKA ABSENSI
        // ========================================================
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAttendanceOptions(context),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Buka Absensi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: config.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // ========================================================
        // EDIT
        // ========================================================
        if (item.onEdit != null) ...[
          const SizedBox(width: 8),

          IconButton(
            onPressed: item.canEdit ? item.onEdit : null,
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: item.canEdit ? config.textColor : Colors.grey,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            tooltip: 'Edit',
          ),
        ],

        // ========================================================
        // DELETE
        // ========================================================
        if (item.onDelete != null) ...[
          const SizedBox(width: 6),

          IconButton(
            onPressed: item.onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            tooltip: 'Hapus',
          ),
        ],
      ],
    );
  }

  void _showAttendanceOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Buka Absensi',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih tempat untuk mengisi absensi pertemuan ini.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // Pilihan aplikasi
              _buildOption(
                icon: Icons.phone_android_rounded,
                title: 'Lanjut di Aplikasi',
                subtitle: 'Gunakan halaman absensi di aplikasi ini.',
                color: config.primaryColor,
                onTap: () {
                  Navigator.pop(sheetContext);
                  item.onOpen?.call();
                },
              ),

              const SizedBox(height: 10),

              // Pilihan web
              _buildOption(
                icon: Icons.language_rounded,
                title: 'Buka di Web (Chrome)',
                subtitle: 'Gunakan halaman absensi melalui browser.',
                color: Colors.blue.shade700,
                onTap: () {
                  Navigator.pop(sheetContext);

                  if (item.onOpenWeb != null) {
                    item.onOpenWeb!.call();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Halaman absensi web belum dikonfigurasi.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

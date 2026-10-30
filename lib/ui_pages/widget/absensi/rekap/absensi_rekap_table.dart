import 'package:flutter/material.dart';
import 'package:ptl_mobile/ui_pages/widget/absensi/rekap/absensi_rekap_row.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _primaryLightColor = Color(0xFFE6F3F3);
const Color _cardColor = Colors.white;
const Color _textColor = Color(0xFF1E293B);
const Color _subtitleColor = Color(0xFF64748B);
const Color _borderColor = Color(0xFFE2E8F0);

class AbsensiRekapTable extends StatelessWidget {
  final List<AbsensiRekapRow> rekapList;
  final List<DateTime> tanggalList;

  final String title;

  const AbsensiRekapTable({
    super.key,
    required this.rekapList,
    required this.tanggalList,
    this.title = 'Rekap Kehadiran Santri',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: _borderColor),
          if (rekapList.isEmpty) _buildEmpty() else _buildTable(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(
        children: [
          const Icon(
            Icons.table_chart_outlined,
            color: _primaryColor,
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${rekapList.length} santri',
            style: const TextStyle(color: _subtitleColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(_primaryLightColor),
          headingTextStyle: const TextStyle(
            color: _textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          dataTextStyle: const TextStyle(color: _textColor, fontSize: 12),
          columnSpacing: 18,
          horizontalMargin: 12,
          dividerThickness: 0.5,
          columns: [
            const DataColumn(label: Text('No')),
            const DataColumn(label: Text('Nama Santri')),

            ...tanggalList.map((tanggal) {
              return DataColumn(label: Text(_formatDateShort(tanggal)));
            }),

            const DataColumn(label: Text('H')),
            const DataColumn(label: Text('I')),
            const DataColumn(label: Text('S')),
            const DataColumn(label: Text('A')),
            const DataColumn(label: Text('%')),
          ],
          rows: List.generate(rekapList.length, (index) {
            final row = rekapList[index];

            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),

                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 180,
                      maxWidth: 240,
                    ),
                    child: Text(
                      row.namaSantri,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                ...tanggalList.map((tanggal) {
                  final status = row.getStatus(_formatDateKey(tanggal));

                  return DataCell(_buildStatusChip(status));
                }),

                DataCell(Text(row.totalHadir.toString())),

                DataCell(Text(row.totalIzin.toString())),

                DataCell(Text(row.totalSakit.toString())),

                DataCell(Text(row.totalAlpa.toString())),

                DataCell(
                  Text('${row.persentaseKehadiran.toStringAsFixed(1)}%'),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final String normalized = status.trim().toUpperCase();

    String label;
    Color background;
    Color foreground;

    switch (normalized) {
      case 'H':
      case 'HADIR':
        label = 'H';
        background = const Color(0xFFE8F5E9);
        foreground = const Color(0xFF2E7D32);
        break;

      case 'I':
      case 'IZIN':
        label = 'I';
        background = const Color(0xFFFFF8E1);
        foreground = const Color(0xFFF57F17);
        break;

      case 'S':
      case 'SAKIT':
        label = 'S';
        background = const Color(0xFFE3F2FD);
        foreground = const Color(0xFF1565C0);
        break;

      case 'A':
      case 'ALPA':
      case 'ALPHA':
        label = 'A';
        background = const Color(0xFFFFEBEE);
        foreground = const Color(0xFFC62828);
        break;

      case '-':
      case '':
        label = '-';
        background = const Color(0xFFF1F5F9);
        foreground = _subtitleColor;
        break;

      default:
        label = '-';
        background = const Color(0xFFF1F5F9);
        foreground = _subtitleColor;
    }

    return Container(
      width: 28,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: _subtitleColor, size: 34),
          SizedBox(height: 10),
          Text(
            'Tidak ada data pada filter yang dipilih.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _subtitleColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

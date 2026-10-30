import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'absensi_filter.dart';
import 'absensi_page_config.dart';
import 'absensi_pertemuan_item.dart';

class AbsensiFilterSheet extends StatefulWidget {
  final AbsensiFilterState initialFilter;

  final List<AbsensiPertemuanItem> items;

  final AbsensiPageConfig config;

  final ValueChanged<AbsensiFilterState> onApply;

  const AbsensiFilterSheet({
    super.key,
    required this.initialFilter,
    required this.items,
    required this.config,
    required this.onApply,
  });

  @override
  State<AbsensiFilterSheet> createState() => _AbsensiFilterSheetState();
}

class _AbsensiFilterSheetState extends State<AbsensiFilterSheet> {
  late DateTimeRange? _dateRange;

  late String? _pengajarId;

  late AbsensiPbm? _pbm;

  @override
  void initState() {
    super.initState();

    _dateRange = widget.initialFilter.dateRange;

    _pengajarId = widget.initialFilter.pengajarId;

    _pbm = widget.initialFilter.pbm;
  }

  // ============================================================
  // PENGAJAR
  // ============================================================

  Map<String, String> get pengajarMap {
    final result = <String, String>{};

    for (final item in widget.items) {
      final id = item.pengajarId;

      if (id == null || id.isEmpty) {
        continue;
      }

      final nama = item.pengajar.trim();

      if (nama.isEmpty) {
        continue;
      }

      result[id] = nama;
    }

    final entries = result.entries.toList();

    entries.sort(
      (a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()),
    );

    return Map.fromEntries(entries);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),

              const SizedBox(height: 18),

              _buildTitle(),

              const SizedBox(height: 20),

              _buildDateFilter(),

              const SizedBox(height: 18),

              _buildPengajarFilter(),

              const SizedBox(height: 18),

              _buildPbmFilter(),

              const SizedBox(height: 26),

              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HANDLE
  // ============================================================

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Filter Pertemuan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: widget.config.textColor,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.close_rounded, color: widget.config.subtitleColor),
        ),
      ],
    );
  }

  // ============================================================
  // TANGGAL
  // ============================================================

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rentang Tanggal',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: widget.config.textColor,
          ),
        ),

        const SizedBox(height: 8),

        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _pickDateRange,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 20,
                  color: widget.config.primaryColor,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    _dateRange == null
                        ? 'Semua tanggal'
                        : _formatDateRange(_dateRange!),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: _dateRange == null
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: _dateRange == null
                          ? widget.config.subtitleColor
                          : widget.config.textColor,
                    ),
                  ),
                ),

                if (_dateRange != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _dateRange = null;
                      });
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: widget.config.subtitleColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateUtils.dateOnly(DateTime.now());

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      initialDateRange: _dateRange,
      currentDate: now,
      saveText: 'Pilih',
      cancelText: 'Batal',
      helpText: 'Pilih Rentang Tanggal',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _dateRange = DateTimeRange(
        start: DateUtils.dateOnly(picked.start),
        end: DateUtils.dateOnly(picked.end),
      );
    });
  }

  String _formatDateRange(DateTimeRange range) {
    final start = DateFormat('dd MMM yyyy', 'id_ID').format(range.start);

    final end = DateFormat('dd MMM yyyy', 'id_ID').format(range.end);

    if (DateUtils.isSameDay(range.start, range.end)) {
      return start;
    }

    return '$start - $end';
  }

  // ============================================================
  // PENGAJAR
  // ============================================================

  Widget _buildPengajarFilter() {
    final data = pengajarMap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengajar',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: widget.config.textColor,
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String?>(
          value: _pengajarId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: widget.config.primaryColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          hint: const Text('Semua pengajar'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Semua pengajar'),
            ),
            ...data.entries.map(
              (entry) => DropdownMenuItem<String?>(
                value: entry.key,
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _pengajarId = value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // PBM
  // ============================================================

  Widget _buildPbmFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PBM',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: widget.config.textColor,
          ),
        ),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPbmChip(
              label: 'Semua',
              selected: _pbm == null,
              onTap: () {
                setState(() {
                  _pbm = null;
                });
              },
            ),

            _buildPbmChip(
              label: 'Offline',
              selected: _pbm == AbsensiPbm.offline,
              onTap: () {
                setState(() {
                  _pbm = AbsensiPbm.offline;
                });
              },
            ),

            _buildPbmChip(
              label: 'Online',
              selected: _pbm == AbsensiPbm.online,
              onTap: () {
                setState(() {
                  _pbm = AbsensiPbm.online;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPbmChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? widget.config.primaryColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? widget.config.primaryColor : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : widget.config.textColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON
  // ============================================================

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _dateRange = null;
                _pengajarId = null;
                _pbm = null;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.config.subtitleColor,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              widget.onApply(
                AbsensiFilterState(
                  dateRange: _dateRange,
                  pengajarId: _pengajarId,
                  pbm: _pbm,
                ),
              );

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.config.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Terapkan Filter',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'absensi_detail_page_config.dart';
import 'absensi_detail_pertemuan_item.dart';
import 'absensi_detail_santri_item.dart';
import 'absensi_detail_summary.dart';

class AbsensiDetailPageTemplate extends StatefulWidget {
  final AbsensiDetailPageConfig config;
  final AbsensiDetailPertemuanItem pertemuan;
  final List<AbsensiDetailSantriItem> santri;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool canInputAttendance;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onRetry;
  final VoidCallback? onSave;
  final AbsensiDetailSummary summary;
  final String Function(String santriId) getStatus;
  final void Function({required String santriId, required String status})
  onChangeStatus;

  /// Filter status tambahan, misalnya untuk Tahfidz.
  final String selectedFilter;
  final ValueChanged<String>? onFilterChanged;

  /// Custom builder untuk card santri jika membutuhkan
  /// form spesifik seperti Tahfidz.
  final Widget Function(
    BuildContext context,
    AbsensiDetailSantriItem santri,
    String status,
  )?
  santriItemBuilder;

  const AbsensiDetailPageTemplate({
    super.key,
    required this.config,
    required this.pertemuan,
    required this.santri,
    required this.summary,
    required this.getStatus,
    required this.onChangeStatus,
    this.selectedFilter = 'Semua',
    this.onFilterChanged,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.canInputAttendance = true,
    this.onRefresh,
    this.onRetry,
    this.onSave,
    this.santriItemBuilder,
  });

  @override
  State<AbsensiDetailPageTemplate> createState() =>
      _AbsensiDetailPageTemplateState();

  // ============================================================
  // STATUS SELECTOR
  // ============================================================

  /// Selector status yang dapat digunakan oleh halaman lain,
  /// termasuk Absensi Tahfidz.
  static Widget buildStatusSelector({
    required String santriId,
    required String selectedStatus,
    required bool isDisabled,
    required void Function({required String santriId, required String status})
    onChangeStatus,
    required AbsensiDetailPageConfig config,
  }) {
    const statuses = ['Hadir', 'Izin', 'Sakit', 'Alpa'];

    Color getActiveColor(String status) {
      switch (status) {
        case 'Hadir':
          return config.hadirColor;
        case 'Izin':
          return config.izinColor;
        case 'Sakit':
          return config.sakitColor;
        case 'Alpa':
          return config.alpaColor;
        default:
          return config.subtitleColor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: statuses.map((status) {
          final selected = selectedStatus == status;
          final activeColor = getActiveColor(status);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: isDisabled
                      ? null
                      : () =>
                            onChangeStatus(santriId: santriId, status: status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? Colors.transparent
                          : selected
                          ? activeColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: selected && !isDisabled
                          ? [
                              BoxShadow(
                                color: activeColor.withOpacity(0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected && !isDisabled
                            ? Colors.white
                            : config.subtitleColor,
                      ),
                      child: Text(status),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ================================================================
// STATE
// ================================================================

class _AbsensiDetailPageTemplateState extends State<AbsensiDetailPageTemplate> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // ============================================================
  // BATAS WAKTU & STATUS PERTEMUAN
  // ============================================================

  DateTime get _batasWaktuPengisian => widget.pertemuan.batasWaktu;

  bool get _isPertemuanExpired => widget.pertemuan.isExpired;

  bool get _canEditAttendance =>
      widget.canInputAttendance &&
      widget.pertemuan.canInputAttendance &&
      !_isPertemuanExpired;

  Duration get _sisaWaktu => widget.pertemuan.remainingAttendanceTime;

  String _formatSisaWaktu() {
    final sisa = _sisaWaktu;

    if (sisa == Duration.zero) {
      return 'Waktu pengisian telah berakhir';
    }

    final hari = sisa.inDays;
    final jam = sisa.inHours.remainder(24);
    final menit = sisa.inMinutes.remainder(60);

    if (hari > 0) {
      return '$hari hari $jam jam $menit menit tersisa';
    }

    if (jam > 0) {
      return '$jam jam $menit menit tersisa';
    }

    if (menit > 0) {
      return '$menit menit tersisa';
    }

    return '${sisa.inSeconds} detik tersisa';
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);

    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // SEARCH & FILTER
  // ============================================================

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = query;
    });
  }

  List<AbsensiDetailSantriItem> get filteredSantri {
    final query = _searchQuery.trim().toLowerCase();

    return widget.santri.where((item) {
      final matchesSearch =
          query.isEmpty || item.nama.toLowerCase().contains(query);

      final status = widget.getStatus(item.id);

      bool matchesFilter = true;

      if (widget.selectedFilter != 'Semua') {
        matchesFilter =
            status.toLowerCase() == widget.selectedFilter.toLowerCase();
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.config.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: widget.config.primaryColor,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      centerTitle: true,
      title: Text(
        widget.config.title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (widget.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: widget.config.primaryColor),
      );
    }

    if (widget.errorMessage != null && widget.santri.isEmpty) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      color: widget.config.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          _buildPertemuanInfo(),

          const SizedBox(height: 14),

          _buildAttendanceTimeInfo(),

          const SizedBox(height: 14),

          _buildSummary(),

          const SizedBox(height: 14),

          _buildSearchAndFilterSection(),

          const SizedBox(height: 14),

          _buildSantriList(),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH & FILTER
  // ============================================================

  Widget _buildSearchAndFilterSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildSearchField()),
        if (widget.onFilterChanged != null) ...[
          const SizedBox(width: 8),
          _buildModernFilterButton(),
        ],
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: widget.config.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 13.5, color: widget.config.textColor),
        decoration: InputDecoration(
          hintText: widget.config.searchHint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => _searchController.clear(),
                  icon: const Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildModernFilterButton() {
    final isFiltered = widget.selectedFilter != 'Semua';

    return Container(
      decoration: BoxDecoration(
        color: isFiltered
            ? widget.config.primaryLight
            : widget.config.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFiltered
              ? widget.config.primaryColor.withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _showModernFilterBottomSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: isFiltered
                      ? widget.config.primaryColor
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.selectedFilter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isFiltered
                        ? widget.config.primaryColor
                        : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isFiltered
                      ? widget.config.primaryColor
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModernFilterBottomSheet() {
    const filters = ['Semua', 'Hadir', 'Izin', 'Sakit', 'Alpa'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Filter Status Absensi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: filters.map((filter) {
                  final isSelected = widget.selectedFilter == filter;

                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected && widget.onFilterChanged != null) {
                        widget.onFilterChanged!(filter);

                        Navigator.pop(context);
                      }
                    },
                    selectedColor: widget.config.primaryColor,
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide.none,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // PERTEMUAN INFO
  // ============================================================

  Widget _buildPertemuanInfo() {
    final pertemuan = widget.pertemuan;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.config.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.config.borderColor),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.02),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.config.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.config.pertemuanIcon,
                  color: widget.config.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.config.pertemuanTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: widget.config.textColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildInfoRow(
            Icons.calendar_today_rounded,
            _formatTanggal(pertemuan.tanggal),
          ),

          const SizedBox(height: 8),

          _buildPengajarInfo(pertemuan),

          const SizedBox(height: 8),

          _buildInfoRow(Icons.sensors_rounded, pertemuan.metode),

          if (pertemuan.materi != null &&
              pertemuan.materi!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.article_outlined, pertemuan.materi!),
          ],

          if (pertemuan.menggunakanPengganti) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.config.izinColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: widget.config.izinColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Menggunakan guru pengganti',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.config.izinColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          _buildInfoRow(
            Icons.schedule_rounded,
            'Dibuat: ${_formatTanggalWaktu(pertemuan.createdAt)}',
          ),
        ],
      ),
    );
  }

  Widget _buildPengajarInfo(AbsensiDetailPertemuanItem pertemuan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.person_rounded, pertemuan.pengajarAktif),

        if (pertemuan.menggunakanPengganti) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const SizedBox(width: 26),
              Expanded(
                child: Text(
                  'Menggantikan ${pertemuan.pengajar}',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.config.subtitleColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: widget.config.subtitleColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: widget.config.subtitleColor,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ATTENDANCE TIME
  // ============================================================

  Widget _buildAttendanceTimeInfo() {
    final expired = !_canEditAttendance;

    final colorBg = expired ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);

    final colorBorder = expired
        ? const Color(0xFFFCA5A5)
        : const Color(0xFF6EE7B7);

    final colorText = expired
        ? widget.config.alpaColor
        : widget.config.hadirColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorder.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            expired ? Icons.lock_clock_rounded : Icons.timer_outlined,
            color: colorText,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expired
                      ? 'Pengisian absensi telah ditutup'
                      : 'Pengisian absensi masih dibuka',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expired
                      ? 'Batas pengisian: ${_formatTanggalWaktu(_batasWaktuPengisian)}'
                      : _formatSisaWaktu(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorText.withOpacity(0.85),
                  ),
                ),
                if (!expired) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Batas: ${_formatTanggalWaktu(_batasWaktuPengisian)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorText.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.config.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.config.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ringkasan Kehadiran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.config.textColor,
                  ),
                ),
              ),
              if (widget.summary.total > 0)
                Text(
                  '${widget.summary.total} Santri',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.config.subtitleColor,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Hadir',
                  widget.summary.hadir,
                  Icons.check_circle_rounded,
                  widget.config.hadirColor,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Izin',
                  widget.summary.izin,
                  Icons.info_rounded,
                  widget.config.izinColor,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Sakit',
                  widget.summary.sakit,
                  Icons.healing_rounded,
                  widget.config.sakitColor,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Alpa',
                  widget.summary.alpa,
                  Icons.cancel_rounded,
                  widget.config.alpaColor,
                ),
              ),
            ],
          ),

          if (widget.summary.belumAbsen > 0) ...[
            const SizedBox(height: 10),
            _buildBelumAbsenItem(widget.summary.belumAbsen),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBelumAbsenItem(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            size: 17,
            color: Color(0xFFEA580C),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Belum Diabsen',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A3412),
              ),
            ),
          ),
          Text(
            '$total santri',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SANTRI LIST
  // ============================================================

  Widget _buildSantriList() {
    final data = filteredSantri;

    if (data.isEmpty) {
      return _buildEmptySantriState();
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${data.length} Santri',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.config.subtitleColor,
            ),
          ),
        ),
        const SizedBox(height: 8),

        ...data.map((santri) {
          final status = widget.getStatus(santri.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: widget.santriItemBuilder != null
                ? widget.santriItemBuilder!(context, santri, status)
                : _buildSantriCard(santri),
          );
        }),
      ],
    );
  }

  // ============================================================
  // DEFAULT SANTRI CARD
  // ============================================================

  Widget _buildSantriCard(AbsensiDetailSantriItem santri) {
    final status = widget.getStatus(santri.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.config.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.config.borderColor),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.01),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.config.primaryLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitial(santri.nama),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: widget.config.primaryColor,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  santri.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.config.textColor,
                  ),
                ),
              ),

              _buildStatusBadge(status),
            ],
          ),

          const SizedBox(height: 12),

          AbsensiDetailPageTemplate.buildStatusSelector(
            santriId: santri.id,
            selectedStatus: status,
            isDisabled: widget.isSaving || !_canEditAttendance,
            onChangeStatus: widget.onChangeStatus,
            config: widget.config,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status) {
    late Color bg;
    late Color fg;

    switch (status) {
      case 'Hadir':
        bg = widget.config.hadirColor.withOpacity(0.12);
        fg = widget.config.hadirColor;
        break;

      case 'Izin':
        bg = widget.config.izinColor.withOpacity(0.12);
        fg = widget.config.izinColor;
        break;

      case 'Sakit':
        bg = widget.config.sakitColor.withOpacity(0.12);
        fg = widget.config.sakitColor;
        break;

      case 'Alpa':
        bg = widget.config.alpaColor.withOpacity(0.12);
        fg = widget.config.alpaColor;
        break;

      default:
        bg = const Color(0xFFF1F5F9);
        fg = widget.config.subtitleColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget? _buildBottomButton() {
    if (widget.santri.isEmpty || !_canEditAttendance || widget.onSave == null) {
      return null;
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.config.cardColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, -2),
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: widget.isSaving ? null : widget.onSave,
            icon: widget.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              widget.isSaving
                  ? widget.config.savingButtonLabel
                  : widget.config.saveButtonLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.config.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: widget.config.primaryColor.withOpacity(
                0.5,
              ),
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptySantriState() {
    final hasSearch = _searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Icon(
            hasSearch
                ? Icons.person_search_rounded
                : Icons.people_outline_rounded,
            size: 48,
            color: widget.config.subtitleColor,
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch
                ? widget.config.filteredSantriTitle
                : widget.config.emptySantriTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: widget.config.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Coba gunakan kata kunci pencarian atau filter lain.'
                : widget.config.emptySantriDescription,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: widget.config.subtitleColor),
          ),
          if (hasSearch) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _searchController.clear(),
              icon: const Icon(Icons.search_off_rounded, size: 17),
              label: const Text('Reset Pencarian'),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.config.primaryColor,
                side: BorderSide(color: widget.config.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: Colors.redAccent,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              widget.config.errorTitle,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: widget.config.textColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.errorMessage ?? 'Terjadi masalah saat memuat data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: widget.config.subtitleColor,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.config.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  String _formatTanggal(DateTime tanggal) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal.toLocal());
  }

  String _formatTanggalWaktu(DateTime tanggal) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tanggal.toLocal());
  }

  String _getInitial(String nama) {
    if (nama.trim().isEmpty) {
      return '?';
    }

    return nama.trim().substring(0, 1).toUpperCase();
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'absensi_filter.dart';
import 'absensi_filter_sheet.dart';
import 'absensi_page_config.dart';
import 'absensi_pertemuan_card.dart';
import 'absensi_pertemuan_item.dart';

class AbsensiPageTemplate extends StatefulWidget {
  final AbsensiPageConfig config;

  final List<AbsensiPertemuanItem> items;

  final bool isLoading;

  final String? errorMessage;

  final Future<void> Function()? onRefresh;

  final VoidCallback? onAdd;

  final VoidCallback? onRetry;

  final List<Widget>? appBarActions;

  /// Widget tambahan untuk filter khusus modul.
  ///
  /// Contoh:
  /// Filter Tarjamah memiliki metode pembelajaran.
  final Widget? filterSheetBuilder;

  /// Widget tambahan di bawah filter.
  final Widget? additionalHeader;

  /// Widget tambahan di bagian filter.
  final Widget? additionalFilter;

  final int totalSantri;

  const AbsensiPageTemplate({
    super.key,
    required this.config,
    required this.items,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.onAdd,
    this.onRetry,
    this.appBarActions,
    this.filterSheetBuilder,
    this.additionalHeader,
    this.additionalFilter,
    this.totalSantri = 0,
  });

  @override
  State<AbsensiPageTemplate> createState() => _AbsensiPageTemplateState();
}

class _AbsensiPageTemplateState extends State<AbsensiPageTemplate> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  String? _expandedPertemuanId;

  AbsensiFilterState _filter = const AbsensiFilterState();

  bool get _hasActiveFilter {
    return _filter.hasActiveFilter;
  }

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
  // SEARCH
  // ============================================================

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = query;
      _expandedPertemuanId = null;
    });
  }

  void _clearFilter() {
    setState(() {
      _filter = const AbsensiFilterState();

      _expandedPertemuanId = null;
    });
  }

  // ============================================================
  // FILTER DATA (LOGIKA AWAL)
  // ============================================================

  List<AbsensiPertemuanItem> get filteredItems {
    final query = _searchQuery.trim().toLowerCase();

    return widget.items.where((item) {
      // ========================================================
      // SEARCH
      // ========================================================

      final tanggal = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(item.tanggal).toLowerCase();

      final hari = DateFormat(
        'EEEE',
        'id_ID',
      ).format(item.tanggal).toLowerCase();

      final pengajar = item.pengajar.toLowerCase();

      final materi = (item.materi ?? '').toLowerCase();

      final pbm = item.pbm.toLowerCase();

      final pengganti = (item.pengganti ?? '').toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          tanggal.contains(query) ||
          hari.contains(query) ||
          pengajar.contains(query) ||
          materi.contains(query) ||
          pbm.contains(query) ||
          pengganti.contains(query);

      // ========================================================
      // TANGGAL
      // ========================================================

      bool matchesDate = true;

      if (_filter.dateRange != null) {
        final itemDate = DateUtils.dateOnly(item.tanggal);

        final startDate = DateUtils.dateOnly(_filter.dateRange!.start);

        final endDate = DateUtils.dateOnly(_filter.dateRange!.end);

        matchesDate =
            !itemDate.isBefore(startDate) && !itemDate.isAfter(endDate);
      }

      // ========================================================
      // PENGAJAR
      // ========================================================

      final matchesPengajar =
          _filter.pengajarId == null || item.pengajarId == _filter.pengajarId;

      // ========================================================
      // PBM
      // ========================================================

      final matchesPbm =
          _filter.pbm == null ||
          item.pbm.toLowerCase() == _filter.pbm!.value.toLowerCase();

      return matchesSearch && matchesDate && matchesPengajar && matchesPbm;
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

      floatingActionButton: widget.config.showAddButton && widget.onAdd != null
          ? FloatingActionButton.extended(
              onPressed: widget.onAdd,
              backgroundColor: widget.config.primaryColor,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: Icon(widget.config.addButtonIcon, size: 22),
              label: Text(
                widget.config.addButtonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            )
          : null,

      body: _buildBody(),
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
      centerTitle: false,
      title: Text(
        widget.config.title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 19,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        if (widget.appBarActions != null) ...widget.appBarActions!,

        if (widget.onRefresh != null)
          IconButton(
            tooltip: 'Refresh',
            onPressed: widget.isLoading ? null : widget.onRefresh,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 23),
          ),

        const SizedBox(width: 4),
      ],
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

    if (widget.errorMessage != null && widget.items.isEmpty) {
      return _buildErrorState();
    }

    final data = filteredItems;

    return RefreshIndicator(
      onRefresh:
          widget.onRefresh ??
          () async {
            await Future<void>.value();
          },
      color: widget.config.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: const SizedBox(height: 10)),
          SliverToBoxAdapter(child: _buildHeader()),

          if (widget.additionalHeader != null)
            SliverToBoxAdapter(child: widget.additionalHeader!),

          SliverToBoxAdapter(child: _buildSearch()),

          if (widget.additionalFilter != null)
            SliverToBoxAdapter(child: widget.additionalFilter!),

          SliverToBoxAdapter(child: _buildFilterSection()),

          if (_hasActiveFilter)
            SliverToBoxAdapter(child: _buildActiveFilterInfo()),

          if (data.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = data[index];

                  final isExpanded = _expandedPertemuanId == item.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AbsensiPertemuanCard(
                      item: item,
                      isExpanded: isExpanded,
                      config: widget.config,
                      onToggle: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedPertemuanId = null;
                          } else {
                            _expandedPertemuanId = item.id;
                          }
                        });
                      },
                    ),
                  );
                }, childCount: data.length),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER (REKAP PERTEMUAN & SANTRI BERDAMPINGAN)
  // ============================================================

  Widget _buildHeader() {
    final filteredCount = filteredItems.length;

    final hasSearch = _searchQuery.isNotEmpty;

    final hasCondition = hasSearch || _hasActiveFilter;

    final displayPertemuan = hasCondition
        ? '$filteredCount/${widget.items.length}'
        : '${widget.items.length}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.config.primaryColor,
            widget.config.primaryColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: widget.config.primaryColor.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.config.subtitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            hasCondition
                ? 'Menampilkan $filteredCount dari ${widget.items.length} pertemuan.'
                : 'Kelola agenda dan presensi keikutsertaan santri.',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.88),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  icon: Icons.event_note_rounded,
                  value: displayPertemuan,
                  label: hasCondition
                      ? 'Pertemuan (Filter)'
                      : 'Total Pertemuan',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeaderStat(
                  icon: Icons.people_alt_rounded,
                  value: '${widget.totalSantri}',
                  label: 'Total Santri',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          style: TextStyle(fontSize: 14, color: widget.config.textColor),
          decoration: InputDecoration(
            hintText: widget.config.searchHint,
            hintStyle: TextStyle(
              color: widget.config.subtitleColor,
              fontSize: 13.5,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: widget.config.primaryColor,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: widget.config.subtitleColor,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: widget.config.primaryColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER SECTION (RINGKAS TANPA TEKS STAT)
  // ============================================================

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showFilterSheet,
              icon: Icon(
                _hasActiveFilter
                    ? Icons.filter_alt_rounded
                    : Icons.tune_rounded,
                size: 18,
              ),
              label: Text(
                _hasActiveFilter ? 'Filter Aktif' : 'Filter',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _hasActiveFilter
                    ? widget.config.primaryColor
                    : widget.config.textColor,
                backgroundColor: _hasActiveFilter
                    ? widget.config.primaryLight
                    : Colors.white,
                side: BorderSide(
                  color: _hasActiveFilter
                      ? widget.config.primaryColor
                      : Colors.grey.shade200,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          if (_hasActiveFilter) ...[
            const SizedBox(width: 8),

            IconButton(
              onPressed: _clearFilter,
              tooltip: 'Reset filter',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.filter_alt_off_rounded,
                size: 20,
                color: Colors.redAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: widget.config.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.config.emptyIcon,
                size: 32,
                color: widget.config.primaryColor,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              hasSearch
                  ? widget.config.filteredEmptyTitle
                  : widget.config.emptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: widget.config.textColor,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              hasSearch
                  ? widget.config.filteredEmptyDescription
                  : widget.config.emptyDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: widget.config.subtitleColor,
                height: 1.4,
              ),
            ),

            if (hasSearch) ...[
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _expandedPertemuanId = null;
                  });
                },
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
      ),
    );
  }

  // ============================================================
  // ERROR
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
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: widget.config.textColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.errorMessage ?? 'Terjadi masalah pada jaringan.',
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

  Widget _buildActiveFilterInfo() {
    final chips = <Widget>[];

    if (_filter.dateRange != null) {
      chips.add(
        _buildActiveChip(
          icon: Icons.date_range_rounded,
          label: _formatDateRange(_filter.dateRange!),
        ),
      );
    }

    if (_filter.pengajarId != null) {
      final pengajar = widget.items
          .where((item) => item.pengajarId == _filter.pengajarId)
          .map((item) => item.pengajar)
          .firstWhere(
            (name) => name.trim().isNotEmpty,
            orElse: () => 'Pengajar',
          );

      chips.add(
        _buildActiveChip(icon: Icons.person_outline_rounded, label: pengajar),
      );
    }

    if (_filter.pbm != null) {
      chips.add(
        _buildActiveChip(icon: Icons.school_rounded, label: _filter.pbm!.label),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }

  Widget _buildActiveChip({required IconData icon, required String label}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.config.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.config.primaryColor.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: widget.config.primaryColor),

          const SizedBox(width: 5),

          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.config.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return AbsensiFilterSheet(
          initialFilter: _filter,
          items: widget.items,
          config: widget.config,
          onApply: (newFilter) {
            setState(() {
              _filter = newFilter;

              // Tutup card yang sedang terbuka
              // supaya setelah filter diterapkan
              // tampilan kembali rapi.
              _expandedPertemuanId = null;
            });
          },
        );
      },
    );
  }

  String _formatDateRange(DateTimeRange range) {
    final start = DateFormat('dd MMM yyyy', 'id_ID').format(range.start);

    final end = DateFormat('dd MMM yyyy', 'id_ID').format(range.end);

    if (DateUtils.isSameDay(range.start, range.end)) {
      return start;
    }

    return '$start - $end';
  }
}

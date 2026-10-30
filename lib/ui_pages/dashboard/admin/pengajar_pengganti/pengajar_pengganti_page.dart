import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/pengajar_pengganti/pengajar_pengganti_model.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';
import 'package:ptl_mobile/state_management/pengajar_pengganti_provider.dart';

class PengajarPenggantiPage extends StatefulWidget {
  const PengajarPenggantiPage({super.key});

  @override
  State<PengajarPenggantiPage> createState() => _PengajarPenggantiPageState();
}

class _PengajarPenggantiPageState extends State<PengajarPenggantiPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  /// 0 = Aktif
  /// 1 = Nonaktif
  /// 2 = Semua
  int _statusFilter = 0;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primaryColor = Color(0xFF0D8B8B);
  static const Color _primaryDark = Color(0xFF075B5B);
  static const Color _primaryLight = Color(0xFFE7F5F5);

  static const Color _backgroundColor = Color(0xFFF6F8F8);
  static const Color _surfaceColor = Colors.white;

  static const Color _textPrimary = Color(0xFF263238);
  static const Color _textSecondary = Color(0xFF607D8B);

  static const Color _borderColor = Color(0xFFE4E9EA);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    _loadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    final provider = context.read<PengajarPenggantiProvider>();

    await provider.loadAll(hanyaAktif: false);
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (_searchQuery == query) return;

    setState(() {
      _searchQuery = query;
    });
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<PengajarPenggantiModel> _getFilteredItems(
    PengajarPenggantiProvider provider,
  ) {
    Iterable<PengajarPenggantiModel> result = provider.items;

    if (_statusFilter == 0) {
      result = result.where((item) => item.aktif);
    } else if (_statusFilter == 1) {
      result = result.where((item) => !item.aktif);
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((item) {
        final nama = item.nama.toLowerCase();
        final noHp = (item.noHp ?? '').toLowerCase();

        return nama.contains(_searchQuery) || noHp.contains(_searchQuery);
      });
    }

    return result.toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _backgroundColor,

        // ======================================================
        // APP BAR
        // ======================================================
        appBar: AppBar(
          title: const Text(
            'Pengajar Pengganti',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _primaryColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        // ======================================================
        // FAB
        // ======================================================
        floatingActionButton: FloatingActionButton(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          onPressed: () => _showForm(),
          elevation: 3,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),

        // ======================================================
        // BODY
        // ======================================================
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;

            return Column(
              children: [
                // ==================================================
                // HEADER
                //
                // TIDAK berada di dalam RefreshIndicator.
                // ==================================================
                Consumer<PengajarPenggantiProvider>(
                  builder: (context, provider, _) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 32 : 16,
                        16,
                        isDesktop ? 32 : 16,
                        0,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 1050 : double.infinity,
                          ),
                          child: _buildHeaderSummary(provider, isDesktop),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ==================================================
                // SEARCH + FILTER
                //
                // TIDAK berada di dalam RefreshIndicator.
                // ==================================================
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 1050 : double.infinity,
                      ),
                      child: _buildSearchAndFilter(isDesktop),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // LIST AREA
                //
                // HANYA BAGIAN INI YANG DI-REFRESH.
                // ==================================================
                Expanded(
                  child: Consumer<PengajarPenggantiProvider>(
                    builder: (context, provider, _) {
                      final items = _getFilteredItems(provider);

                      return RefreshIndicator(
                        color: _primaryColor,
                        backgroundColor: Colors.white,
                        strokeWidth: 2.4,
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            isDesktop ? 32 : 16,
                            4,
                            isDesktop ? 32 : 16,
                            100,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isDesktop ? 1050 : double.infinity,
                              ),
                              child: _buildContent(provider, items),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(
    PengajarPenggantiProvider provider,
    List<PengajarPenggantiModel> items,
  ) {
    final initialLoading = provider.isLoading && !provider.hasData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.errorMessage != null) _buildError(provider.errorMessage!),

        if (initialLoading)
          _buildInitialLoading()
        else if (items.isEmpty)
          _buildEmptyState()
        else
          _buildList(items),
      ],
    );
  }

  // ============================================================
  // HEADER SUMMARY
  // ============================================================

  Widget _buildHeaderSummary(
    PengajarPenggantiProvider provider,
    bool isDesktop,
  ) {
    final total = provider.items.length;

    final aktif = provider.items.where((item) => item.aktif).length;

    final nonaktif = total - aktif;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, Color(0xFF00A896)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(.14),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                _buildHeaderIcon(),

                const SizedBox(width: 14),

                Expanded(child: _buildHeaderText()),

                const SizedBox(width: 18),

                _buildMiniStatistic(
                  label: 'Total',
                  value: total.toString(),
                  icon: Icons.people_alt_outlined,
                ),

                const SizedBox(width: 8),

                _buildMiniStatistic(
                  label: 'Aktif',
                  value: aktif.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  active: true,
                ),

                const SizedBox(width: 8),

                _buildMiniStatistic(
                  label: 'Nonaktif',
                  value: nonaktif.toString(),
                  icon: Icons.pause_circle_outline_rounded,
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    _buildHeaderIcon(),

                    const SizedBox(width: 13),

                    Expanded(child: _buildHeaderText()),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatistic(
                        label: 'Total',
                        value: total.toString(),
                        icon: Icons.people_alt_outlined,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: _buildMiniStatistic(
                        label: 'Aktif',
                        value: aktif.toString(),
                        icon: Icons.check_circle_outline_rounded,
                        active: true,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: _buildMiniStatistic(
                        label: 'Nonaktif',
                        value: nonaktif.toString(),
                        icon: Icons.pause_circle_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(Icons.badge_outlined, color: _primaryColor, size: 25),
    );
  }

  Widget _buildHeaderText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelola Pengajar Pengganti',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Kelola daftar pengajar yang dapat ditugaskan sebagai pengganti.',
          style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildMiniStatistic({
    required String label,
    required String value,
    required IconData icon,
    bool active = false,
  }) {
    final color = active ? _primaryColor : _textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH + FILTER
  // ============================================================

  Widget _buildSearchAndFilter(bool isDesktop) {
    final searchField = Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.018),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: _textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari nama atau nomor HP...',
          hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _textSecondary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: _searchController.clear,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _textSecondary,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );

    final filter = _buildStatusFilter();

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: searchField),
          const SizedBox(width: 10),
          filter,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [searchField, const SizedBox(height: 10), filter],
    );
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterOption(
            index: 0,
            label: 'Aktif',
            icon: Icons.check_circle_outline_rounded,
          ),
          _buildFilterOption(
            index: 1,
            label: 'Nonaktif',
            icon: Icons.pause_circle_outline_rounded,
          ),
          _buildFilterOption(
            index: 2,
            label: 'Semua',
            icon: Icons.list_alt_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final selected = _statusFilter == index;

    return GestureDetector(
      onTap: () {
        if (selected) return;

        setState(() {
          _statusFilter = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? _primaryColor : _textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _primaryDark : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INITIAL LOADING
  // ============================================================

  Widget _buildInitialLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: const Column(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Memuat data pengajar...',
            style: TextStyle(fontSize: 12, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIST
  // ============================================================

  Widget _buildList(List<PengajarPenggantiModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Daftar Pengajar',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${items.length}',
                style: const TextStyle(
                  color: _primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 11),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _buildPengajarCard(items[index]);
          },
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildPengajarCard(PengajarPenggantiModel item) {
    final initial = item.nama.trim().isNotEmpty
        ? item.nama.trim()[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: item.aktif ? _borderColor : const Color(0xFFE8ECEE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.018),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => _showForm(item: item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                _buildAvatar(initial: initial, aktif: item.aktif),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.noHp?.trim().isNotEmpty == true
                                  ? item.noHp!
                                  : 'Nomor HP belum diisi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _buildStatusBadge(item.aktif),

                const SizedBox(width: 2),

                IconButton(
                  tooltip: 'Opsi',
                  onPressed: () => _showActionSheet(item),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 21,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar({required String initial, required bool aktif}) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        gradient: aktif
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE6F7F7), Color(0xFFD3EEEE)],
              )
            : const LinearGradient(
                colors: [Color(0xFFF2F4F5), Color(0xFFE8ECEE)],
              ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: aktif ? _primaryDark : _textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(bool aktif) {
    final color = aktif ? _primaryColor : _textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: aktif ? _primaryLight : const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            aktif ? 'Aktif' : 'Nonaktif',
            style: TextStyle(
              color: aktif ? _primaryDark : _textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION SHEET
  // ============================================================

  Future<void> _showActionSheet(PengajarPenggantiModel item) async {
    final action = await showModalBottomSheet<_PengajarAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      builder: (_) {
        return _PengajarActionSheet(item: item);
      },
    );

    if (!mounted || action == null) {
      return;
    }

    // ----------------------------------------------------------
    // PENTING:
    // Modal action sheet sudah benar-benar selesai ditutup
    // sebelum membuka form/dialog berikutnya.
    //
    // Ini membantu menghindari _dependents.isEmpty.
    // ----------------------------------------------------------

    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    switch (action) {
      case _PengajarAction.edit:
        await _showForm(item: item);
        break;

      case _PengajarAction.toggle:
        await _toggleStatus(item);
        break;

      case _PengajarAction.delete:
        await _confirmDelete(item);
        break;
    }
  }

  // ============================================================
  // FORM
  // ============================================================

  Future<void> _showForm({PengajarPenggantiModel? item}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) {
        return _PengajarFormSheet(item: item);
      },
    );

    if (!mounted || result != true) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(
        item == null
            ? 'Pengajar baru berhasil ditambahkan.'
            : 'Data pengajar berhasil diperbarui.',
      ),
    );
  }

  // ============================================================
  // TOGGLE STATUS
  // ============================================================

  Future<void> _toggleStatus(PengajarPenggantiModel item) async {
    final provider = context.read<PengajarPenggantiProvider>();

    final loadingProvider = context.read<LoadingProvider>();

    final success = await provider.setAktif(
      id: item.id,
      aktif: !item.aktif,
      loadingProvider: loadingProvider,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(
        success
            ? item.aktif
                  ? '${item.nama} dinonaktifkan.'
                  : '${item.nama} diaktifkan.'
            : provider.errorMessage ?? 'Gagal mengubah status pengajar.',
        error: !success,
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _confirmDelete(PengajarPenggantiModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: _surfaceColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Hapus Pengajar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Data "${item.nama}" akan dihapus '
                  'secara permanen. Pastikan data ini '
                  'tidak sedang digunakan oleh pertemuan '
                  'atau absensi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textSecondary,
                          side: const BorderSide(color: _borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<PengajarPenggantiProvider>();

    final loadingProvider = context.read<LoadingProvider>();

    final success = await provider.delete(
      item.id,
      loadingProvider: loadingProvider,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(
        success
            ? '${item.nama} berhasil dihapus.'
            : provider.errorMessage ?? 'Gagal menghapus data.',
        error: !success,
      ),
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  SnackBar _buildSnackBar(String message, {bool error = false}) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: error ? Colors.redAccent : _primaryDark,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2CACA)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE6E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9B3030),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),

          IconButton(
            onPressed: () {
              context.read<PengajarPenggantiProvider>().clearError();
            },
            icon: const Icon(
              Icons.close_rounded,
              size: 17,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty;

    String title;

    if (hasSearch) {
      title = 'Data Tidak Ditemukan';
    } else if (_statusFilter == 0) {
      title = 'Belum Ada Pengajar Aktif';
    } else if (_statusFilter == 1) {
      title = 'Belum Ada Pengajar Nonaktif';
    } else {
      title = 'Belum Ada Data Pengajar';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 42),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.person_search_outlined,
              size: 31,
              color: _primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            hasSearch
                ? 'Tidak ada data yang sesuai dengan '
                      '"$_searchQuery".'
                : 'Belum ada data yang sesuai dengan '
                      'filter saat ini.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),

          if (!hasSearch && _statusFilter != 1) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text(
                'Tambah Pengajar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: const BorderSide(color: _primaryColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
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
}

// ============================================================================
// ACTION ENUM
// ============================================================================

enum _PengajarAction { edit, toggle, delete }

// ============================================================================
// ACTION SHEET
// ============================================================================

class _PengajarActionSheet extends StatelessWidget {
  final PengajarPenggantiModel item;

  const _PengajarActionSheet({required this.item});

  static const Color primary = Color(0xFF0D8B8B);
  static const Color primaryLight = Color(0xFFE7F5F5);

  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF607D8B);
  static const Color border = Color(0xFFE4E9EA);

  @override
  Widget build(BuildContext context) {
    final initial = item.nama.trim().isNotEmpty
        ? item.nama.trim()[0].toUpperCase()
        : '?';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HANDLE
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 18),

              // HEADER
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryLight,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          item.aktif ? 'Pengajar aktif' : 'Pengajar nonaktif',
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // EDIT
              _buildAction(
                icon: Icons.edit_outlined,
                title: 'Edit Data',
                subtitle: 'Perbarui informasi pengajar',
                color: primary,
                onTap: () {
                  Navigator.pop(context, _PengajarAction.edit);
                },
              ),

              const SizedBox(height: 8),

              // TOGGLE
              _buildAction(
                icon: item.aktif
                    ? Icons.pause_circle_outline_rounded
                    : Icons.check_circle_outline_rounded,
                title: item.aktif ? 'Nonaktifkan' : 'Aktifkan',
                subtitle: item.aktif
                    ? 'Sembunyikan dari pilihan pengajar'
                    : 'Aktifkan kembali pengajar',
                color: item.aktif ? const Color(0xFF64748B) : primary,
                onTap: () {
                  Navigator.pop(context, _PengajarAction.toggle);
                },
              ),

              const SizedBox(height: 8),

              // DELETE
              _buildAction(
                icon: Icons.delete_outline_rounded,
                title: 'Hapus Data',
                subtitle: 'Hapus pengajar secara permanen',
                color: Colors.redAccent,
                background: const Color(0xFFFFF5F5),
                onTap: () {
                  Navigator.pop(context, _PengajarAction.delete);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Color? background,
  }) {
    return Material(
      color: background ?? const Color(0xFFF8FAFA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color == Colors.redAccent
                            ? Colors.redAccent
                            : textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: color.withOpacity(.55),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FORM BOTTOM SHEET
// ============================================================================

class _PengajarFormSheet extends StatefulWidget {
  final PengajarPenggantiModel? item;

  const _PengajarFormSheet({this.item});

  @override
  State<_PengajarFormSheet> createState() => _PengajarFormSheetState();
}

class _PengajarFormSheetState extends State<_PengajarFormSheet> {
  late final TextEditingController _namaController;
  late final TextEditingController _noHpController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _aktif = true;
  bool _saving = false;

  static const Color primary = Color(0xFF0D8B8B);
  static const Color primaryLight = Color(0xFFE7F5F5);

  static const Color background = Color(0xFFF6F8F8);

  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF607D8B);

  static const Color border = Color(0xFFE4E9EA);

  bool get isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();

    _namaController = TextEditingController(text: widget.item?.nama ?? '');

    _noHpController = TextEditingController(text: widget.item?.noHp ?? '');

    _aktif = widget.item?.aktif ?? true;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final provider = context.read<PengajarPenggantiProvider>();

    final loadingProvider = context.read<LoadingProvider>();

    bool success;

    if (isEdit) {
      success = await provider.update(
        id: widget.item!.id,
        nama: _namaController.text.trim(),
        noHp: _noHpController.text.trim(),
        aktif: _aktif,
        loadingProvider: loadingProvider,
      );
    } else {
      success = await provider.create(
        nama: _namaController.text.trim(),
        noHp: _noHpController.text.trim(),
        aktif: _aktif,
        loadingProvider: loadingProvider,
      );
    }

    if (!mounted) return;

    if (success) {
      // Hanya form ini yang ditutup.
      // Tidak menggunakan context parent.
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
    });

    final error = provider.errorMessage ?? 'Gagal menyimpan data pengajar.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: bottomInset + 18,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHandle(),

                  const SizedBox(height: 17),

                  _buildFormHeader(),

                  const SizedBox(height: 22),

                  _buildFieldLabel('Nama Pengajar', required: true),

                  const SizedBox(height: 7),

                  TextFormField(
                    controller: _namaController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: textPrimary, fontSize: 14),
                    decoration: _inputDecoration(
                      hint: 'Masukkan nama lengkap',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama pengajar wajib diisi';
                      }

                      if (value.trim().length < 3) {
                        return 'Nama minimal 3 karakter';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildFieldLabel('Nomor WhatsApp / HP'),

                  const SizedBox(height: 7),

                  TextFormField(
                    controller: _noHpController,
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: textPrimary, fontSize: 14),
                    decoration: _inputDecoration(
                      hint: 'Contoh: 08123456789',
                      icon: Icons.phone_outlined,
                    ),
                  ),

                  const SizedBox(height: 17),

                  _buildStatusCard(),

                  const SizedBox(height: 22),

                  _buildButtons(),
                ],
              ),
            ),
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
          color: border,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // ============================================================
  // FORM HEADER
  // ============================================================

  Widget _buildFormHeader() {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isEdit ? Icons.edit_outlined : Icons.person_add_alt_1_outlined,
            color: primary,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Pengajar' : 'Tambah Pengajar',
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                isEdit
                    ? 'Perbarui informasi pengajar pengganti.'
                    : 'Tambahkan pengajar baru ke dalam daftar.',
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FIELD LABEL
  // ============================================================

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ]
            : null,
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: SwitchListTile(
        value: _aktif,
        onChanged: _saving
            ? null
            : (value) {
                setState(() {
                  _aktif = value;
                });
              },
        activeColor: primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        title: const Text(
          'Status Pengajar',
          style: TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          _aktif
              ? 'Pengajar dapat dipilih untuk penugasan.'
              : 'Pengajar tidak muncul pada pilihan aktif.',
          style: const TextStyle(
            color: textSecondary,
            fontSize: 10.5,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: textSecondary,
              side: const BorderSide(color: border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primary.withOpacity(.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 17),
                      const SizedBox(width: 6),
                      Text(
                        isEdit ? 'Simpan Perubahan' : 'Simpan Data',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: textSecondary, fontSize: 12),
      prefixIcon: Icon(icon, color: textSecondary, size: 19),
      filled: true,
      fillColor: background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pembayaran/tagihan_model.dart';
import '../../state_management/pembayaran/tagihan_provider.dart';
import 'tagihan_detail_page.dart';

class TagihanPage extends StatefulWidget {
  const TagihanPage({super.key});

  @override
  State<TagihanPage> createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  static const Color _primary = Color(0xFF0D8B8B);
  static const Color _background = Color(0xFFF8FAFA);

  final TextEditingController _searchController = TextEditingController();

  String _filter = 'semua';
  DateTime? _periodeMulai;
  DateTime? _periodeSelesai;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TagihanProvider>().loadTagihan();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TagihanModel> _filterItems(List<TagihanModel> items) {
    final keyword = _searchController.text.trim().toLowerCase();

    return items.where((item) {
      // Filter status.
      if (_filter != 'semua' && item.status != _filter) {
        return false;
      }

      // Filter pencarian.
      if (keyword.isNotEmpty) {
        final nomor = item.nomorTagihan.toLowerCase();
        final santri = (item.namaSantri ?? '').toLowerCase();
        final program = (item.namaProgram ?? '').toLowerCase();
        final lembaga = (item.namaLembaga ?? '').toLowerCase();

        if (!nomor.contains(keyword) &&
            !santri.contains(keyword) &&
            !program.contains(keyword) &&
            !lembaga.contains(keyword)) {
          return false;
        }
      }

      // Filter periode berdasarkan tanggal tagihan.
      final tanggal = DateUtils.dateOnly(item.tanggalTagihan);

      if (_periodeMulai != null &&
          tanggal.isBefore(DateUtils.dateOnly(_periodeMulai!))) {
        return false;
      }

      if (_periodeSelesai != null &&
          tanggal.isAfter(DateUtils.dateOnly(_periodeSelesai!))) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _pilihTanggal({required bool tanggalMulai}) async {
    final sekarang = DateTime.now();

    final awal = _periodeMulai;
    final akhir = _periodeSelesai;

    final tanggalAwal = tanggalMulai ? awal : (akhir ?? awal ?? sekarang);

    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalAwal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: tanggalMulai ? 'Pilih tanggal mulai' : 'Pilih tanggal akhir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (!mounted || picked == null) return;

    setState(() {
      if (tanggalMulai) {
        _periodeMulai = picked;

        if (_periodeSelesai != null && _periodeSelesai!.isBefore(picked)) {
          _periodeSelesai = picked;
        }
      } else {
        _periodeSelesai = picked;

        if (_periodeMulai != null && _periodeMulai!.isAfter(picked)) {
          _periodeMulai = picked;
        }
      }
    });
  }

  void _resetFilter() {
    setState(() {
      _filter = 'semua';
      _periodeMulai = null;
      _periodeSelesai = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Tagihan Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => context.read<TagihanProvider>().loadTagihan(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Consumer<TagihanProvider>(
        builder: (context, provider, _) {
          final semuaTagihan = provider.items;
          final items = _filterItems(semuaTagihan);

          final belumLunas = semuaTagihan.where(
            (e) => e.status != 'lunas' && e.status != 'dibatalkan',
          );

          final totalBelumLunas = belumLunas.fold<double>(
            0,
            (sum, item) => sum + item.total,
          );

          if (provider.isLoading && semuaTagihan.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (provider.errorMessage != null && semuaTagihan.isEmpty) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: provider.loadTagihan,
            );
          }

          return RefreshIndicator(
            color: _primary,
            onRefresh: provider.loadTagihan,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _SummaryCard(
                  totalTagihan: totalBelumLunas,
                  jumlahTagihan: belumLunas.length,
                ),
                const SizedBox(height: 22),

                const Text(
                  'Daftar tagihan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 12),

                // Pencarian.
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari nomor, santri, atau program...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF90A4AE),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _primary,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE0E7E7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE0E7E7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _primary, width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Filter status.
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        selected: _filter == 'semua',
                        onTap: () => setState(() => _filter = 'semua'),
                      ),
                      _FilterChip(
                        label: 'Belum bayar',
                        selected: _filter == 'belum_bayar',
                        onTap: () => setState(() => _filter = 'belum_bayar'),
                      ),
                      _FilterChip(
                        label: 'Menunggu',
                        selected: _filter == 'menunggu_verifikasi',
                        onTap: () =>
                            setState(() => _filter = 'menunggu_verifikasi'),
                      ),
                      _FilterChip(
                        label: 'Lunas',
                        selected: _filter == 'lunas',
                        onTap: () => setState(() => _filter = 'lunas'),
                      ),
                      _FilterChip(
                        label: 'Ditolak',
                        selected: _filter == 'ditolak',
                        onTap: () => setState(() => _filter = 'ditolak'),
                      ),
                      _FilterChip(
                        label: 'Dibatalkan',
                        selected: _filter == 'dibatalkan',
                        onTap: () => setState(() => _filter = 'dibatalkan'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Filter periode.
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8EEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: _primary,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Periode tanggal tagihan',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF263238),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DateFilterButton(
                              label: 'Dari',
                              tanggal: _periodeMulai,
                              onTap: () => _pilihTanggal(tanggalMulai: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DateFilterButton(
                              label: 'Sampai',
                              tanggal: _periodeSelesai,
                              onTap: () => _pilihTanggal(tanggalMulai: false),
                            ),
                          ),
                        ],
                      ),
                      if (_periodeMulai != null ||
                          _periodeSelesai != null ||
                          _filter != 'semua' ||
                          _searchController.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _resetFilter,
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text('Reset filter'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Hasil pencarian',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF607D8B),
                        ),
                      ),
                    ),
                    Text(
                      '${items.length} tagihan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (provider.errorMessage != null) ...[
                  _InlineError(message: provider.errorMessage!),
                  const SizedBox(height: 12),
                ],

                if (items.isEmpty)
                  const _EmptyView()
                else
                  ...items.map(
                    (tagihan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TagihanCard(
                        tagihan: tagihan,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TagihanDetailPage(tagihan: tagihan),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalTagihan;
  final int jumlahTagihan;

  const _SummaryCard({required this.totalTagihan, required this.jumlahTagihan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D8B8B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'Total belum lunas',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatRupiah(totalTagihan),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$jumlahTagihan tagihan perlu diperhatikan',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TagihanCard extends StatelessWidget {
  final TagihanModel tagihan;
  final VoidCallback onTap;

  const _TagihanCard({required this.tagihan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(tagihan.status);

    final namaSantri = tagihan.namaSantri?.trim();
    final namaProgram = tagihan.namaProgram?.trim();
    final namaLembaga = tagihan.namaLembaga?.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF0D8B8B),
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      tagihan.nomorTagihan,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: status.label,
                    color: status.color,
                    background: status.background,
                  ),
                ],
              ),

              if (namaSantri != null && namaSantri.isNotEmpty) ...[
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  text: namaSantri,
                  bold: true,
                ),
              ],

              if (namaProgram != null && namaProgram.isNotEmpty) ...[
                const SizedBox(height: 7),
                _InfoRow(icon: Icons.menu_book_outlined, text: namaProgram),
              ],

              if (namaLembaga != null && namaLembaga.isNotEmpty) ...[
                const SizedBox(height: 7),
                _InfoRow(icon: Icons.apartment_rounded, text: namaLembaga),
              ],

              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                text:
                    '${formatTanggal(tagihan.periodeMulai)} - '
                    '${formatTanggal(tagihan.periodeSelesai)}',
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFEDF1F1)),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total tagihan',
                          style: TextStyle(
                            color: Color(0xFF78909C),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          formatRupiah(tagihan.total),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF263238),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF90A4AE),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;

  const _InfoRow({required this.icon, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF78909C)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: const Color(0xFF607D8B),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  final String label;
  final DateTime? tanggal;
  final VoidCallback onTap;

  const _DateFilterButton({
    required this.label,
    required this.tanggal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF263238),
        side: const BorderSide(color: Color(0xFFE0E7E7)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: Color(0xFF0D8B8B),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF78909C),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tanggal == null ? 'Pilih tanggal' : formatTanggal(tanggal!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: const Color(0xFFDDF3F1),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF0D8B8B) : const Color(0xFFE0E7E7),
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? const Color(0xFF0D8B8B) : const Color(0xFF607D8B),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada tagihan ditemukan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Coba ubah kata kunci atau filter yang digunakan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF78909C)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat tagihan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Pembaruan gagal: $message',
      style: const TextStyle(color: Colors.red, fontSize: 12),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color color;
  final Color background;

  const _StatusStyle(this.label, this.color, this.background);
}

_StatusStyle _statusStyle(String status) {
  switch (status) {
    case 'menunggu_verifikasi':
      return const _StatusStyle(
        'Menunggu',
        Color(0xFF9A6700),
        Color(0xFFFFF4CC),
      );
    case 'lunas':
      return const _StatusStyle('Lunas', Color(0xFF18794E), Color(0xFFE0F5E9));
    case 'ditolak':
      return const _StatusStyle(
        'Ditolak',
        Color(0xFFB42318),
        Color(0xFFFEE4E2),
      );
    case 'dibatalkan':
      return const _StatusStyle(
        'Dibatalkan',
        Color(0xFF667085),
        Color(0xFFF2F4F7),
      );
    default:
      return const _StatusStyle(
        'Belum bayar',
        Color(0xFF0D8B8B),
        Color(0xFFDDF3F1),
      );
  }
}

String formatRupiah(num nominal) {
  final angka = nominal.round().toString();
  final hasil = StringBuffer();

  for (var i = 0; i < angka.length; i++) {
    hasil.write(angka[i]);

    final sisa = angka.length - i - 1;
    if (sisa > 0 && sisa % 3 == 0) {
      hasil.write('.');
    }
  }

  return 'Rp$hasil';
}

String formatTanggal(DateTime tanggal) {
  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
}

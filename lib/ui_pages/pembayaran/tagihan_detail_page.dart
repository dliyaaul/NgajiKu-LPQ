import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptl_mobile/ui_pages/pembayaran/pengajuan_pembayaran_page.dart';

import '../../models/pembayaran/tagihan_model.dart';
import '../../state_management/pembayaran/tagihan_provider.dart';
import '../../utils/pembayaran_format.dart';

class TagihanDetailPage extends StatefulWidget {
  final TagihanModel tagihan;

  const TagihanDetailPage({super.key, required this.tagihan});

  @override
  State<TagihanDetailPage> createState() => _TagihanDetailPageState();
}

class _TagihanDetailPageState extends State<TagihanDetailPage> {
  static const Color _primary = Color(0xFF0D8B8B);

  late TagihanModel _tagihan;

  @override
  void initState() {
    super.initState();
    _tagihan = widget.tagihan;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final provider = context.read<TagihanProvider>();
      final result = await provider.loadDetail(widget.tagihan.id);

      if (!mounted) return;

      if (result != null) {
        setState(() => _tagihan = result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        title: const Text(
          'Detail Tagihan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFF8FAFA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<TagihanProvider>(
        builder: (context, provider, _) {
          final status = _detailStatus(_tagihan.status);

          return RefreshIndicator(
            color: _primary,
            onRefresh: () async {
              final result = await provider.loadDetail(widget.tagihan.id);
              if (!mounted) return;
              if (result != null) {
                setState(() => _tagihan = result);
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8EEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nomor tagihan',
                        style: TextStyle(
                          color: Color(0xFF78909C),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _tagihan.nomorTagihan,
                        style: const TextStyle(
                          color: Color(0xFF263238),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: status.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.label,
                          style: TextStyle(
                            color: status.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _InfoRow(
                        label: 'Tanggal tagihan',
                        value: formatTanggal(_tagihan.tanggalTagihan),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Periode mulai',
                        value: formatTanggal(_tagihan.periodeMulai),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Periode selesai',
                        value: formatTanggal(_tagihan.periodeSelesai),
                      ),
                      if (_tagihan.tanggalJatuhTempo != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'Jatuh tempo',
                          value: formatTanggal(_tagihan.tanggalJatuhTempo!),
                        ),
                      ],
                      if (_tagihan.bisaDibayar) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                                    final berhasil = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PengajuanPembayaranPage(
                                          tagihan: _tagihan,
                                        ),
                                      ),
                                    );

                                    if (!mounted || berhasil != true) return;

                                    final terbaru = await provider.loadDetail(
                                      widget.tagihan.id,
                                    );

                                    if (!mounted) return;

                                    if (terbaru != null) {
                                      setState(() => _tagihan = terbaru);
                                    }
                                  },
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Bayar Sekarang'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D8B8B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8EEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rincian tagihan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_tagihan.items.isEmpty)
                        const Text(
                          'Belum ada rincian untuk tagihan ini.',
                          style: TextStyle(
                            color: Color(0xFF78909C),
                            fontSize: 13,
                          ),
                        )
                      else
                        ..._tagihan.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.deskripsi,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${formatJumlah(item.jumlah)} '
                                        '${item.satuan} × '
                                        '${formatRupiah(item.hargaSatuan)}',
                                        style: const TextStyle(
                                          color: Color(0xFF78909C),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formatRupiah(item.subtotal),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF263238),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.tanggal != null) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    formatTanggal(item.tanggal!),
                                    style: const TextStyle(
                                      color: Color(0xFF90A4AE),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const Divider(color: Color(0xFFE8EEEE)),
                      const SizedBox(height: 12),
                      _MoneyRow(
                        label: 'Subtotal',
                        value: formatRupiah(_tagihan.subtotal),
                      ),
                      const SizedBox(height: 12),
                      _MoneyRow(
                        label: 'Diskon',
                        value: '- ${formatRupiah(_tagihan.diskon)}',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F6F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total pembayaran',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ),
                            Text(
                              formatRupiah(_tagihan.total),
                              style: const TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_tagihan.status == 'ditolak') ...[
                  const SizedBox(height: 14),
                  const _NoticeCard(
                    icon: Icons.info_outline_rounded,
                    message:
                        'Pembayaran sebelumnya ditolak. Periksa '
                        'keterangan penolakan pada riwayat pembayaran '
                        'sebelum mengajukan kembali.',
                  ),
                ],
                if (provider.isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(color: _primary),
                  ),
                ],
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF78909C), fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF263238),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final String value;

  const _MoneyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF607D8B), fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF263238),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _NoticeCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4CC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF9A6700), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF795500), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatus {
  final String label;
  final Color color;
  final Color background;

  const _DetailStatus(this.label, this.color, this.background);
}

_DetailStatus _detailStatus(String status) {
  switch (status) {
    case 'menunggu_verifikasi':
      return const _DetailStatus(
        'Menunggu verifikasi',
        Color(0xFF9A6700),
        Color(0xFFFFF4CC),
      );
    case 'lunas':
      return const _DetailStatus('Lunas', Color(0xFF18794E), Color(0xFFE0F5E9));
    case 'ditolak':
      return const _DetailStatus(
        'Ditolak',
        Color(0xFFB42318),
        Color(0xFFFEE4E2),
      );
    case 'dibatalkan':
      return const _DetailStatus(
        'Dibatalkan',
        Color(0xFF667085),
        Color(0xFFF2F4F7),
      );
    default:
      return const _DetailStatus(
        'Belum bayar',
        Color(0xFF0D8B8B),
        Color(0xFFDDF3F1),
      );
  }
}

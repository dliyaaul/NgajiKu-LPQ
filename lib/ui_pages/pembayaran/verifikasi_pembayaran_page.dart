import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/pembayaran/verifikasi_pembayaran_model.dart';
import '../../state_management/pembayaran/verifikasi_pembayaran_provider.dart';
import '../../utils/pembayaran_format.dart';

class VerifikasiPembayaranPage extends StatefulWidget {
  const VerifikasiPembayaranPage({super.key});

  @override
  State<VerifikasiPembayaranPage> createState() =>
      _VerifikasiPembayaranPageState();
}

class _VerifikasiPembayaranPageState extends State<VerifikasiPembayaranPage> {
  static const Color _primary = Color(0xFF0D8B8B);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VerifikasiPembayaranProvider>().loadData();
    });
  }

  void _pesan(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _lihatDetail(VerifikasiPembayaranModel item) async {
    final provider = context.read<VerifikasiPembayaranProvider>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return _DetailPembayaranSheet(
          item: item,
          provider: provider,
          onVerifikasi: (status, catatan) async {
            Navigator.pop(sheetContext);

            final konfirmasi = await _konfirmasi(
              status: status,
              nomor: item.nomorPembayaran,
            );

            if (!konfirmasi || !mounted) return;

            try {
              await provider.verifikasi(
                pembayaranId: item.id,
                statusBaru: status,
                catatan: catatan,
              );

              if (!mounted) return;

              _pesan(
                status == 'diterima'
                    ? 'Pembayaran berhasil diterima.'
                    : 'Pembayaran berhasil ditolak.',
              );
            } catch (e) {
              if (!mounted) return;
              _pesan('Verifikasi gagal: $e');
            }
          },
        );
      },
    );
  }

  Future<bool> _konfirmasi({
    required String status,
    required String nomor,
  }) async {
    final menerima = status == 'diterima';

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(menerima ? 'Terima Pembayaran?' : 'Tolak Pembayaran?'),
            content: Text(
              menerima
                  ? 'Pastikan bukti transfer dan nominal pembayaran $nomor sudah sesuai.'
                  : 'Pembayaran $nomor akan ditolak. Pastikan alasan penolakan sudah diisi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: menerima ? _primary : Colors.red,
                ),
                child: Text(menerima ? 'Ya, Terima' : 'Ya, Tolak'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        title: const Text(
          'Verifikasi Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<VerifikasiPembayaranProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (provider.items.isEmpty && provider.errorMessage != null) {
            return _StatusView(
              icon: Icons.error_outline_rounded,
              message: 'Gagal memuat pembayaran.',
              detail: provider.errorMessage,
              actionLabel: 'Coba Lagi',
              onAction: provider.loadData,
            );
          }

          if (provider.items.isEmpty) {
            return RefreshIndicator(
              color: _primary,
              onRefresh: provider.loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 56,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada pembayaran menunggu verifikasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pembayaran baru akan muncul di sini setelah santri atau koordinator mengirim bukti transfer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: _primary,
            onRefresh: provider.loadData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menunggu Verifikasi',
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Periksa setiap bukti transfer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${provider.items.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                for (final item in provider.items)
                  _PembayaranCard(item: item, onTap: () => _lihatDetail(item)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PembayaranCard extends StatelessWidget {
  final VerifikasiPembayaranModel item;
  final VoidCallback onTap;

  const _PembayaranCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EEEE)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF0D8B8B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.nomorPembayaran,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black45,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                formatRupiah(item.nominalTransfer),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D8B8B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tagihan: ${item.nomorTagihan}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                'Tanggal transfer: ${formatTanggal(item.tanggalTransfer)}',
                style: const TextStyle(color: Colors.black54),
              ),
              if (item.namaPengirim?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  'Pengirim: ${item.namaPengirim}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPembayaranSheet extends StatefulWidget {
  final VerifikasiPembayaranModel item;
  final VerifikasiPembayaranProvider provider;
  final Future<void> Function(String status, String? catatan) onVerifikasi;

  const _DetailPembayaranSheet({
    required this.item,
    required this.provider,
    required this.onVerifikasi,
  });

  @override
  State<_DetailPembayaranSheet> createState() => _DetailPembayaranSheetState();
}

class _DetailPembayaranSheetState extends State<_DetailPembayaranSheet> {
  final TextEditingController _alasanController = TextEditingController();

  String? _urlBukti;
  String? _errorBukti;
  bool _loadingBukti = true;

  @override
  void initState() {
    super.initState();
    _muatBukti();
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _muatBukti() async {
    try {
      final url = await widget.provider.getUrlBuktiTransfer(
        widget.item.buktiTransfer,
      );

      if (!mounted) return;

      setState(() {
        _urlBukti = url;
        _loadingBukti = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorBukti = e.toString();
        _loadingBukti = false;
      });
    }
  }

  bool get _isPdf => widget.item.buktiTransfer.toLowerCase().endsWith('.pdf');

  Future<void> _bukaPdf() async {
    final url = _urlBukti;
    if (url == null) return;

    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF tidak dapat dibuka.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Detail Pembayaran',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _barisDetail('Nomor pembayaran', item.nomorPembayaran),
                  _barisDetail('Nomor tagihan', item.nomorTagihan),
                  _barisDetail('Nama pengirim', item.namaPengirim ?? '-'),
                  _barisDetail(
                    'Rekening pengirim',
                    item.rekeningPengirim ?? '-',
                  ),
                  _barisDetail(
                    'Tanggal transfer',
                    formatTanggal(item.tanggalTransfer),
                  ),
                  _barisDetail('Bank tujuan', item.namaBank),
                  _barisDetail('Nomor rekening tujuan', item.nomorRekening),
                  _barisDetail('Nama pemilik rekening', item.namaPemilik),
                  _barisDetail(
                    'Nominal transfer',
                    formatRupiah(item.nominalTransfer),
                  ),
                  _barisDetail(
                    'Total tagihan',
                    formatRupiah(item.totalTagihan),
                  ),
                  _barisDetail(
                    'Periode tagihan',
                    '${formatTanggal(item.periodeMulai)} – ${formatTanggal(item.periodeSelesai)}',
                  ),
                  if (item.catatan?.trim().isNotEmpty == true)
                    _barisDetail('Catatan pengirim', item.catatan!),
                  const SizedBox(height: 16),
                  const Text(
                    'Bukti Transfer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _loadingBukti
                        ? const CircularProgressIndicator(
                            color: Color(0xFF0D8B8B),
                          )
                        : _errorBukti != null
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Bukti transfer tidak dapat dimuat:\n$_errorBukti',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _isPdf
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 52,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 8),
                                const Text('Bukti transfer PDF'),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: _bukaPdf,
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: const Text('Buka PDF'),
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              _urlBukti!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Gambar bukti transfer gagal dimuat.',
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Alasan penolakan (wajib jika menolak)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _alasanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Contoh: nominal transfer tidak sesuai.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final alasan = _alasanController.text.trim();

                        if (alasan.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Isi alasan penolakan terlebih dahulu.',
                              ),
                            ),
                          );
                          return;
                        }

                        widget.onVerifikasi('ditolak', alasan);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => widget.onVerifikasi('diterima', null),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D8B8B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Terima'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barisDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? detail;
  final String actionLabel;
  final Future<void> Function() onAction;

  const _StatusView({
    required this.icon,
    required this.message,
    this.detail,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.black45),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

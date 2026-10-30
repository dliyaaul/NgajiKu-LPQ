import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/pembayaran/pembayaran_rekening_model.dart';
import '../../models/pembayaran/tagihan_model.dart';
import '../../services/pembayaran/pembayaran_service.dart';
import '../../utils/pembayaran_format.dart';

class PengajuanPembayaranPage extends StatefulWidget {
  final TagihanModel tagihan;

  const PengajuanPembayaranPage({super.key, required this.tagihan});

  @override
  State<PengajuanPembayaranPage> createState() =>
      _PengajuanPembayaranPageState();
}

class _PengajuanPembayaranPageState extends State<PengajuanPembayaranPage> {
  static const Color _primary = Color(0xFF0D8B8B);

  final PembayaranService _service = PembayaranService();
  final _formKey = GlobalKey<FormState>();

  final _namaPengirimController = TextEditingController();
  final _rekeningPengirimController = TextEditingController();
  final _catatanController = TextEditingController();

  List<PembayaranRekeningModel> _rekening = [];
  String? _rekeningId;

  DateTime _tanggalTransfer = DateTime.now();

  Uint8List? _fileBytes;
  String? _namaFile;
  String? _mimeType;

  bool _memuatRekening = true;
  bool _mengirim = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRekening();
  }

  @override
  void dispose() {
    _namaPengirimController.dispose();
    _rekeningPengirimController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadRekening() async {
    try {
      final data = await _service.getRekeningAktif();

      if (!mounted) return;

      setState(() {
        _rekening = data;
        _rekeningId = data.isNotEmpty ? data.first.id : null;
        _memuatRekening = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _memuatRekening = false;
        _error = 'Gagal memuat rekening tujuan: $e';
      });
    }
  }

  Future<void> _pilihBukti() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );

      if (files.isEmpty) return;

      final file = files.single;

      // Membaca isi file melalui XFile API.
      final bytes = await file.xFile.readAsBytes();

      if (bytes.isEmpty) {
        _showMessage('File tidak dapat dibaca. Coba pilih file lain.');
        return;
      }

      if (bytes.length > 10 * 1024 * 1024) {
        _showMessage('Ukuran file maksimal 10 MB.');
        return;
      }

      final extension = file.extension?.toLowerCase();

      final mime = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'pdf' => 'application/pdf',
        _ => null,
      };

      if (mime == null) {
        _showMessage('Format bukti transfer tidak didukung.');
        return;
      }

      setState(() {
        _fileBytes = bytes;
        _namaFile = file.name;
        _mimeType = mime;
      });
    } catch (e) {
      _showMessage('Gagal memilih file: $e');
    }
  }

  Future<void> _pilihTanggal() async {
    final sekarang = DateTime.now();

    final tanggal = await showDatePicker(
      context: context,
      initialDate: _tanggalTransfer,
      firstDate: DateTime(2000),
      lastDate: DateTime(sekarang.year, sekarang.month, sekarang.day),
      helpText: 'Pilih tanggal transfer',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (tanggal != null && mounted) {
      setState(() => _tanggalTransfer = tanggal);
    }
  }

  Future<void> _kirimPengajuan() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_rekeningId == null) {
      _showMessage('Belum ada rekening tujuan yang aktif.');
      return;
    }

    if (_fileBytes == null || _namaFile == null || _mimeType == null) {
      _showMessage('Pilih bukti transfer terlebih dahulu.');
      return;
    }

    if (!widget.tagihan.bisaDibayar) {
      _showMessage('Tagihan ini tidak tersedia untuk pembayaran baru.');
      return;
    }

    setState(() {
      _mengirim = true;
      _error = null;
    });

    try {
      await _service.ajukanPembayaran(
        tagihanId: widget.tagihan.id,
        rekeningTujuanId: _rekeningId!,
        tanggalTransfer: _tanggalTransfer,
        nominalTransfer: widget.tagihan.total,
        namaPengirim: _namaPengirimController.text,
        rekeningPengirim: _rekeningPengirimController.text,
        catatan: _catatanController.text,
        bytes: _fileBytes!,
        namaFile: _namaFile!,
        mimeType: _mimeType!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti transfer berhasil diajukan.'),
          backgroundColor: _primary,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Pengajuan gagal: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _mengirim = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        title: const Text(
          'Pengajuan Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFF8FAFA),
        surfaceTintColor: Colors.transparent,
      ),
      body: _memuatRekening
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _section(
                    title: 'Ringkasan tagihan',
                    child: Column(
                      children: [
                        _infoRow('Nomor tagihan', widget.tagihan.nomorTagihan),
                        const SizedBox(height: 12),
                        _infoRow(
                          'Periode',
                          '${formatTanggal(widget.tagihan.periodeMulai)}'
                              ' - '
                              '${formatTanggal(widget.tagihan.periodeSelesai)}',
                        ),
                        const Divider(height: 24),
                        _infoRow(
                          'Total yang harus dibayar',
                          formatRupiah(widget.tagihan.total),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Rekening tujuan',
                    child: _rekening.isEmpty
                        ? const Text(
                            'Belum ada rekening aktif. '
                            'Silakan hubungi admin.',
                            style: TextStyle(color: Colors.red),
                          )
                        : Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _rekeningId,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  'Pilih rekening tujuan',
                                ),
                                items: _rekening.map((rekening) {
                                  return DropdownMenuItem<String>(
                                    value: rekening.id,
                                    child: Text(
                                      '${rekening.namaBank} '
                                      '• ${rekening.nomorRekening}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _mengirim
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _rekeningId = value;
                                        });
                                      },
                                validator: (value) =>
                                    value == null ? 'Pilih rekening' : null,
                              ),
                              if (_rekeningId != null) ...[
                                const SizedBox(height: 14),
                                Builder(
                                  builder: (context) {
                                    final selected = _rekening.firstWhere(
                                      (e) => e.id == _rekeningId,
                                    );

                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F6F5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selected.namaBank,
                                            style: const TextStyle(
                                              color: _primary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          SelectableText(
                                            selected.nomorRekening,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'a.n. ${selected.namaPemilik}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF607D8B),
                                            ),
                                          ),
                                          if (selected.keterangan != null &&
                                              selected.keterangan!
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              selected.keterangan!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Informasi transfer',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal transfer',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _mengirim ? null : _pilihTanggal,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: _inputDecoration('Tanggal transfer')
                                .copyWith(
                                  suffixIcon: const Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                ),
                            child: Text(formatTanggal(_tanggalTransfer)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _namaPengirimController,
                          enabled: !_mengirim,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration('Nama pengirim'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Nama pengirim wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _rekeningPengirimController,
                          enabled: !_mengirim,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Nomor rekening pengirim (opsional)',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _catatanController,
                          enabled: !_mengirim,
                          maxLines: 3,
                          decoration: _inputDecoration('Catatan (opsional)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Bukti transfer',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Format JPG, PNG, WebP, atau PDF. Maksimal 10 MB.',
                          style: TextStyle(
                            color: Color(0xFF78909C),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: _mengirim ? null : _pilihBukti,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFA),
                              border: Border.all(
                                color: const Color(0xFFB8DAD7),
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _namaFile == null
                                      ? Icons.cloud_upload_outlined
                                      : Icons.check_circle_outline,
                                  color: _primary,
                                  size: 34,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _namaFile ?? 'Pilih bukti transfer',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _namaFile == null
                                      ? 'Ketuk untuk memilih file'
                                      : 'Ketuk untuk mengganti file',
                                  style: const TextStyle(
                                    color: Color(0xFF78909C),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE4E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed:
                          _mengirim ||
                              _rekening.isEmpty ||
                              !widget.tagihan.bisaDibayar
                          ? null
                          : _kirimPengajuan,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _mengirim
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Kirim Bukti Pembayaran',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF78909C)),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? _primary : const Color(0xFF263238),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFAFCFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E7E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E7E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary),
      ),
    );
  }
}

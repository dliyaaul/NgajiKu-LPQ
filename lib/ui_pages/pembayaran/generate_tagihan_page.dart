import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GenerateTagihanPage extends StatefulWidget {
  const GenerateTagihanPage({super.key});

  @override
  State<GenerateTagihanPage> createState() => _GenerateTagihanPageState();
}

class _GenerateTagihanPageState extends State<GenerateTagihanPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const Color _primary = Color(0xFF0D8B8B);
  static const Color _background = Color(0xFFF8FAFA);
  static const Color _text = Color(0xFF263238);
  static const Color _secondary = Color(0xFF607D8B);

  late DateTime _periodeMulai;
  late DateTime _periodeSelesai;
  late DateTime _tanggalJatuhTempo;

  Map<String, dynamic>? _preview;
  List<Map<String, dynamic>> _daftarSantri = [];

  bool _loadingPreview = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _periodeMulai = DateTime(now.year, now.month, 1);
    _periodeSelesai = DateTime(now.year, now.month + 1, 0);
    _tanggalJatuhTempo = _periodeSelesai;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  String _toSqlDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatRupiah(dynamic value) {
    final number = value is num
        ? value.round()
        : int.tryParse(value.toString()) ?? 0;

    final formatted = number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp$formatted';
  }

  int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _pilihTanggal({
    required DateTime tanggalAwal,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final result = await showDatePicker(
      context: context,
      initialDate: tanggalAwal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null && mounted) {
      onSelected(DateTime(result.year, result.month, result.day));
    }
  }

  void _ubahPeriodeMulai(DateTime date) {
    setState(() {
      _periodeMulai = date;

      if (_periodeSelesai.isBefore(date)) {
        _periodeSelesai = date;
      }

      if (_tanggalJatuhTempo.isBefore(date)) {
        _tanggalJatuhTempo = _periodeSelesai;
      }

      _preview = null;
      _daftarSantri = [];
    });
  }

  void _ubahPeriodeSelesai(DateTime date) {
    setState(() {
      _periodeSelesai = date;

      if (_tanggalJatuhTempo.isBefore(_periodeMulai)) {
        _tanggalJatuhTempo = date;
      }

      _preview = null;
      _daftarSantri = [];
    });
  }

  void _ubahJatuhTempo(DateTime date) {
    setState(() {
      _tanggalJatuhTempo = date;
      _preview = null;
      _daftarSantri = [];
    });
  }

  Future<Map<String, dynamic>> _panggilGenerate({
    required bool konfirmasi,
  }) async {
    final result = await _supabase.rpc(
      'generate_tagihan_reguler',
      params: {
        'p_periode_mulai': _toSqlDate(_periodeMulai),
        'p_periode_selesai': _toSqlDate(_periodeSelesai),
        'p_tanggal_jatuh_tempo': _toSqlDate(_tanggalJatuhTempo),
        'p_konfirmasi': konfirmasi,
      },
    );

    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }

    throw Exception('Format respons server tidak sesuai.');
  }

  Future<void> _muatPratinjau() async {
    if (_loadingPreview || _generating) return;

    if (_periodeSelesai.isBefore(_periodeMulai)) {
      _pesan('Periode selesai tidak boleh sebelum periode mulai.');
      return;
    }

    if (_tanggalJatuhTempo.isBefore(_periodeMulai)) {
      _pesan('Tanggal jatuh tempo tidak boleh sebelum periode mulai.');
      return;
    }

    setState(() {
      _loadingPreview = true;
      _preview = null;
      _daftarSantri = [];
    });

    try {
      final result = await _panggilGenerate(konfirmasi: false);

      if (!mounted) return;

      final rawList = result['daftar'];

      final daftar = rawList is List
          ? rawList
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _preview = result;
        _daftarSantri = daftar;
      });

      if (result['berhasil'] != true) {
        _pesan('Pratinjau tagihan gagal diproses.');
      } else if (daftar.isEmpty) {
        _pesan('Tidak ada peserta Reguler yang ditemukan.');
      }
    } catch (e) {
      if (!mounted) return;
      _pesan(_pesanError(e));
    } finally {
      if (mounted) {
        setState(() => _loadingPreview = false);
      }
    }
  }

  Future<void> _generateTagihan() async {
    final preview = _preview;

    if (preview == null || preview['berhasil'] != true) {
      _pesan('Lakukan pratinjau terlebih dahulu.');
      return;
    }

    final jumlahSiap = _intValue(preview['total_siap_generate']);

    if (jumlahSiap <= 0) {
      _pesan('Tidak ada tagihan baru yang perlu dibuat.');
      return;
    }

    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Generate Tagihan?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Sistem akan membuat $jumlahSiap tagihan Reguler '
            'untuk periode ${_formatDate(_periodeMulai)} '
            'sampai ${_formatDate(_periodeSelesai)}.\n\n'
            'Nominal per santri: '
            '${_formatRupiah(preview['nominal_per_santri'])}.\n\n'
            'Tagihan yang berhasil dibuat tidak otomatis dibatalkan '
            'jika halaman ditutup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _primary),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ya, Generate'),
            ),
          ],
        );
      },
    );

    if (setuju != true || !mounted) return;

    setState(() => _generating = true);

    try {
      final result = await _panggilGenerate(konfirmasi: true);

      if (!mounted) return;

      if (result['berhasil'] != true) {
        _pesan('Generate tagihan tidak berhasil.');
        return;
      }

      final dibuat = _intValue(result['total_dibuat']);
      final dilewati = _intValue(result['total_dilewati_duplikat']);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: Icon(
              dibuat > 0 ? Icons.check_circle_rounded : Icons.info_rounded,
              color: dibuat > 0 ? const Color(0xFF0D8B8B) : Colors.orange,
              size: 52,
            ),
            title: const Text(
              'Generate Selesai',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Hasil pembuatan tagihan Reguler:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _hasilGenerate(
                  label: 'Tagihan berhasil dibuat',
                  jumlah: dibuat,
                  warna: const Color(0xFF0D8B8B),
                ),
                const SizedBox(height: 10),
                _hasilGenerate(
                  label: 'Duplikat dilewati',
                  jumlah: dilewati,
                  warna: Colors.orange,
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D8B8B),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          );
        },
      );

      // Muat ulang pratinjau setelah generate selesai.
      // Peserta yang sudah memiliki tagihan akan ditandai duplikat.
      await _muatPratinjau();
    } catch (e) {
      if (!mounted) return;
      _pesan(_pesanError(e));
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  String _pesanError(Object error) {
    if (error is PostgrestException) {
      return error.message;
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  void _pesan(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Generate Tagihan',
          style: TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _text),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildPeriodeCard(),
                  const SizedBox(height: 20),
                  _buildPreviewSection(),
                ],
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tagihan Reguler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Buat tagihan bulanan santri berdasarkan tarif '
                  'yang berlaku. Periksa pratinjau sebelum '
                  'mengonfirmasi pembuatan tagihan.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodeCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.calendar_month_rounded,
            title: 'Periode Tagihan',
            subtitle: 'Tentukan rentang dan jatuh tempo tagihan.',
          ),
          const SizedBox(height: 20),
          _dateField(
            label: 'Periode Mulai',
            date: _periodeMulai,
            onTap: () => _pilihTanggal(
              tanggalAwal: _periodeMulai,
              onSelected: _ubahPeriodeMulai,
            ),
          ),
          const SizedBox(height: 14),
          _dateField(
            label: 'Periode Selesai',
            date: _periodeSelesai,
            onTap: () => _pilihTanggal(
              tanggalAwal: _periodeSelesai,
              onSelected: _ubahPeriodeSelesai,
            ),
          ),
          const SizedBox(height: 14),
          _dateField(
            label: 'Tanggal Jatuh Tempo',
            date: _tanggalJatuhTempo,
            onTap: () => _pilihTanggal(
              tanggalAwal: _tanggalJatuhTempo,
              onSelected: _ubahJatuhTempo,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8F8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 19, color: _primary),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Tarif Reguler dihitung penuh per bulan, '
                    'termasuk untuk santri yang bergabung '
                    'di tengah bulan.',
                    style: TextStyle(color: _text, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _loadingPreview || _generating ? null : _muatPratinjau,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: _loadingPreview
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.visibility_outlined),
              label: Text(
                _loadingPreview ? 'Memeriksa Data...' : 'Pratinjau Tagihan',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_preview == null) {
      return _card(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(Icons.fact_check_outlined, size: 42, color: _secondary),
              SizedBox(height: 12),
              Text(
                'Pratinjau Belum Tersedia',
                style: TextStyle(color: _text, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Pilih periode, lalu tekan Pratinjau Tagihan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _secondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final preview = _preview!;
    final nominal = preview['nominal_per_santri'];
    final siap = _intValue(preview['total_siap_generate']);
    final duplikat = _intValue(preview['total_duplikat']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.analytics_outlined,
                title: 'Ringkasan Pratinjau',
                subtitle: 'Periksa hasil sebelum generate.',
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _summaryBox(
                      label: 'Siap Dibuat',
                      value: siap.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryBox(
                      label: 'Duplikat',
                      value: duplikat.toString(),
                      icon: Icons.copy_all_rounded,
                      color: const Color(0xFFB7791F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _infoRow('Tarif', '${preview['nama_tarif'] ?? '-'}'),
              const SizedBox(height: 10),
              _infoRow('Nominal per santri', _formatRupiah(nominal)),
              const SizedBox(height: 10),
              _infoRow(
                'Periode',
                '${_formatDate(_periodeMulai)} – '
                    '${_formatDate(_periodeSelesai)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Daftar Santri',
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${_daftarSantri.length} peserta',
              style: const TextStyle(color: _secondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_daftarSantri.isEmpty)
          _card(
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Tidak ada data peserta untuk ditampilkan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _secondary),
              ),
            ),
          )
        else
          ..._daftarSantri.map(_buildSantriCard),
      ],
    );
  }

  Widget _buildSantriCard(Map<String, dynamic> item) {
    final isDuplikat = item['status'] == 'duplikat';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F5),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.person_outline_rounded, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['nama_santri'] ?? 'Tanpa nama'}',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['nama_program'] ?? 'Tanpa program'}',
                  style: const TextStyle(color: _secondary, fontSize: 11),
                ),
                const SizedBox(height: 7),
                Text(
                  _formatRupiah(item['nominal']),
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: isDuplikat
                  ? const Color(0xFFFFF4E5)
                  : const Color(0xFFE6F5EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isDuplikat ? 'Duplikat' : 'Siap',
              style: TextStyle(
                color: isDuplikat
                    ? const Color(0xFF9A6700)
                    : const Color(0xFF207653),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    final siap = _preview == null
        ? 0
        : _intValue(_preview!['total_siap_generate']);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed:
              _preview == null || siap <= 0 || _loadingPreview || _generating
              ? null
              : _generateTagihan,
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: _generating
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.receipt_long_rounded),
          label: Text(
            _generating ? 'Membuat Tagihan...' : 'Generate $siap Tagihan',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _text,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDE5E5)),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 19,
                    color: _primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatDate(date),
                      style: const TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: _secondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(color: _secondary, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EEEE)),
      ),
      child: child,
    );
  }

  Widget _hasilGenerate({
    required String label,
    required int jumlah,
    required Color warna,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            jumlah.toString(),
            style: TextStyle(
              color: warna,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5F5),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: const Color(0xFF0D8B8B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF263238),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF607D8B), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

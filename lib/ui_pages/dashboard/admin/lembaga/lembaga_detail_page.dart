import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/lembaga/lembaga_model.dart';
import 'package:ptl_mobile/state_management/lembaga_provider.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';
import 'package:ptl_mobile/state_management/program_provider.dart';
import 'package:ptl_mobile/models/kelas/kelas_pengajaran_model.dart';
import 'package:ptl_mobile/services/kelas_pengajaran_service.dart';

class LembagaDetailPage extends StatefulWidget {
  final LembagaModel lembaga;

  const LembagaDetailPage({super.key, required this.lembaga});

  @override
  State<LembagaDetailPage> createState() => _LembagaDetailPageState();
}

class _LembagaDetailPageState extends State<LembagaDetailPage> {
  static const Color primaryColor = Color(0xFF0D8B8B);

  final KelasPengajaranService _kelasService = KelasPengajaranService();

  List<KelasPengajaranModel> _kelasLembaga = [];
  bool _isLoadingKelas = false;
  String? _kelasError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lembagaProvider = context.read<LembagaProvider>();

      final loadingProvider = context.read<LoadingProvider>();

      lembagaProvider.loadSantriByLembaga(widget.lembaga.id, loadingProvider);
      _loadKelasLembaga();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lembagaProvider = context.watch<LembagaProvider>();
    final programProvider = context.watch<ProgramProvider>();

    String programName = '-';

    if (widget.lembaga.programId != null) {
      final program = programProvider.items.where(
        (item) => item.id == widget.lembaga.programId,
      );

      if (program.isNotEmpty) {
        programName = program.first.nama;
      }
    }

    // Pengajar lembaga bersumber dari kelas pengajaran yang terhubung,
    // bukan dari kolom legacy lembaga.pengajar_id.
    final kelasLembaga = _kelasLembaga.isNotEmpty ? _kelasLembaga.first : null;
    final pengajarName = _isLoadingKelas
        ? 'Memuat...'
        : (kelasLembaga?.namaPengajar?.trim().isNotEmpty == true
              ? kelasLembaga!.namaPengajar!
              : '-');

    final isOffline = widget.lembaga.pbmType.toLowerCase() == 'offline';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Detail Lembaga',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          await Future.wait([
            context.read<LembagaProvider>().loadSantriByLembaga(
              widget.lembaga.id,
              context.read<LoadingProvider>(),
            ),
            _loadKelasLembaga(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // =====================================================
            // INFORMASI LEMBAGA
            // =====================================================
            _buildLembagaInfo(
              programName: programName,
              pengajarName: pengajarName,
              isOffline: isOffline,
            ),

            const SizedBox(height: 20),

            // =====================================================
            // HEADER SANTRI
            // =====================================================
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Santri Terdaftar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${lembagaProvider.santriLembaga.length} Santri',
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // =====================================================
            // SANTRI
            // =====================================================
            if (lembagaProvider.isLoadingSantri &&
                lembagaProvider.santriLembaga.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              )
            else if (lembagaProvider.santriErrorMessage != null)
              _buildError(lembagaProvider.santriErrorMessage!)
            else if (lembagaProvider.santriLembaga.isEmpty)
              _buildEmptySantri()
            else
              ...lembagaProvider.santriLembaga.map(
                (item) => _buildSantriCard(item),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMASI LEMBAGA
  // ============================================================

  Widget _buildLembagaInfo({
    required String programName,
    required String pengajarName,
    required bool isOffline,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.lembaga.namaLembaga,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildInfoRow(Icons.menu_book_outlined, 'Program', programName),

          const SizedBox(height: 12),

          _buildInfoRow(
            Icons.school_outlined,
            'Kelas',
            _isLoadingKelas
                ? 'Memuat...'
                : (_kelasLembaga.isNotEmpty
                      ? _kelasLembaga.first.namaKelas
                      : '-'),
          ),

          const SizedBox(height: 12),

          _buildInfoRow(Icons.person_outline, 'Pengajar', pengajarName),

          if (_kelasError != null) ...[
            const SizedBox(height: 10),
            Text(
              'Gagal memuat kelas pengajaran: $_kelasError',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 10),
              const Text(
                'PBM',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isOffline
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.lembaga.pbmType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOffline
                        ? Colors.orange.shade800
                        : Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),

          if (widget.lembaga.alamat != null &&
              widget.lembaga.alamat!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Alamat',
              widget.lembaga.alamat!,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SANTRI CARD
  // ============================================================

  Widget _buildSantriCard(dynamic item) {
    final santri = item.santri;
    // Nama kelas berasal dari relasi kelas_pengajaran. kelasType hanya
    // menjadi fallback untuk data lama yang belum memiliki relasi kelas.
    final namaKelas =
        item.kelasPengajaran?.namaKelas ??
        item.kelasType?.nama ??
        'Kelas belum ditentukan';
    final namaPengajar = item.kelasPengajaran?.namaPengajar;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: const Icon(Icons.person_outline, color: primaryColor),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  santri?.username ?? '-',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        namaKelas,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (namaPengajar != null && namaPengajar.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          namaPengajar,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
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
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptySantri() {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 55, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Santri',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada santri yang terdaftar pada lembaga ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadKelasLembaga() async {
    if (!mounted) return;

    setState(() {
      _isLoadingKelas = true;
      _kelasError = null;
    });

    try {
      final semuaKelas = await _kelasService.getAll();

      if (!mounted) return;

      setState(() {
        _kelasLembaga = semuaKelas
            .where((kelas) => kelas.lembagaId == widget.lembaga.id)
            .toList();
        _kelasError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _kelasError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingKelas = false);
      }
    }
  }
}

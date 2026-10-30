import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/models/kelas/kelas_pengajaran_model.dart';

import 'package:ptl_mobile/services/kelas_pengajaran_service.dart';

import 'package:ptl_mobile/state_management/loading_provider.dart';
import 'package:ptl_mobile/state_management/program_provider.dart';

import 'package:ptl_mobile/ui_pages/absensi_bbaq/absensi_bbaq_page.dart';
import 'package:ptl_mobile/ui_pages/absensi_tahfidz/absensi_tahfidz_page.dart';
import 'package:ptl_mobile/ui_pages/absensi_tarjamah/absensi_tarjamah_page.dart';

import 'absensi_ptl_page.dart';

// ================================================================
// COLORS
// ================================================================

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _primaryDark = Color(0xFF075B5B);
const Color _primaryLight = Color(0xFFE7F5F5);

const Color _backgroundColor = Color(0xFFF6F8F8);
const Color _textColor = Color(0xFF263238);
const Color _secondaryColor = Color(0xFF607D8B);
const Color _borderColor = Color(0xFFE5EAEA);

// Warna khusus untuk setiap program absensi.
Color _getProgramColor(String namaProgram) {
  switch (namaProgram.toLowerCase().trim()) {
    case 'bbaq':
      return const Color(0xFF0288D1);
    case 'tahfidz':
      return const Color(0xFF7C3AED);
    case 'tarjamah':
    case 'tarjamah lafdziyah':
      return const Color(0xFF059669);
    case 'ptl':
      return const Color(0xFF0D8B8B);
    case 'kajian':
      return const Color(0xFFD97706);
    default:
      return _primaryColor;
  }
}

// ================================================================
// PAGE
// ================================================================

class AbsensiMainPage extends StatefulWidget {
  const AbsensiMainPage({super.key});

  @override
  State<AbsensiMainPage> createState() => _AbsensiMainPageState();
}

class _AbsensiMainPageState extends State<AbsensiMainPage> {
  // ==============================================================
  // LOADING STATES
  // ==============================================================

  bool _isLoadingBbaq = false;
  bool _isLoadingTahfidz = false;
  bool _isLoadingTarjamah = false;
  bool _isLoadingKajian = false;

  // ==============================================================
  // PROGRAM LOADERS
  // ==============================================================

  Future<void> _openBbaq() async {
    if (_isLoadingBbaq) return;

    setState(() {
      _isLoadingBbaq = true;
    });

    try {
      // ----------------------------------------------------------
      // 1. Ambil ID program BBAQ dari ProgramProvider.
      // ----------------------------------------------------------

      final programId = await _getBbaqProgramId();

      if (!mounted) return;

      if (programId == null) {
        _showSnackBar('Program BBAQ belum tersedia.');
        return;
      }

      // ----------------------------------------------------------
      // 2. Ambil daftar kelas pengajaran program BBAQ.
      // ----------------------------------------------------------

      final kelasPengajaranService = KelasPengajaranService();
      final List<KelasPengajaranModel> kelasList = await kelasPengajaranService
          .getByProgram(programId);

      if (!mounted) return;

      // ----------------------------------------------------------
      // 3. Validasi daftar kelas.
      // ----------------------------------------------------------

      if (kelasList.isEmpty) {
        _showSnackBar('Belum ada kelas pengajaran pada program BBAQ.');
        return;
      }

      // ----------------------------------------------------------
      // 4. Tampilkan pilihan kelas pengajaran.
      // ----------------------------------------------------------

      final kelasTerpilih = await _showKelasPengajaranDialog(
        kelasList,
        namaProgram: 'BBAQ',
      );

      if (!mounted) return;

      // Pengguna membatalkan pemilihan kelas.
      if (kelasTerpilih == null) return;

      // ----------------------------------------------------------
      // 5. Buka halaman absensi sesuai kelas terpilih.
      // ----------------------------------------------------------

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AbsensiBbaqKelasPertemuanPage(
            programId: programId,
            kelasPengajaranId: kelasTerpilih.id,
            namaKelas: kelasTerpilih.namaKelas,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal membuka program BBAQ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBbaq = false;
        });
      }
    }
  }

  // ==============================================================
  // GET BBAQ PROGRAM ID
  // ==============================================================

  Future<String?> _getBbaqProgramId() async {
    final programProvider = context.read<ProgramProvider>();
    final loadingProvider = context.read<LoadingProvider>();

    if (!programProvider.hasData) {
      await programProvider.loadAll(loadingProvider);
    }

    try {
      final bbaq = programProvider.items.firstWhere(
        (program) => program.nama.trim().toLowerCase() == 'bbaq',
      );

      return bbaq.id;
    } catch (_) {
      return null;
    }
  }

  // ==============================================================
  // GET TAHFIDZ PROGRAM ID
  // ==============================================================

  Future<String?> _getTahfidzProgramId() async {
    final programProvider = context.read<ProgramProvider>();
    final loadingProvider = context.read<LoadingProvider>();

    if (!programProvider.hasData) {
      await programProvider.loadAll(loadingProvider);
    }

    try {
      final tahfidz = programProvider.items.firstWhere(
        (program) => program.nama.trim().toLowerCase() == 'tahfidz',
      );

      return tahfidz.id;
    } catch (_) {
      return null;
    }
  }

  // ==============================================================
  // GET TARJAMAH PROGRAM ID
  // ==============================================================

  Future<String?> _getTarjamahProgramId() async {
    final programProvider = context.read<ProgramProvider>();
    final loadingProvider = context.read<LoadingProvider>();

    if (!programProvider.hasData) {
      await programProvider.loadAll(loadingProvider);
    }

    try {
      final tarjamah = programProvider.items.firstWhere(
        (program) => program.nama.trim().toLowerCase() == 'tarjamah lafdziyah',
      );

      return tarjamah.id;
    } catch (_) {
      return null;
    }
  }

  // ==============================================================
  // OPEN TAHFIDZ
  // ==============================================================

  Future<void> _openTahfidz() async {
    if (_isLoadingTahfidz) return;

    setState(() {
      _isLoadingTahfidz = true;
    });

    try {
      // ----------------------------------------------------------
      // 1. Ambil ID program Tahfidz.
      // ----------------------------------------------------------

      final programId = await _getTahfidzProgramId();

      if (!mounted) return;

      if (programId == null) {
        _showSnackBar('Program Tahfidz belum tersedia.');
        return;
      }

      // ----------------------------------------------------------
      // 2. Ambil daftar kelas pengajaran program Tahfidz.
      // ----------------------------------------------------------

      final kelasPengajaranService = KelasPengajaranService();

      final List<KelasPengajaranModel> kelasList = await kelasPengajaranService
          .getByProgram(programId);

      if (!mounted) return;

      // ----------------------------------------------------------
      // 3. Validasi daftar kelas.
      // ----------------------------------------------------------

      if (kelasList.isEmpty) {
        _showSnackBar('Belum ada kelas pengajaran pada program Tahfidz.');
        return;
      }

      // ----------------------------------------------------------
      // 4. Tampilkan pilihan kelas pengajaran.
      // ----------------------------------------------------------

      final kelasTerpilih = await _showKelasPengajaranDialog(
        kelasList,
        namaProgram: 'Tahfidz',
      );

      if (!mounted) return;

      // Pengguna membatalkan pemilihan kelas.
      if (kelasTerpilih == null) {
        return;
      }

      // ----------------------------------------------------------
      // 5. Buka halaman absensi sesuai kelas terpilih.
      // ----------------------------------------------------------

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AbsensiTahfidzPage(
            programId: programId,
            kelasPengajaranId: kelasTerpilih.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('Gagal membuka program Tahfidz: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTahfidz = false;
        });
      }
    }
  }

  // ==============================================================
  // SELECT KELAS PENGAJARAN
  // ==============================================================

  Future<KelasPengajaranModel?> _showKelasPengajaranDialog(
    List<KelasPengajaranModel> kelasList, {
    required String namaProgram,
  }) {
    final programColor = _getProgramColor(namaProgram);

    return showModalBottomSheet<KelasPengajaranModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bottom Sheet.
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Header.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: programColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.groups_rounded,
                          color: programColor,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Kelas $namaProgram',
                              style: const TextStyle(
                                color: _textColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 4),

                            const Text(
                              'Pilih kelas pengajaran yang ingin dikelola.',
                              style: TextStyle(
                                color: _secondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                const Divider(height: 1),

                // Daftar kelas pengajaran.
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    itemCount: kelasList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final kelas = kelasList[index];

                      return _KelasPengajaranItem(
                        kelas: kelas,
                        programColor: programColor,
                        onTap: () {
                          Navigator.pop(sheetContext, kelas);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==============================================================
  // OPEN TARJAMAH
  // ==============================================================

  Future<void> _openTarjamah() async {
    if (_isLoadingTarjamah) return;

    setState(() {
      _isLoadingTarjamah = true;
    });

    try {
      // ----------------------------------------------------------
      // 1. Ambil ID program Tarjamah Lafdziyah.
      // ----------------------------------------------------------

      final programId = await _getTarjamahProgramId();

      if (!mounted) return;

      if (programId == null) {
        _showSnackBar('Program Tarjamah Lafdziyah belum tersedia.');
        return;
      }

      // ----------------------------------------------------------
      // 2. Ambil daftar kelas pengajaran program Tarjamah.
      // ----------------------------------------------------------

      final kelasPengajaranService = KelasPengajaranService();
      final List<KelasPengajaranModel> kelasList = await kelasPengajaranService
          .getByProgram(programId);

      if (!mounted) return;

      // ----------------------------------------------------------
      // 3. Validasi daftar kelas.
      // ----------------------------------------------------------

      if (kelasList.isEmpty) {
        _showSnackBar(
          'Belum ada kelas pengajaran pada program Tarjamah Lafdziyah.',
        );
        return;
      }

      // ----------------------------------------------------------
      // 4. Tampilkan pilihan kelas pengajaran.
      // ----------------------------------------------------------

      final kelasTerpilih = await _showKelasPengajaranDialog(
        kelasList,
        namaProgram: 'Tarjamah Lafdziyah',
      );

      if (!mounted) return;

      // Pengguna membatalkan pemilihan kelas.
      if (kelasTerpilih == null) return;

      // ----------------------------------------------------------
      // 5. Buka halaman absensi sesuai kelas terpilih.
      // ----------------------------------------------------------

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AbsensiTarjamahPage(
            programId: programId,
            kelasPengajaranId: kelasTerpilih.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('Gagal membuka program Tarjamah Lafdziyah: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTarjamah = false;
        });
      }
    }
  }

  // ==============================================================
  // OPEN KAJIAN
  // ==============================================================

  Future<void> _openKajian() async {
    if (_isLoadingKajian) return;

    setState(() {
      _isLoadingKajian = true;
    });

    try {
      // Halaman absensi Kajian belum tersedia.
      // Jangan membuka halaman Tahfidz menggunakan
      // programId Tahfidz sebagai pengganti.
      if (!mounted) return;

      _showSnackBar('Halaman absensi Program Kajian belum tersedia.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingKajian = false;
        });
      }
    }
  }

  // ==============================================================
  // SNACKBAR
  // ==============================================================

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: _primaryDark,
        ),
      );
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final bool isMobile = width < 600;
            final bool isTablet = width >= 600 && width < 1000;

            int crossAxisCount;

            if (isMobile) {
              crossAxisCount = 1;
            } else if (isTablet) {
              crossAxisCount = 2;
            } else if (width < 1350) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 4;
            }

            final horizontalPadding = isMobile
                ? 16.0
                : width >= 1200
                ? 32.0
                : 24.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isMobile: isMobile),

                      SizedBox(height: isMobile ? 20 : 28),

                      _buildSectionHeader(isMobile: isMobile),

                      const SizedBox(height: 14),

                      _buildProgramGrid(
                        isMobile: isMobile,
                        isTablet: isTablet,
                        crossAxisCount: crossAxisCount,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==============================================================
  // APP BAR
  // ==============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: const Text(
        'Pilih Program Absensi',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ==============================================================
  // HEADER
  // ==============================================================

  Widget _buildHeader({required bool isMobile}) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // --------------------------------------------------------
          // DECORATION
          // --------------------------------------------------------
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.055),
              ),
            ),
          ),

          Positioned(
            right: 50,
            bottom: -75,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
          ),

          // --------------------------------------------------------
          // CONTENT
          // --------------------------------------------------------
          Padding(
            padding: EdgeInsets.all(isMobile ? 18 : 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeaderIcon(isMobile: isMobile),

                SizedBox(width: isMobile ? 14 : 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat Presensi Santri',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Pilih program pembelajaran untuk mengelola absensi santri.',
                        maxLines: isMobile ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: isMobile ? 12 : 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({required bool isMobile}) {
    final size = isMobile ? 48.0 : 56.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(isMobile ? 15 : 17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Icon(
        Icons.fact_check_rounded,
        color: Colors.white,
        size: isMobile ? 25 : 29,
      ),
    );
  }

  // ==============================================================
  // SECTION HEADER
  // ==============================================================

  Widget _buildSectionHeader({required bool isMobile}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Program Absensi',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Pilih program yang ingin dikelola',
                style: TextStyle(
                  color: _secondaryColor,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '5 Program',
            style: TextStyle(
              color: _primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // PROGRAM GRID
  // ==============================================================

  Widget _buildProgramGrid({
    required bool isMobile,
    required bool isTablet,
    required int crossAxisCount,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isMobile ? 12 : 16,
      mainAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: isMobile
          ? 3.0
          : isTablet
          ? 1.45
          : 1.40,
      children: [
        // ----------------------------------------------------------
        // PTL
        // ----------------------------------------------------------
        _buildProgramCard(
          title: 'Program PTL',
          subtitle: 'Lihat rekap dan kelola absensi santri PTL',
          icon: Icons.school_rounded,
          accentColor: const Color(0xFF0D8B8B),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PtlAbsensiPage()));
          },
        ),

        // ----------------------------------------------------------
        // BBAQ
        // ----------------------------------------------------------
        _buildProgramCard(
          title: 'Program BBAQ',
          subtitle: 'Absensi bimbingan baca Al-Qur\'an per kelompok',
          icon: Icons.menu_book_rounded,
          accentColor: const Color(0xFF0288D1),
          isLoading: _isLoadingBbaq,
          onTap: _openBbaq,
        ),

        // ----------------------------------------------------------
        // TAHFIDZ
        // ----------------------------------------------------------
        _buildProgramCard(
          title: 'Program Tahfidz',
          subtitle: 'Lihat rekap dan buat absensi santri Tahfidz',
          icon: Icons.auto_stories_rounded,
          accentColor: const Color(0xFF7C3AED),
          isLoading: _isLoadingTahfidz,
          onTap: _openTahfidz,
        ),

        // ----------------------------------------------------------
        // TARJAMAH
        // ----------------------------------------------------------
        _buildProgramCard(
          title: 'Program Tarjamah Lafdziyah',
          subtitle: 'Lihat rekap dan buat absensi santri Tarjamah',
          icon: Icons.translate_rounded,
          accentColor: const Color(0xFF059669),
          isLoading: _isLoadingTarjamah,
          onTap: _openTarjamah,
        ),

        // ----------------------------------------------------------
        // KAJIAN
        // ----------------------------------------------------------
        _buildProgramCard(
          title: 'Program Kajian',
          subtitle: 'Lihat rekap dan buat absensi santri Kajian',
          icon: Icons.campaign_rounded,
          accentColor: const Color(0xFFD97706),
          isLoading: _isLoadingKajian,
          onTap: _openKajian,
        ),
      ],
    );
  }

  // ==============================================================
  // PROGRAM CARD
  // ==============================================================

  Widget _buildProgramCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return _ProgramCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accentColor: accentColor,
      isLoading: isLoading,
      onTap: onTap,
    );
  }
}

// ================================================================
// KELAS PENGAJARAN ITEM
// ================================================================

class _KelasPengajaranItem extends StatelessWidget {
  final KelasPengajaranModel kelas;
  final VoidCallback onTap;
  final Color programColor;

  const _KelasPengajaranItem({
    required this.kelas,
    required this.onTap,
    required this.programColor,
  });

  @override
  Widget build(BuildContext context) {
    final namaPengajar = kelas.namaPengajar?.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // ------------------------------------------------------
              // CLASS ICON
              // ------------------------------------------------------
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: programColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: programColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // ------------------------------------------------------
              // CLASS INFO
              // ------------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kelas.namaKelas,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      namaPengajar == null || namaPengajar.isEmpty
                          ? 'Pengajar belum ditentukan'
                          : 'Pengajar: $namaPengajar',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _secondaryColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ------------------------------------------------------
              // ACTION ICON
              // ------------------------------------------------------
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: programColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: programColor,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// PROGRAM CARD WIDGET
// ================================================================

class _ProgramCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return MouseRegion(
      cursor: widget.isLoading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (!isMobile) {
          setState(() {
            _isHovered = true;
          });
        }
      },
      onExit: (_) {
        if (!isMobile) {
          setState(() {
            _isHovered = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withValues(alpha: 0.22)
                : _borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.075 : 0.035),
              blurRadius: _isHovered ? 18 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: widget.accentColor.withValues(alpha: 0.07),
            highlightColor: widget.accentColor.withValues(alpha: 0.035),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 16,
                vertical: isMobile ? 12 : 16,
              ),
              child: _buildContent(isMobile: isMobile),
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // CONTENT
  // ==============================================================

  Widget _buildContent({required bool isMobile}) {
    // ------------------------------------------------------------
    // MOBILE
    // ------------------------------------------------------------

    if (isMobile) {
      return Row(
        children: [
          _buildIcon(),

          const SizedBox(width: 13),

          Expanded(child: _buildTextContent(compact: true)),

          const SizedBox(width: 10),

          _buildAction(),
        ],
      );
    }

    // ------------------------------------------------------------
    // TABLET / DESKTOP
    // ------------------------------------------------------------

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildIcon(), const Spacer(), _buildTopBadge()],
        ),

        const Spacer(),

        _buildTextContent(),

        const SizedBox(height: 12),

        Row(
          children: [
            Text(
              'Buka program',
              style: TextStyle(
                color: widget.accentColor.withValues(alpha: 0.80),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            _buildAction(),
          ],
        ),
      ],
    );
  }

  // ==============================================================
  // ICON
  // ==============================================================

  Widget _buildIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: _isHovered ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(widget.icon, color: widget.accentColor, size: 24),
    );
  }

  // ==============================================================
  // TEXT
  // ==============================================================

  Widget _buildTextContent({bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: compact
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Text(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.25,
            letterSpacing: -0.1,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          widget.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _secondaryColor,
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // TOP BADGE
  // ==============================================================

  Widget _buildTopBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'ABSENSI',
        style: TextStyle(
          color: _secondaryColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ==============================================================
  // ACTION
  // ==============================================================

  Widget _buildAction() {
    if (widget.isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: widget.accentColor,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _isHovered
            ? widget.accentColor.withValues(alpha: 0.12)
            : const Color(0xFFF5F7F7),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 16,
        color: widget.accentColor,
      ),
    );
  }
}

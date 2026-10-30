import 'package:flutter/material.dart';
import 'package:ptl_mobile/models/santri_program/santri_program_model.dart';

class DetailProgramPembelajaranPage extends StatelessWidget {
  final SantriProgramModel programSantri;

  const DetailProgramPembelajaranPage({super.key, required this.programSantri});

  static const Color primary = Color(0xFF0D8B8B);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF78909C);

  @override
  Widget build(BuildContext context) {
    final namaProgram = programSantri.program?.nama ?? 'Program';
    final namaJenisKelas = programSantri.kelasType?.nama ?? 'Belum ditentukan';
    final namaKelas =
        programSantri.kelasPengajaran?.namaKelas ?? 'Belum ditentukan';
    final namaPengajar =
        programSantri.kelasPengajaran?.namaPengajar ??
        programSantri.pengajar?.username ??
        'Belum ditentukan';

    final sumberPendaftaran = programSantri.lembagaId == null
        ? 'Individu'
        : 'Lembaga';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detail Program',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header program
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaProgram,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Program pembelajaran yang sedang Anda ikuti',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Informasi Pembelajaran',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.menu_book_rounded,
              title: 'Nama Program',
              value: namaProgram,
            ),

            _buildInfoCard(
              icon: Icons.category_outlined,
              title: 'Jenis Kelas',
              value: namaJenisKelas,
            ),

            _buildInfoCard(
              icon: Icons.groups_rounded,
              title: 'Kelas Pengajaran',
              value: namaKelas,
            ),

            _buildInfoCard(
              icon: Icons.person_outline_rounded,
              title: 'Pengajar',
              value: namaPengajar,
            ),

            _buildInfoCard(
              icon: Icons.account_balance_outlined,
              title: 'Sumber Pendaftaran',
              value: sumberPendaftaran,
            ),

            _buildInfoCard(
              icon: Icons.school_outlined,
              title: 'Metode Pembelajaran',
              value: programSantri.defaultPbm.isNotEmpty
                  ? programSantri.defaultPbm
                  : 'Belum ditentukan',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEEE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 21),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
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

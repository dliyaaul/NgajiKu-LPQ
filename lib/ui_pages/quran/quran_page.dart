import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/quran/surah_model.dart';
import '../../state_management/quran_provider.dart';
import 'surah_detail_page.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranProvider>().fetchSurahList();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF263238),
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Al-Qur\'an Digital',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: Consumer<QuranProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingSurah && !provider.hasSurahData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0D8B8B)),
              );
            }

            if (provider.errorMessage != null && !provider.hasSurahData) {
              return _buildErrorState(provider);
            }

            // Filter daftar surah berdasarkan input pencarian
            final filteredList = provider.surahList.where((surah) {
              final nameLatin = surah.namaLatin.toLowerCase();
              final nameArab = surah.nama.toLowerCase();
              final number = surah.nomor.toString();

              return nameLatin.contains(_searchQuery) ||
                  nameArab.contains(_searchQuery) ||
                  number.contains(_searchQuery);
            }).toList();

            return RefreshIndicator(
              color: const Color(0xFF0D8B8B),
              onRefresh: provider.refreshSurahList,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                // +2 Item: Banner Pesantren (Index 0) & Input Pencarian (Index 1)
                itemCount: filteredList.isEmpty && _searchQuery.isNotEmpty
                    ? 3 // +1 untuk widget status Kosong
                    : filteredList.length + 2,
                itemBuilder: (context, index) {
                  // Header Banner
                  if (index == 0) {
                    return _buildPesantrenBanner();
                  }

                  // Field Input Pencarian
                  if (index == 1) {
                    return _buildSearchField();
                  }

                  // Tampilan saat Surah yang dicari tidak ditemukan
                  if (filteredList.isEmpty && _searchQuery.isNotEmpty) {
                    return _buildEmptySearchState();
                  }

                  final SurahModel surah = filteredList[index - 2];
                  return _buildSurahCard(context, surah);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // FIELD PENCARIAN SURAH
  // =========================================================
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) {
          // Menutup keyboard saat tombol Enter/Cari di keyboard ditekan
          FocusScope.of(context).unfocus();
        },
        style: const TextStyle(fontSize: 14, color: Color(0xFF263238)),
        decoration: InputDecoration(
          hintText: 'Cari surah (contoh: Yasin, 36, Al-Kahf)...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF90A4AE)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF0D8B8B),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF78909C),
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFECEFF1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0D8B8B), width: 1.5),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BANNER HEADER PESANTREN
  // =========================================================
  Widget _buildPesantrenBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D8B8B), Color(0xFF14A3A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D8B8B).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Program Ziyadah & Muraja\'ah',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Istiqomah Membaca & Menghafal Al-Qur\'an',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white24,
            size: 50,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SURAH CARD
  // =========================================================
  Widget _buildSurahCard(BuildContext context, SurahModel surah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEFF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SurahDetailPage(surah: surah)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _buildIslamicNumberBadge(surah.nomor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.namaLatin,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      surah.arti,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF78909C),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.menu_book_outlined,
                          '${surah.jumlahAyat} Ayat',
                        ),
                        const SizedBox(width: 6),
                        _buildInfoChip(
                          Icons.location_on_outlined,
                          surah.tempatTurun,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                surah.nama,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D8B8B),
                  fontFamily: 'AmiriQuran',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIslamicNumberBadge(int number) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0D8B8B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0D8B8B).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        Text(
          '$number',
          style: const TextStyle(
            color: Color(0xFF0D8B8B),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF546E7A)),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF546E7A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Tampilan ketika hasil pencarian kosong
  Widget _buildEmptySearchState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          const Icon(
            Icons.find_in_page_outlined,
            size: 60,
            color: Color(0xFFB0BEC5),
          ),
          const SizedBox(height: 12),
          Text(
            'Surah "$_searchQuery" tidak ditemukan',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba periksa kembali ejaan nama surah atau nomor yang Anda masukkan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF78909C)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(QuranProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: Color(0xFF0D8B8B),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gagal Memuat Al-Qur\'an',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Terjadi kesalahan saat mengambil data.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF78909C)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchSurahList(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D8B8B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

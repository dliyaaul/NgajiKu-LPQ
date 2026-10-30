import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/quran/surah_model.dart';
import '../../state_management/quran_provider.dart';
import '../../state_management/quran_audio_provider.dart';
import '../../state_management/saved_ayat_provider.dart'; // Tambahkan provider ini
import 'arsip_ayat_page.dart'; // Tambahkan halaman ini

class SurahDetailPage extends StatefulWidget {
  final SurahModel surah;

  const SurahDetailPage({super.key, required this.surah});

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranProvider>().fetchAyat(widget.surah.nomor);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF263238),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.surah.namaLatin,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${widget.surah.arti} • ${widget.surah.jumlahAyat} Ayat',
              style: const TextStyle(fontSize: 11, color: Color(0xFF78909C)),
            ),
          ],
        ),
        actions: [
          // Button Arahkan ke Halaman Arsip Ayat
          IconButton(
            icon: const Icon(
              Icons.collections_bookmark_rounded,
              color: Color(0xFF0D8B8B),
            ),
            tooltip: 'Arsip Ayat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArsipAyatPage()),
              );
            },
          ),
        ],
      ),
      body: Consumer<QuranProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingAyat && !provider.hasAyatData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D8B8B)),
            );
          }

          if (provider.errorMessage != null && !provider.hasAyatData) {
            return _buildErrorState(provider);
          }

          return RefreshIndicator(
            color: const Color(0xFF0D8B8B),
            onRefresh: provider.refreshAyat,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildSurahHeader(),

                if (widget.surah.nomor != 1 && widget.surah.nomor != 9)
                  _buildBismillahHeader(),

                const SizedBox(height: 16),

                ...provider.ayatList.map(
                  (ayat) => _buildAyatCard(
                    ayat.nomorAyat,
                    ayat.teksArab,
                    ayat.teksLatin,
                    ayat.teksIndonesia,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER SURAH & BISMILLAH ... (Sama seperti sebelumnya)
  // ============================================================
  Widget _buildSurahHeader() {
    final audioUrl = widget.surah.getAudioFullUrl();

    return Consumer<QuranAudioProvider>(
      builder: (context, audioProvider, child) {
        final isCurrentSurah = audioProvider.playingSurah == widget.surah.nomor;
        final isPlaying = audioProvider.isPlayingSurah(widget.surah.nomor);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D8B8B), Color(0xFF085E5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D8B8B).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                widget.surah.nama,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AmiriQuran',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.surah.namaLatin,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.surah.tempatTurun} • ${widget.surah.jumlahAyat} Ayat',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: audioUrl.isEmpty || audioProvider.isLoading
                      ? null
                      : () {
                          audioProvider.toggleAudio(
                            nomorSurah: widget.surah.nomor,
                            audioUrl: audioUrl,
                          );
                        },
                  icon: audioProvider.isLoading && isCurrentSurah
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0D8B8B),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                        ),
                  label: Text(
                    isPlaying
                        ? 'Jeda Audio Surah'
                        : isCurrentSurah
                        ? 'Memuat Audio...'
                        : 'Putar Murottal Surah',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D8B8B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBismillahHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 8),
      alignment: Alignment.center,
      child: const Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        style: TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D8B8B),
        ),
      ),
    );
  }

  // ============================================================
  // CARD AYAT WITH DYNAMIC BOOKMARK BUTTON
  // ============================================================
  Widget _buildAyatCard(
    int nomorAyat,
    String arab,
    String latin,
    String indonesia,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEFF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bar Atas Ayat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7F7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF0D8B8B),
                  child: Text(
                    '$nomorAyat',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Tombol Salin
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: Color(0xFF78909C),
                  ),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: '$arab\n\n$indonesia'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Teks ayat berhasil disalin'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                // Tombol Simpan Ayat (Dengan Indikator Hijau & SnackBar)
                Consumer<SavedAyatProvider>(
                  builder: (context, savedProvider, child) {
                    final isSaved = savedProvider.isSaved(
                      widget.surah.nomor,
                      nomorAyat,
                    );

                    return IconButton(
                      icon: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 22,
                        color: isSaved
                            ? const Color(0xFF2E7D32)
                            : const Color(
                                0xFF78909C,
                              ), // Berubah jadi Hijau saat disimpan
                      ),
                      onPressed: () {
                        savedProvider.toggleSaveAyat(
                          SavedAyatItem(
                            nomorSurah: widget.surah.nomor,
                            namaSurah: widget.surah.namaLatin,
                            nomorAyat: nomorAyat,
                            teksArab: arab,
                            teksLatin: latin,
                            teksIndonesia: indonesia,
                          ),
                        );

                        // Munculkan Pesan Notifikasi
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !isSaved
                                  ? 'Berhasil disimpan ke Arsip Ayat'
                                  : 'Ayat dihapus dari Arsip',
                            ),
                            backgroundColor: !isSaved
                                ? const Color(0xFF2E7D32)
                                : Colors.redAccent,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Teks Arab
                Text(
                  arab,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 26,
                    height: 2.1,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 14),

                // Teks Latin
                if (latin.isNotEmpty)
                  Text(
                    latin,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF0D8B8B),
                    ),
                  ),
                const SizedBox(height: 8),

                // Terjemahan
                Text(
                  indonesia,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: Color(0xFF455A64),
                  ),
                ),
              ],
            ),
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
            const Icon(
              Icons.cloud_off_rounded,
              size: 60,
              color: Color(0xFF90A4AE),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat ayat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF78909C)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => provider.fetchAyat(widget.surah.nomor),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D8B8B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

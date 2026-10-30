import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state_management/saved_ayat_provider.dart';

class ArsipAyatPage extends StatelessWidget {
  const ArsipAyatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF263238),
        elevation: 0,
        title: const Text(
          'Arsip Ayat Tersimpan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Consumer<SavedAyatProvider>(
        builder: (context, provider, child) {
          if (provider.savedAyatList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.bookmark_outline_rounded,
                    size: 70,
                    color: Color(0xFFB0BEC5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum Ada Ayat Tersimpan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ayat yang Anda simpan saat membaca akan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF78909C)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.savedAyatList.length,
            itemBuilder: (context, index) {
              final item = provider.savedAyatList[index];

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
                    // Header Bar (Informasi Surah & Tombol Hapus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F7F7),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D8B8B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.namaSurah} : Ayat ${item.nomorAyat}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 22,
                            ),
                            onPressed: () {
                              provider.removeAyat(
                                item.nomorSurah,
                                item.nomorAyat,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ayat berhasil dihapus dari arsip',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Teks Ayat Arab, Latin & Indonesia
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            item.teksArab,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 24,
                              height: 2,
                              color: Color(0xFF263238),
                            ),
                          ),
                          if (item.teksLatin.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              item.teksLatin,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF0D8B8B),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            item.teksIndonesia,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF455A64),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

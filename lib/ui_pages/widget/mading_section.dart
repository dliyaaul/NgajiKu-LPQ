import 'package:flutter/material.dart';

class MadingSection extends StatefulWidget {
  const MadingSection({super.key});

  @override
  State<MadingSection> createState() => _MadingSectionState();
}

class _MadingSectionState extends State<MadingSection> {
  static const Color tealPrimary = Color(0xFF0D8B8B);
  static const Color textDark = Color(0xFF263238);

  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<String> _madingImages = [
    'assets/images/header_bg1.jpg',
    'assets/images/header_bg2.jpg',
    'assets/images/header_bg3.jpg',
    'assets/images/header_bg4.jpg',
    'assets/images/header_bg5.jpg',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 28,
      ), // Hapus padding horizontal di sini
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================================================================
          // HEADER SECTION (Tetap menggunakan padding horizontal 20)
          // ================================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Group Kiri: Indikator Garis + Teks Judul
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC67C00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Mading Pesantren',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),

                // Group Kanan: Badge Label "Informasi"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tealPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Informasi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tealPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ================================================================
          // MADING 16:9 (Lebar Full Layar)
          // ================================================================
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _madingImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildMadingItem(_madingImages[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ITEM MADING
  // --------------------------------------------------------------------------
  Widget _buildMadingItem(String imagePath) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey.shade200),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 40,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gambar tidak tersedia',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

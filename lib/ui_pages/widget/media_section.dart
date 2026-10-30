import 'dart:async';
import 'package:flutter/material.dart';

class MediaSection extends StatefulWidget {
  const MediaSection({super.key});

  @override
  State<MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<MediaSection> {
  static const Color tealPrimary = Color(0xFF0D8B8B);
  static const Color textDark = Color(0xFF263238);

  late final PageController _pageController;
  Timer? _autoSlideTimer;

  static const int _virtualInitialPage = 1000;
  int _actualCurrentIndex = 1; // Dimulai dari gambar ke-2 (index 1)

  final List<String> _mediaImages = [
    'assets/images/header_bg1.jpg',
    'assets/images/header_bg2.jpg',
    'assets/images/header_bg3.jpg',
  ];

  @override
  void initState() {
    super.initState();

    final int startPage = _virtualInitialPage + 1;

    _pageController = PageController(
      viewportFraction: 0.60,
      initialPage: startPage,
    );

    _startAutoSlide();
  }

  void _startAutoSlide() {
    // 5. Kurangi kecepatan slide: interval antar slide diperlama menjadi 5 detik
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_pageController.hasClients) return;

      // 4. Slide lebih smooth: durasi transisi diubah ke 1000ms dengan kurva easeInOutCubic
      _pageController.nextPage(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleFeatureTap(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title akan segera tersedia.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 234, 234, 234),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // JUDUL & TOMBOL "LAINNYA"
          // =========================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC67C00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Media',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _handleFeatureTap(context, 'Menu Lainnya'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tealPrimary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Lainnya',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tealPrimary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: tealPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // =========================
          // MEDIA SLIDER CAROUSEL
          // =========================
          SizedBox(
            height: (MediaQuery.of(context).size.width * 0.60) + 24,
            child: PageView.builder(
              controller: _pageController,
              itemCount: null,
              // 3. Tidak bisa slide manual oleh pengguna
              clipBehavior: Clip.none,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _actualCurrentIndex = index % _mediaImages.length;
                });
              },
              itemBuilder: (context, index) {
                final int imageIndex = index % _mediaImages.length;
                final bool isActive = imageIndex == _actualCurrentIndex;

                // 1. Efek abu-abu dihapus (ColorFiltered dihilangkan)
                // 4. Durasi animasi scaling & opacity disamakan (1000ms) agar transisi halus
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.80,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOutCubic,
                  child: AnimatedOpacity(
                    // 2. Transparansi ditambahkan lagi: item non-aktif diubah opasitasnya dari 0.5 ke 0.25
                    opacity: isActive ? 1.0 : 0.25,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOutCubic,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 12.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isActive ? 0.18 : 0.05,
                              ),
                              blurRadius: isActive ? 12 : 4,
                              spreadRadius: isActive ? 1 : 0,
                              offset: const Offset(
                                0,
                                6,
                              ), // Posisi bayangan ke arah bawah
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            child: _buildMediaItem(_mediaImages[imageIndex]),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // =========================
          // INDIKATOR (BAR STYLE)
          // =========================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_mediaImages.length, (index) {
              final bool isActive = index == _actualCurrentIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 28 : 16,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive ? tealPrimary : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(String imagePath) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey.shade200),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 32,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Gambar tidak tersedia',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                    textAlign: TextAlign.center,
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

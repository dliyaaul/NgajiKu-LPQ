import 'package:flutter/material.dart';
import 'package:ptl_mobile/ui_pages/hadits/hadits_page.dart';
import 'package:ptl_mobile/ui_pages/quran/quran_page.dart';

class FeatureMenu extends StatelessWidget {
  const FeatureMenu({super.key});

  static const Color textDark = Color(0xFF263238);

  @override
  Widget build(BuildContext context) {
    // 8 Fitur (masing-masing 2 fitur berbagi tema warna yang sama)
    final List<_FeatureItem> features = [
      // Kelompok 1: Teal
      const _FeatureItem(
        title: 'Artikel',
        icon: Icons.article_outlined,
        color: Color(0xFF0D8B8B),
      ),
      const _FeatureItem(
        title: 'Tanya Jawab',
        icon: Icons.question_answer_outlined,
        color: Color(0xFFE65100),
      ),
      // Kelompok 2: Orange / Amber
      const _FeatureItem(
        title: 'Al-Qur\'an',
        icon: Icons.menu_book_outlined,
        color: Color(0xFF283593),
      ),
      const _FeatureItem(
        title: 'Hadits',
        icon: Icons.auto_stories_outlined,
        color: Color(0xFF2E7D32),
      ),
      // Kelompok 3: Indigo / Biru
      const _FeatureItem(
        title: 'Pustaka',
        icon: Icons.library_books_outlined,
        color: Color(0xFF2E7D32),
      ),
      const _FeatureItem(
        title: 'Dzikir & Ibadah',
        icon: Icons.volunteer_activism_outlined,
        color: Color(0xFF283593),
      ),
      // Kelompok 4: Emerald / Hijau
      const _FeatureItem(
        title: 'Kajian',
        icon: Icons.mic_none_outlined,
        color: Color(0xFFE65100),
      ),
      const _FeatureItem(
        title: 'Jadwal Sholat',
        icon: Icons.access_time_outlined,
        color: Color(0xFF0D8B8B),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================================================================
          // JUDUL SECTION + TOMBOL MENU LAINNYA
          // ================================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Kiri: Indikator Garis + Teks "Fitur Utama"
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
                    'Fitur Utama',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),

              // Kanan: Tombol "Menu Lainnya"
              InkWell(
                onTap: () {
                  _handleFeatureTap(context, 'Menu Lainnya');
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D8B8B).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Menu Lainnya',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D8B8B),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFF0D8B8B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ================================================================
          // GRID MENU (8 FITUR / 2 BARIS x 4 KOLOM)
          // ================================================================
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.80,
            ),
            itemBuilder: (context, index) {
              final feature = features[index];

              return _FeatureCard(
                feature: feature,
                onTap: () {
                  _handleFeatureTap(context, feature.title);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // AKSI MENU
  // ------------------------------------------------------------------------
  void _handleFeatureTap(BuildContext context, String title) {
    if (title == 'Al-Qur\'an') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuranPage()),
      );

      return;
    }

    if (title == 'Hadits') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HaditsPage()),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title akan segera tersedia.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// ============================================================================
// MODEL MENU
// ============================================================================

class _FeatureItem {
  final String title;
  final IconData icon;
  final Color color;

  const _FeatureItem({
    required this.title,
    required this.icon,
    required this.color,
  });
}

// ============================================================================
// CARD MENU
// ============================================================================

class _FeatureCard extends StatelessWidget {
  final _FeatureItem feature;
  final VoidCallback onTap;

  const _FeatureCard({required this.feature, required this.onTap});

  static const Color textDark = Color(0xFF263238);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ------------------------------------------------------------
                // ICON WITH CATEGORY COLOR
                // ------------------------------------------------------------
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: feature.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(feature.icon, color: feature.color, size: 24),
                ),

                const SizedBox(height: 6),

                // ------------------------------------------------------------
                // NAMA MENU
                // ------------------------------------------------------------
                Expanded(
                  child: Center(
                    child: Text(
                      feature.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

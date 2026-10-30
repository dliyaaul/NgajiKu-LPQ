import 'package:flutter/material.dart';

import 'package:ptl_mobile/ui_pages/dashboard/admin/kelas/kelas_type_page.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/lembaga/lembaga_page.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/pengajar_page.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/pengajar_pengganti/pengajar_pengganti_page.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/program/program_page.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/santri/santri_page.dart';

// ================================================================
// COLORS
// ================================================================

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _primaryDark = Color(0xFF075B5B);
const Color _primaryLight = Color(0xFFE7F5F5);

const Color _backgroundColor = Color(0xFFF6F8F8);
const Color _cardColor = Colors.white;

const Color _textColor = Color(0xFF263238);
const Color _secondaryColor = Color(0xFF607D8B);

const Color _borderColor = Color(0xFFE5EAEA);

// ================================================================
// PAGE
// ================================================================

class ManajemenLpqPage extends StatelessWidget {
  const ManajemenLpqPage({super.key});

  // ==============================================================
  // MENU
  // ==============================================================

  List<_ManagementMenuItem> _buildMenuItems(BuildContext context) {
    return [
      _ManagementMenuItem(
        title: 'Kelola Santri',
        subtitle: 'Kelola data santri',
        icon: Icons.person_rounded,
        color: const Color(0xFF0D8B8B),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SantriPage()));
        },
      ),

      _ManagementMenuItem(
        title: 'Kelola Pengajar',
        subtitle: 'Kelola data pengajar',
        icon: Icons.co_present_rounded,
        color: const Color(0xFF1976D2),
        onTap: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PengajarPage()));
        },
      ),

      _ManagementMenuItem(
        title: 'Pengajar Pengganti',
        subtitle: 'Kelola data pengajar pengganti',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF7B61FF),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PengajarPenggantiPage()),
          );
        },
      ),

      _ManagementMenuItem(
        title: 'Jenis Kelas',
        subtitle: 'Kelola jenis kelas',
        icon: Icons.class_rounded,
        color: const Color(0xFFFF8A00),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const KelasTypePage()));
        },
      ),

      _ManagementMenuItem(
        title: 'Program Santri',
        subtitle: 'Kelola program santri',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF009688),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProgramPage()));
        },
      ),

      _ManagementMenuItem(
        title: 'Lembaga',
        subtitle: 'Kelola data lembaga',
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF5C6BC0),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LembagaPage()));
        },
      ),
    ];
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final menuItems = _buildMenuItems(context);

    return Scaffold(
      backgroundColor: _backgroundColor,

      appBar: _buildAppBar(context),

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

                      _buildSectionHeader(
                        itemCount: menuItems.length,
                        isMobile: isMobile,
                      ),

                      const SizedBox(height: 14),

                     GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: menuItems.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: isMobile ? 12 : 16,
                          mainAxisSpacing: isMobile ? 12 : 16,

                          // Mobile menggunakan tinggi tetap agar isi card
                          // tidak mengalami overflow.
                          mainAxisExtent: isMobile
                              ? 92
                              : isTablet
                              ? 190
                              : 200,
                        ),
                        itemBuilder: (context, index) {
                          return _ManagementCard(
                            item: menuItems[index],
                            index: index,
                          );
                        },
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _primaryColor,
      elevation: 0,
      scrolledUnderElevation: 0,

      leading: IconButton(
        tooltip: 'Kembali',
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),

      titleSpacing: 0,

      title: const Text(
        'Manajemen LPQ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
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
          // Decorative circle
          Positioned(
            right: -45,
            top: -55,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.055),
              ),
            ),
          ),

          // Decorative circle
          Positioned(
            right: 50,
            bottom: -70,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
          ),

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
                        'Manajemen LPQ',
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
                        'Kelola data dan kebutuhan pembelajaran LPQ dalam satu tempat.',
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
        Icons.dashboard_customize_rounded,
        color: Colors.white,
        size: isMobile ? 25 : 29,
      ),
    );
  }

  // ==============================================================
  // SECTION HEADER
  // ==============================================================

  Widget _buildSectionHeader({required int itemCount, required bool isMobile}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menu Manajemen',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Pilih menu untuk mengelola data LPQ',
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
          child: Text(
            '$itemCount Menu',
            style: const TextStyle(
              color: _primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// MENU MODEL
// ================================================================

class _ManagementMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ManagementMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// ================================================================
// MANAGEMENT CARD
// ================================================================

class _ManagementCard extends StatefulWidget {
  final _ManagementMenuItem item;
  final int index;

  const _ManagementCard({required this.item, required this.index});

  @override
  State<_ManagementCard> createState() => _ManagementCardState();
}

class _ManagementCardState extends State<_ManagementCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? item.color.withValues(alpha: 0.22)
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
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: item.color.withValues(alpha: 0.07),
            highlightColor: item.color.withValues(alpha: 0.035),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: _buildCardContent(item),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(_ManagementMenuItem item) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    if (isMobile) {
      return Row(
        children: [
          _buildIcon(item),

          const SizedBox(width: 13),

          Expanded(child: _buildTextContent(item, compact: true)),

          const SizedBox(width: 10),

          _buildArrow(item),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildIcon(item), const Spacer(), _buildNumber()],
        ),

        const Spacer(),

        _buildTextContent(item),

        const SizedBox(height: 12),

        Row(
          children: [
            Text(
              'Buka menu',
              style: TextStyle(
                color: item.color.withValues(alpha: 0.80),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            _buildArrow(item),
          ],
        ),
      ],
    );
  }

  Widget _buildIcon(_ManagementMenuItem item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: _isHovered ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(item.icon, color: item.color, size: 24),
    );
  }

  Widget _buildNumber() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${widget.index + 1}'.padLeft(2, '0'),
        style: const TextStyle(
          color: _secondaryColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTextContent(_ManagementMenuItem item, {bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: compact
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.1,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          item.subtitle,
          maxLines: compact ? 2 : 2,
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

  Widget _buildArrow(_ManagementMenuItem item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _isHovered
            ? item.color.withValues(alpha: 0.12)
            : const Color(0xFFF5F7F7),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_forward_rounded, size: 16, color: item.color),
    );
  }
}

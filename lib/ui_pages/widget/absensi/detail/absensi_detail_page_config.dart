import 'package:flutter/material.dart';

class AbsensiDetailPageConfig {
  final String title;

  final String pertemuanTitle;

  final String searchHint;

  final Color primaryColor;
  final Color primaryLight;
  final Color backgroundColor;
  final Color cardColor;

  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;

  final Color hadirColor;
  final Color izinColor;
  final Color sakitColor;
  final Color alpaColor;

  final IconData pertemuanIcon;

  final String saveButtonLabel;

  final String savingButtonLabel;

  final String emptySantriTitle;

  final String emptySantriDescription;

  final String filteredSantriTitle;

  final String errorTitle;

  const AbsensiDetailPageConfig({
    required this.title,
    required this.pertemuanTitle,

    this.searchHint = 'Cari nama santri...',

    this.primaryColor = const Color(0xFF0D8B8B),
    this.primaryLight = const Color(0xFFCCFBF1),
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.cardColor = Colors.white,

    this.textColor = const Color(0xFF0F172A),
    this.subtitleColor = const Color(0xFF64748B),
    this.borderColor = const Color(0xFFE2E8F0),

    this.hadirColor = const Color(0xFF10B981),
    this.izinColor = const Color(0xFFF59E0B),
    this.sakitColor = const Color(0xFF6366F1),
    this.alpaColor = const Color(0xFFEF4444),

    this.pertemuanIcon = Icons.menu_book_rounded,

    this.saveButtonLabel = 'Simpan Absensi',
    this.savingButtonLabel = 'Menyimpan...',

    this.emptySantriTitle = 'Belum ada santri',

    this.emptySantriDescription =
        'Belum ada santri yang terdaftar pada program ini.',

    this.filteredSantriTitle = 'Santri tidak ditemukan',

    this.errorTitle = 'Gagal Memuat Absensi',
  });
}

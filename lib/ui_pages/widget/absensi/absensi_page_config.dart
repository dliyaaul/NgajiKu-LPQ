import 'package:flutter/material.dart';

class AbsensiPageConfig {
  final String title;
  final String subtitle;

  /// Warna utama halaman absensi.
  final Color primaryColor;

  /// Warna background halaman.
  final Color backgroundColor;

  /// Warna background ringan untuk icon/chip.
  final Color primaryLight;

  /// Warna teks utama.
  final Color textColor;

  /// Warna teks sekunder.
  final Color subtitleColor;

  /// Placeholder pencarian.
  final String searchHint;

  /// Judul ketika tidak ada data sama sekali.
  final String emptyTitle;

  /// Deskripsi ketika tidak ada data sama sekali.
  final String emptyDescription;

  /// Judul ketika hasil pencarian/filter kosong.
  final String filteredEmptyTitle;

  /// Deskripsi ketika hasil pencarian/filter kosong.
  final String filteredEmptyDescription;

  /// Label tombol tambah.
  final String addButtonLabel;

  /// Icon tombol tambah.
  final IconData addButtonIcon;

  /// Icon empty state.
  final IconData emptyIcon;

  /// Apakah tombol tambah ditampilkan?
  final bool showAddButton;

  const AbsensiPageConfig({
    required this.title,
    required this.subtitle,
    this.primaryColor = const Color(0xFF0D8B8B),
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.primaryLight = const Color(0xFFE6F4F4),
    this.textColor = const Color(0xFF0F172A),
    this.subtitleColor = const Color(0xFF64748B),
    this.searchHint = 'Cari tanggal, pengajar, materi...',
    this.emptyTitle = 'Belum Ada Pertemuan',
    this.emptyDescription =
        'Belum ada jadwal atau rekap pertemuan untuk program ini.',
    this.filteredEmptyTitle = 'Data Tidak Ditemukan',
    this.filteredEmptyDescription =
        'Tidak ada pertemuan yang sesuai dengan pencarian atau filter.',
    this.addButtonLabel = 'Pertemuan Baru',
    this.addButtonIcon = Icons.add_rounded,
    this.emptyIcon = Icons.event_busy_rounded,
    this.showAddButton = true,
  });
}

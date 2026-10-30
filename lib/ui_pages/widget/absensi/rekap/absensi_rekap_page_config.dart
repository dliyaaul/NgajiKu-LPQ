import 'package:flutter/material.dart';

class AbsensiRekapPageConfig {
  /// Judul pada AppBar.
  final String pageTitle;

  /// Judul utama pada header halaman.
  final String headerTitle;

  /// Deskripsi singkat di bawah header.
  final String headerSubtitle;

  /// Nama program yang digunakan pada laporan/PDF.
  final String namaProgram;

  /// Nama bidang yang digunakan pada laporan/PDF.
  final String bidang;

  /// Judul laporan PDF.
  final String judulPdf;

  /// Ikon utama yang digunakan pada header.
  final IconData icon;

  /// Judul bagian tabel rekap.
  final String tableTitle;

  /// Pesan ketika data belum ditampilkan.
  final String emptyTitle;

  /// Deskripsi ketika data belum ditampilkan.
  final String emptyMessage;

  /// Label tombol untuk menampilkan rekap.
  final String tampilkanButtonLabel;

  const AbsensiRekapPageConfig({
    required this.pageTitle,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.namaProgram,
    required this.bidang,
    required this.judulPdf,
    this.icon = Icons.assessment_outlined,
    this.tableTitle = 'Rekap Kehadiran Santri',
    this.emptyTitle = 'Belum Ada Rekap',
    this.emptyMessage =
        'Silakan pilih filter terlebih dahulu untuk menampilkan rekap absensi.',
    this.tampilkanButtonLabel = 'Tampilkan Rekap',
  });
}

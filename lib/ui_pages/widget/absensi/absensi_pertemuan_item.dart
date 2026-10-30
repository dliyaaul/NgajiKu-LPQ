import 'package:flutter/material.dart';

class AbsensiPertemuanItem {
  final String id;

  final DateTime tanggal;

  /// ID pengajar utama.
  final String? pengajarId;

  /// Nama pengajar utama.
  final String pengajar;

  final String? materi;

  /// Nilai yang digunakan untuk filter PBM.
  ///
  /// Contoh:
  /// Offline
  /// Online
  final String pbm;

  final String? pengganti;

  final DateTime createdAt;

  final DateTime? batasWaktu;

  final bool canEdit;

  final bool canInputAttendance;

  final bool hasPengganti;

  final VoidCallback? onOpen;

  final VoidCallback? onEdit;

  final VoidCallback? onDelete;

  final List<AbsensiInfoItem> additionalInfo;

  final VoidCallback? onOpenWeb;

  const AbsensiPertemuanItem({
    required this.id,
    required this.tanggal,
    required this.pengajar,
    required this.pbm,
    required this.createdAt,
    this.pengajarId,
    this.materi,
    this.pengganti,
    this.batasWaktu,
    this.canEdit = true,
    this.canInputAttendance = true,
    this.hasPengganti = false,
    this.onOpen,
    this.onEdit,
    this.onDelete,
    this.additionalInfo = const [],
    this.onOpenWeb,
  });
}

class AbsensiInfoItem {
  final IconData icon;

  final String label;

  final String value;

  final Color? valueColor;

  const AbsensiInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

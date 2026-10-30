class AbsensiDetailPertemuanItem {
  final String id;
  final DateTime tanggal;

  /// Nama pengajar utama.
  final String pengajar;

  /// Nama pengajar pengganti jika pertemuan menggunakan pengajar pengganti.
  final String? pengganti;

  /// Menandakan apakah pertemuan menggunakan pengajar pengganti.
  final bool hasPengganti;

  /// Metode pembelajaran.
  final String metode;

  /// Materi pembelajaran.
  final String? materi;

  /// Waktu pertemuan dibuat.
  ///
  /// Digunakan sebagai fallback untuk menentukan batas waktu
  /// pengisian absensi.
  final DateTime createdAt;

  /// Batas waktu pengisian absensi dari domain/provider tertentu.
  ///
  /// Jika null, template akan menggunakan:
  /// createdAt + 24 jam.
  ///
  /// Ini berguna untuk Tahfidz yang memiliki aturan batas waktu
  /// pengisian absensi sendiri.
  final DateTime? batasWaktuOverride;

  const AbsensiDetailPertemuanItem({
    required this.id,
    required this.tanggal,
    required this.pengajar,
    this.pengganti,
    this.hasPengganti = false,
    required this.metode,
    this.materi,
    required this.createdAt,
    this.batasWaktuOverride,
  });

  /// Nama pengajar yang sedang aktif pada pertemuan.
  ///
  /// Jika terdapat pengajar pengganti yang valid,
  /// maka nama pengajar pengganti yang digunakan.
  String get pengajarAktif {
    if (hasPengganti && pengganti != null && pengganti!.trim().isNotEmpty) {
      return pengganti!.trim();
    }

    return pengajar.trim().isNotEmpty ? pengajar.trim() : 'Belum dipilih';
  }

  /// Apakah pertemuan menggunakan pengajar pengganti
  /// yang valid.
  bool get menggunakanPengganti {
    return hasPengganti && pengganti != null && pengganti!.trim().isNotEmpty;
  }

  /// Batas waktu pengisian absensi.
  ///
  /// Jika terdapat batas waktu khusus dari provider/domain,
  /// gunakan batas tersebut.
  ///
  /// Jika tidak ada, gunakan fallback 24 jam dari createdAt.
  DateTime get batasWaktu {
    return batasWaktuOverride ?? createdAt.add(const Duration(hours: 24));
  }

  /// Apakah pengisian absensi masih diperbolehkan.
  bool get canInputAttendance {
    return DateTime.now().isBefore(batasWaktu);
  }

  /// Apakah batas waktu pengisian absensi sudah lewat.
  bool get isExpired {
    return !canInputAttendance;
  }

  /// Sisa waktu pengisian absensi.
  Duration get remainingAttendanceTime {
    final remaining = batasWaktu.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }
}

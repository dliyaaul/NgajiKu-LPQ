class BbaqRekapModel {
  final String santriProgramId;
  final String santriId;
  final String namaSantri;

  /// Key   : tanggal dalam format YYYY-MM-DD
  /// Value : status (Hadir/Izin/Sakit/Alpa/-)
  final Map<String, String> statusPerTanggal;

  const BbaqRekapModel({
    required this.santriProgramId,
    required this.santriId,
    required this.namaSantri,
    required this.statusPerTanggal,
  });

  String getStatus(String tanggal) {
    return statusPerTanggal[tanggal] ?? '-';
  }

  int get totalHadir {
    return statusPerTanggal.values.where((status) => status == 'Hadir').length;
  }

  int get totalIzin {
    return statusPerTanggal.values.where((status) => status == 'Izin').length;
  }

  int get totalSakit {
    return statusPerTanggal.values.where((status) => status == 'Sakit').length;
  }

  int get totalAlpa {
    return statusPerTanggal.values.where((status) => status == 'Alpa').length;
  }

  int get totalPertemuan {
    return statusPerTanggal.values.where((status) => status != '-').length;
  }

  double get persentaseKehadiran {
    if (totalPertemuan == 0) {
      return 0;
    }

    return (totalHadir / totalPertemuan) * 100;
  }
}

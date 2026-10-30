class TarjamahRekapModel {
  final String santriProgramId;
  final String santriId;
  final String namaSantri;
  final Map<String, String> statusPerTanggal;

  const TarjamahRekapModel({
    required this.santriProgramId,
    required this.santriId,
    required this.namaSantri,
    required this.statusPerTanggal,
  });

  String getStatus(String tanggal) {
    return statusPerTanggal[tanggal] ?? '-';
  }

  int get totalHadir =>
      statusPerTanggal.values.where((status) => status == 'Hadir').length;

  int get totalIzin =>
      statusPerTanggal.values.where((status) => status == 'Izin').length;

  int get totalSakit =>
      statusPerTanggal.values.where((status) => status == 'Sakit').length;

  int get totalAlpa =>
      statusPerTanggal.values.where((status) => status == 'Alpa').length;

  int get totalPertemuan =>
      statusPerTanggal.values.where((status) => status != '-').length;

  double get persentaseKehadiran {
    if (totalPertemuan == 0) {
      return 0;
    }

    return (totalHadir / totalPertemuan) * 100;
  }
}

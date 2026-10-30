class AbsensiRekapRow {
  final String namaSantri;

  /// Key menggunakan format:
  /// yyyy-MM-dd
  ///
  /// Value:
  /// H = Hadir
  /// I = Izin
  /// S = Sakit
  /// A = Alpa
  /// - = Belum ada data
  final Map<String, String> statusByDate;

  final int totalHadir;
  final int totalIzin;
  final int totalSakit;
  final int totalAlpa;

  final double persentaseKehadiran;

  const AbsensiRekapRow({
    required this.namaSantri,
    required this.statusByDate,
    required this.totalHadir,
    required this.totalIzin,
    required this.totalSakit,
    required this.totalAlpa,
    required this.persentaseKehadiran,
  });

  String getStatus(String dateKey) {
    return statusByDate[dateKey] ?? '-';
  }
}

class AbsensiDetailSummary {
  final int hadir;
  final int izin;
  final int sakit;
  final int alpa;

  /// Jumlah santri yang belum memiliki status absensi.
  final int belumAbsen;

  const AbsensiDetailSummary({
    this.hadir = 0,
    this.izin = 0,
    this.sakit = 0,
    this.alpa = 0,
    this.belumAbsen = 0,
  });

  /// Total santri yang sudah memiliki status absensi.
  int get total => hadir + izin + sakit + alpa;

  /// Total seluruh santri.
  ///
  /// Termasuk santri yang belum melakukan absensi.
  int get totalSantri => total + belumAbsen;
}

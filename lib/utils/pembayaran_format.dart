String formatRupiah(num nominal) {
  final angka = nominal.round().toString();
  final hasil = StringBuffer();

  for (var i = 0; i < angka.length; i++) {
    hasil.write(angka[i]);
    final sisa = angka.length - i - 1;

    if (sisa > 0 && sisa % 3 == 0) {
      hasil.write('.');
    }
  }

  return 'Rp$hasil';
}

String formatTanggal(DateTime tanggal) {
  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
}

String formatJumlah(num jumlah) {
  if (jumlah == jumlah.roundToDouble()) {
    return jumlah.toInt().toString();
  }

  return jumlah.toString();
}

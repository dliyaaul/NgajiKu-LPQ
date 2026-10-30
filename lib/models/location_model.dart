class CityLocation {
  final String id;
  final String name;

  CityLocation({required this.id, required this.name});

  factory CityLocation.fromJson(Map<String, dynamic> json) {
    return CityLocation(
      id: json['id'].toString(),
      name: json['lokasi'].toString(),
    );
  }
}

class JadwalSholatModel {
  final String tanggal;
  final String imsak;
  final String subuh;
  final String terbit;
  final String dhuha;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;

  JadwalSholatModel({
    required this.tanggal,
    required this.imsak,
    required this.subuh,
    required this.terbit,
    required this.dhuha,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  factory JadwalSholatModel.fromJson(Map<String, dynamic> json) {
    return JadwalSholatModel(
      tanggal: json['tanggal'] ?? '',
      imsak: json['imsak'] ?? '',
      subuh: json['subuh'] ?? '',
      terbit: json['terbit'] ?? '',
      dhuha: json['dhuha'] ?? '',
      dzuhur: json['dzuhur'] ?? '',
      ashar: json['ashar'] ?? '',
      maghrib: json['maghrib'] ?? '',
      isya: json['isya'] ?? '',
    );
  }
}

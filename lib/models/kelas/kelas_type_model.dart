class KelasTypeModel {
  final String id;
  final String nama;

  KelasTypeModel({required this.id, required this.nama});

  factory KelasTypeModel.fromMap(Map<String, dynamic> map) {
    return KelasTypeModel(id: map['id'] as String, nama: map['nama'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nama': nama};
  }
}

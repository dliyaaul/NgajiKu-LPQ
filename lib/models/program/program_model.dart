class ProgramModel {
  final String id;
  final String nama;
  final String? deskripsi;

  ProgramModel({required this.id, required this.nama, this.deskripsi});

  factory ProgramModel.fromMap(Map<String, dynamic> map) {
    return ProgramModel(
      id: map['id'] as String,
      nama: map['nama'] as String,
      deskripsi: map['deskripsi'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nama': nama, 'deskripsi': deskripsi};
  }
}

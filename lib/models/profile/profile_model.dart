class ProfileModel {
  final String id;
  final String username;
  final String? email;
  final String? nik;
  final String? alamat;
  final String? noHp;
  final String role;
  final String? avatarUrl;
  final String? lembagaId;
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    required this.username,
    this.email,
    this.nik,
    this.alamat,
    this.noHp,
    required this.role,
    this.avatarUrl,
    this.lembagaId,
    this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String?,
      nik: map['nik'] as String?,
      alamat: map['alamat'] as String?,
      noHp: map['no_hp'] as String?,
      role: map['role'] as String,
      avatarUrl: map['avatar_url'] as String?,
      lembagaId: map['lembaga_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nik': nik,
      'alamat': alamat,
      'no_hp': noHp,
      'role': role,
      'avatar_url': avatarUrl,
      'lembaga_id': lembagaId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

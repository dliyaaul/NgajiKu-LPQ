import 'package:ptl_mobile/models/lembaga/lembaga_model.dart';

import '../kelas/kelas_type_model.dart';
import '../kelas/kelas_pengajaran_model.dart';
import '../profile/profile_model.dart';
import '../program/program_model.dart';

class SantriProgramModel {
  final String id;
  final String santriId;
  final String programId;
  final String kelasTypeId;
  final String? kelasPengajaranId;
  final String? pengajarId;
  final String defaultPbm;
  final DateTime? createdAt;
  final String? lembagaId;

  // Relasi lembaga.
  final LembagaModel? lembaga;

  // Data relasional.
  final ProfileModel? santri;
  final ProfileModel? pengajar;
  final ProgramModel? program;
  final KelasTypeModel? kelasType;
  final KelasPengajaranModel? kelasPengajaran;

  const SantriProgramModel({
    required this.id,
    required this.santriId,
    required this.programId,
    required this.kelasTypeId,
    this.kelasPengajaranId,
    this.pengajarId,
    required this.defaultPbm,
    this.lembagaId,
    this.createdAt,
    this.santri,
    this.pengajar,
    this.program,
    this.kelasType,
    this.kelasPengajaran,
    this.lembaga,
  });

  factory SantriProgramModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? relationMap(dynamic value) {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    }

    final santriMap = relationMap(map['santri']);
    final pengajarMap = relationMap(map['pengajar']);
    final programMap = relationMap(map['program']);
    final kelasTypeMap = relationMap(map['kelas_type']);
    final kelasPengajaranMap = relationMap(map['kelas_pengajaran']);
    final lembagaMap = relationMap(map['lembaga']);

    return SantriProgramModel(
      id: map['id'].toString(),
      santriId: map['santri_id'].toString(),
      programId: map['program_id'].toString(),
      kelasTypeId: map['kelas_type_id'].toString(),
      kelasPengajaranId: map['kelas_pengajaran_id']?.toString(),
      pengajarId: map['pengajar_id']?.toString(),
      lembagaId: map['lembaga_id']?.toString(),
      defaultPbm: map['default_pbm']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      santri: santriMap == null ? null : ProfileModel.fromMap(santriMap),
      pengajar: pengajarMap == null ? null : ProfileModel.fromMap(pengajarMap),
      program: programMap == null ? null : ProgramModel.fromMap(programMap),
      kelasType: kelasTypeMap == null
          ? null
          : KelasTypeModel.fromMap(kelasTypeMap),
      kelasPengajaran: kelasPengajaranMap == null
          ? null
          : KelasPengajaranModel.fromMap(kelasPengajaranMap),
      lembaga: lembagaMap == null ? null : LembagaModel.fromMap(lembagaMap),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'santri_id': santriId,
      'program_id': programId,
      'kelas_type_id': kelasTypeId,
      'kelas_pengajaran_id': kelasPengajaranId,
      'pengajar_id': pengajarId,
      'lembaga_id': lembagaId,
      'default_pbm': defaultPbm,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Menghasilkan salinan model.
  ///
  /// Parameter nullable yang tidak dikirim akan mempertahankan nilai lama.
  /// Untuk mengosongkan relasi nullable secara eksplisit, buat model baru
  /// atau tambahkan mekanisme sentinel sesuai kebutuhan pemanggil.
  SantriProgramModel copyWith({
    String? id,
    String? santriId,
    String? programId,
    String? kelasTypeId,
    String? kelasPengajaranId,
    String? pengajarId,
    String? defaultPbm,
    DateTime? createdAt,
    ProfileModel? santri,
    ProfileModel? pengajar,
    ProgramModel? program,
    KelasTypeModel? kelasType,
    KelasPengajaranModel? kelasPengajaran,
    String? lembagaId,
    LembagaModel? lembaga,
  }) {
    return SantriProgramModel(
      id: id ?? this.id,
      santriId: santriId ?? this.santriId,
      programId: programId ?? this.programId,
      kelasTypeId: kelasTypeId ?? this.kelasTypeId,
      kelasPengajaranId: kelasPengajaranId ?? this.kelasPengajaranId,
      pengajarId: pengajarId ?? this.pengajarId,
      defaultPbm: defaultPbm ?? this.defaultPbm,
      lembagaId: lembagaId ?? this.lembagaId,
      createdAt: createdAt ?? this.createdAt,
      santri: santri ?? this.santri,
      pengajar: pengajar ?? this.pengajar,
      program: program ?? this.program,
      kelasType: kelasType ?? this.kelasType,
      kelasPengajaran: kelasPengajaran ?? this.kelasPengajaran,
      lembaga: lembaga ?? this.lembaga,
    );
  }
}

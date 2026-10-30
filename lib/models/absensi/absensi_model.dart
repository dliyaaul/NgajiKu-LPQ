import '../profile/profile_model.dart';
import '../santri_program/santri_program_model.dart';

class AbsensiModel {
  final String id;
  final String santriProgramId;
  final String? userId;
  final String? createdBy;
  final DateTime tanggal;
  final String? pbmAktual;
  final String status;
  final String? catatan;

  // Relational
  final SantriProgramModel? santriProgram;
  final ProfileModel? user;
  final ProfileModel? createdByProfile;

  AbsensiModel({
    required this.id,
    required this.santriProgramId,
    this.userId,
    this.createdBy,
    required this.tanggal,
    this.pbmAktual,
    required this.status,
    this.catatan,
    this.santriProgram,
    this.user,
    this.createdByProfile,
  });

  factory AbsensiModel.fromMap(Map<String, dynamic> map) {
    return AbsensiModel(
      id: map['id'] as String,
      santriProgramId: map['santri_program_id'] as String,
      userId: map['user_id'] as String?,
      createdBy: map['created_by'] as String?,
      tanggal: DateTime.parse(map['tanggal'].toString()),
      pbmAktual: map['pbm_aktual'] as String?,
      status: map['status'] as String,
      catatan: map['catatan'] as String?,

      santriProgram: map['santri_program'] != null
          ? SantriProgramModel.fromMap(
              Map<String, dynamic>.from(map['santri_program']),
            )
          : null,

      user: map['user'] != null
          ? ProfileModel.fromMap(Map<String, dynamic>.from(map['user']))
          : null,

      createdByProfile: map['created_by_profile'] != null
          ? ProfileModel.fromMap(
              Map<String, dynamic>.from(map['created_by_profile']),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'santri_program_id': santriProgramId,
      'user_id': userId,
      'created_by': createdBy,
      'tanggal': tanggal.toIso8601String().split('T').first,
      'pbm_aktual': pbmAktual,
      'status': status,
      'catatan': catatan,
    };
  }
}

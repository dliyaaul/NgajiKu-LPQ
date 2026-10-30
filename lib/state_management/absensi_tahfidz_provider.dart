import 'package:flutter/foundation.dart';

import 'package:ptl_mobile/models/absensi_tahfidz/absensi_tahfidz_model.dart';
import 'package:ptl_mobile/models/absensi_tahfidz/daftar_surat.dart';
import 'package:ptl_mobile/models/absensi_tahfidz/tahfidz_pertemuan_model.dart';
import 'package:ptl_mobile/models/santri_program/santri_program_model.dart';
import 'package:ptl_mobile/services/absensi_tahfidz_service.dart';

class TahfidzAttendanceState {
  final String santriProgramId;

  final String status;
  final String? jenisTahfidz;
  final String? surat;
  final int? ayatMulai;
  final int? ayatSelesai;
  final String? keterangan;
  final String? absensiId;

  const TahfidzAttendanceState({
    required this.santriProgramId,
    this.status = 'Belum Absen',
    this.jenisTahfidz,
    this.surat,
    this.ayatMulai,
    this.ayatSelesai,
    this.keterangan,
    this.absensiId,
  });

  factory TahfidzAttendanceState.fromAbsensi(AbsensiTahfidzModel absensi) {
    return TahfidzAttendanceState(
      santriProgramId: absensi.santriProgramId,
      status: normalizeStatus(absensi.status),
      jenisTahfidz: absensi.jenisTahfidz,
      surat: absensi.surat,
      ayatMulai: absensi.ayatMulai,
      ayatSelesai: absensi.ayatSelesai,
      keterangan: absensi.keterangan,
      absensiId: absensi.id,
    );
  }

  TahfidzAttendanceState copyWith({
    String? status,
    String? jenisTahfidz,
    String? surat,
    int? ayatMulai,
    int? ayatSelesai,
    String? keterangan,
    String? absensiId,

    bool clearJenisTahfidz = false,
    bool clearSurat = false,
    bool clearAyatMulai = false,
    bool clearAyatSelesai = false,
    bool clearKeterangan = false,
    bool clearAbsensiId = false,
  }) {
    return TahfidzAttendanceState(
      santriProgramId: santriProgramId,
      status: status ?? this.status,

      jenisTahfidz: clearJenisTahfidz
          ? null
          : jenisTahfidz ?? this.jenisTahfidz,

      surat: clearSurat ? null : surat ?? this.surat,

      ayatMulai: clearAyatMulai ? null : ayatMulai ?? this.ayatMulai,

      ayatSelesai: clearAyatSelesai ? null : ayatSelesai ?? this.ayatSelesai,

      keterangan: clearKeterangan ? null : keterangan ?? this.keterangan,

      absensiId: clearAbsensiId ? null : absensiId ?? this.absensiId,
    );
  }

  static String normalizeStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'izin':
        return 'Izin';
      case 'sakit':
        return 'Sakit';
      case 'alpha':
      case 'alpa':
        return 'Alpa';
      case 'belum absen':
      case '':
        return 'Belum Absen';
      default:
        return status;
    }
  }

  /// Nilai status yang disimpan ke database.
  String get databaseStatus {
    return status == 'Alpa' ? 'Alpha' : status;
  }
}

class AbsensiTahfidzProvider extends ChangeNotifier {
  final AbsensiTahfidzService _service = AbsensiTahfidzService();

  // ============================================================
  // STATE
  // ============================================================

  List<SantriProgramModel> _santri = [];

  final Map<String, TahfidzAttendanceState> _attendance = {};

  List<Map<String, dynamic>> _pengajar = [];

  TahfidzPertemuanModel? _pertemuan;

  String? _programId;
  String? _pertemuanId;
  DateTime? _tanggalPertemuan;

  bool _isLoading = false;
  bool _isSaving = false;

  String? _error;
  String? _kelasPengajaranId;

  // ============================================================
  // GETTERS
  // ============================================================

  List<SantriProgramModel> get santri => List.unmodifiable(_santri);

  Map<String, TahfidzAttendanceState> get attendance =>
      Map.unmodifiable(_attendance);

  List<Map<String, dynamic>> get pengajar => List.unmodifiable(_pengajar);

  TahfidzPertemuanModel? get pertemuan => _pertemuan;

  String? get programId => _programId;

  String? get pertemuanId => _pertemuanId;

  DateTime? get tanggalPertemuan => _tanggalPertemuan;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get error => _error;

  DateTime? get pertemuanCreatedAt => _pertemuan?.createdAt;

  String? get kelasPengajaranId => _kelasPengajaranId;

  // ============================================================
  // BATAS WAKTU ABSENSI
  // ============================================================

  DateTime? get batasAbsensi {
    final createdAt = _pertemuan?.createdAt;

    if (createdAt == null) {
      return null;
    }

    return createdAt.toLocal().add(const Duration(hours: 24));
  }

  bool get canInputAbsensi {
    final batas = batasAbsensi;

    if (batas == null) {
      return false;
    }

    return DateTime.now().isBefore(batas);
  }

  Duration get remainingAbsensiDuration {
    final batas = batasAbsensi;

    if (batas == null) {
      return Duration.zero;
    }

    final remaining = batas.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  // ============================================================
  // STATISTIK
  // ============================================================

  int get totalSantri => _santri.length;

  int get totalHadir =>
      _attendance.values.where((item) => item.status == 'Hadir').length;

  int get totalIzin =>
      _attendance.values.where((item) => item.status == 'Izin').length;

  int get totalSakit =>
      _attendance.values.where((item) => item.status == 'Sakit').length;

  int get totalAlpha =>
      _attendance.values.where((item) => item.status == 'Alpa').length;

  int get totalBelumAbsen =>
      _attendance.values.where((item) => item.status == 'Belum Absen').length;

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> loadAbsensi({
    required String programId,
    required String kelasPengajaranId,
    required String pertemuanId,
    DateTime? tanggalPertemuan,
  }) async {
    _programId = programId;
    _kelasPengajaranId = kelasPengajaranId;
    _pertemuanId = pertemuanId;

    _isLoading = true;
    _error = null;

    // Kosongkan data sebelumnya agar tidak tertinggal
    // ketika berpindah pertemuan atau kelas.
    _santri = [];
    _attendance.clear();
    _pengajar = [];
    _pertemuan = null;

    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getSantriTahfidz(
          programId: programId,
          kelasPengajaranId: kelasPengajaranId,
        ),
        _service.getPengajarByProgram(programId),
        _service.getAbsensiByPertemuan(pertemuanId),
        _service.getPertemuanById(pertemuanId),
      ]);

      _santri = results[0] as List<SantriProgramModel>;

      _pengajar = results[1] as List<Map<String, dynamic>>;

      final absensiList = results[2] as List<AbsensiTahfidzModel>;

      _pertemuan = results[3] as TahfidzPertemuanModel?;

      if (_pertemuan == null) {
        throw Exception('Pertemuan Tahfidz tidak ditemukan.');
      }

      // Validasi program dan kelas pertemuan.
      if (_pertemuan!.programId != programId) {
        throw Exception('Pertemuan tidak termasuk dalam program yang dipilih.');
      }

      if (_pertemuan!.kelasPengajaranId != kelasPengajaranId) {
        throw Exception(
          'Pertemuan tidak termasuk dalam kelas pengajaran yang dipilih.',
        );
      }

      _tanggalPertemuan = tanggalPertemuan ?? _pertemuan!.tanggal;

      // Inisialisasi seluruh santri kelas dengan status Belum Absen.
      for (final santri in _santri) {
        _attendance[santri.id] = TahfidzAttendanceState(
          santriProgramId: santri.id,
        );
      }

      // Timpa dengan data absensi yang sudah tersimpan.
      for (final absensi in absensiList) {
        if (_attendance.containsKey(absensi.santriProgramId)) {
          _attendance[absensi.santriProgramId] =
              TahfidzAttendanceState.fromAbsensi(absensi);
        }
      }
    } catch (e) {
      _santri = [];
      _attendance.clear();
      _error = _cleanError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CHANGE STATUS
  // ============================================================

  void setStatus(String santriProgramId, String status) {
    if (!canInputAbsensi) {
      return;
    }

    final current = _attendance[santriProgramId];

    if (current == null) {
      return;
    }

    final normalized = TahfidzAttendanceState.normalizeStatus(status);

    if (normalized == 'Hadir') {
      _attendance[santriProgramId] = current.copyWith(status: 'Hadir');
    } else {
      _attendance[santriProgramId] = current.copyWith(
        status: normalized,
        clearJenisTahfidz: true,
        clearSurat: true,
        clearAyatMulai: true,
        clearAyatSelesai: true,
      );
    }

    notifyListeners();
  }

  // ============================================================
  // JENIS TAHFIDZ
  // ============================================================

  void setJenisTahfidz(String santriProgramId, String? value) {
    if (!canInputAbsensi) {
      return;
    }

    final current = _attendance[santriProgramId];

    if (current == null) {
      return;
    }

    _attendance[santriProgramId] = current.copyWith(
      jenisTahfidz: value,
      clearJenisTahfidz: value == null || value.trim().isEmpty,
    );

    notifyListeners();
  }

  // ============================================================
  // SURAT
  // ============================================================

  void setSurat(String santriProgramId, String? value) {
    if (!canInputAbsensi) {
      return;
    }

    final current = _attendance[santriProgramId];

    if (current == null) {
      return;
    }

    _attendance[santriProgramId] = current.copyWith(
      surat: value,
      clearSurat: value == null || value.trim().isEmpty,
      clearAyatMulai: true,
      clearAyatSelesai: true,
    );

    notifyListeners();
  }

  // ============================================================
  // AYAT MULAI
  // ============================================================

  void setAyatMulai(String santriProgramId, int? value) {
    if (!canInputAbsensi) {
      return;
    }

    final current = _attendance[santriProgramId];

    if (current == null) {
      return;
    }

    _attendance[santriProgramId] = current.copyWith(
      ayatMulai: value,
      clearAyatMulai: value == null,
    );

    notifyListeners();
  }

  // ============================================================
  // AYAT SELESAI
  // ============================================================

  void setAyatSelesai(String santriProgramId, int? value) {
    if (!canInputAbsensi) {
      return;
    }

    final current = _attendance[santriProgramId];

    if (current == null) {
      return;
    }

    _attendance[santriProgramId] = current.copyWith(
      ayatSelesai: value,
      clearAyatSelesai: value == null,
    );

    notifyListeners();
  }

  // ============================================================
  // KETERANGAN
  // ============================================================

  void setKeterangan(String santriProgramId, String? value) {
    if (!canInputAbsensi) {
      return;
    }

    final current = _attendance[santriProgramId];

    if (current == null) {
      return;
    }

    _attendance[santriProgramId] = current.copyWith(
      keterangan: value,
      clearKeterangan: value == null || value.trim().isEmpty,
    );

    notifyListeners();
  }

  // ============================================================
  // GET ATTENDANCE
  // ============================================================

  TahfidzAttendanceState? getAttendance(String santriProgramId) {
    return _attendance[santriProgramId];
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? validateAttendance(TahfidzAttendanceState state) {
    if (state.status == 'Belum Absen') {
      return 'Status absensi belum dipilih.';
    }

    if (state.status != 'Hadir') {
      return null;
    }

    // ----------------------------------------------------------
    // JENIS SETORAN
    // ----------------------------------------------------------

    const jenisSetoran = ['Ziyadah', 'Murojaah'];

    if (state.jenisTahfidz == null || state.jenisTahfidz!.trim().isEmpty) {
      return 'Jenis setoran belum dipilih.';
    }

    if (!jenisSetoran.contains(state.jenisTahfidz)) {
      return 'Jenis setoran tidak valid.';
    }

    // ----------------------------------------------------------
    // SURAT
    // ----------------------------------------------------------

    if (state.surat == null || state.surat!.trim().isEmpty) {
      return 'Surat belum dipilih.';
    }

    final surat = getSuratByNama(state.surat!);

    if (surat == null) {
      return 'Surat yang dipilih tidak valid.';
    }

    // ----------------------------------------------------------
    // AYAT MULAI
    // ----------------------------------------------------------

    if (state.ayatMulai == null) {
      return 'Ayat mulai belum diisi.';
    }

    // ----------------------------------------------------------
    // AYAT SELESAI
    // ----------------------------------------------------------

    if (state.ayatSelesai == null) {
      return 'Ayat selesai belum diisi.';
    }

    if (state.ayatMulai! < 1 || state.ayatMulai! > surat.jumlahAyat) {
      return 'Ayat mulai tidak valid untuk surat ${surat.nama}.';
    }

    if (state.ayatSelesai! < 1 || state.ayatSelesai! > surat.jumlahAyat) {
      return 'Ayat selesai tidak valid untuk surat ${surat.nama}.';
    }

    if (state.ayatSelesai! < state.ayatMulai!) {
      return 'Ayat selesai tidak boleh lebih kecil dari ayat mulai.';
    }

    return null;
  }

  // ============================================================
  // VALIDATE ALL
  // ============================================================

  String? validateAll() {
    for (final state in _attendance.values) {
      final error = validateAttendance(state);

      if (error != null) {
        return error;
      }
    }

    return null;
  }

  // ============================================================
  // SAVE ALL
  // ============================================================

  Future<bool> saveAll({required String createdBy}) async {
    if (_pertemuanId == null || _pertemuanId!.isEmpty) {
      _error = 'Pertemuan Tahfidz tidak ditemukan.';
      notifyListeners();
      return false;
    }

    if (_tanggalPertemuan == null) {
      _error = 'Tanggal pertemuan tidak ditemukan.';
      notifyListeners();
      return false;
    }

    if (_pertemuan == null ||
        _pertemuan!.kelasPengajaranId != _kelasPengajaranId) {
      _error = 'Pertemuan tidak sesuai dengan kelas pengajaran.';
      notifyListeners();
      return false;
    }

    // Deadline dicek lagi tepat sebelum save.
    if (!canInputAbsensi) {
      _error =
          'Masa input absensi telah berakhir. '
          'Absensi hanya dapat diisi atau diubah '
          'dalam waktu 24 jam sejak pertemuan dibuat.';
      notifyListeners();
      return false;
    }

    final validationError = validateAll();

    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _error = null;

    notifyListeners();

    try {
      final data = <AbsensiTahfidzModel>[];

      for (final state in _attendance.values) {
        data.add(
          AbsensiTahfidzModel(
            id: state.absensiId ?? '',
            tahfidzPertemuanId: _pertemuanId!,
            santriProgramId: state.santriProgramId,
            tanggal: _tanggalPertemuan!,
            status: state.databaseStatus,
            jenisTahfidz: state.status == 'Hadir' ? state.jenisTahfidz : null,
            surat: state.status == 'Hadir' ? state.surat : null,
            ayatMulai: state.status == 'Hadir' ? state.ayatMulai : null,
            ayatSelesai: state.status == 'Hadir' ? state.ayatSelesai : null,
            keterangan: state.keterangan,
            createdBy: createdBy,
          ),
        );
      }

      final saved = await _service.upsertManyAbsensi(data);

      for (final item in saved) {
        final current = _attendance[item.santriProgramId];

        if (current != null) {
          _attendance[item.santriProgramId] = current.copyWith(
            absensiId: item.id,
          );
        }
      }

      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _santri = [];
    _attendance.clear();
    _pengajar = [];

    _pertemuan = null;

    _programId = null;
    _kelasPengajaranId = null;
    _pertemuanId = null;
    _tanggalPertemuan = null;

    _isLoading = false;
    _isSaving = false;
    _error = null;

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }
}

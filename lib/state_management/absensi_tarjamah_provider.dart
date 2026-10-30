import 'package:flutter/foundation.dart';

import 'package:ptl_mobile/models/absensi_tarjamah/absensi_tarjamah_model.dart';
import 'package:ptl_mobile/models/santri_program/santri_program_model.dart';
import 'package:ptl_mobile/models/absensi_tarjamah/tarjamah_pertemuan_model.dart';
import 'package:ptl_mobile/services/absensi_tarjamah_service.dart';
import 'package:ptl_mobile/services/santri_program_service.dart';
import 'package:ptl_mobile/services/tarjamah_pertemuan_service.dart';

class AbsensiTarjamahProvider extends ChangeNotifier {
  final AbsensiTarjamahService _service = AbsensiTarjamahService();

  final SantriProgramService _santriProgramService = SantriProgramService();

  final TarjamahPertemuanService _pertemuanService = TarjamahPertemuanService();

  // ============================================================
  // STATE
  // ============================================================

  List<AbsensiTarjamahModel> _absensi = [];

  List<SantriProgramModel> _santri = [];

  TarjamahPertemuanModel? _pertemuan;

  /// Status sementara sebelum tombol Simpan ditekan.
  ///
  /// key   = santri_program_id
  /// value = Hadir / Izin / Sakit / Alpa
  final Map<String, String> _statusSementara = {};

  bool _isLoading = false;
  bool _isSaving = false;

  String? _errorMessage;

  String? _tarjamahPertemuanId;
  String? _programId;

  // ============================================================
  // GETTER
  // ============================================================

  List<AbsensiTarjamahModel> get absensi => List.unmodifiable(_absensi);

  List<SantriProgramModel> get santri => List.unmodifiable(_santri);

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  String? get tarjamahPertemuanId => _tarjamahPertemuanId;

  String? get programId => _programId;

  TarjamahPertemuanModel? get pertemuan => _pertemuan;

  bool get hasData => _santri.isNotEmpty;

  bool get hasAbsensiData => _absensi.isNotEmpty;

  // ============================================================
  // ATURAN WAKTU ABSENSI
  // ============================================================

  /// Batas akhir pengisian absensi.
  ///
  /// Batas = createdAt + 24 jam.
  ///
  /// createdAt berasal dari waktu pembuatan pertemuan
  /// yang dikirim oleh perangkat.
  DateTime? get batasWaktuAbsensi {
    if (_pertemuan == null) {
      return null;
    }

    return _pertemuan!.createdAt.add(const Duration(days: 1));
  }

  /// Apakah absensi masih boleh diisi?
  ///
  /// Aturan:
  /// createdAt + 24 jam.
  bool get canInputAttendance {
    final batas = batasWaktuAbsensi;

    if (batas == null) {
      return false;
    }

    return DateTime.now().isBefore(batas);
  }

  /// Apakah waktu pengisian absensi sudah berakhir?
  bool get isAttendanceExpired {
    return !canInputAttendance;
  }

  /// Sisa waktu pengisian absensi.
  Duration get remainingAttendanceTime {
    final batas = batasWaktuAbsensi;

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
  // BATAS EDIT
  // ============================================================

  /// Batas edit pertemuan.
  ///
  /// Sama dengan batas pengisian absensi:
  /// createdAt + 24 jam.
  DateTime? get batasWaktuEdit {
    if (_pertemuan == null) {
      return null;
    }

    return _pertemuan!.createdAt.add(const Duration(days: 1));
  }

  /// Apakah pertemuan masih dapat diedit?
  bool get canEditPertemuan {
    final batas = batasWaktuEdit;

    if (batas == null) {
      return false;
    }

    return DateTime.now().isBefore(batas);
  }

  /// Sisa waktu edit pertemuan.
  Duration get remainingEditTime {
    final batas = batasWaktuEdit;

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
  // LOAD DATA
  // ============================================================

  Future<void> loadData({
    required String programId,
    required String pertemuanId,
  }) async {
    _programId = programId;
    _tarjamahPertemuanId = pertemuanId;

    _isLoading = true;
    _errorMessage = null;

    _santri = [];
    _absensi = [];
    _statusSementara.clear();
    _pertemuan = null;

    notifyListeners();

    try {
      // ========================================================
      // AMBIL DATA:
      //
      // 1. Pertemuan
      // 2. Santri program
      // 3. Absensi
      // ========================================================

      final results = await Future.wait([
        _pertemuanService.getPertemuanById(pertemuanId),
        _santriProgramService.getByProgram(programId),
        _service.getAbsensiByPertemuan(pertemuanId),
      ]);

      final pertemuanResult = results[0] as TarjamahPertemuanModel;

      final santriResult = results[1] as List<SantriProgramModel>;

      final absensiResult = results[2] as List<AbsensiTarjamahModel>;

      // ========================================================
      // VALIDASI PERTEMUAN
      // ========================================================

      if (pertemuanResult.id != pertemuanId) {
        throw Exception('Data pertemuan Tarjamah tidak sesuai.');
      }

      if (pertemuanResult.programId != programId) {
        throw Exception('Pertemuan tidak sesuai dengan program Tarjamah.');
      }

      // ========================================================
      // VALIDASI KELAS PENGAJARAN
      // ========================================================

      final kelasPengajaranId = pertemuanResult.kelasPengajaranId;

      if (kelasPengajaranId == null || kelasPengajaranId.trim().isEmpty) {
        throw Exception(
          'Pertemuan ini belum terhubung dengan Kelas Pengajaran. '
          'Hubungkan pertemuan ke kelas terlebih dahulu sebelum mengisi absensi.',
        );
      }

      _pertemuan = pertemuanResult;

      // ========================================================
      // SANTRI: HANYA KELAS PENGAJARAN PERTEMUAN AKTIF
      // ========================================================

      _santri = santriResult
          .where(
            (item) =>
                item.programId == programId &&
                item.kelasPengajaranId == kelasPengajaranId,
          )
          .toList();

      // ========================================================
      // ABSENSI
      // ========================================================

      _absensi = List<AbsensiTarjamahModel>.from(absensiResult);

      // ========================================================
      // STATUS SEMENTARA
      // ========================================================

      for (final item in _absensi) {
        _statusSementara[item.santriProgramId] = item.status;
      }
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // LOAD ABSENSI BERDASARKAN PERTEMUAN
  // ============================================================

  Future<void> loadAbsensiByPertemuan({
    required String tarjamahPertemuanId,
  }) async {
    _tarjamahPertemuanId = tarjamahPertemuanId;

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _pertemuan = await _pertemuanService.getPertemuanById(
        tarjamahPertemuanId,
      );

      final result = await _service.getAbsensiByPertemuan(tarjamahPertemuanId);

      _absensi = List<AbsensiTarjamahModel>.from(result);

      _statusSementara.clear();

      for (final item in _absensi) {
        _statusSementara[item.santriProgramId] = item.status;
      }
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // GET ABSENSI SANTRI
  // ============================================================

  AbsensiTarjamahModel? getBySantriProgramId(String santriProgramId) {
    try {
      return _absensi.firstWhere(
        (item) => item.santriProgramId == santriProgramId,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // GET ABSENSI BY ID
  // ============================================================

  AbsensiTarjamahModel? getById(String id) {
    try {
      return _absensi.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CEK ABSENSI
  // ============================================================

  bool hasAbsensi(String santriProgramId) {
    return _absensi.any((item) => item.santriProgramId == santriProgramId);
  }

  // ============================================================
  // STATUS
  // ============================================================

  String getStatus(String santriProgramId) {
    return _statusSementara[santriProgramId] ?? 'Alpa';
  }

  void changeStatus({required String santriProgramId, required String status}) {
    // ==========================================================
    // CEK BATAS WAKTU
    // ==========================================================

    if (!canInputAttendance) {
      return;
    }

    const allowedStatuses = ['Hadir', 'Izin', 'Sakit', 'Alpa'];

    if (!allowedStatuses.contains(status)) {
      return;
    }

    _statusSementara[santriProgramId] = status;

    notifyListeners();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get jumlahHadir => _countStatus('Hadir');

  int get jumlahIzin => _countStatus('Izin');

  int get jumlahSakit => _countStatus('Sakit');

  int get jumlahAlpa => _countStatus('Alpa');

  int _countStatus(String status) {
    return _santri.where((item) {
      return getStatus(item.id) == status;
    }).length;
  }

  // ============================================================
  // VALIDASI WAKTU ABSENSI
  // ============================================================

  bool _validateAttendanceTime() {
    if (_pertemuan == null) {
      _errorMessage = 'Data pertemuan Tarjamah tidak ditemukan.';

      return false;
    }

    // ==========================================================
    // CEK CREATED AT
    // ==========================================================

    final createdAt = _pertemuan!.createdAt;

    // ==========================================================
    // CEK EXPIRED
    // ==========================================================

    if (!canInputAttendance) {
      final batas = batasWaktuAbsensi;

      if (batas == null) {
        _errorMessage = 'Waktu pengisian absensi tidak valid.';

        return false;
      }

      _errorMessage =
          'Waktu pengisian absensi telah berakhir. '
          'Pertemuan dibuat pada '
          '${_formatDateTime(createdAt)} '
          'dan batas pengisian sampai '
          '${_formatDateTime(batas)}.';

      return false;
    }

    return true;
  }

  // ============================================================
  // SAVE ALL
  // ============================================================

  Future<bool> saveAll() async {
    // ==========================================================
    // VALIDASI PERTEMUAN
    // ==========================================================

    if (_tarjamahPertemuanId == null) {
      _errorMessage = 'Pertemuan Tarjamah belum dipilih.';

      notifyListeners();

      return false;
    }

    // ==========================================================
    // VALIDASI WAKTU
    // ==========================================================

    if (!_validateAttendanceTime()) {
      notifyListeners();

      return false;
    }

    // ==========================================================
    // VALIDASI SANTRI
    // ==========================================================

    if (_santri.isEmpty) {
      _errorMessage = 'Tidak ada santri pada program Tarjamah.';

      notifyListeners();

      return false;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final List<AbsensiTarjamahModel> toCreate = [];

      final List<AbsensiTarjamahModel> toUpdate = [];

      for (final santriProgram in _santri) {
        final santriProgramId = santriProgram.id;

        final status = getStatus(santriProgramId);

        final existing = getBySantriProgramId(santriProgramId);

        // ======================================================
        // INSERT
        // ======================================================

        if (existing == null) {
          toCreate.add(
            AbsensiTarjamahModel(
              id: '',
              tarjamahPertemuanId: _tarjamahPertemuanId!,
              santriProgramId: santriProgramId,
              status: status,
              createdBy: null,

              // Waktu lokal perangkat.
              createdAt: DateTime.now(),
            ),
          );
        }
        // ======================================================
        // UPDATE
        // ======================================================
        else if (existing.status != status) {
          toUpdate.add(existing.copyWith(status: status));
        }
      }

      // ========================================================
      // INSERT
      // ========================================================

      if (toCreate.isNotEmpty) {
        final created = await _service.createManyAbsensi(toCreate);

        _absensi.addAll(created);
      }

      // ========================================================
      // UPDATE
      // ========================================================

      for (final model in toUpdate) {
        final updated = await _service.updateAbsensi(model);

        final index = _absensi.indexWhere((item) => item.id == model.id);

        if (index != -1) {
          _absensi[index] = updated;
        }
      }

      // ========================================================
      // SINKRONISASI
      // ========================================================

      _statusSementara.clear();

      for (final item in _absensi) {
        _statusSementara[item.santriProgramId] = item.status;
      }

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CREATE ABSENSI
  // ============================================================

  Future<bool> createAbsensi(AbsensiTarjamahModel model) async {
    // Pastikan pertemuan yang digunakan
    // sama dengan pertemuan aktif.
    if (_tarjamahPertemuanId != model.tarjamahPertemuanId) {
      _errorMessage = 'Pertemuan absensi tidak sesuai.';

      notifyListeners();

      return false;
    }

    if (!_validateAttendanceTime()) {
      notifyListeners();

      return false;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.createAbsensi(model);

      _absensi.add(result);

      _statusSementara[result.santriProgramId] = result.status;

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CREATE / UPDATE ABSENSI
  // ============================================================

  Future<bool> saveAbsensi({
    required String tarjamahPertemuanId,
    required String santriProgramId,
    required String status,
  }) async {
    // ==========================================================
    // VALIDASI PERTEMUAN
    // ==========================================================

    if (_tarjamahPertemuanId != tarjamahPertemuanId) {
      _errorMessage = 'Pertemuan absensi tidak sesuai.';

      notifyListeners();

      return false;
    }

    // ==========================================================
    // VALIDASI WAKTU
    // ==========================================================

    if (!_validateAttendanceTime()) {
      notifyListeners();

      return false;
    }

    // ==========================================================
    // VALIDASI STATUS
    // ==========================================================

    const allowedStatuses = ['Hadir', 'Izin', 'Sakit', 'Alpa'];

    if (!allowedStatuses.contains(status)) {
      _errorMessage = 'Status absensi tidak valid.';

      notifyListeners();

      return false;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final existing = getBySantriProgramId(santriProgramId);

      // ========================================================
      // INSERT
      // ========================================================

      if (existing == null) {
        final model = AbsensiTarjamahModel(
          id: '',
          tarjamahPertemuanId: tarjamahPertemuanId,
          santriProgramId: santriProgramId,
          status: status,
          createdBy: null,

          // Waktu lokal perangkat.
          createdAt: DateTime.now(),
        );

        final result = await _service.createAbsensi(model);

        _absensi.add(result);

        _statusSementara[santriProgramId] = result.status;
      }
      // ========================================================
      // UPDATE
      // ========================================================
      else {
        final updated = existing.copyWith(status: status);

        final result = await _service.updateAbsensi(updated);

        final index = _absensi.indexWhere((item) => item.id == existing.id);

        if (index != -1) {
          _absensi[index] = result;
        }

        _statusSementara[santriProgramId] = result.status;
      }

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CREATE MANY
  // ============================================================

  Future<bool> createManyAbsensi(List<AbsensiTarjamahModel> models) async {
    if (models.isEmpty) {
      return true;
    }

    if (!_validateAttendanceTime()) {
      notifyListeners();

      return false;
    }

    // Semua data harus berasal dari
    // pertemuan yang sama.
    if (_tarjamahPertemuanId == null ||
        models.any(
          (item) => item.tarjamahPertemuanId != _tarjamahPertemuanId,
        )) {
      _errorMessage = 'Data absensi memiliki pertemuan yang tidak sesuai.';

      notifyListeners();

      return false;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.createManyAbsensi(models);

      _absensi.addAll(result);

      for (final item in result) {
        _statusSementara[item.santriProgramId] = item.status;
      }

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> updateAbsensi(AbsensiTarjamahModel model) async {
    if (_tarjamahPertemuanId != model.tarjamahPertemuanId) {
      _errorMessage = 'Pertemuan absensi tidak sesuai.';

      notifyListeners();

      return false;
    }

    if (!_validateAttendanceTime()) {
      notifyListeners();

      return false;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.updateAbsensi(model);

      final index = _absensi.indexWhere((item) => item.id == model.id);

      if (index != -1) {
        _absensi[index] = result;
      }

      _statusSementara[result.santriProgramId] = result.status;

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // DELETE ABSENSI
  // ============================================================

  Future<bool> deleteAbsensi(String id) async {
    // Penghapusan juga mengikuti
    // batas waktu 24 jam.
    if (!_validateAttendanceTime()) {
      notifyListeners();

      return false;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final deleted = getById(id);

      if (deleted == null) {
        _errorMessage = 'Data absensi tidak ditemukan.';

        return false;
      }

      if (deleted.tarjamahPertemuanId != _tarjamahPertemuanId) {
        _errorMessage = 'Data absensi bukan milik pertemuan ini.';

        return false;
      }

      await _service.deleteAbsensi(id);

      _absensi.removeWhere((item) => item.id == id);

      _statusSementara.remove(deleted.santriProgramId);

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // DELETE SEMUA ABSENSI PERTEMUAN
  // ============================================================

  Future<bool> deleteAbsensiByPertemuan(String tarjamahPertemuanId) async {
    if (_tarjamahPertemuanId != tarjamahPertemuanId) {
      _errorMessage = 'Pertemuan absensi tidak sesuai.';

      notifyListeners();

      return false;
    }

    if (!_validateAttendanceTime()) {
      notifyListeners();

      return false;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.deleteAbsensiByPertemuan(tarjamahPertemuanId);

      _absensi.clear();
      _statusSementara.clear();

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    if (_tarjamahPertemuanId == null || _programId == null) {
      return;
    }

    await loadData(programId: _programId!, pertemuanId: _tarjamahPertemuanId!);
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _absensi = [];
    _santri = [];

    _statusSementara.clear();

    _pertemuan = null;

    _tarjamahPertemuanId = null;
    _programId = null;

    _errorMessage = null;

    _isLoading = false;
    _isSaving = false;

    notifyListeners();
  }

  // ============================================================
  // PRIVATE
  // ============================================================

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');

    final month = dateTime.month.toString().padLeft(2, '0');

    final year = dateTime.year.toString();

    final hour = dateTime.hour.toString().padLeft(2, '0');

    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

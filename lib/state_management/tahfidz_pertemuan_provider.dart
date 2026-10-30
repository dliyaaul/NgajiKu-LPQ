import 'package:flutter/foundation.dart';

import 'package:ptl_mobile/models/absensi_tahfidz/tahfidz_pertemuan_model.dart';
import 'package:ptl_mobile/services/tahfidz_pertemuan_service.dart';

class TahfidzPertemuanProvider extends ChangeNotifier {
  final TahfidzPertemuanService _service = TahfidzPertemuanService();

  // ================================================================
  // STATE
  // ================================================================

  List<TahfidzPertemuanModel> _pertemuan = [];

  bool _isLoading = false;
  bool _isSaving = false;

  String? _error;

  String? _programId;
  String? _kelasPengajaranId;

  // ================================================================
  // GETTERS
  // ================================================================

  List<TahfidzPertemuanModel> get pertemuan => _pertemuan;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get error => _error;

  String? get programId => _programId;

  String? get kelasPengajaranId => _kelasPengajaranId;

  bool get hasData => _pertemuan.isNotEmpty;

  // ================================================================
  // LOAD DATA BY KELAS
  // ================================================================

  Future<void> loadData({
    required String programId,
    required String kelasPengajaranId,
  }) async {
    if (programId.trim().isEmpty) {
      _error = 'Program tidak valid.';
      notifyListeners();
      return;
    }

    if (kelasPengajaranId.trim().isEmpty) {
      _error = 'Kelas pengajaran tidak valid.';
      notifyListeners();
      return;
    }

    _programId = programId;
    _kelasPengajaranId = kelasPengajaranId;

    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      final data = await _service.getPertemuanByKelas(
        kelasPengajaranId: kelasPengajaranId,
      );

      // Pastikan pertemuan sesuai dengan program yang dipilih.
      _pertemuan = data.where((item) => item.programId == programId).toList();
    } catch (e) {
      _error = _cleanError(e);
      _pertemuan = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> refresh() async {
    if (_programId == null ||
        _programId!.isEmpty ||
        _kelasPengajaranId == null ||
        _kelasPengajaranId!.isEmpty) {
      return;
    }

    await loadData(
      programId: _programId!,
      kelasPengajaranId: _kelasPengajaranId!,
    );
  }

  // ================================================================
  // GET DETAIL
  // ================================================================

  Future<TahfidzPertemuanModel?> getPertemuanById(String pertemuanId) async {
    if (pertemuanId.isEmpty) {
      _error = 'ID pertemuan tidak valid.';
      notifyListeners();
      return null;
    }

    try {
      return await _service.getPertemuanById(pertemuanId);
    } catch (e) {
      _error = _cleanError(e);
      notifyListeners();
      return null;
    }
  }

  // ================================================================
  // CREATE
  // ================================================================

  Future<TahfidzPertemuanModel?> createPertemuan(
    TahfidzPertemuanModel model,
  ) async {
    _isSaving = true;
    _error = null;

    notifyListeners();

    try {
      final result = await _service.createPertemuan(model);

      // Tambahkan ke list hanya jika sesuai program dan kelas aktif.
      if (_programId == result.programId &&
          _kelasPengajaranId == result.kelasPengajaranId) {
        _pertemuan = [result, ..._pertemuan];
      }

      return result;
    } catch (e) {
      _error = _cleanError(e);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ================================================================
  // UPDATE
  // ================================================================

  Future<TahfidzPertemuanModel?> updatePertemuan(
    TahfidzPertemuanModel model,
  ) async {
    if (model.id.isEmpty) {
      _error = 'ID pertemuan tidak valid.';
      notifyListeners();
      return null;
    }

    if (!canEdit(model)) {
      _error =
          'Pertemuan hanya dapat diubah dalam waktu 24 jam setelah dibuat.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _error = null;

    notifyListeners();

    try {
      final result = await _service.updatePertemuan(model);

      final index = _pertemuan.indexWhere((item) => item.id == result.id);

      if (index != -1) {
        // Jika pertemuan berpindah kelas, keluarkan dari list kelas lama.
        if (_kelasPengajaranId != result.kelasPengajaranId ||
            _programId != result.programId) {
          _pertemuan.removeAt(index);
        } else {
          _pertemuan[index] = result;
        }
      }

      return result;
    } catch (e) {
      _error = _cleanError(e);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ================================================================
  // DELETE
  // ================================================================

  Future<bool> deletePertemuan(TahfidzPertemuanModel model) async {
    if (model.id.isEmpty) {
      _error = 'ID pertemuan tidak valid.';
      notifyListeners();
      return false;
    }

    if (!canDelete(model)) {
      _error =
          'Pertemuan hanya dapat dihapus dalam waktu 24 jam setelah dibuat.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _error = null;

    notifyListeners();

    try {
      await _service.deletePertemuan(model.id);

      _pertemuan.removeWhere((item) => item.id == model.id);

      return true;
    } catch (e) {
      _error = _cleanError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ================================================================
  // CHECK EDIT / DELETE
  // ================================================================

  bool canEdit(TahfidzPertemuanModel model) {
    return _service.canEdit(model);
  }

  bool canDelete(TahfidzPertemuanModel model) {
    return _service.canDelete(model);
  }

  // ================================================================
  // SISA WAKTU EDIT
  // ================================================================

  Duration remainingEditDuration(TahfidzPertemuanModel model) {
    return _service.remainingEditDuration(model);
  }

  // ================================================================
  // FORMAT SISA WAKTU
  // ================================================================

  String remainingEditText(TahfidzPertemuanModel model) {
    final remaining = remainingEditDuration(model);

    if (remaining <= Duration.zero) {
      return 'Masa edit telah berakhir';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return 'Sisa waktu edit $hours jam $minutes menit';
    }

    return 'Sisa waktu edit $minutes menit';
  }

  // ================================================================
  // CEK PENGAJAR
  // ================================================================

  Future<bool> isPengajarTerdaftar(String programId, String pengajarId) async {
    try {
      return await _service.isPengajarTerdaftar(programId, pengajarId);
    } catch (e) {
      _error = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  // ================================================================
  // CLEAR ERROR
  // ================================================================

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  // ================================================================
  // CLEAR DATA
  // ================================================================

  void clear() {
    _pertemuan = [];

    _programId = null;
    _kelasPengajaranId = null;

    _error = null;
    _isLoading = false;
    _isSaving = false;

    notifyListeners();
  }

  // ================================================================
  // ERROR CLEANER
  // ================================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  @override
  void dispose() {
    _pertemuan.clear();
    super.dispose();
  }
}

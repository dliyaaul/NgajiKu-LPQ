import 'package:flutter/foundation.dart';

import 'package:ptl_mobile/models/absensi_bbaq/bbaq_pertemuan_model.dart';
import 'package:ptl_mobile/models/pengajar_program/pengajar_program_model.dart';
import 'package:ptl_mobile/services/absensi_bbaq_service.dart';

class BbaqPertemuanProvider extends ChangeNotifier {
  final AbsensiBbaqService _service = AbsensiBbaqService();

  //  ============================================================
  // STATE - PERTEMUAN
  // ============================================================

  List<BbaqPertemuanModel> _pertemuan = [];

  // ============================================================
  // STATE - PENGAJAR
  // ============================================================

  List<PengajarProgramModel> _pengajar = [];

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingPengajar = false;

  String? _errorMessage;

  String? _programId;

  String? _kelasPengajaranId;

  // ============================================================
  // GETTER - PERTEMUAN
  // ============================================================

  List<BbaqPertemuanModel> get pertemuan => _pertemuan;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  String? get programId => _programId;

  bool get hasData => _pertemuan.isNotEmpty;

  String? get kelasPengajaranId => _kelasPengajaranId;

  // ============================================================
  // GETTER - PENGAJAR
  // ============================================================

  List<PengajarProgramModel> get pengajar => _pengajar;

  bool get isLoadingPengajar => _isLoadingPengajar;

  // ============================================================
  // LOAD PERTEMUAN BERDASARKAN PROGRAM
  // ============================================================

  Future<void> loadPertemuan({required String programId}) async {
    if (_isLoading) {
      debugPrint('LOAD PERTEMUAN DIBATALKAN karena masih loading');
      return;
    }

    _programId = programId;

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _pertemuan = await _service.getPertemuanByProgram(programId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // LOAD PENGAJAR BERDASARKAN PROGRAM
  //
  // SUMBER:
  // pengajar_programs
  //
  // BUKAN:
  // santri_programs
  // ============================================================

  Future<void> loadPengajarByProgram({required String programId}) async {
    if (_isLoadingPengajar) {
      debugPrint('LOAD PENGAJAR DIBATALKAN karena masih loading');
      return;
    }

    _isLoadingPengajar = true;

    notifyListeners();

    try {
      _pengajar = await _service.getPengajarByProgram(programId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingPengajar = false;
      notifyListeners();
    }
  }

  // ============================================================
  // LOAD PERTEMUAN + PENGAJAR
  // ============================================================

  Future<void> loadData({
    required String programId,
    String? kelasPengajaranId,
  }) async {
    _programId = programId;
    _kelasPengajaranId = kelasPengajaranId;

    _isLoading = true;
    _isLoadingPengajar = true;
    _errorMessage = null;

    notifyListeners();

    try {
      if (kelasPengajaranId != null && kelasPengajaranId.trim().isNotEmpty) {
        _pertemuan = await _service.getPertemuanByKelas(
          kelasPengajaranId: kelasPengajaranId,
        );
      } else {
        // Kompatibilitas untuk halaman lama yang masih
        // memuat pertemuan berdasarkan program.
        _pertemuan = await _service.getPertemuanByProgram(programId);
      }

      _pengajar = await _service.getPengajarByProgram(programId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingPengajar = false;
      notifyListeners();
    }
  }

  // ============================================================
  // GET DETAIL SATU PERTEMUAN
  // ============================================================

  Future<BbaqPertemuanModel?> getPertemuanById(String id) async {
    try {
      return await _service.getPertemuanById(id);
    } catch (e) {
      _errorMessage = e.toString();

      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<bool> createPertemuan(BbaqPertemuanModel model) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.createPertemuan(model);

      _pertemuan.insert(0, result);

      // Urutkan berdasarkan tanggal terbaru
      _pertemuan.sort((a, b) => b.tanggal.compareTo(a.tanggal));

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CREATE MANY
  // ============================================================

  Future<bool> createManyPertemuan(List<BbaqPertemuanModel> models) async {
    if (models.isEmpty) {
      return true;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.createManyPertemuan(models);

      _pertemuan.addAll(result);

      // Urutkan berdasarkan tanggal terbaru
      _pertemuan.sort((a, b) => b.tanggal.compareTo(a.tanggal));

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> updatePertemuan(BbaqPertemuanModel model) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.updatePertemuan(model);

      final index = _pertemuan.indexWhere((item) => item.id == model.id);

      if (index != -1) {
        _pertemuan[index] = result;

        _pertemuan.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> deletePertemuan(String id) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.deletePertemuan(id);

      _pertemuan.removeWhere((item) => item.id == id);

      return true;
    } catch (e) {
      _errorMessage = e.toString();

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
    if (_programId == null) {
      return;
    }

    await loadData(
      programId: _programId!,
      kelasPengajaranId: _kelasPengajaranId,
    );
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR DATA
  // ============================================================

  void clear() {
    _pertemuan = [];
    _pengajar = [];

    _programId = null;
    _kelasPengajaranId = null;

    _errorMessage = null;

    notifyListeners();
  }
}

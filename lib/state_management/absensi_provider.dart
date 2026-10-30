import 'package:flutter/foundation.dart';

import '../models/absensi/absensi_model.dart';
import '../services/absensi_service.dart';

class AbsensiProvider extends ChangeNotifier {
  final AbsensiService _service = AbsensiService();

  // ============================================================
  // STATE
  // ============================================================

  List<AbsensiModel> _items = [];

  bool _isLoading = false;
  bool _isSaving = false;

  String? _errorMessage;

  // ============================================================
  // GETTER
  // ============================================================

  List<AbsensiModel> get items => _items;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  bool get hasData => _items.isNotEmpty;

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<void> loadAll() async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getAll();
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<AbsensiModel?> getById(String id) async {
    _clearError();

    try {
      return await _service.getById(id);
    } catch (e) {
      _errorMessage = _cleanError(e);
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // LOAD BY SANTRI
  // ============================================================

  Future<void> loadBySantri(String santriId) async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getBySantri(santriId);
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD BY SANTRI PROGRAM
  // ============================================================

  Future<void> loadBySantriProgram(String santriProgramId) async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getBySantriProgram(santriProgramId);
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD BY PENGAJAR
  // ============================================================

  Future<void> loadByPengajar(String pengajarId) async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getByPengajar(pengajarId);
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD BY USER
  // ============================================================

  Future<void> loadByUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getByUser(userId);
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD BY CREATED BY
  // ============================================================

  Future<void> loadByCreatedBy(String profileId) async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getByCreatedBy(profileId);
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD BY TANGGAL
  // ============================================================

  Future<void> loadByTanggal(DateTime tanggal) async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getByTanggal(tanggal);
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD BY RANGE TANGGAL
  // ============================================================

  Future<void> loadByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD BY STATUS
  // ============================================================

  Future<void> loadByStatus(String status) async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getByStatus(status);
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD BY PROGRAM
  // ============================================================

  Future<void> loadByProgram(String programId) async {
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getByProgram(programId);
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<bool> create(AbsensiModel data) async {
    _setSaving(true);
    _clearError();

    try {
      final created = await _service.create(data);

      _items.insert(0, created);

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> update(AbsensiModel data) async {
    _setSaving(true);
    _clearError();

    try {
      final updated = await _service.update(data);

      final index = _items.indexWhere((item) => item.id == data.id);

      if (index != -1) {
        _items[index] = updated;
      }

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> delete(String id) async {
    _setSaving(true);
    _clearError();

    try {
      await _service.delete(id);

      _items.removeWhere((item) => item.id == id);

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    await loadAll();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _items = [];
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ============================================================
  // PRIVATE
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

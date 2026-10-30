import 'package:flutter/foundation.dart';

import '../models/pengajar_program/pengajar_program_model.dart';
import '../services/pengajar_program_service.dart';

class PengajarProgramProvider extends ChangeNotifier {
  final PengajarProgramService _service = PengajarProgramService();

  // ============================================================
  // STATE
  // ============================================================

  List<PengajarProgramModel> _items = [];

  List<PengajarProgramModel> get items => _items;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _isSaving = false;

  bool get isSaving => _isSaving;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  String? _successMessage;

  String? get successMessage => _successMessage;

  // ============================================================
  // DATA PENGAJAR BERDASARKAN PROGRAM
  // ============================================================

  List<Map<String, dynamic>> _pengajarByProgram = [];

  List<Map<String, dynamic>> get pengajarByProgram => _pengajarByProgram;

  bool _isLoadingPengajar = false;

  bool get isLoadingPengajar => _isLoadingPengajar;

  // ============================================================
  // PROGRAM MILIK PENGAJAR
  // ============================================================

  List<PengajarProgramModel> _programByPengajar = [];

  List<PengajarProgramModel> get programByPengajar => _programByPengajar;

  bool _isLoadingProgram = false;

  bool get isLoadingProgram => _isLoadingProgram;

  // ============================================================
  // CLEAR ERROR / MESSAGE
  // ============================================================

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ============================================================
  // GET ALL
  // ============================================================

  Future<void> loadAll() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _items = await _service.getAll();
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // GET PROGRAM BERDASARKAN PENGAJAR
  // ============================================================

  Future<void> loadByPengajar(String pengajarId) async {
    _isLoadingProgram = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _programByPengajar = await _service.getByPengajar(pengajarId);
    } catch (e) {
      _errorMessage = _cleanError(e);
      _programByPengajar = [];
    } finally {
      _isLoadingProgram = false;
      notifyListeners();
    }
  }

  // ============================================================
  // GET PENGAJAR BERDASARKAN PROGRAM
  //
  // Ini yang akan digunakan oleh:
  //
  // Program → Pengajar
  //
  // Contoh:
  // Tahfidz → Ust. Ahmad, Ust. Ali
  // BBAQ    → Ust. Ahmad, Ust. Budi
  // ============================================================

  Future<void> loadPengajarByProgram(String programId) async {
    _isLoadingPengajar = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _pengajarByProgram = await _service.getPengajarByProgram(programId);
    } catch (e) {
      _errorMessage = _cleanError(e);
      _pengajarByProgram = [];
    } finally {
      _isLoadingPengajar = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR PENGAJAR BERDASARKAN PROGRAM
  // ============================================================

  void clearPengajarByProgram() {
    _pengajarByProgram = [];
    notifyListeners();
  }

  // ============================================================
  // CLEAR PROGRAM BERDASARKAN PENGAJAR
  // ============================================================

  void clearProgramByPengajar() {
    _programByPengajar = [];
    notifyListeners();
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<bool> create({
    required String pengajarId,
    required String programId,
  }) async {
    _setSaving(true);

    _errorMessage = null;
    _successMessage = null;

    try {
      final item = await _service.create(
        pengajarId: pengajarId,
        programId: programId,
      );

      _items.insert(0, item);

      _successMessage = 'Program berhasil ditambahkan ke pengajar.';

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // CREATE MANY
  // ============================================================

  Future<bool> createMany({
    required String pengajarId,
    required List<String> programIds,
  }) async {
    _setSaving(true);

    _errorMessage = null;
    _successMessage = null;

    try {
      await _service.createMany(pengajarId: pengajarId, programIds: programIds);

      _successMessage = 'Program pengajar berhasil diperbarui.';

      await loadAll();

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // SYNC PROGRAM
  //
  // Digunakan ketika user memilih beberapa program sekaligus.
  //
  // Contoh sebelumnya:
  //
  // ☑ Tahfidz
  // ☑ BBAQ
  // ☐ Tilawati
  //
  // kemudian klik Simpan.
  // ============================================================

  Future<bool> syncPrograms({
    required String pengajarId,
    required List<String> programIds,
  }) async {
    _setSaving(true);

    _errorMessage = null;
    _successMessage = null;

    try {
      await _service.syncPrograms(
        pengajarId: pengajarId,
        programIds: programIds,
      );

      _successMessage = 'Program pengajar berhasil diperbarui.';

      await loadByPengajar(pengajarId);

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

    _errorMessage = null;
    _successMessage = null;

    try {
      await _service.delete(id);

      _items.removeWhere((item) => item.id == id);

      _successMessage = 'Program berhasil dihapus dari pengajar.';

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // DELETE BERDASARKAN PENGAJAR + PROGRAM
  // ============================================================

  Future<bool> deleteByPengajarAndProgram({
    required String pengajarId,
    required String programId,
  }) async {
    _setSaving(true);

    _errorMessage = null;
    _successMessage = null;

    try {
      await _service.deleteByPengajarAndProgram(
        pengajarId: pengajarId,
        programId: programId,
      );

      _items.removeWhere(
        (item) => item.pengajarId == pengajarId && item.programId == programId,
      );

      _programByPengajar.removeWhere((item) => item.programId == programId);

      _pengajarByProgram.removeWhere(
        (item) => item['id']?.toString() == pengajarId,
      );

      _successMessage = 'Relasi pengajar-program berhasil dihapus.';

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // CHECK EXISTS
  // ============================================================

  Future<bool> exists({
    required String pengajarId,
    required String programId,
  }) async {
    try {
      return await _service.exists(
        pengajarId: pengajarId,
        programId: programId,
      );
    } catch (e) {
      _errorMessage = _cleanError(e);

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // SET LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ============================================================
  // SET SAVING
  // ============================================================

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}

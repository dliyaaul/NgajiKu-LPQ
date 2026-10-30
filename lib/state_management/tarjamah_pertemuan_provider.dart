import 'package:flutter/foundation.dart';

import 'package:ptl_mobile/models/absensi_tarjamah/tarjamah_pertemuan_model.dart';
import 'package:ptl_mobile/models/pengajar_program/pengajar_program_model.dart';
import 'package:ptl_mobile/services/tarjamah_pertemuan_service.dart';

class TarjamahPertemuanProvider extends ChangeNotifier {
  final TarjamahPertemuanService _service = TarjamahPertemuanService();

  // STATE

  List<TarjamahPertemuanModel> _pertemuan = [];

  List<PengajarProgramModel> _pengajar = [];

  List<Map<String, dynamic>> _kelasPengajaran = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingPengajar = false;
  bool _isLoadingKelas = false;

  String? _errorMessage;

  String? _programId;
  String? _kelasPengajaranId;

  // GETTER

  List<TarjamahPertemuanModel> get pertemuan => List.unmodifiable(_pertemuan);

  List<PengajarProgramModel> get pengajar => List.unmodifiable(_pengajar);

  List<Map<String, dynamic>> get kelasPengajaran =>
      List.unmodifiable(_kelasPengajaran);

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  bool get isLoadingPengajar => _isLoadingPengajar;

  bool get isLoadingKelas => _isLoadingKelas;

  String? get errorMessage => _errorMessage;

  String? get programId => _programId;

  String? get kelasPengajaranId => _kelasPengajaranId;

  bool get hasData => _pertemuan.isNotEmpty;

  String? get currentUserId => _service.currentUserId;

  // LOAD PERTEMUAN

  Future<void> loadPertemuan({
    required String programId,
    String? kelasPengajaranId,
  }) async {
    _programId = programId;
    _kelasPengajaranId = kelasPengajaranId;

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.getPertemuanByProgram(
        programId,
        kelasPengajaranId: kelasPengajaranId,
      );

      _pertemuan = List<TarjamahPertemuanModel>.from(result);

      _sortPertemuan();
    } catch (e) {
      _errorMessage = e.toString();

      debugPrint('ERROR LOAD PERTEMUAN TARJAMAH: $_errorMessage');
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // LOAD KELAS PENGAJARAN

  Future<void> loadKelasPengajaranByProgram({required String programId}) async {
    _isLoadingKelas = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _kelasPengajaran = await _service.getKelasPengajaranByProgram(programId);
    } catch (e) {
      _errorMessage = e.toString();

      debugPrint('ERROR LOAD KELAS TARJAMAH: $_errorMessage');
    } finally {
      _isLoadingKelas = false;

      notifyListeners();
    }
  }

  // LOAD PENGAJAR

  Future<void> loadPengajarByProgram({required String programId}) async {
    if (_isLoadingPengajar) {
      debugPrint(
        'LOAD PENGAJAR TARJAMAH DIBATALKAN '
        'karena masih loading.',
      );

      return;
    }

    _isLoadingPengajar = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _pengajar = await _service.getPengajarByProgram(programId);
    } catch (e) {
      _errorMessage = e.toString();

      debugPrint('ERROR LOAD PENGAJAR TARJAMAH: $_errorMessage');
    } finally {
      _isLoadingPengajar = false;

      notifyListeners();
    }
  }

  // LOAD SEMUA DATA

  Future<void> loadData({
    required String programId,
    String? kelasPengajaranId,
  }) async {
    _programId = programId;
    _kelasPengajaranId = kelasPengajaranId;

    _isLoading = true;
    _isLoadingPengajar = true;
    _isLoadingKelas = true;

    _errorMessage = null;

    _pertemuan = [];
    _pengajar = [];
    _kelasPengajaran = [];

    notifyListeners();

    try {
      // Load pertemuan.
      _pertemuan = await _service.getPertemuanByProgram(
        programId,
        kelasPengajaranId: kelasPengajaranId,
      );

      _sortPertemuan();

      // Load pengajar program.
      _pengajar = await _service.getPengajarByProgram(programId);

      // Load kelas pengajaran program.
      _kelasPengajaran = await _service.getKelasPengajaranByProgram(programId);
    } catch (e) {
      _errorMessage = e.toString();

      debugPrint('ERROR LOAD DATA TARJAMAH: $_errorMessage');
    } finally {
      _isLoading = false;
      _isLoadingPengajar = false;
      _isLoadingKelas = false;

      notifyListeners();
    }
  }

  // GET PERTEMUAN BY ID

  Future<TarjamahPertemuanModel?> getPertemuanById(String id) async {
    try {
      return await _service.getPertemuanById(id);
    } catch (e) {
      _errorMessage = e.toString();

      debugPrint('ERROR GET PERTEMUAN TARJAMAH: $_errorMessage');

      notifyListeners();

      return null;
    }
  }

  // CREATE

  Future<bool> createPertemuan(TarjamahPertemuanModel model) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.createPertemuan(model);

      // Tambahkan ke list hanya jika sesuai filter aktif.
      final isSameProgram = result.programId == _programId;

      final isSameClass =
          _kelasPengajaranId == null ||
          result.kelasPengajaranId == _kelasPengajaranId;

      if (isSameProgram && isSameClass) {
        _pertemuan.add(result);
        _sortPertemuan();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      debugPrint('ERROR CREATE PERTEMUAN TARJAMAH: $_errorMessage');

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // CREATE MANY

  Future<bool> createManyPertemuan(List<TarjamahPertemuanModel> models) async {
    if (models.isEmpty) {
      return true;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.createManyPertemuan(models);

      final filteredResult = result.where((item) {
        final isSameProgram = item.programId == _programId;

        final isSameClass =
            _kelasPengajaranId == null ||
            item.kelasPengajaranId == _kelasPengajaranId;

        return isSameProgram && isSameClass;
      });

      _pertemuan.addAll(filteredResult);

      _sortPertemuan();

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      debugPrint('ERROR CREATE MANY TARJAMAH: $_errorMessage');

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // UPDATE

  Future<bool> updatePertemuan(TarjamahPertemuanModel model) async {
    if (!model.canEdit) {
      _errorMessage = 'Pertemuan sudah melewati batas waktu edit 24 jam.';

      notifyListeners();

      return false;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.updatePertemuan(model);

      final index = _pertemuan.indexWhere((item) => item.id == model.id);

      if (index != -1) {
        // Jika kelas berubah, item mungkin tidak lagi
        // sesuai dengan filter kelas yang sedang aktif.
        final isSameClass =
            _kelasPengajaranId == null ||
            result.kelasPengajaranId == _kelasPengajaranId;

        if (isSameClass) {
          _pertemuan[index] = result;
        } else {
          _pertemuan.removeAt(index);
        }

        _sortPertemuan();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      debugPrint('ERROR UPDATE PERTEMUAN TARJAMAH: $_errorMessage');

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // DELETE

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

      debugPrint('ERROR DELETE PERTEMUAN TARJAMAH: $_errorMessage');

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // REFRESH

  Future<void> refresh() async {
    if (_programId == null || _programId!.trim().isEmpty) {
      return;
    }

    await loadData(
      programId: _programId!,
      kelasPengajaranId: _kelasPengajaranId,
    );
  }

  // SORT

  void _sortPertemuan() {
    _pertemuan.sort((a, b) => b.tanggal.compareTo(a.tanggal));
  }

  // CLEAR ERROR

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }

  // CLEAR

  void clear() {
    _pertemuan = [];
    _pengajar = [];
    _kelasPengajaran = [];

    _programId = null;
    _kelasPengajaranId = null;

    _errorMessage = null;

    _isLoading = false;
    _isSaving = false;
    _isLoadingPengajar = false;
    _isLoadingKelas = false;

    notifyListeners();
  }
}

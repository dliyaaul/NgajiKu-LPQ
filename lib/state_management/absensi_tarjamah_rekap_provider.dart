import 'package:flutter/foundation.dart';

import 'package:ptl_mobile/models/absensi_tarjamah/tarjamah_rekap_model.dart';
import 'package:ptl_mobile/services/absensi_tarjamah_rekap_service.dart';

class AbsensiTarjamahRekapProvider extends ChangeNotifier {
  final AbsensiTarjamahRekapService _service = AbsensiTarjamahRekapService();
  final String kelasPengajaranId;

  AbsensiTarjamahRekapProvider({required this.kelasPengajaranId});

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;

  String? _errorMessage;

  String? _programId;

  List<Map<String, dynamic>> _pengajarList = [];

  List<TarjamahRekapModel> _rekapList = [];

  List<DateTime> _tanggalList = [];

  // ============================================================
  // FILTER
  // ============================================================

  String? _selectedPengajarId;

  String? _selectedPengajarName;

  DateTime _dariTanggal = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  DateTime _sampaiTanggal = DateTime.now();

  // ============================================================
  // GETTER
  // ============================================================

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get programId => _programId;

  List<Map<String, dynamic>> get pengajarList =>
      List.unmodifiable(_pengajarList);

  List<TarjamahRekapModel> get rekapList => List.unmodifiable(_rekapList);

  List<DateTime> get tanggalList => List.unmodifiable(_tanggalList);

  String? get selectedPengajarId => _selectedPengajarId;

  String? get selectedPengajarName => _selectedPengajarName;

  DateTime get dariTanggal => _dariTanggal;

  DateTime get sampaiTanggal => _sampaiTanggal;

  bool get hasData => _rekapList.isNotEmpty && _tanggalList.isNotEmpty;

  // ============================================================
  // NAMA PENGAJAR
  // ============================================================

  String get namaPengajar {
    if (_selectedPengajarName == null ||
        _selectedPengajarName!.trim().isEmpty) {
      return 'Semua Pengajar';
    }

    return _selectedPengajarName!;
  }

  // ============================================================
  // SET PENGAJAR
  // ============================================================

  void setPengajar(String? pengajarId) {
    _selectedPengajarId = pengajarId;

    if (pengajarId == null || pengajarId.trim().isEmpty) {
      _selectedPengajarName = null;
    } else {
      final pengajar = _pengajarList.cast<Map<String, dynamic>?>().firstWhere(
        (item) => item?['id']?.toString() == pengajarId,
        orElse: () => null,
      );

      _selectedPengajarName = pengajar?['username']?.toString();
    }

    notifyListeners();
  }

  // ============================================================
  // SET DARI TANGGAL
  // ============================================================

  void setDariTanggal(DateTime tanggal) {
    _dariTanggal = DateTime(tanggal.year, tanggal.month, tanggal.day);

    notifyListeners();
  }

  // ============================================================
  // SET SAMPAI TANGGAL
  // ============================================================

  void setSampaiTanggal(DateTime tanggal) {
    _sampaiTanggal = DateTime(tanggal.year, tanggal.month, tanggal.day);

    notifyListeners();
  }

  // ============================================================
  // LOAD PENGAJAR
  // ============================================================

  Future<void> loadPengajarByProgram(String programId) async {
    if (programId.trim().isEmpty) {
      _errorMessage = 'Program tidak valid.';
      notifyListeners();
      return;
    }

    _programId = programId;
    _errorMessage = null;

    try {
      _pengajarList = await _service.getPengajarTarjamahByProgram(
        programId,
        kelasPengajaranId: kelasPengajaranId,
      );

      // ----------------------------------------------------------
      // Pastikan selected pengajar masih tersedia
      // ----------------------------------------------------------

      if (_selectedPengajarId != null) {
        final exists = _pengajarList.any(
          (item) => item['id']?.toString() == _selectedPengajarId,
        );

        if (!exists) {
          _selectedPengajarId = null;
          _selectedPengajarName = null;
        }
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = _cleanError(e);
      _pengajarList = [];

      notifyListeners();
    }
  }

  // ============================================================
  // LOAD REKAP
  // ============================================================

  Future<void> loadRekap() async {
    // ----------------------------------------------------------
    // Validasi program
    // ----------------------------------------------------------

    if (_programId == null || _programId!.trim().isEmpty) {
      _errorMessage = 'Program belum dipilih.';
      _rekapList = [];
      _tanggalList = [];

      notifyListeners();
      return;
    }

    // ----------------------------------------------------------
    // Validasi tanggal
    // ----------------------------------------------------------

    if (_dariTanggal.isAfter(_sampaiTanggal)) {
      _errorMessage =
          'Tanggal mulai tidak boleh lebih besar dari tanggal akhir.';

      _rekapList = [];
      _tanggalList = [];

      notifyListeners();
      return;
    }

    try {
      _setLoading(true);

      _errorMessage = null;

      // --------------------------------------------------------
      // Ambil tanggal pertemuan
      // --------------------------------------------------------

      final tanggal = await _service.getTanggalTarjamah(
        programId: _programId!,
        kelasPengajaranId: kelasPengajaranId,
        dariTanggal: _dariTanggal,
        sampaiTanggal: _sampaiTanggal,
        pengajarId: _selectedPengajarId,
      );

      // --------------------------------------------------------
      // Ambil rekap
      // --------------------------------------------------------

      final rekap = await _service.getRekapTarjamah(
        programId: _programId!,
        kelasPengajaranId: kelasPengajaranId,
        dariTanggal: _dariTanggal,
        sampaiTanggal: _sampaiTanggal,
        pengajarId: _selectedPengajarId,
      );

      _tanggalList = tanggal;
      _rekapList = rekap;

      notifyListeners();
    } catch (e) {
      _errorMessage = _cleanError(e);

      _rekapList = [];
      _tanggalList = [];

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD DETAIL ABSENSI
  // ============================================================

  Future<List<Map<String, dynamic>>> loadDetailAbsensi() async {
    if (_programId == null || _programId!.isEmpty) {
      return [];
    }

    try {
      return await _service.getDetailAbsensiTarjamah(
        programId: _programId!,
        kelasPengajaranId: kelasPengajaranId,
        dariTanggal: _dariTanggal,
        sampaiTanggal: _sampaiTanggal,
        pengajarId: _selectedPengajarId,
      );
    } catch (e) {
      _errorMessage = _cleanError(e);
      notifyListeners();
      return [];
    }
  }

  // ============================================================
  // LOAD PERTEMUAN
  // ============================================================

  Future<List<Map<String, dynamic>>> loadPertemuan() async {
    if (_programId == null || _programId!.trim().isEmpty) {
      _errorMessage = 'Program belum dipilih.';
      notifyListeners();

      return [];
    }

    if (_dariTanggal.isAfter(_sampaiTanggal)) {
      _errorMessage =
          'Tanggal mulai tidak boleh lebih besar dari tanggal akhir.';

      notifyListeners();

      return [];
    }

    try {
      return await _service.getPertemuanTarjamah(
        programId: _programId!,
        kelasPengajaranId: kelasPengajaranId,
        dariTanggal: _dariTanggal,
        sampaiTanggal: _sampaiTanggal,
        pengajarId: _selectedPengajarId,
      );
    } catch (e) {
      _errorMessage = _cleanError(e);

      notifyListeners();

      return [];
    }
  }

  // ============================================================
  // RESET FILTER
  // ============================================================

  void resetFilter() {
    _selectedPengajarId = null;
    _selectedPengajarName = null;

    _dariTanggal = DateTime(DateTime.now().year, DateTime.now().month, 1);

    _sampaiTanggal = DateTime.now();

    clearData(notify: false);

    notifyListeners();
  }

  // ============================================================
  // CLEAR DATA
  // ============================================================

  void clearData({bool notify = true}) {
    _rekapList = [];
    _tanggalList = [];
    _errorMessage = null;

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get jumlahSantri {
    return _rekapList.length;
  }

  int get jumlahPertemuan {
    return _tanggalList.length;
  }

  int get totalHadir {
    return _rekapList.fold(0, (total, item) => total + item.totalHadir);
  }

  int get totalIzin {
    return _rekapList.fold(0, (total, item) => total + item.totalIzin);
  }

  int get totalSakit {
    return _rekapList.fold(0, (total, item) => total + item.totalSakit);
  }

  int get totalAlpa {
    return _rekapList.fold(0, (total, item) => total + item.totalAlpa);
  }

  int get totalAbsensi {
    return totalHadir + totalIzin + totalSakit + totalAlpa;
  }

  double get persentaseKehadiran {
    if (totalAbsensi == 0) {
      return 0;
    }

    return (totalHadir / totalAbsensi) * 100;
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ============================================================
  // ERROR CLEANER
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pengajarList.clear();
    _rekapList.clear();
    _tanggalList.clear();

    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

import '../../models/absensi_tahfidz/absensi_tahfidz_rekap_model.dart';
import '../../services/absensi_tahfidz_rekap_service.dart';

class AbsensiTahfidzRekapProvider extends ChangeNotifier {
  final AbsensiTahfidzRekapService _service = AbsensiTahfidzRekapService();

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  // ============================================================
  // PROGRAM DAN KELAS PENGAJARAN
  // ============================================================

  String? _programId;

  String? get programId => _programId;

  String? _kelasPengajaranId;

  String? get kelasPengajaranId => _kelasPengajaranId;

  // ============================================================
  // DATA PENGAJAR
  // ============================================================

  List<Map<String, dynamic>> _pengajarList = [];

  List<Map<String, dynamic>> get pengajarList => _pengajarList;

  // ============================================================
  // DATA REKAP
  // ============================================================

  List<AbsensiTahfidzRekapModel> _rekapList = [];

  List<AbsensiTahfidzRekapModel> get rekapList => _rekapList;

  // ============================================================
  // TANGGAL
  // ============================================================

  List<DateTime> _tanggalList = [];

  List<DateTime> get tanggalList => _tanggalList;

  // ============================================================
  // FILTER PENGAJAR
  // ============================================================

  String? _selectedPengajarId;

  String? get selectedPengajarId => _selectedPengajarId;

  String? _selectedPengajarName;

  String? get selectedPengajarName => _selectedPengajarName;

  // ============================================================
  // FILTER TANGGAL
  // ============================================================

  DateTime _dariTanggal = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  DateTime get dariTanggal => _dariTanggal;

  DateTime _sampaiTanggal = DateTime.now();

  DateTime get sampaiTanggal => _sampaiTanggal;

  // ============================================================
  // SET PROGRAM DAN KELAS
  // ============================================================

  void setProgramDanKelas({
    required String programId,
    required String kelasPengajaranId,
  }) {
    final isChanged =
        _programId != programId || _kelasPengajaranId != kelasPengajaranId;

    _programId = programId;
    _kelasPengajaranId = kelasPengajaranId;

    if (isChanged) {
      _selectedPengajarId = null;
      _selectedPengajarName = null;

      _pengajarList = [];
      _rekapList = [];
      _tanggalList = [];

      _errorMessage = null;
    }

    notifyListeners();
  }

  // ============================================================
  // SET FILTER PENGAJAR
  // ============================================================

  void setPengajar(String? pengajarId) {
    _selectedPengajarId = pengajarId;

    if (pengajarId == null || pengajarId.isEmpty) {
      _selectedPengajarName = null;
    } else {
      final pengajar = _pengajarList.where(
        (item) => item['id']?.toString() == pengajarId,
      );

      if (pengajar.isNotEmpty) {
        _selectedPengajarName = pengajar.first['username']?.toString();
      } else {
        _selectedPengajarName = null;
      }
    }

    // Data rekap lama tidak lagi sesuai filter pengajar.
    _rekapList = [];
    _tanggalList = [];

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // SET DARI TANGGAL
  // ============================================================

  void setDariTanggal(DateTime tanggal) {
    _dariTanggal = DateTime(tanggal.year, tanggal.month, tanggal.day);

    // Reset rekap karena rentang tanggal berubah.
    _rekapList = [];
    _tanggalList = [];

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // SET SAMPAI TANGGAL
  // ============================================================

  void setSampaiTanggal(DateTime tanggal) {
    _sampaiTanggal = DateTime(tanggal.year, tanggal.month, tanggal.day);

    // Reset rekap karena rentang tanggal berubah.
    _rekapList = [];
    _tanggalList = [];

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // LOAD DAFTAR PENGAJAR
  // ============================================================

  Future<void> loadPengajarByProgram(
    String programId,
    String kelasPengajaranId,
  ) async {
    try {
      _setLoading(true);

      _errorMessage = null;

      // Simpan program dan kelas yang sedang digunakan.
      _programId = programId;
      _kelasPengajaranId = kelasPengajaranId;

      // Ambil daftar pengajar sesuai program dan kelas.
      final result = await _service.getPengajarTahfidzByProgram(
        programId,
        kelasPengajaranId,
      );

      _pengajarList = result;

      // Pastikan pengajar yang terpilih masih tersedia
      // pada kelas yang sedang dibuka.
      final selectedPengajarIsValid = _pengajarList.any(
        (item) => item['id']?.toString() == _selectedPengajarId,
      );

      if (!selectedPengajarIsValid) {
        _selectedPengajarId = null;
        _selectedPengajarName = null;
      } else {
        final selectedPengajar = _pengajarList.firstWhere(
          (item) => item['id']?.toString() == _selectedPengajarId,
        );

        _selectedPengajarName = selectedPengajar['username']?.toString();
      }
    } catch (e) {
      _errorMessage = e.toString();

      _pengajarList = [];
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD REKAP
  // ============================================================

  Future<void> loadRekap() async {
    // ----------------------------------------------------------
    // Validasi program.
    // ----------------------------------------------------------

    if (_programId == null || _programId!.isEmpty) {
      _errorMessage = 'Program Tahfidz belum dipilih.';

      _rekapList = [];
      _tanggalList = [];

      notifyListeners();
      return;
    }

    // ----------------------------------------------------------
    // Validasi kelas pengajaran.
    // ----------------------------------------------------------

    if (_kelasPengajaranId == null || _kelasPengajaranId!.isEmpty) {
      _errorMessage = 'Kelas pengajaran belum dipilih.';

      _rekapList = [];
      _tanggalList = [];

      notifyListeners();
      return;
    }

    // ----------------------------------------------------------
    // Validasi rentang tanggal.
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
      // Ambil tanggal absensi sesuai program dan kelas.
      // --------------------------------------------------------

      final tanggal = await _service.getTanggalTahfidz(
        programId: _programId!,
        kelasPengajaranId: _kelasPengajaranId!,
        dariTanggal: _dariTanggal,
        sampaiTanggal: _sampaiTanggal,
        pengajarId: _selectedPengajarId,
      );

      // --------------------------------------------------------
      // Ambil rekap santri sesuai program dan kelas.
      // --------------------------------------------------------

      final rekap = await _service.getRekapTahfidz(
        programId: _programId!,
        kelasPengajaranId: _kelasPengajaranId!,
        dariTanggal: _dariTanggal,
        sampaiTanggal: _sampaiTanggal,
        pengajarId: _selectedPengajarId,
      );

      // --------------------------------------------------------
      // Simpan hasil.
      // --------------------------------------------------------

      _tanggalList = tanggal;
      _rekapList = rekap;

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();

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
    // ----------------------------------------------------------
    // Validasi program dan kelas.
    // ----------------------------------------------------------

    if (_programId == null || _programId!.isEmpty) {
      _errorMessage = 'Program Tahfidz belum dipilih.';

      notifyListeners();
      return [];
    }

    if (_kelasPengajaranId == null || _kelasPengajaranId!.isEmpty) {
      _errorMessage = 'Kelas pengajaran belum dipilih.';

      notifyListeners();
      return [];
    }

    // ----------------------------------------------------------
    // Validasi tanggal.
    // ----------------------------------------------------------

    if (_dariTanggal.isAfter(_sampaiTanggal)) {
      _errorMessage =
          'Tanggal mulai tidak boleh lebih besar dari tanggal akhir.';

      notifyListeners();
      return [];
    }

    try {
      _errorMessage = null;

      // --------------------------------------------------------
      // Ambil detail absensi sesuai program, kelas, pengajar,
      // dan rentang tanggal.
      // --------------------------------------------------------

      final detail = await _service.getDetailAbsensiTahfidz(
        programId: _programId!,
        kelasPengajaranId: _kelasPengajaranId!,
        dariTanggal: _dariTanggal,
        sampaiTanggal: _sampaiTanggal,
        pengajarId: _selectedPengajarId,
      );

      return detail;
    } catch (e) {
      _errorMessage = e.toString();

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

    _rekapList = [];
    _tanggalList = [];

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR DATA
  // ============================================================

  void clearData() {
    _rekapList = [];
    _tanggalList = [];

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR SEMUA DATA DAN FILTER
  // ============================================================

  void clearAll() {
    _programId = null;
    _kelasPengajaranId = null;

    _pengajarList = [];

    _rekapList = [];
    _tanggalList = [];

    _selectedPengajarId = null;
    _selectedPengajarName = null;

    _dariTanggal = DateTime(DateTime.now().year, DateTime.now().month, 1);

    _sampaiTanggal = DateTime.now();

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;

    notifyListeners();
  }

  // ============================================================
  // GET NAMA PENGAJAR
  // ============================================================

  String get namaPengajar {
    if (_selectedPengajarName == null ||
        _selectedPengajarName!.trim().isEmpty) {
      return 'Semua Pengajar';
    }

    return _selectedPengajarName!;
  }

  // ============================================================
  // JUMLAH SANTRI
  // ============================================================

  int get jumlahSantri => _rekapList.length;

  // ============================================================
  // JUMLAH TANGGAL / PERTEMUAN
  // ============================================================

  int get jumlahPertemuan => _tanggalList.length;

  // ============================================================
  // TOTAL HADIR
  // ============================================================

  int get totalHadir {
    return _rekapList.fold(0, (total, item) => total + item.totalHadir);
  }

  // ============================================================
  // TOTAL IZIN
  // ============================================================

  int get totalIzin {
    return _rekapList.fold(0, (total, item) => total + item.totalIzin);
  }

  // ============================================================
  // TOTAL SAKIT
  // ============================================================

  int get totalSakit {
    return _rekapList.fold(0, (total, item) => total + item.totalSakit);
  }

  // ============================================================
  // TOTAL ALPA
  // ============================================================

  int get totalAlpa {
    return _rekapList.fold(0, (total, item) => total + item.totalAlpa);
  }

  // ============================================================
  // TOTAL DATA ABSENSI
  // ============================================================

  int get totalAbsensi {
    return totalHadir + totalIzin + totalSakit + totalAlpa;
  }

  // ============================================================
  // PERSENTASE KEHADIRAN KESELURUHAN
  // ============================================================

  double get persentaseKehadiran {
    if (totalAbsensi == 0) {
      return 0;
    }

    return (totalHadir / totalAbsensi) * 100;
  }
}

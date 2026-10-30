import 'package:flutter/foundation.dart';

import 'package:ptl_mobile/models/absensi_bbaq/bbaq_rekap_model.dart';
import 'package:ptl_mobile/services/absensi_bbaq_rekap_service.dart';

class BbaqRekapProvider extends ChangeNotifier {
  final AbsensiBbaqRekapService _service = AbsensiBbaqRekapService();
  final String kelasPengajaranId;

  BbaqRekapProvider({required this.kelasPengajaranId});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _programId;
  String? get programId => _programId;

  List<Map<String, dynamic>> _pengajarList = [];
  List<Map<String, dynamic>> get pengajarList => _pengajarList;

  List<Map<String, dynamic>> _pertemuanList = [];
  List<Map<String, dynamic>> get pertemuanList => _pertemuanList;

  List<BbaqRekapModel> _rekapList = [];
  List<BbaqRekapModel> get rekapList => _rekapList;

  List<DateTime> _tanggalList = [];
  List<DateTime> get tanggalList => _tanggalList;

  String? _selectedPengajarId;
  String? get selectedPengajarId => _selectedPengajarId;

  String? _selectedPengajarName;
  String? get selectedPengajarName => _selectedPengajarName;

  DateTime _dariTanggal = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get dariTanggal => _dariTanggal;

  DateTime _sampaiTanggal = DateTime.now();
  DateTime get sampaiTanggal => _sampaiTanggal;

  void setPengajar(String? pengajarId) {
    _selectedPengajarId = pengajarId?.isEmpty == true ? null : pengajarId;
    final matches = _pengajarList.where(
      (item) => item['id']?.toString() == _selectedPengajarId,
    );
    _selectedPengajarName = matches.isEmpty
        ? null
        : matches.first['username']?.toString();
    notifyListeners();
  }

  void setDariTanggal(DateTime tanggal) {
    _dariTanggal = DateTime(tanggal.year, tanggal.month, tanggal.day);
    notifyListeners();
  }

  void setSampaiTanggal(DateTime tanggal) {
    _sampaiTanggal = DateTime(tanggal.year, tanggal.month, tanggal.day);
    notifyListeners();
  }

  Future<void> loadPengajarByProgram(String programId) async {
    _programId = programId;
    _errorMessage = null;
    try {
      _pengajarList = await _service.getPengajarBbaqByProgram(
        programId,
        kelasPengajaranId: kelasPengajaranId,
      );
    } catch (e) {
      _pengajarList = [];
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadRekap({required String programId}) async {
    _programId = programId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _service.getTanggalBbaq(
          programId: programId,
          kelasPengajaranId: kelasPengajaranId,
          dariTanggal: _dariTanggal,
          sampaiTanggal: _sampaiTanggal,
          pengajarId: _selectedPengajarId,
        ),
        _service.getRekapBbaq(
          programId: programId,
          kelasPengajaranId: kelasPengajaranId,
          dariTanggal: _dariTanggal,
          sampaiTanggal: _sampaiTanggal,
          pengajarId: _selectedPengajarId,
        ),
        _service.getPertemuanBbaq(
          programId: programId,
          kelasPengajaranId: kelasPengajaranId,
          dariTanggal: _dariTanggal,
          sampaiTanggal: _sampaiTanggal,
          pengajarId: _selectedPengajarId,
        ),
      ]);
      _tanggalList = values[0] as List<DateTime>;
      _rekapList = values[1] as List<BbaqRekapModel>;
      _pertemuanList = values[2] as List<Map<String, dynamic>>;
    } catch (e) {
      _tanggalList = [];
      _rekapList = [];
      _pertemuanList = [];
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> loadDetailAbsensi() async {
    final programId = _programId;
    if (programId == null || programId.isEmpty) {
      _errorMessage = 'Program BBAQ belum dimuat.';
      notifyListeners();
      return [];
    }
    try {
      _errorMessage = null;
      return await _service.getDetailAbsensiBbaq(
        programId: programId,
        kelasPengajaranId: kelasPengajaranId,
        dariTanggal: _dariTanggal,
        sampaiTanggal: _sampaiTanggal,
        pengajarId: _selectedPengajarId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  void resetFilter() {
    _selectedPengajarId = null;
    _selectedPengajarName = null;
    _dariTanggal = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _sampaiTanggal = DateTime.now();
    clearData();
  }

  void clearData() {
    _rekapList = [];
    _tanggalList = [];
    _pertemuanList = [];
    _errorMessage = null;
    notifyListeners();
  }

  String get namaPengajar =>
      _selectedPengajarName?.trim().isNotEmpty == true
          ? _selectedPengajarName!
          : 'Semua Pengajar';

  int get jumlahSantri => _rekapList.length;
  int get jumlahPertemuan => _tanggalList.length;
  int get totalHadir => _rekapList.fold(0, (sum, item) => sum + item.totalHadir);
  int get totalIzin => _rekapList.fold(0, (sum, item) => sum + item.totalIzin);
  int get totalSakit => _rekapList.fold(0, (sum, item) => sum + item.totalSakit);
  int get totalAlpa => _rekapList.fold(0, (sum, item) => sum + item.totalAlpa);
  int get totalAbsensi => totalHadir + totalIzin + totalSakit + totalAlpa;
  double get persentaseKehadiran =>
      totalAbsensi == 0 ? 0 : (totalHadir / totalAbsensi) * 100;
  bool get hasData => _rekapList.isNotEmpty;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

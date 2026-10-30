import 'package:flutter/foundation.dart';

import '../../models/pembayaran/tagihan_model.dart';
import '../../services/pembayaran/tagihan_service.dart';

class TagihanProvider extends ChangeNotifier {
  final TagihanService _service = TagihanService();

  List<TagihanModel> _items = [];
  TagihanModel? _detail;
  bool _isLoading = false;
  String? _errorMessage;

  List<TagihanModel> get items => List.unmodifiable(_items);
  TagihanModel? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TagihanModel> get tagihanBelumLunas => _items
      .where((item) => item.status != 'lunas' && item.status != 'dibatalkan')
      .toList();

  List<TagihanModel> get tagihanLunas =>
      _items.where((item) => item.status == 'lunas').toList();

  Future<void> loadTagihan() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _service.getTagihanSaya();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TagihanModel?> loadDetail(String tagihanId) async {
    _isLoading = true;
    _errorMessage = null;
    _detail = null;
    notifyListeners();

    try {
      _detail = await _service.getDetailTagihan(tagihanId);
      return _detail;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearDetail() {
    _detail = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

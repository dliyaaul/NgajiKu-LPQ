import 'package:flutter/foundation.dart';

import '../models/hadits/hadits_book_model.dart';
import '../services/hadits_service.dart';

class HaditsProvider extends ChangeNotifier {
  final HaditsService _haditsService = HaditsService();

  List<HaditsBookModel> _books = [];

  bool _isLoadingBooks = false;

  String? _errorMessage;

  List<HaditsBookModel> get books => _books;

  bool get isLoadingBooks => _isLoadingBooks;

  bool get hasBooksData => _books.isNotEmpty;

  String? get errorMessage => _errorMessage;

  Future<void> fetchBooks({bool forceRefresh = false}) async {
    if (_books.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoadingBooks = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _books = await _haditsService.getHaditsBooks();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingBooks = false;

      notifyListeners();
    }
  }

  Future<void> refreshBooks() async {
    await fetchBooks(forceRefresh: true);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

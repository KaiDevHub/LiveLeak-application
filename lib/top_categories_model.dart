// top_categories_model.dart

import 'package:flutter/foundation.dart';

class TopCategoriesModel extends ChangeNotifier {
  List<String> _categories = [];

  List<String> get categories => _categories;

  void updateCategories(List<String> newCategories) {
    _categories = newCategories;
    notifyListeners();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WindowsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> _itemDocs = [];

  List<DocumentSnapshot> get itemDocs {
    return _itemDocs;
  }

  void setItemDocs(List<DocumentSnapshot> docs) {
    _itemDocs = docs;
    notifyListeners();
  }
}

final itemsProvider =
    ChangeNotifierProvider<WindowsNotifier>((ref) => WindowsNotifier());

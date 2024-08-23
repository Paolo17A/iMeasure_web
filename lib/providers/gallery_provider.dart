import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GalleryNotifier extends ChangeNotifier {
  List<DocumentSnapshot> _galleryDocs = [];

  List<DocumentSnapshot> get galleryDocs {
    return _galleryDocs;
  }

  void setGalleryDocs(List<DocumentSnapshot> docs) {
    _galleryDocs = docs;
    notifyListeners();
  }
}

final galleryProvider =
    ChangeNotifierProvider<GalleryNotifier>((ref) => GalleryNotifier());

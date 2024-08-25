import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileImageURLNotifier extends ChangeNotifier {
  String profileImageURL = '';

  void removeImageURL() {
    profileImageURL = '';
    notifyListeners();
  }

  void setImageURL(String image) {
    profileImageURL = image;
    notifyListeners();
  }
}

final profileImageURLProvider =
    ChangeNotifierProvider<ProfileImageURLNotifier>((ref) {
  return ProfileImageURLNotifier();
});

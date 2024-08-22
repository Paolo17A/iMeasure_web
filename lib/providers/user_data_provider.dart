import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class UserDataNotifier extends ChangeNotifier {
  String userType = UserTypes.client;
  String profileImageURL = '';

  void setUserType(String type) {
    userType = type;
    notifyListeners();
  }

  void setProfileImage(String imageURL) {
    profileImageURL = imageURL;
    notifyListeners();
  }
}

final userDataProvider =
    ChangeNotifierProvider<UserDataNotifier>((ref) => UserDataNotifier());

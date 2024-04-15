import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsersNotifier extends ChangeNotifier {
  List<DocumentSnapshot> userDocs = [];

  void setUserDocs(List<DocumentSnapshot> users) {
    userDocs = users;
    notifyListeners();
  }
}

final usersProvider =
    ChangeNotifierProvider<UsersNotifier>((ref) => UsersNotifier());

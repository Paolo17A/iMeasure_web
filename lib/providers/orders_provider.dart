import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrdersNotifier extends ChangeNotifier {
  List<DocumentSnapshot> orderDocs = [];

  void setOrderDocs(List<DocumentSnapshot> orders) {
    orderDocs = orders;
    notifyListeners();
  }
}

final ordersProvider =
    ChangeNotifierProvider<OrdersNotifier>((ref) => OrdersNotifier());

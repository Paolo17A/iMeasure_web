import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class OrdersNotifier extends ChangeNotifier {
  List<DocumentSnapshot> orderDocs = [];

  void setOrderDocs(List<DocumentSnapshot> orders) {
    orderDocs = orders;
    notifyListeners();
  }

  void sortOrdersByDate() {
    orderDocs.sort((a, b) {
      DateTime aTime = (a[OrderFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[OrderFields.dateCreated] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });
    notifyListeners();
  }

  void sortOrdersByClientName(Map<String, String> orderIDandNameMap) {
    orderDocs.sort((a, b) {
      String aName = orderIDandNameMap[a.id] ?? '';
      String bName = orderIDandNameMap[b.id] ?? '';
      return aName.compareTo(bName);
    });
    notifyListeners();
  }
}

final ordersProvider =
    ChangeNotifierProvider<OrdersNotifier>((ref) => OrdersNotifier());

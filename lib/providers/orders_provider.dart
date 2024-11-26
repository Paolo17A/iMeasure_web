import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class OrdersNotifier extends ChangeNotifier {
  List<DocumentSnapshot> orderDocs = [];
  String sortingMethod = 'DATE';
  bool isChronological = false;

  void setOrderDocs(List<DocumentSnapshot> orders) {
    orderDocs = orders;
    notifyListeners();
  }

  void setOrderMethodAndSort(
      String method, Map<String, String> orderIDandNameMap) {
    sortingMethod = method;
    if (sortingMethod == 'DATE')
      sortFromLatestToEarliest();
    else if (sortingMethod == 'NAME') sortOrdersByClientName(orderIDandNameMap);
  }

  setIsChronological(bool value) {
    isChronological = value;
    isChronological ? sortFromEarliestToLatest() : sortFromLatestToEarliest();
    //notifyListeners();
  }

  sortFromLatestToEarliest() {
    orderDocs.sort((a, b) {
      DateTime aTime = (a[OrderFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[OrderFields.dateCreated] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });
    notifyListeners();
  }

  sortFromEarliestToLatest() {
    orderDocs.sort((a, b) {
      DateTime aTime = (a[OrderFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[OrderFields.dateCreated] as Timestamp).toDate();
      return aTime.compareTo(bTime);
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

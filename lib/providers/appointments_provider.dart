import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imeasure/utils/string_util.dart';

class AppointmentsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> _appointmentDocs = [];
  bool isChronological = false;

  List<DocumentSnapshot> get appointmentDocs {
    return _appointmentDocs;
  }

  void setAppointmentDocs(List<DocumentSnapshot> docs) {
    _appointmentDocs = docs;
    notifyListeners();
  }

  setIsChronological(bool value) {
    isChronological = value;
    isChronological ? sortFromEarliestToLatest() : sortFromLatestToEarliest();
    notifyListeners();
  }

  sortFromLatestToEarliest() {
    _appointmentDocs.sort((a, b) {
      DateTime aTime = (a[AppointmentFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[AppointmentFields.dateCreated] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });
  }

  sortFromEarliestToLatest() {
    _appointmentDocs.sort((a, b) {
      DateTime aTime = (a[AppointmentFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[AppointmentFields.dateCreated] as Timestamp).toDate();
      return aTime.compareTo(bTime);
    });
  }
}

final appointmentsProvider = ChangeNotifierProvider<AppointmentsNotifier>(
    (ref) => AppointmentsNotifier());

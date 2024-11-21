import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppointmentsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> _appointmentDocs = [];

  List<DocumentSnapshot> get appointmentDocs {
    return _appointmentDocs;
  }

  void setAppointmentDocs(List<DocumentSnapshot> docs) {
    _appointmentDocs = docs;
    notifyListeners();
  }
}

final appointmentsProvider = ChangeNotifierProvider<AppointmentsNotifier>(
    (ref) => AppointmentsNotifier());

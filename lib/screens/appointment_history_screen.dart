import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';
import 'package:intl/intl.dart';

import '../providers/loading_provider.dart';
import '../providers/user_data_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/text_widgets.dart';

class AppointmentHistoryScreen extends ConsumerStatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  ConsumerState<AppointmentHistoryScreen> createState() =>
      _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState
    extends ConsumerState<AppointmentHistoryScreen> {
  List<DocumentSnapshot> appointmentDocs = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        String userType = userData[UserFields.userType];
        ref.read(userDataProvider).setUserType(userType);
        if (ref.read(userDataProvider).userType == UserTypes.admin) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        appointmentDocs = await getAllUserAppointments();
        appointmentDocs.sort((a, b) {
          DateTime aTime =
              (a[AppointmentFields.dateCreated] as Timestamp).toDate();
          DateTime bTime =
              (b[AppointmentFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting your appointment history: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(userDataProvider);
    return Scaffold(
      appBar: topUserNavigator(context, path: GoRoutes.profile),
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          SingleChildScrollView(
            child: Column(
              children: [Divider(), _backButton(), _appointmentHistory()],
            ),
          )),
    );
  }

  Widget _backButton() {
    return all10Pix(
        child: Row(children: [
      backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.profile))
    ]));
  }

  Widget _appointmentHistory() {
    return horizontal5Percent(context,
        child: Column(
          children: [
            quicksandWhiteBold('APPOINTMENT HISTORY', fontSize: 40),
            appointmentDocs.isNotEmpty
                ? Row(
                    children: [
                      Wrap(
                        spacing: 40,
                        runSpacing: 40,
                        children: appointmentDocs
                            .map((appointmentDoc) =>
                                _appointmentEntry(appointmentDoc))
                            .toList(),
                      ),
                    ],
                  )
                : vertical20Pix(
                    child: quicksandWhiteBold(
                        'You have not yet made any appointments.'))
          ],
        ));
  }

  Widget _appointmentEntry(DocumentSnapshot appointmentDoc) {
    final appointmentData = appointmentDoc.data() as Map<dynamic, dynamic>;
    List<dynamic> proposedDates =
        appointmentData[AppointmentFields.proposedDates];
    DateTime selectedDate =
        (appointmentData[AppointmentFields.selectedDate] as Timestamp).toDate();
    String appointmentStatus =
        appointmentData[AppointmentFields.appointmentStatus];
    String denialReason = appointmentData[AppointmentFields.denialReason];
    return Container(
        width: 400,
        height: 150,
        decoration: BoxDecoration(border: Border.all(color: Colors.white)),
        padding: EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (appointmentStatus == AppointmentStatuses.approved)
            Wrap(children: [
              quicksandWhiteBold('Selected Date: '),
              quicksandWhiteRegular(
                  DateFormat('MMM dd, yyyy').format(selectedDate))
            ])
          else ...[
            quicksandWhiteBold('Requested Dates: '),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: proposedDates
                    .map((proposedDate) => quicksandWhiteRegular(
                        '\t\t${DateFormat('MMM dd, yyyy').format((proposedDate as Timestamp).toDate())}',
                        fontSize: 15,
                        textAlign: TextAlign.left))
                    .toList())
          ],
          Wrap(children: [
            quicksandWhiteBold('Status: '),
            quicksandWhiteRegular(appointmentStatus)
          ]),
          if (appointmentStatus == AppointmentStatuses.denied)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              quicksandWhiteBold('Denial Reason: '),
              quicksandWhiteRegular(denialReason,
                  textAlign: TextAlign.left,
                  textOverflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  fontSize: 14)
            ])
        ]));
  }
}

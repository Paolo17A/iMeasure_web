import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/appointments_provider.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:intl/intl.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/text_widgets.dart';

class ViewAppointmentsScreen extends ConsumerStatefulWidget {
  const ViewAppointmentsScreen({super.key});

  @override
  ConsumerState<ViewAppointmentsScreen> createState() =>
      _ViewAppointmentsScreenState();
}

class _ViewAppointmentsScreenState
    extends ConsumerState<ViewAppointmentsScreen> {
  final denialReasonController = TextEditingController();
  List<DocumentSnapshot> currentDisplayedAppointments = [];
  int currentPage = 0;
  int maxPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref
            .read(appointmentsProvider)
            .setAppointmentDocs(await getNotFinalizedAppointments());
        maxPage = (ref.read(appointmentsProvider).appointmentDocs.length / 10)
            .floor();
        if (ref.read(appointmentsProvider).appointmentDocs.length % 10 == 0)
          maxPage--;
        setDisplayedAppointments();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all appointments: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  void setDisplayedAppointments() {
    if (ref.read(appointmentsProvider).appointmentDocs.length > 10) {
      currentDisplayedAppointments = ref
          .read(appointmentsProvider)
          .appointmentDocs
          .getRange(
              currentPage * 10,
              min((currentPage * 10) + 10,
                  ref.read(appointmentsProvider).appointmentDocs.length))
          .toList();
    } else
      currentDisplayedAppointments =
          ref.read(appointmentsProvider).appointmentDocs;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(appointmentsProvider);
    setDisplayedAppointments();
    return Scaffold(
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftNavigator(context, path: GoRoutes.viewAppointments),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: horizontal5Percent(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _appointmentsHeader(),
                        _appointmentsContainer()
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _appointmentsHeader() {
    return vertical20Pix(
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                quicksandWhiteBold('APPOINTMENTS: ', fontSize: 36),
                quicksandCoralRedBold(
                    ref
                        .read(appointmentsProvider)
                        .appointmentDocs
                        .length
                        .toString(),
                    fontSize: 36)
              ],
            ),
          ),
          Gap(20),
          // Sorting pop-up
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              quicksandWhiteBold('Sort:'),
              PopupMenuButton(
                  color: CustomColors.forestGreen,
                  iconColor: Colors.white,
                  onSelected: (value) {
                    ref
                        .read(appointmentsProvider)
                        .setIsChronological(bool.parse(value));
                    currentPage = 0;
                    setDisplayedAppointments();
                  },
                  itemBuilder: (context) => [
                        PopupMenuItem(
                            value: false.toString(),
                            child: quicksandWhiteBold('Newest to Oldest')),
                        PopupMenuItem(
                            value: true.toString(),
                            child: quicksandWhiteBold('Oldest to Newest')),
                      ]),
            ],
          )
        ],
      ),
    );
  }

  Widget _appointmentsContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _appointmentsLabelRow(),
          ref.read(appointmentsProvider).appointmentDocs.isNotEmpty
              ? _appointmentEntries()
              : viewContentUnavailable(context,
                  text: 'NO AVAILABLE APPOINTMENTS'),
          if (ref.read(appointmentsProvider).appointmentDocs.length > 10)
            pageNavigatorButtons(
                currentPage: currentPage,
                maxPage: maxPage,
                onPreviousPage: () {
                  currentPage--;
                  setState(() {
                    setDisplayedAppointments();
                  });
                },
                onNextPage: () {
                  currentPage++;
                  setState(() {
                    setDisplayedAppointments();
                  });
                })
        ],
      ),
    );
  }

  Widget _appointmentsLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 3),
      viewFlexLabelTextCell('Date Created', 2),
      //viewFlexLabelTextCell('Selected Date', 2),
      viewFlexLabelTextCell('Status', 2),
      viewFlexLabelTextCell('Actions', 2),
      viewFlexLabelTextCell('Details', 2)
    ]);
  }

  Widget _appointmentEntries() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: currentDisplayedAppointments.length,
          itemBuilder: (context, index) {
            final appointmentData = ref
                .read(appointmentsProvider)
                .appointmentDocs[index]
                .data() as Map<dynamic, dynamic>;
            String appointmentID = currentDisplayedAppointments[index].id;
            String denialReason =
                appointmentData[AppointmentFields.denialReason] ?? '';
            String clientID = appointmentData[AppointmentFields.clientID];
            String appointmentStatus =
                appointmentData[AppointmentFields.appointmentStatus];
            List<dynamic> requestedDates =
                appointmentData[AppointmentFields.proposedDates];
            DateTime selectedDate =
                (appointmentData[AppointmentFields.selectedDate] as Timestamp)
                    .toDate();
            DateTime dateCreated =
                (appointmentData[AppointmentFields.dateCreated] as Timestamp)
                    .toDate();
            String address = appointmentData[AppointmentFields.address];
            return FutureBuilder(
                future: getThisUserDoc(clientID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData ||
                      snapshot.hasError) return snapshotHandler(snapshot);

                  final clientData =
                      snapshot.data!.data() as Map<dynamic, dynamic>;
                  String formattedName =
                      '${clientData[UserFields.firstName]} ${clientData[UserFields.lastName]}';
                  Color entryColor = Colors.white;
                  Color backgroundColor = Colors.transparent;

                  return _appointmentEntry(
                      appointmentID: appointmentID,
                      formattedName: formattedName,
                      backgroundColor: backgroundColor,
                      entryColor: entryColor,
                      requestedDates: requestedDates,
                      selectedDate: selectedDate,
                      dateCreated: dateCreated,
                      status: appointmentStatus,
                      address: address,
                      denialReason: denialReason);
                });
          }),
    );
  }

  Widget _appointmentEntry(
      {required String appointmentID,
      required String formattedName,
      required Color backgroundColor,
      required Color entryColor,
      required DateTime selectedDate,
      required DateTime dateCreated,
      required String status,
      required List<dynamic> requestedDates,
      required String address,
      required String denialReason}) {
    return viewContentEntryRow(
      context,
      children: [
        viewFlexTextCell(formattedName,
            flex: 3, backgroundColor: backgroundColor, textColor: entryColor),
        viewFlexTextCell(DateFormat('MMM dd, yyyy').format(dateCreated),
            flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
        // viewFlexTextCell(
        //     status != AppointmentStatuses.denied
        //         ? DateFormat('MMM dd, yyyy').format(selectedDate)
        //         : 'N/A',
        //     flex: 2,
        //     backgroundColor: backgroundColor,
        //     textColor: entryColor),
        viewFlexTextCell(status,
            flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
        viewFlexActionsCell([
          if (status == AppointmentStatuses.pending) ...[
            TextButton(
                onPressed: () => _showProposedDates(
                    appointmentID: appointmentID,
                    address: address,
                    requestedDates: requestedDates),
                child: Icon(Icons.check, color: CustomColors.lavenderMist)),
            TextButton(
                onPressed: () => showDenialReasonInputDialog(
                    appointmentID: appointmentID,
                    address: address,
                    formattedName: formattedName,
                    proposedDates: requestedDates),
                child: Icon(Icons.block, color: CustomColors.coralRed))
          ] else if (status == AppointmentStatuses.approved)
            ElevatedButton(
                onPressed: () => completeThisAppointment(context, ref,
                    appointmentID: appointmentID),
                child: quicksandWhiteRegular('MARK AS DONE', fontSize: 12))
        ], flex: 2, backgroundColor: backgroundColor),
        viewFlexActionsCell([
          if (status == AppointmentStatuses.approved)
            Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.white)),
              child: TextButton(
                  onPressed: () => showServiceDetails(context,
                      appointmentStatus: status,
                      selectedDate: selectedDate,
                      address: address),
                  child: quicksandWhiteBold('VIEW APPOINTMENT DETAILS',
                      fontSize: 12)),
            )
          else
            quicksandWhiteBold('N/A')
        ], flex: 2, backgroundColor: backgroundColor)
      ],
    );
  }

  void _showProposedDates(
      {required String appointmentID,
      required List<dynamic> requestedDates,
      required String address}) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => StatefulBuilder(
              builder: (context, setState) => Dialog(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  padding: EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                  onPressed: () => GoRouter.of(context).pop(),
                                  child: quicksandBlackBold('X'))
                            ]),
                        Row(children: [
                          quicksandBlackBold('Client Address: '),
                          quicksandBlackRegular(address,
                              textAlign: TextAlign.left)
                        ]),
                        vertical10Pix(
                            child: quicksandBlackBold(
                                'SELECT ONE OF THE FOLLOWING DATES FOR APPOINTMENT',
                                fontSize: 28)),
                        Column(
                          children: requestedDates
                              .map((requestedDate) => vertical10Pix(
                                    child: ElevatedButton(
                                        onPressed: () => approveThisAppointment(
                                            context, ref,
                                            appointmentID: appointmentID,
                                            selectedDate:
                                                (requestedDate).toDate()),
                                        child: quicksandWhiteRegular(
                                            DateFormat('MMM dd, yyyy').format(
                                                (requestedDate as Timestamp)
                                                    .toDate()))),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ));
  }

  void showDenialReasonInputDialog(
      {required String appointmentID,
      required String formattedName,
      required String address,
      required List<dynamic> proposedDates}) {
    denialReasonController.clear();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                //height: MediaQuery.of(context).size.height * 0.4,
                child: SingleChildScrollView(
                  child: all10Pix(
                      child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                            onPressed: () => GoRouter.of(context).pop(),
                            child: quicksandBlackBold('X'))
                      ]),
                      vertical10Pix(
                          child: quicksandBlackBold(
                              'You will deny this appointment request.')),
                      Row(children: [
                        quicksandBlackBold('Client Name: '),
                        quicksandBlackRegular(formattedName),
                      ]),
                      Row(children: [
                        quicksandBlackBold('Client Address: '),
                        quicksandBlackRegular(address,
                            textAlign: TextAlign.left)
                      ]),
                      Row(children: [quicksandBlackBold('Proposed Dates: ')]),
                      Row(
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: proposedDates
                                  .map((proposedDate) => quicksandBlackRegular(
                                      DateFormat('MMM dd, yyy').format(
                                          (proposedDate as Timestamp).toDate()),
                                      textAlign: TextAlign.left))
                                  .toList()),
                        ],
                      ),
                      Row(children: [quicksandBlackBold('Denial Reason')]),
                      CustomTextField(
                          text: 'Denial Reason',
                          controller: denialReasonController,
                          textInputType: TextInputType.text),
                      Gap(20),
                      ElevatedButton(
                          onPressed: () => denyThisAppointment(context, ref,
                              appointmentID: appointmentID,
                              denialReasonController: denialReasonController),
                          child: quicksandWhiteRegular('DENY TRANSACTION'))
                    ],
                  )),
                ),
              ),
            ));
  }
}

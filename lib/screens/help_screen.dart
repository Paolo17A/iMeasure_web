import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';
import 'package:intl/intl.dart';

import '../utils/color_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_text_field_widget.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  List<DocumentSnapshot> faqDocs = [];
  List<DateTime> proposedDates = [];
  final streetController = TextEditingController();
  final barangayController = TextEditingController();
  final municipalityController = TextEditingController();
  final zipCodeController = TextEditingController();
  final contactNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        faqDocs = await getAllFAQs();
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error gettinga all FAQs: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: hasLoggedInUser()
          ? topUserNavigator(context, path: GoRoutes.help)
          : topGuestNavigator(context, path: GoRoutes.help),
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: horizontal5Percent(context,
                      child: Column(
                        children: [
                          vertical20Pix(
                              child: quicksandWhiteBold(
                                  'FREQUENTLY ASKED QUESTIONS',
                                  fontSize: 32)),
                          _faqEntries()
                        ],
                      )),
                ),
                Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    padding: EdgeInsets.all(20),
                    child: Column(children: [
                      if (hasLoggedInUser())
                        vertical20Pix(
                            child: ElevatedButton(
                                onPressed: () => showSetAppointmentDialog(),
                                child: quicksandWhiteRegular(
                                    'SET AN APPOINTMENT'))),
                      quicksandWhiteBold('CONTACT US', fontSize: 28),
                      Row(children: [
                        Icon(Icons.support_agent_outlined,
                            color: CustomColors.emeraldGreen, size: 80),
                        all20Pix(
                            child: Column(children: [
                          quicksandWhiteRegular('09985657446'),
                          quicksandWhiteRegular('09484548667')
                        ])),
                      ]),
                      Gap(20),
                      Row(
                        children: [
                          Icon(Icons.facebook, color: Colors.blue, size: 60),
                          Expanded(
                            child: all20Pix(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  quicksandWhiteBold(
                                      'Heritage Aluminum Sales Corporation Los Banos',
                                      textAlign: TextAlign.left,
                                      fontSize: 16),
                                  quicksandWhiteRegular('FACEBOOK')
                                ])),
                          ),
                        ],
                      ),
                      Gap(20),
                      Row(
                        children: [
                          Icon(Icons.mail,
                              color: CustomColors.emeraldGreen, size: 60),
                          Expanded(
                            child: all20Pix(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  quicksandWhiteBold(
                                      'heritage.losbanos@gmail.com',
                                      textAlign: TextAlign.left,
                                      fontSize: 16),
                                  quicksandWhiteRegular('EMAIL')
                                ])),
                          ),
                        ],
                      ),
                      Gap(20),
                      Row(
                        children: [
                          Icon(Icons.home,
                              color: CustomColors.emeraldGreen, size: 60),
                          Expanded(
                            child: all20Pix(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  quicksandWhiteBold(
                                      'National Hwy, Los Baños, Philippines, 4030',
                                      textAlign: TextAlign.left,
                                      fontSize: 16),
                                  quicksandWhiteRegular('ADDRESS')
                                ])),
                          ),
                        ],
                      ),
                    ]))
              ],
            ),
          )),
    );
  }

  Widget _faqEntries() {
    return faqDocs.isNotEmpty
        ? SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: faqDocs.length,
                itemBuilder: (context, index) {
                  return _faqEntry(faqDocs[index]);
                }),
          )
        : quicksandWhiteBold('No FAQs Avaialble', fontSize: 30);
  }

  Widget _faqEntry(DocumentSnapshot faqDoc) {
    final faqData = faqDoc.data() as Map<dynamic, dynamic>;
    String question = faqData[FAQFields.question];
    String answer = faqData[FAQFields.answer];
    return vertical10Pix(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quicksandWhiteBold(question, fontSize: 27, textAlign: TextAlign.left),
        all10Pix(
            child: quicksandWhiteRegular(answer, textAlign: TextAlign.left)),
        Divider(color: Colors.white)
      ],
    ));
  }

  void showSetAppointmentDialog() {
    proposedDates.clear();
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
                          quicksandBlackBold(
                              'SELECT UP TO FIVE APPOINTMENT DATES',
                              fontSize: 28),
                          Gap(20),
                          ElevatedButton(
                              onPressed: () async {
                                if (proposedDates.length == 5) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'You can only select a maximum of 5 dates')));
                                  return;
                                }
                                DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    firstDate:
                                        DateTime.now().add(Duration(days: 1)),
                                    lastDate:
                                        DateTime.now().add(Duration(days: 14)));
                                if (pickedDate == null) return null;
                                if (proposedDates
                                        .where((proposedDate) =>
                                            proposedDate.day ==
                                                pickedDate.day &&
                                            proposedDate.month ==
                                                pickedDate.month &&
                                            pickedDate.year == pickedDate.year)
                                        .firstOrNull !=
                                    null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'You have already selected this date.')));
                                  return;
                                }
                                setState(() {
                                  proposedDates.add(pickedDate);
                                });
                              },
                              child: quicksandWhiteRegular('ADD A DATE')),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.25,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: proposedDates
                                    .map((proposedDate) => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            quicksandBlackBold(
                                                DateFormat('MMM dd, yyy')
                                                    .format(proposedDate)),
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    proposedDates
                                                        .remove(proposedDate);
                                                  });
                                                },
                                                icon: Icon(Icons.delete,
                                                    color: Colors.black))
                                          ],
                                        ))
                                    .toList()),
                          ),
                          addressGroup(context,
                              streetController: streetController,
                              barangayController: barangayController,
                              municipalityController: municipalityController,
                              zipCodeController: zipCodeController,
                              isWhite: false),
                          all20Pix(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  quicksandBlackBold('Mobile Number'),
                                  CustomTextField(
                                      text: 'Contact Number',
                                      controller: contactNumberController,
                                      textInputType: TextInputType.phone)
                                ]),
                          ),
                          if (proposedDates.isNotEmpty)
                            vertical20Pix(
                                child: ElevatedButton(
                                    onPressed: () => requestForAppointment(
                                        context, ref,
                                        requestedDates: proposedDates,
                                        streetController: streetController,
                                        barangayController: barangayController,
                                        municipalityController:
                                            municipalityController,
                                        zipCodeController: zipCodeController,
                                        contactNumberController:
                                            contactNumberController),
                                    child: quicksandWhiteRegular(
                                        'REQUEST FOR AN APPOINTMENT')))
                        ],
                      ),
                    ),
                  ),
                )));
  }
}

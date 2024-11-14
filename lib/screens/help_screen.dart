import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../utils/color_util.dart';
import '../utils/string_util.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  List<DocumentSnapshot> faqDocs = [];

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
            SnackBar(content: Text('Error gettinga ll FAQs: $error')));
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
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

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
            child: horizontal5Percent(context,
                child: Column(
                  children: [
                    vertical20Pix(
                        child: quicksandWhiteBold('FREQUENTLY ASKED QUESTIONS',
                            fontSize: 32)),
                    _faqEntries()
                  ],
                )),
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

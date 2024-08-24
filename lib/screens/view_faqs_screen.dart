import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class ViewFAQsScreen extends ConsumerStatefulWidget {
  const ViewFAQsScreen({super.key});

  @override
  ConsumerState<ViewFAQsScreen> createState() => _ViewFAQsScreenState();
}

class _ViewFAQsScreenState extends ConsumerState<ViewFAQsScreen> {
  List<DocumentSnapshot> allFAQDocs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        if (!hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.home);
          ref.read(loadingProvider).toggleLoading(false);

          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] != UserTypes.admin) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        allFAQDocs = await getAllFAQs();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting FAQs: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      body: stackedLoadingContainer(
        context,
        ref.read(loadingProvider).isLoading,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leftNavigator(context, path: GoRoutes.viewFAQs),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    horizontal5Percent(context,
                        child: Column(
                          children: [_addFAQButton(), _faqContainer()],
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addFAQButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        quicksandBlackBold('FREQUENTLY ASKED QUESTIONS', fontSize: 40),
        ElevatedButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.addFAQ),
            child: quicksandBlackBold('ADD FAQ'))
      ]),
    );
  }

  Widget _faqContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _faqLabelRow(),
          allFAQDocs.isNotEmpty
              ? _faqEntries()
              : viewContentUnavailable(context, text: 'NO AVAILABLE FAQs'),
        ],
      ),
    );
  }

  Widget _faqLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Question', 2),
      viewFlexLabelTextCell('Answer', 4),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _faqEntries() {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: allFAQDocs.length,
            itemBuilder: (context, index) {
              return _faqEntry(allFAQDocs[index], index);
            }));
  }

  Widget _faqEntry(DocumentSnapshot faqDoc, int index) {
    final faqData = faqDoc.data() as Map<dynamic, dynamic>;
    String question = faqData[FAQFields.question];
    String answer = faqData[FAQFields.answer];
    Color entryColor = Colors.black;
    Color backgroundColor = CustomColors.lavenderMist;
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(question,
          flex: 2,
          backgroundColor: backgroundColor,
          textColor: entryColor,
          customBorder: Border.symmetric(horizontal: BorderSide())),
      viewFlexTextCell(answer,
          flex: 4,
          backgroundColor: backgroundColor,
          textColor: entryColor,
          customBorder: Border.symmetric(horizontal: BorderSide())),
      viewFlexActionsCell([
        editEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.editFAQ,
                pathParameters: {PathParameters.faqID: faqDoc.id})),
        deleteEntryButton(context,
            onPress: () => displayDeleteEntryDialog(context,
                message: 'Are you sure you wish to remove this FAQ?',
                deleteEntry: () =>
                    deleteFAQEntry(context, ref, faqID: faqDoc.id)))
      ],
          flex: 2,
          backgroundColor: backgroundColor,
          customBorder: Border.symmetric(horizontal: BorderSide()))
    ]);
  }
}

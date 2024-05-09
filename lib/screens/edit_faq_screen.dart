import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/left_navigator_widget.dart';

class EditFAQScreen extends ConsumerStatefulWidget {
  final String faqID;
  const EditFAQScreen({super.key, required this.faqID});

  @override
  ConsumerState<EditFAQScreen> createState() => _EditFAQScreenState();
}

class _EditFAQScreenState extends ConsumerState<EditFAQScreen> {
  final questionController = TextEditingController();
  final answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] != UserTypes.admin) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        final faq = await getThisFAQDoc(widget.faqID);
        final faqData = faq.data() as Map<dynamic, dynamic>;
        questionController.text = faqData[FAQFields.question];
        answerController.text = faqData[FAQFields.answer];
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewFAQs),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
              ref.read(loadingProvider).isLoading,
              SingleChildScrollView(
                child: horizontal5Percent(context,
                    child: Column(children: [
                      _backButton(),
                      _newFAQHeaderWidget(),
                      _questionWidget(),
                      _answerWidget(),
                      _submitButtonWidget()
                    ])),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _backButton() {
    return vertical20Pix(
      child: Row(children: [
        ElevatedButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.viewFAQs),
            child: montserratMidnightBlueBold('BACK'))
      ]),
    );
  }

  Widget _newFAQHeaderWidget() {
    return montserratBlackBold(
      'EDIT FAQ',
      textAlign: TextAlign.center,
      fontSize: 38,
    );
  }

  Widget _questionWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: montserratBlackBold('Question', fontSize: 24)),
      CustomTextField(
          text: 'Question',
          controller: questionController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
      const SizedBox(height: 20)
    ]);
  }

  Widget _answerWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: montserratBlackBold('Answer', fontSize: 24)),
      CustomTextField(
          text: 'Answer',
          controller: answerController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
    ]);
  }

  Widget _submitButtonWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: ElevatedButton(
        onPressed: () => editFAQEntry(context, ref,
            faqID: widget.faqID,
            questionController: questionController,
            answerController: answerController),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: montserratMidnightBlueBold('SUBMIT'),
        ),
      ),
    );
  }
}

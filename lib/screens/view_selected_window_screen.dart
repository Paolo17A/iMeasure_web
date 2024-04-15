import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class ViewSelectedWindowScreen extends ConsumerStatefulWidget {
  final String windowID;
  const ViewSelectedWindowScreen({super.key, required this.windowID});

  @override
  ConsumerState<ViewSelectedWindowScreen> createState() =>
      _SelectedWindowScreenState();
}

class _SelectedWindowScreenState
    extends ConsumerState<ViewSelectedWindowScreen> {
  //  PRODUCT VARIABLES
  String name = '';
  String description = '';
  bool isAvailable = false;
  num minWidth = 0;
  num maxWidth = 0;
  num minLength = 0;
  num maxLength = 0;
  String imageURL = '';
  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (!hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        //  GET PRODUCT DATA
        final window = await getThisWindowDoc(widget.windowID);
        final windowData = window.data() as Map<dynamic, dynamic>;
        name = windowData[WindowFields.name];
        description = windowData[WindowFields.description];
        isAvailable = windowData[WindowFields.isAvailable];
        imageURL = windowData[WindowFields.imageURL];
        minLength = windowData[WindowFields.minHeight];
        maxLength = windowData[WindowFields.maxHeight];
        minWidth = windowData[WindowFields.minWidth];
        maxWidth = windowData[WindowFields.maxWidth];
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting selected product: $error')));
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
          leftNavigator(context, path: GoRoutes.windows),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
                ref.read(loadingProvider).isLoading,
                SingleChildScrollView(
                  child: horizontal5Percent(context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _backButton(),
                          _windowDetails(),
                          ordersHistory()
                        ],
                      )),
                )),
          )
        ],
      ),
    );
  }

  Widget _backButton() {
    return vertical20Pix(
      child: backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.windows)),
    );
  }

  Widget _windowDetails() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        buildProfileImage(profileImageURL: imageURL),
        montserratBlackBold(name, fontSize: 40),
        montserratMidnightBlueRegular(
            '\t\tAVAILABLE: ${isAvailable ? 'YES' : 'NO'}'),
        Gap(20),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: Column(
            children: [
              Row(children: [
                montserratMidnightBlueRegular(
                    'Minimum Width: ${minWidth.toString()}cm',
                    fontSize: 16),
                Gap(40),
                montserratMidnightBlueRegular(
                    'Minimum Length: ${minLength.toString()}cm',
                    fontSize: 16),
              ]),
              Row(
                children: [
                  montserratMidnightBlueRegular(
                      'Maximum Width: ${maxWidth.toString()}cm',
                      fontSize: 16),
                  Gap(40),
                  montserratMidnightBlueRegular(
                      'Maximum Length: ${maxLength.toString()}cm',
                      fontSize: 16)
                ],
              )
            ],
          ),
        ),
        Divider(color: CustomColors.midnightBlue),
        montserratMidnightBlueRegular(description)
      ]),
    );
  }

  Widget ordersHistory() {
    return vertical20Pix(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: CustomColors.slateBlue,
            borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(children: [montserratWhiteBold('ORDER HISTORY', fontSize: 36)]),
            montserratWhiteBold('THIS WINDOW HAS NOT BEEN ORDERED YET.',
                fontSize: 20),
          ],
        ),
      ),
    );
  }
}

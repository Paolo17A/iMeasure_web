import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();
    if (hasLoggedInUser()) {
      GoRouter.of(context).goNamed(GoRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topGuestNavigator(context, path: GoRoutes.about),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [Divider(), Gap(40), _aboutContent(), Gap(80)],
              ),
              socialsFooter(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutContent() {
    return horizontal5Percent(context,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage(ImagePaths.testimony))),
              ),
            ),
            Gap(MediaQuery.of(context).size.width * 0.05),
            Flexible(
              flex: 2,
              child: Column(
                children: [
                  vertical20Pix(
                    child: itcBaumansWhiteBold('HERITAGE ALUMINUM CORP',
                        fontSize: 36),
                  ),
                  quicksandWhiteRegular(about, textAlign: TextAlign.justify),
                ],
              ),
            ),
          ],
        ));
  }
}

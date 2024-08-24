import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../utils/go_router_util.dart';

PreferredSizeWidget topGuestNavigator(BuildContext context,
    {required String path}) {
  return AppBar(
    backgroundColor: CustomColors.deepCharcoal,
    toolbarHeight: 100,
    automaticallyImplyLeading: false,
    title: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Gap(40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: path == GoRoutes.home
                      ? null
                      : () => GoRouter.of(context).goNamed(GoRoutes.home),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Gap(40),
                    Image.asset(ImagePaths.heritageIcon, scale: 4),
                    Gap(8),
                    quicksandWhiteBold('iMeasure', fontSize: 28)
                  ]),
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  topNavigatorButton(context,
                      label: 'HOME',
                      thisPath: GoRoutes.home,
                      currentPath: path),
                  topNavigatorButton(context,
                      label: 'ABOUT',
                      thisPath: GoRoutes.about,
                      currentPath: path),
                  topNavigatorButton(context,
                      label: 'ITEMS',
                      thisPath: GoRoutes.items,
                      currentPath: path),
                  topNavigatorButton(context,
                      label: 'SHOP',
                      thisPath: GoRoutes.shop,
                      currentPath: path),
                ])
              ],
            ),
          ],
        )),
  );
}

PreferredSizeWidget topUserNavigator(BuildContext context,
    {required String path}) {
  return AppBar(
    backgroundColor: CustomColors.deepCharcoal,
    toolbarHeight: 100,
    automaticallyImplyLeading: false,
    title: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Gap(40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: path == GoRoutes.home
                      ? null
                      : () => GoRouter.of(context).goNamed(GoRoutes.home),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Gap(40),
                    Image.asset(ImagePaths.heritageIcon, scale: 4),
                    Gap(8),
                    quicksandWhiteBold('iMeasure', fontSize: 28)
                  ]),
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  topNavigatorButton(context,
                      label: 'HOME',
                      thisPath: GoRoutes.home,
                      currentPath: path),
                  topNavigatorButton(context,
                      label: 'SHOP',
                      thisPath: GoRoutes.shop,
                      currentPath: path),
                  topNavigatorButton(context,
                      label: 'CART', thisPath: '', currentPath: path),
                  topNavigatorButton(context,
                      label: 'ACCOUNT',
                      thisPath: GoRoutes.profile,
                      currentPath: path),
                ])
              ],
            ),
          ],
        )),
  );
}

topNavigatorButton(BuildContext context,
    {required String label,
    required String thisPath,
    required String currentPath}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.1,
    height: 50,
    child: TextButton(
        onPressed: () {
          if (thisPath.isEmpty || thisPath == currentPath) return;
          GoRouter.of(context).goNamed(thisPath);
          if (thisPath == GoRoutes.home) {
            GoRouter.of(context).pushReplacementNamed(thisPath);
          }
        },
        child: thisPath == currentPath
            ? quicksandWhiteBold(label)
            : quicksandWhiteRegular(label, fontSize: 16)),
  );
}

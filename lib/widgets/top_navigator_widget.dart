import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/main.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
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
                  topNavigatorButton(context,
                      label: 'HELP',
                      thisPath: GoRoutes.help,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: path == GoRoutes.home
                        ? null
                        : () {
                            iMeasure.searchController.clear();
                            GoRouter.of(context).goNamed(GoRoutes.home);
                          },
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Gap(40),
                      Image.asset(ImagePaths.heritageIcon, scale: 4),
                      Gap(8),
                      quicksandWhiteBold('iMeasure', fontSize: 28)
                    ]),
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: CustomTextField(
                            text: 'Search...',
                            hasSearchButton: true,
                            controller: iMeasure.searchController,
                            textInputType: TextInputType.text,
                            fillColor: Colors.white.withOpacity(0.8),
                            onSearchPress: () {
                              GoRouter.of(context).goNamed(GoRoutes.search,
                                  pathParameters: {
                                    PathParameters.searchInput:
                                        iMeasure.searchController.text
                                  });
                              GoRouter.of(context).pushNamed(GoRoutes.search,
                                  pathParameters: {
                                    PathParameters.searchInput:
                                        iMeasure.searchController.text
                                  });
                            })),
                    topNavigatorButton(context,
                        label: 'HOME',
                        thisPath: GoRoutes.home,
                        currentPath: path),
                    topNavigatorButton(context,
                        label: 'SHOP',
                        thisPath: GoRoutes.shop,
                        currentPath: path),
                    Stack(children: [
                      topNavigatorButton(context,
                          label: 'CART',
                          thisPath: GoRoutes.cart,
                          currentPath: path),
                      Positioned(
                          right: 20, child: pendingCheckOutStreamBuilder())
                    ]),
                    Stack(
                      children: [
                        topNavigatorButton(context,
                            label: 'ACCOUNT',
                            thisPath: GoRoutes.profile,
                            currentPath: path),
                        Positioned(
                            right: 20,
                            child: pendingPickUpOrdersStreamBuilder())
                      ],
                    ),
                    topNavigatorButton(context,
                        label: 'HELP',
                        thisPath: GoRoutes.help,
                        currentPath: path),
                  ])
                ],
              ),
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

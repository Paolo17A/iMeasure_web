import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../utils/go_router_util.dart';

PreferredSizeWidget topNavigator(BuildContext context, {required String path}) {
  return AppBar(
    backgroundColor: CustomColors.lavenderMist,
    toolbarHeight: 100,
    title: Container(
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            topNavigatorButton(context,
                label: 'DASHBOARD', thisPath: GoRoutes.home, currentPath: path),
            topNavigatorButton(context,
                label: 'USERS', thisPath: GoRoutes.users, currentPath: path),
            topNavigatorButton(context,
                label: 'WINDOWS',
                thisPath: GoRoutes.windows,
                currentPath: path),
            topNavigatorButton(context,
                label: 'TRANSACTIONS',
                thisPath: GoRoutes.transactions,
                currentPath: path),
            topNavigatorButton(context,
                label: 'ORDERS', thisPath: GoRoutes.orders, currentPath: path),
          ],
        )),
  );
}

topNavigatorButton(BuildContext context,
    {required String label,
    required String thisPath,
    required String currentPath}) {
  return Flexible(
      flex: 2,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.15,
        height: 50,
        decoration: BoxDecoration(
            gradient: thisPath == currentPath
                ? LinearGradient(
                    colors: [CustomColors.emeraldGreen, CustomColors.azure])
                : null),
        child: TextButton(
            onPressed: () {
              GoRouter.of(context).goNamed(thisPath);
              if (thisPath == GoRoutes.home) {
                GoRouter.of(context).pushReplacementNamed(thisPath);
              }
            },
            child: quicksandBlackBold(label)),
      ));
}

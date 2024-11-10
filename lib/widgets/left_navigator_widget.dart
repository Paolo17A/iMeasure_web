import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../utils/go_router_util.dart';
import '../utils/string_util.dart';

Widget leftNavigator(BuildContext context, {required String path}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.2,
    height: MediaQuery.of(context).size.height,
    decoration: BoxDecoration(
        color: Colors.black, border: Border.all(color: Colors.black)),
    child: Column(
      children: [
        Gap(40),
        Image.asset(ImagePaths.heritageIcon, scale: 3),
        quicksandWhiteBold('iMeasure', fontSize: 24),
        quicksandWhiteBold('• LOS BAÑOS •', fontSize: 12),
        Gap(60),
        Flexible(
            child: ListView(
          padding: EdgeInsets.all(12),
          children: [
            listTile(context,
                label: 'Dashboard', thisPath: GoRoutes.home, currentPath: path),
            listTile(context,
                label: 'Items', thisPath: GoRoutes.windows, currentPath: path),
            listTile(context,
                label: 'Orders', thisPath: GoRoutes.orders, currentPath: path),
            listTile(context,
                label: 'Users', thisPath: GoRoutes.users, currentPath: path),
            listTile(context,
                label: 'Transactions',
                thisPath: GoRoutes.transactions,
                currentPath: path),
            listTile(context,
                label: 'Pending Labor',
                thisPath: GoRoutes.pendingLabor,
                currentPath: path),
            listTile(context,
                label: 'Gallery',
                thisPath: GoRoutes.gallery,
                currentPath: path),
            listTile(context,
                label: 'FAQ', thisPath: GoRoutes.viewFAQs, currentPath: path),
            listTile(context,
                label: 'History',
                thisPath: GoRoutes.gallery,
                currentPath: path),
          ],
        )),
        ListTile(
            title: quicksandWhiteBold('Log-Out', textAlign: TextAlign.left),
            onTap: () {
              FirebaseAuth.instance.signOut().then((value) {
                GoRouter.of(context).goNamed(GoRoutes.home);
                GoRouter.of(context).pushReplacementNamed(GoRoutes.home);
              });
            })
      ],
    ),
  );
}

Widget listTile(BuildContext context,
    {required String label,
    required String thisPath,
    required String currentPath}) {
  return ListTile(
      title: thisPath == currentPath
          ? forestGreenQuicksandBold(label, textAlign: TextAlign.left)
          : quicksandWhiteBold(label, textAlign: TextAlign.left),
      onTap: () {
        GoRouter.of(context).goNamed(thisPath);
        if (thisPath == GoRoutes.home) {
          GoRouter.of(context).pushReplacementNamed(thisPath);
        }
      });
}

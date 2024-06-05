import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../utils/go_router_util.dart';

Widget appDrawer(BuildContext context, {required String currentPath}) {
  return Drawer(
    child: Column(
      children: [
        Flexible(
            child: ListView(
          children: [_faq(context, currentPath: currentPath)],
        )),
        TextButton(
            child: quicksandRedBold('LOG-OUT'),
            onPressed: () {
              FirebaseAuth.instance.signOut().then((value) {
                GoRouter.of(context).goNamed(GoRoutes.home);
                GoRouter.of(context).pushReplacementNamed(GoRoutes.home);
              });
            })
      ],
    ),
  );
}

Widget _faq(BuildContext context, {required String currentPath}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: ListTile(
      leading: const Icon(Icons.question_mark, color: Colors.black),
      title: quicksandBlackBold('FAQ'),
      onTap: () {
        Navigator.of(context).pop();
        if (currentPath == GoRoutes.viewFAQs) {
          return;
        }
        GoRouter.of(context).goNamed(GoRoutes.viewFAQs);
      },
    ),
  );
}

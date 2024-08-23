import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../utils/color_util.dart';
import '../utils/go_router_util.dart';
import 'custom_padding_widgets.dart';

Widget submitButton(BuildContext context,
    {required String label, required Function onPress}) {
  return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () => onPress(),
        style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.lavenderMist),
        child: deepCharcoalQuicksandBold(label),
      ));
}

Widget backButton(BuildContext context, {required Function onPress}) {
  return all4Pix(
    child: ElevatedButton(
        onPressed: () => onPress(),
        style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.lavenderMist,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        child: quicksandBlackBold('BACK')),
  );
}

Widget viewEntryButton(BuildContext context, {required Function onPress}) {
  return TextButton(
      onPressed: () {
        onPress();
      },
      child: const Icon(Icons.visibility_outlined,
          color: CustomColors.lavenderMist));
}

Widget editEntryButton(BuildContext context,
    {required Function onPress, Color iconColor = CustomColors.lavenderMist}) {
  return TextButton(
      onPressed: () {
        onPress();
      },
      child: Icon(Icons.edit_outlined, color: iconColor));
}

Widget restoreEntryButton(BuildContext context, {required Function onPress}) {
  return TextButton(
      onPressed: () {
        onPress();
      },
      child: const Icon(Icons.restore, color: CustomColors.lavenderMist));
}

Widget deleteEntryButton(BuildContext context,
    {required Function onPress, Color iconColor = CustomColors.lavenderMist}) {
  return TextButton(
      onPressed: () {
        onPress();
      },
      child: Icon(Icons.delete_outline_outlined, color: iconColor));
}

Widget uploadImageButton(String label, Function selectImage) {
  return TextButton(
      onPressed: () => selectImage(),
      style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
      child: Padding(
          padding: const EdgeInsets.all(7), child: quicksandWhiteBold(label)));
}

Widget navigatorButtons(BuildContext context,
    {required int pageNumber,
    required Function? onPrevious,
    required Function? onNext,
    Color fontColor = Colors.black}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        pageButton(context,
            label: 'PREV', onPress: onPrevious, fontColor: fontColor),
        Padding(
          padding: const EdgeInsets.all(5.5),
          child:
              Text(pageNumber.toString(), style: TextStyle(color: fontColor)),
        ),
        pageButton(context,
            label: 'NEXT', onPress: onNext, fontColor: fontColor)
      ],
    ),
  );
}

Widget pageButton(BuildContext context,
    {required Function? onPress,
    required String label,
    Color fontColor = Colors.black}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: TextButton(
        onPressed: onPress != null ? () => onPress() : null,
        style: TextButton.styleFrom(
            foregroundColor: fontColor, disabledForegroundColor: Colors.grey),
        child: Text(label)),
  );
}

Widget logOutButton(BuildContext context) {
  return all20Pix(
      child: ElevatedButton(
          onPressed: () {
            FirebaseAuth.instance.signOut().then((value) {
              GoRouter.of(context).goNamed(GoRoutes.home);
              GoRouter.of(context).pushReplacementNamed(GoRoutes.home);
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: quicksandWhiteBold('LOG-OUT')));
}

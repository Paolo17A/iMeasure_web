import 'package:flutter/material.dart';

Padding all20Pix({required Widget child}) {
  return Padding(padding: const EdgeInsets.all(20), child: child);
}

Padding all10Pix({required Widget child}) {
  return Padding(padding: const EdgeInsets.all(10), child: child);
}

Padding vertical10Pix({required Widget child}) {
  return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10), child: child);
}

Padding vertical20Pix({required Widget child}) {
  return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20), child: child);
}

Widget all5Percent(BuildContext context, {required Widget child}) {
  return Padding(
    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
    child: child,
  );
}

Widget horizontal5Percent(BuildContext context, {required Widget child}) {
  return Padding(
    padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05),
    child: child,
  );
}

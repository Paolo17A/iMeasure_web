import 'package:flutter/material.dart';
import 'package:imeasure/widgets/text_widgets.dart';

PreferredSizeWidget appBarWidget({bool hasLeading = false, String label = ''}) {
  return AppBar(
      toolbarHeight: 60,
      automaticallyImplyLeading: hasLeading,
      iconTheme: const IconThemeData(color: Colors.white),
      title: quicksandBlackBold(label, fontSize: 36));
}

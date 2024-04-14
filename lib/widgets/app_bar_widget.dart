import 'package:flutter/material.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../utils/color_util.dart';

PreferredSizeWidget appBarWidget({bool hasLeading = false}) {
  return AppBar(
      toolbarHeight: 60,
      backgroundColor: CustomColors.slateBlue,
      automaticallyImplyLeading: hasLeading,
      iconTheme: const IconThemeData(color: Colors.white),
      title: montserratWhiteBold('iMEASURE ADMIN DASHBOARD', fontSize: 36));
}

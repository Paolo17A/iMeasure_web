import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imeasure/utils/theme_util.dart';

import 'firebase_options.dart';
import 'utils/go_router_util.dart';
import 'utils/string_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  home = await rootBundle.loadString('assets/documents/home.txt');
  about = await rootBundle.loadString('assets/documents/about.txt');
  shop = await rootBundle.loadString('assets/documents/shop.txt');

  runApp(const ProviderScope(child: iMeasure()));
}

// ignore: camel_case_types
class iMeasure extends StatelessWidget {
  const iMeasure({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'iMeasure',
      theme: themeData,
      routerConfig: goRoutes,
    );
  }
}

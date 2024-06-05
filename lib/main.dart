import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imeasure/utils/theme_util.dart';

import 'firebase_options.dart';
import 'utils/go_router_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: iMeasure()));
}

// ignore: camel_case_types
class iMeasure extends StatelessWidget {
  const iMeasure({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'iMeasure Admin Dashboard',
      theme: themeData,
      routerConfig: goRoutes,
    );
  }
}

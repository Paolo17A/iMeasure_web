import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';

import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/text_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (hasLoggedInUser()) {
      GoRouter.of(context).goNamed(GoRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
        body: stackedLoadingContainer(
      context,
      ref.read(loadingProvider).isLoading,
      Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(ImagePaths.heritageBackground),
                fit: BoxFit.cover)),
        child: Column(
          children: [
            all20Pix(
                child: Row(children: [
              backButton(context,
                  onPress: () => GoRouter.of(context).goNamed(GoRoutes.home))
            ])),
            Gap(100),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(ImagePaths.heritageIcon),
                      itcBaumansWhiteBold('HERITAGE ALUMINUM SALES CORPORATION',
                          fontSize: 40),
                      itcBaumansWhiteBold('• LOS BAÑOS •')
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      border: Border.all(color: CustomColors.lavenderMist),
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        vertical20Pix(
                            child:
                                quicksandWhiteBold('iMeasure', fontSize: 40)),
                        CustomTextField(
                            text: 'Email Address',
                            controller: emailController,
                            textInputType: TextInputType.emailAddress,
                            fillColor: CustomColors.deepCharcoal,
                            textColor: Colors.white,
                            displayPrefixIcon: const Icon(Icons.email,
                                color: CustomColors.lavenderMist)),
                        const Gap(16),
                        CustomTextField(
                          text: 'Password',
                          controller: passwordController,
                          textInputType: TextInputType.visiblePassword,
                          fillColor: CustomColors.deepCharcoal,
                          textColor: Colors.white,
                          displayPrefixIcon: const Icon(Icons.lock,
                              color: CustomColors.lavenderMist),
                          onSearchPress: () => logInUser(context, ref,
                              emailController: emailController,
                              passwordController: passwordController),
                        ),
                        Divider(),
                        TextButton(
                            onPressed: () => GoRouter.of(context)
                                .goNamed(GoRoutes.forgotPassword),
                            child: quicksandWhiteRegular("Forgot Password?",
                                fontSize: 16,
                                decoration: TextDecoration.underline)),
                        TextButton(
                            onPressed: () =>
                                GoRouter.of(context).goNamed(GoRoutes.register),
                            child: quicksandWhiteRegular(
                                "Don't have an account?",
                                decoration: TextDecoration.underline,
                                fontSize: 16)),
                        submitButton(context,
                            label: 'LOG-IN',
                            onPress: () => logInUser(context, ref,
                                emailController: emailController,
                                passwordController: passwordController)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    ));
  }
}

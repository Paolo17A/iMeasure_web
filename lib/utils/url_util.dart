import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

launchThisURL(BuildContext context, String passedUrl) async {
  final url = Uri.parse(passedUrl);
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    // Handle the case where the URL cannot be launched
    // ignore: avoid_print
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Could not launch $url')));
    print('Could not launch $url');
  }
}

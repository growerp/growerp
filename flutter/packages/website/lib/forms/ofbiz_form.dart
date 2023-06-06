import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../widgets/text_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class OfbizForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Center(
            child: Wrap(
      spacing: 20,
      runSpacing: 20,
      children: <Widget>[
        Bloc(
            logo: 'assets/ofbizLogo.png',
            header: "About Apache OFBiz",
            content: TextSpan(children: <TextSpan>[
              _text('Apache OFBiz is from the same developer as Moqui and '
                  'started in 2001. In 2006 it became part of the Apache software '
                  'foundation. At that time it was a pretty revolutionary project.'
                  'The product is stil very well maintained and supported '),
              _textLink(
                  'https://cwiki.apache.org/confluence/display/OFBIZ/Apache+OFBiz+Service+Providers',
                  'by many companies'),
              _text('\n\nAlthough we support the OFBiz system for existing '
                  'installations, we advice the Moqui system for new systems for '
                  'its smaller size, it works with any java application server '
                  'and has a REST interface. However, because OFBiz is older it '
                  'has some more functionality than Moqui and a larger community.'
                  '\n\nThe website can be found at '),
              _textLink('https://ofbiz.apache.org', 'ofbiz.apache.org'),
            ])),
        Bloc(
            logo: 'assets/ofbizLogo.png',
            header: "Apache OFBiz features.",
            content: TextSpan(children: <TextSpan>[
              _text(
                  'OFBiz features are very extensive, generally also focussed '
                  'on E-Commerce frontend, the backend with warehouse, picking '
                  'and packing for sales , purchase and returns. Manufacturing '
                  'and CRM and even SCRUM and project managementare part of the package.'
                  '\n\nA detailed feature list can be found '),
              _textLink(
                  'https://cwiki.apache.org/confluence/display/OFBIZ/OFBiz+Features',
                  'here.....'),
            ])),
        Bloc(
            logo: 'assets/ofbizLogo.png',
            header: "Apache OFBiz download.",
            content: TextSpan(children: <TextSpan>[
              _text('Before you want to run the system locally, you need to '
                  'be sure to have Java version 8 JDK installed, either '),
              _textLink(
                  'https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html',
                  'from Oracle, '),
              _text('or '),
              _textLink(
                  'https://openjdk.java.net/install', 'the open JDK version.'),
              _text('\n\nThe getting started page can be found '),
              _textLink('https://ofbiz.apache.org/developers.html', 'here.'),
              _text(
                  'Further instructions how to install the system can be found '
                  'in the archive README text file.'),
            ])),
        Bloc(
            logo: 'assets/ofbizLogo.png',
            header: "Apache OFBiz Email list.",
            content: TextSpan(children: <TextSpan>[
              _text(
                  'OFBiz has several mailingslists which are copies of each other, '
                  'they are separated by developers, users, commits and notifications'),
              _textLink('http://ofbiz.135035.n4.nabble.com',
                  '\n\nNabble forum (for quick browse)'),
              _textLink('https://ofbiz.apache.org/mailing-lists.html',
                  '\nOfficial email list (to subscribe)'),
            ])),
      ],
    )));
  }
}

TextSpan _textLink(final String url, final String text) {
  return TextSpan(
      text: text,
      style: TextStyle(
          color: Colors.blueAccent, decoration: TextDecoration.underline),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        });
}

TextSpan _text(final String text) {
  return TextSpan(text: text, style: TextStyle(color: Colors.black));
}

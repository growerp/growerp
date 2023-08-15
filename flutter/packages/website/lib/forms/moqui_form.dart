import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../widgets/text_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class MoquiForm extends StatelessWidget {
  const MoquiForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Center(
            child: Wrap(
      spacing: 20,
      runSpacing: 20,
      children: <Widget>[
        Bloc(
            logo: 'assets/moquiLogo.png',
            header: "About Moqui",
            content: TextSpan(children: <TextSpan>[
              _text('Moqui is a relatively new framework which started being '
                  'added in Github the beginning of 2016 However it can be assumed '
                  'the actual start would be at least a couple of years earlier, '
                  'so probably 2013. '),
              _textLink('https://www.moqui.org/MakingAppsWithMoqui-1.0.pdf',
                  'The moqui book '),
              _text('was published in 2014.\n\n'
                  'This framework is the successor of Apache Ofbiz. Did you ever '
                  'do a software project twice? The second time you sure will not '
                  'make the same errors and now use the experience of the first '
                  'project! The original developer David Jones of Apache OFBiz '
                  'also developed this Moqui project.\n\n'
                  'Currently the Moqui system is supported by a number of expert '),
              _textLink('https://moqui.org/service.html',
                  'programmers and companies.'),
              _text('\n\nThe website can be found at '),
              _textLink('https://moqui.org', 'moqui.org'),
            ])),
        Bloc(
            logo: 'assets/moquiLogo.png',
            header: "Moqui features",
            content: TextSpan(children: <TextSpan>[
              _text('Moqui\'s features are very extensive but were initially '
                  'focussed on E-Commerce, not only the ecommerce frontend '
                  'but esspecially the backend with warehouse, picking '
                  'and packing for sales, purchase and returns. '
                  'Now also manufacturing and CRM are part of the package.\n\n'
                  'A detailed feature list can be found'),
              _textLink(
                  'https://www.moqui.org/docs/framework/Framework+Features',
                  ' here....'),
            ])),
        Bloc(
            logo: 'assets/moquiLogo.png',
            header: "Moqui Download & Demo",
            content: TextSpan(children: <TextSpan>[
              _text('Before you want to run the system locally, you need to '
                  'be sure to have Java version 8 JDK installed, either '),
              _textLink(
                  'https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html',
                  'from Oracle, '),
              _text('or '),
              _textLink('https://openjdk.java.net/install',
                  'the open JDK version.\n\n'),
              _text(
                  'There are basically two Moqui versions of the system to download.\n\n'
                  'If you just want to try, download the latest binary version '
                  'or if you want to run from source the latest release or latest '
                  'version. check'),
              _textLink(
                  'https://www.moqui.org/docs/framework/Run+and+Deploy#a1.QuickStart',
                  ' the quickstart '),
              _text('for more information.\n\n There is also a demo available, '
                  'either the'),
              _textLink('https://demo.moqui.org/store', ' frontend'),
              _text(' or the'),
              _textLink('https://demo.moqui.org/Login', ' backend.')
            ])),
        Bloc(
            logo: 'assets/moquiLogo.png',
            header: "Moqui mailing list",
            content: TextSpan(children: <TextSpan>[
              _text('There are several google discussion groups about Moqui, '
                  'also the git updates are logged there:\n\n'),
              _textLink('https://demo.moqui.org/store',
                  'Google groups: Moqui Applications\n'),
              _textLink('https://groups.google.com/forum/#!forum/moqui',
                  'Google groups: Moqui Ecosystem\n'),
              _textLink('https://www.linkedin.com/groups/4640689/',
                  'LinkedIn: Moqui'),
            ])),
      ],
    )));
  }
}

TextSpan _textLink(final String url, final String text) {
  return TextSpan(
      text: text,
      style: const TextStyle(
          color: Colors.blueAccent, decoration: TextDecoration.underline),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        });
}

TextSpan _text(final String text) {
  return TextSpan(text: text, style: const TextStyle(color: Colors.black));
}

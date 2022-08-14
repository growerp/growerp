import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../widgets/text_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Center(
            child: Wrap(
      spacing: 20,
      runSpacing: 20,
      children: <Widget>[
        Bloc(
            header: 'About GrowERP',
            content: TextSpan(children: <TextSpan>[
              _text('GrowERP is a Flutter frontend for either Moqui '
                  'or Apache OFBiz being multi company and currency.'
                  'All modules can be run unchanged, '
                  'natively on currenty Mobile(IOS,Android) and in '
                  'the browser(Flutter in beta). '
                  'Linux, Mac and Windows will be available soon.\n'
                  'Yes, even this site is developed with Flutter. GrowERP is '
                  'targetted at the smaller businesses like hotels, restaurants, '
                  'freelancers, dentists and ecommerce business and to larger '
                  'companies wanting a mobile app for a particular ERP system '
                  'function.\n\n'
                  'All apps have full state management and automated tests '
                  'and can be tried in '
                  'the browser and downloaded from either '
                  'the App- or Play-Store.\n\n'
                  'All apps are available on github in a '),
              _textLink('https://www.github.com/growerp/growerp',
                  'single repository'),
              _text(' in several branches.\n\n'),
              _text('The Moqui backend component can be found '),
              _textLink(
                  'https://www.github.com/growerp/growerp-moqui', 'here.\n'),
              _text('The Ofbiz component can be found '),
              _textLink(
                  'https://www.github.com/growerp/growerp-ofbiz', 'here.\n'),
              _text('\nInstallation instructions are in '
                  'the README files inside the project GitHub directories.\n\n'),
              _textLink('https://www.antwebsystems.com',
                  'GrowERP is an initiative of Antwebsystems Co.Ltd'),
            ])),
        Bloc(
            header: 'GrowERP Applications',
            content: TextSpan(children: <TextSpan>[
              _text(
                  'We are working on the following apps for mobile and web:\n\n'
                  'Admininistration App\n'),
              _textLink('https://admin.growerp.org', '1a. Web\n'),
              _textLink(
                  'https://play.google.com/store/apps/details?id=org.growerp.admin',
                  '1b. Android play store\n'),
              _textLink(
                  'https://apps.apple.com/us/app/growerp-admin-open-source/id1545521755',
                  '1c. Apple app store\n'),
              _text(
                  'Maintenance of people/companies, categories/products and orders\n\n'
                  'Hotel\n'),
              _textLink('https://hotel.growerp.org', '2a. Web\n'),
              _textLink(
                  'https://play.google.com/store/apps/details?id=org.growerp.hotel',
                  '2b. Android play store\n'),
              _textLink(
                  'https://apps.apple.com/us/app/growerp-hotel-open-source/id1531267095',
                  '2c. Apple app store\n'),
              _text("Hotel front desk reservation and room management\n\n"),
              _textLink('https://ecommerce.growerp.org', '3. ecommerce\n'),
              _text('via categories/products create order and send to '
                  'related company\n\n'),
              _text('4. restaurant\n'),
              _text('Kitchen, bar and table/customer management'),
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
          if (await canLaunch(url)) {
            await launch(url, forceSafariVC: false);
          }
        });
}

TextSpan _text(final String text) {
  return TextSpan(text: text, style: TextStyle(color: Colors.black));
}

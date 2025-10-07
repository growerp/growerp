/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:about/about.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/src/domains/common/functions/screen_size.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';

import '../widgets/widgets.dart';

class AboutForm extends StatefulWidget {
  const AboutForm({super.key});

  @override
  State<AboutForm> createState() => _AboutFormState();
}

class _AboutFormState extends State<AboutForm> {
  CoreLocalizations? _localizations;
  @override
  Widget build(BuildContext context) {
    _localizations = CoreLocalizations.of(context);
    String version = GlobalConfiguration().get("version") ?? '';
    String build = GlobalConfiguration().get("build") ?? '';
    String databaseUrl = GlobalConfiguration().get("databaseUrl") ?? '';
    String packageName = GlobalConfiguration().get("packageName") ?? '';
    String appName = GlobalConfiguration().get("appName") ?? '';
    var year = DateTime.now().year;

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: _localizations!.aboutGrowERP,
        width: isAPhone(context) ? 400 : 800,
        height: isPhone(context) ? 700 : 600,
        child: AboutPage(
          dialog: false,
          title: Text(_localizations!.aboutApp(appName)),
          applicationVersion: _localizations!.version(version, build),
          applicationName: packageName,
          applicationDescription: Center(child: Text(databaseUrl)),
          applicationIcon: Image.asset(
            'packages/growerp_core/images/growerp.png',
            height: 100,
            width: 200,
          ),
          applicationLegalese: _localizations!.copyright(year.toString()),
          children: <Widget>[
            Center(
              child: SizedBox(
                width: 300,
                child: Form(
                  child: Column(
                    children: <Widget>[
                      MarkdownPageListTile(
                        filename: '../../../../../../../../../../README.md',
                        title: Text(_localizations!.viewReadme),
                        icon: const Icon(Icons.all_inclusive),
                      ),
                      MarkdownPageListTile(
                        filename: '../../../../../../../../../../LICENSE',
                        title: Text(_localizations!.viewLicense),
                        icon: const Icon(Icons.description),
                      ),
                      MarkdownPageListTile(
                        filename:
                            '../../../../../../../../../../CONTRIBUTING.md',
                        title: Text(
                          _localizations!.contributing,
                        ),
                        icon: const Icon(Icons.share),
                      ),
                      MarkdownPageListTile(
                        filename:
                            '../../../../../../../../../../CODE_OF_CONDUCT.md',
                        title: Text(
                          _localizations!.privacyCodeOfConduct,
                        ),
                        icon: const Icon(Icons.sentiment_satisfied),
                      ),
                      LicensesPageListTile(
                        title: Text(
                          _localizations!.openSourceLicenses,
                        ),
                        icon: const Icon(Icons.favorite),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

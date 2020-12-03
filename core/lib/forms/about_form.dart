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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/@widgets.dart';

class AboutForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShowNavigationRail(AboutFormHeader(), 3);
  }
}

class AboutFormHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double version = GlobalConfiguration().get("version");
    double build = GlobalConfiguration().get("build");

    return AboutPage(
        dialog: true,
        title: Text('About GrowERP and this Admin app'),
        applicationVersion: 'Version $version, build #$build',
        applicationIcon: Image(
          image: AssetImage('assets/images/growerp.png'),
          height: 100,
          width: 200,
        ),
        applicationLegalese: '© GrowERP, {{ year }}',
        children: <Widget>[
          Center(
              child: Container(
                  width: 300,
                  child: Form(
                      child: Column(
                    children: <Widget>[
                      MarkdownPageListTile(
                        filename: 'README.md',
                        title: Text('View Readme'),
                        icon: Icon(Icons.all_inclusive),
                      ),
                      MarkdownPageListTile(
                        filename: 'CHANGELOG.md',
                        title: Text('View Changelog'),
                        icon: Icon(Icons.view_list),
                      ),
                      MarkdownPageListTile(
                        filename: 'LICENSE.md',
                        title: Text('View License'),
                        icon: Icon(Icons.description),
                      ),
                      MarkdownPageListTile(
                        filename: 'CONTRIBUTING.md',
                        title: Text('Contributing'),
                        icon: Icon(Icons.share),
                      ),
                      MarkdownPageListTile(
                        filename: 'CODE_OF_CONDUCT.md',
                        title: Text('Privacy, Code of conduct'),
                        icon: Icon(Icons.sentiment_satisfied),
                      ),
                      LicensesPageListTile(
                        title: Text('Open source Licenses'),
                        icon: Icon(Icons.favorite),
                      ),
                    ],
                  ))))
        ]);
  }
}

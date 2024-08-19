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

import 'package:flutter/material.dart';

class FatalErrorForm extends StatelessWidget {
  final String message;
  final String? route;
  final String buttonText;

  const FatalErrorForm(
      {super.key,
      required this.message,
      this.route,
      this.buttonText = 'Restart'});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 20),
            ),
            OutlinedButton(
                child: Text(buttonText),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                }),
          ])),
    );
  }
}

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
import 'package:flutter_phoenix/flutter_phoenix.dart';

class FatalErrorForm extends StatelessWidget {
  final String message;
  final String? route;
  final String? buttonText;

  const FatalErrorForm(
      {super.key, required this.message, this.route, this.buttonText});
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
            Visibility(
                visible: route != null && buttonText != null,
                child: OutlinedButton(
                    child: Text("$buttonText"),
                    onPressed: () {
                      Navigator.pushNamed(context, route!);
                    })),
            const SizedBox(height: 20),
            OutlinedButton(
              key: const Key('restart'),
              child: const Text('Restart'),
              onPressed: () => Phoenix.rebirth(context),
            )
          ])),
    );
  }
}

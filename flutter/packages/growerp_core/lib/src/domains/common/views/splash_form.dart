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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';

class SplashForm extends StatelessWidget {
  const SplashForm({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChannels.textInput.invokeMethod('TextInput.hide'); // dismiss keyboard
    ThemeMode? themeMode = context.read<ThemeBloc>().state.themeMode;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const SizedBox(height: 100),
        Image(
            image: AssetImage(themeMode == ThemeMode.light
                ? 'packages/growerp_core/images/growerp.jpg'
                : 'packages/growerp_core/images/growerpDark.jpg')),
        const SizedBox(height: 20),
        const SizedBox(
            width: 300,
            child: LinearProgressIndicator(
              minHeight: 20,
              color: Color(0xFF4baa9b),
              backgroundColor: Colors.lightGreen,
            )),
      ]),
    );
  }
}

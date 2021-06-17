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

import 'package:core/blocs/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/@models.dart';
import 'package:flutter/material.dart';

class FatalErrorForm extends StatelessWidget {
  final String message;
  final String? route;
  final String? buttonText;
  const FatalErrorForm(this.message, [this.route, this.buttonText]);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
          Text('$message'),
          Visibility(
              visible: route != null && buttonText != null,
              child: ElevatedButton(
                  child: Text("$buttonText"),
                  onPressed: () {
                    Navigator.pushNamed(context, route!,
                        arguments: FormArguments());
                  })),
          SizedBox(height: 20),
          ElevatedButton(
              key: Key('restart'),
              child: Text('Restart'),
              onPressed: () async {
                BlocProvider.of<AuthBloc>(context).add(Logout());
                RestartWidget.restartApp(context);
              }),
        ])));
  }
}

class RestartWidget extends StatefulWidget {
  RestartWidget({required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()!.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}

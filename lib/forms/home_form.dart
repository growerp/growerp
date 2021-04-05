/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:models/@models.dart';
import 'package:core/helper_functions.dart';
import '@forms.dart';

class HomeForm extends StatelessWidget {
  final String? message;
  const HomeForm({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBody(message: message),
    );
  }
}

class HomeBody extends StatefulWidget {
  final String? message;

  const HomeBody({Key? key, this.message}) : super(key: key);
  @override
  State<HomeBody> createState() => _HomeState(message);
}

class _HomeState extends State<HomeBody> {
  final String? message;
  Authenticate? authenticate;
  Company? company;
  ContainerTransitionType _transitionType = ContainerTransitionType.fadeThrough;
  _HomeState(this.message);

  @override
  void initState() {
    Future<Null>.delayed(Duration(milliseconds: 0), () {
      if (message != null) {
        HelperFunctions.showMessage(context, '$message', Colors.green);
      }
    });
    super.initState();
  }

  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthProblem) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: RaisedButton(
                    child: Text("${state.errorMessage} \nRetry?"),
                    onPressed: () {
                      BlocProvider.of<AuthBloc>(context).add(LoadAuth());
                    }),
              )
            ]);
      }
      if (state is AuthAuthenticated) authenticate = state.authenticate;
      if (state is AuthUnauthenticated) authenticate = state.authenticate;
      company = authenticate?.company;
      return Scaffold(
        appBar: AppBar(
            title: Text("${company?.name ?? 'Company??'} " +
                "${authenticate?.apiKey != null ? "- username: " + authenticate!.user!.name! : ''}"),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () async {
                    await _settingsDialog(context, authenticate);
                  }),
              if (authenticate?.apiKey == null)
                IconButton(
                    icon: Icon(Icons.exit_to_app),
                    tooltip: 'Login',
                    onPressed: () async {
                      if (await Navigator.pushNamed(context, '/login') ==
                          true) {
                        Navigator.popAndPushNamed(context, '/',
                            arguments: 'Login Successful');
                      } else {
                        HelperFunctions.showMessage(
                            context, 'Not logged in', Colors.green);
                      }
                    }),
              if (authenticate?.apiKey != null)
                IconButton(
                    icon: Icon(Icons.do_not_disturb),
                    tooltip: 'Logout',
                    onPressed: () => {
                          BlocProvider.of<AuthBloc>(context).add(Logout()),
                          Future<Null>.delayed(Duration(milliseconds: 300), () {
                            Navigator.popAndPushNamed(context, '/',
                                arguments: 'Logout successful');
                          })
                        })
            ]),
        body: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            _OpenContainerWrapper(
              transitionType: _transitionType,
              closedBuilder: (BuildContext _, VoidCallback openContainer) {
                return _topCard(openContainer: openContainer);
              },
            ),
            const SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: _OpenContainerWrapper(
                    transitionType: _transitionType,
                    closedBuilder:
                        (BuildContext _, VoidCallback openContainer) {
                      return _menuCard(
                        openContainer: openContainer,
                        image: 'assets/images/reservation.png',
                        subtitle: 'Reservation',
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _OpenContainerWrapper(
                    transitionType: _transitionType,
                    closedBuilder:
                        (BuildContext _, VoidCallback openContainer) {
                      return _menuCard(
                        openContainer: openContainer,
                        image: 'assets/images/single-bed.png',
                        subtitle: 'Rooms',
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _OpenContainerWrapper(
                    transitionType: _transitionType,
                    closedBuilder:
                        (BuildContext _, VoidCallback openContainer) {
                      return _menuCard(
                        openContainer: openContainer,
                        image: 'assets/images/check-in.png',
                        subtitle: 'Check-In',
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _OpenContainerWrapper(
                    transitionType: _transitionType,
                    closedBuilder:
                        (BuildContext _, VoidCallback openContainer) {
                      return _menuCard(
                        openContainer: openContainer,
                        image: 'assets/images/check-out.png',
                        subtitle: 'Check-Out',
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _OpenContainerWrapper(
                    transitionType: _transitionType,
                    closedBuilder:
                        (BuildContext _, VoidCallback openContainer) {
                      return _menuCard(
                        openContainer: openContainer,
                        image: 'assets/images/myInfo.png',
                        subtitle: 'My Info',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
              ],
            ),
          ],
        ),
      );
    });
  }

  _settingsDialog(BuildContext context, Authenticate? authenticate) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            title: Text('Settings', textAlign: TextAlign.center),
            content: Container(
              height: 200,
              child: Column(children: <Widget>[
                RaisedButton(
                  child: Text('Select an another company'),
                  onPressed: () async {
                    authenticate!.company!.copyWith(partyId: null);
                    BlocProvider.of<AuthBloc>(context)
                        .add(UpdateAuth(authenticate));
                    Navigator.popAndPushNamed(context, '/login');
                  },
                ),
                SizedBox(height: 20),
                RaisedButton(
                  child: Text('Create a new company and admin'),
                  onPressed: () {
                    authenticate!.company!.copyWith(partyId: null);
                    BlocProvider.of<AuthBloc>(context)
                        .add(UpdateAuth(authenticate));
                    Navigator.popAndPushNamed(context, 'register');
                  },
                ),
                SizedBox(height: 20),
                RaisedButton(
                  child: Text('About'),
                  onPressed: () {
                    Navigator.popAndPushNamed(context, '/about');
                  },
                ),
              ]),
            ));
      },
    );
  }
}

class _OpenContainerWrapper extends StatelessWidget {
  const _OpenContainerWrapper({
    this.closedBuilder,
    this.transitionType,
  });

  final OpenContainerBuilder? closedBuilder;
  final ContainerTransitionType? transitionType;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionType: transitionType!,
      openBuilder: (BuildContext context, VoidCallback _) {
        return DetailForm();
      },
      tappable: false,
      closedBuilder:
          closedBuilder as Widget Function(BuildContext, void Function()),
    );
  }
}

class _topCard extends StatelessWidget {
  const _topCard({this.openContainer});

  final VoidCallback? openContainer;

  @override
  Widget build(BuildContext context) {
    return _InkWellOverlay(
        openContainer: openContainer,
        height: 500,
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: <Widget>[
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: GanttForm(),
              )
            ])));
  }
}

class _menuCard extends StatelessWidget {
  const _menuCard({
    this.openContainer,
    this.image,
    this.subtitle,
  });

  final VoidCallback? openContainer;
  final String? image;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return _InkWellOverlay(
      openContainer: openContainer,
      height: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[Image.asset(image!), Text(subtitle!)],
      ),
    );
  }
}

class _InkWellOverlay extends StatelessWidget {
  const _InkWellOverlay({
    this.openContainer,
    this.width,
    this.height,
    this.child,
  });

  final VoidCallback? openContainer;
  final double? width;
  final double? height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: InkWell(
        onTap: openContainer,
        child: child,
      ),
    );
  }
}

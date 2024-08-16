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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../l10n/generated/core_localizations.dart';
import '../../../templates/templates.dart';
import '../../domains.dart';

class HomeForm extends StatefulWidget {
  final List<MenuOption> menuOptions;
  final String title;
  final String? launcherImage;

  const HomeForm(
      {super.key,
      required this.menuOptions,
      this.title = "",
      this.launcherImage});
  @override
  HomeFormState createState() => HomeFormState();
}

class HomeFormState extends State<HomeForm> {
  late AuthBloc _authBloc;
  Company? company;
  late String classificationId;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    company = context.read<Company?>();
    classificationId = context.read<String>();
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = isAPhone(context);

    Widget appInfo = Center(
        child: Align(
            alignment: Alignment.bottomCenter,
            child: GlobalConfiguration().get("appName") != ''
                ? Text(
                    "${GlobalConfiguration().get("appName")} "
                    "V${GlobalConfiguration().get("version")} "
                    "#${GlobalConfiguration().get("build")}",
                    style: const TextStyle(fontSize: 10))
                : const Text('')));

    return BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
      switch (state.status) {
        case AuthStatus.failure:
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          break;
        default:
          HelperFunctions.showMessage(context, state.message, Colors.green);
      }
    }, builder: (context, state) {
      switch (state.status) {
        case AuthStatus.authenticated:
          return Column(children: [
            Expanded(
                child: DisplayMenuOption(
                    menuList: widget.menuOptions,
                    menuIndex: 0,
                    actions: <Widget>[
                  if (state.authenticate?.apiKey != null &&
                      widget.menuOptions[0].route == '/')
                    IconButton(
                        key: const Key('logoutButton'),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.do_not_disturb,
                            key: Key('HomeFormAuth')),
                        tooltip: 'Logout',
                        onPressed: () => {
                              _authBloc.add(const AuthLoggedOut()),
                            }),
                ])),
            // hidden text be able to load demo data for testing
            if (kDebugMode)
              Text(state.authenticate?.apiKey ?? '',
                  key: const Key('apiKey'),
                  style: const TextStyle(fontSize: 0)),
            if (kDebugMode)
              Text(state.authenticate?.moquiSessionToken ?? '',
                  key: const Key('moquiSessionToken'),
                  style: const TextStyle(fontSize: 0)),
            appInfo
          ]);
        case AuthStatus.unAuthenticated:
          ThemeMode? themeMode = context.read<ThemeBloc>().state.themeMode;
          return Column(children: [
            Expanded(
                child: Scaffold(
                    appBar: AppBar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        key: const Key('HomeFormUnAuth'),
                        title: appBarTitle(
                          context,
                          'Login / New company',
                          isPhone,
                        )),
                    body: Center(
                      child: Column(children: <Widget>[
                        const SizedBox(height: 20),
                        Image(
                            image: AssetImage(themeMode == ThemeMode.light
                                ? 'packages/growerp_core/images/growerp100.png'
                                : 'packages/growerp_core/images/growerpDark100.png'),
                            height: 80,
                            width: 80),
                        if (widget.title.isNotEmpty) const SizedBox(height: 30),
                        Text(widget.title,
                            style: TextStyle(
                                fontSize: isPhone ? 15 : 25,
                                fontWeight: FontWeight.bold)),
                        if (widget.title.isNotEmpty) const SizedBox(height: 30),
                        state.authenticate!.company?.partyId != null
                            ? OutlinedButton(
                                key: const Key('loginButton'),
                                child: Text(CoreLocalizations.of(context)!
                                    .loginWithExistingUserName),
                                onPressed: () async {
                                  await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                            value: _authBloc,
                                            child: const LoginDialog());
                                      });
                                })
                            : const Text('No companies yet, create one!'),
                        Expanded(child: const SizedBox(height: 10)),
                        OutlinedButton(
                            key: const Key('newCompButton'),
                            child: Text(
                                'Register ${classificationId == 'AppHealth' ? 'Patient' : 'Customer'} at ${company == null ? 'Company' : company!.name}'),
                            onPressed: () async {
                              await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BlocProvider.value(
                                        value: _authBloc,
                                        child: const NewCompanyDialog(false));
                                  });
                            }),
                        SizedBox(height: 10),
                        if (company == null)
                          OutlinedButton(
                              key: const Key('newUserButton'),
                              child:
                                  const Text('Create a new company and admin'),
                              onPressed: () async {
                                await showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return BlocProvider.value(
                                          value: _authBloc,
                                          child: const NewCompanyDialog(true));
                                    });
                              }),
                        const SizedBox(height: 50)
                      ]),
                    ))),
            Align(alignment: Alignment.bottomCenter, child: appInfo),
          ]);
        case AuthStatus.failure:
          return FatalErrorForm(message: state.message!);
        default:
          return const LoadingIndicator();
      }
    });
  }
}

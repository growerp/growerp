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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../domains/domains.dart';
import '../../../l10n/generated/core_localizations.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  LoginDialogState createState() => LoginDialogState();
}

class LoginDialogState extends State<LoginDialog> {
  final _loginFormKey = GlobalKey<FormBuilderState>();
  final _moreInfoFormKey = GlobalKey<FormBuilderState>();
  final _changePasswordFormKey = GlobalKey<FormBuilderState>();
  final builderFormKey = GlobalKey<FormBuilderState>();
  late Authenticate authenticate;
  List<Company>? companies;
  String? oldPassword;
  late bool _obscureText;
  late bool _obscureText3;
  late bool _obscureText4;
  late AuthBloc _authBloc;
  late Currency _currencySelected;
  late bool _demoData;
  late String _classification;
  late User? user;
  late String? moquiSessionToken; // in login process used for password
  String? furtherAction;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _classification = context.read<String>();
    authenticate = _authBloc.state.authenticate!;
    _currencySelected = currencies[1];
    _demoData = kReleaseMode ? false : true;
    _obscureText = true;
    _obscureText3 = true;
    _obscureText4 = true;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
              switch (state.status) {
                case AuthStatus.failure:
                  HelperFunctions.showMessage(
                      context, '${state.message}', Colors.red);
                case AuthStatus.authenticated:
                  Navigator.of(context).pop();
                default:
                  HelperFunctions.showMessage(
                      context, state.message, Colors.green);
              }
            }, buildWhen: (previous, current) {
              // Rebuild the UI only when the (apikey=furtherAction) changes
              return previous.authenticate?.apiKey !=
                  current.authenticate?.apiKey;
            }, builder: (context, state) {
              if (state.status == AuthStatus.loading) {
                return const LoadingIndicator();
              }
              furtherAction = state.authenticate?.apiKey;
              user = state.authenticate!.user;
              moquiSessionToken = state.authenticate!.moquiSessionToken;

              return Dialog(
                  insetPadding: const EdgeInsets.all(10),
                  child: furtherAction == 'moreInfo'
                      ? moreInfoForm()
                      : furtherAction == 'payment'
                          ? paymentForm()
                          : furtherAction == 'passwordChange'
                              ? changePasswordForm('', '')
                              : loginForm());
            })));
  }

  Widget changePasswordForm(String username, String oldPassword) {
    return popUp(
        height: 500,
        context: context,
        title: "Create New Password",
        child: FormBuilder(
          key: _changePasswordFormKey,
          child: Column(children: <Widget>[
            const SizedBox(height: 40),
            Text("username: $username"),
            const SizedBox(height: 20),
            FormBuilderTextField(
              name: 'password1',
              key: const Key("password1"),
              autofocus: true,
              obscureText: _obscureText3,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 8 characters, including alpha, number '
                    '&\nspecial character, no previous password.',
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText3 = !_obscureText3;
                    });
                  },
                  child: Icon(
                      _obscureText3 ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                    errorText: 'Please enter first password?'),
                (value) {
                  if (value != null) {
                    final regExpRequire = RegExp(
                        r'^(?=.*[0-9])(?=.*[a-zA-Z])(?=.*[!@#$%^&+=]).{8,}');
                    if (!regExpRequire.hasMatch(value)) {
                      return 'At least 8 characters, including alpha, number & special character.';
                    }
                  }
                  return null;
                },
              ]),
            ),
            const SizedBox(height: 20),
            FormBuilderTextField(
              name: 'password2',
              key: const Key("password2"),
              obscureText: _obscureText4,
              decoration: InputDecoration(
                labelText: 'Verify Password',
                helperText: 'Enter the new password again.',
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText4 = !_obscureText4;
                    });
                  },
                  child: Icon(
                      _obscureText4 ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                    errorText: 'Enter password again to verify?'),
                (value) {
                  final password1 = _changePasswordFormKey
                      .currentState?.fields['password1']?.value;
                  if (value != null &&
                      password1 != null &&
                      value != password1) {
                    return 'Password is not matching';
                  }
                  return null;
                },
              ]),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
                child: const Text('Submit new Password'),
                onPressed: () {
                  if (_changePasswordFormKey.currentState!.saveAndValidate()) {
                    final formData = _changePasswordFormKey.currentState!.value;
                    _authBloc.add(
                      AuthChangePassword(
                        username,
                        oldPassword,
                        formData['password2']?.toString() ?? '',
                      ),
                    );
                  }
                }),
          ]),
        ));
  }

  Widget moreInfoForm() {
    String defaultCompanyName = kReleaseMode ? '' : 'Main Company';

    return popUp(
        height: user?.userGroup == UserGroup.admin ? 450 : 350,
        context: context,
        title: 'Complete your registration',
        child: FormBuilder(
            key: _moreInfoFormKey,
            initialValue: {
              'companyName': defaultCompanyName,
              'currency': _currencySelected,
              'demoData': _demoData,
            },
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                key: const Key('listView'),
                child: Column(key: const Key('moreInfo'), children: <Widget>[
                  Column(children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Welcome!",
                      textAlign: TextAlign.center,
                    ),
                    Text("${user?.firstName} ${user?.lastName}"),
                    if (user?.userGroup == UserGroup.admin)
                      const Text(
                          "please enter both the company name\nand currency for the new company"),
                    if (user?.userGroup != UserGroup.admin)
                      const Text(
                          "please enter optionally a company name you work for."),
                    const SizedBox(height: 10),
                    FormBuilderTextField(
                      name: 'companyName',
                      key: const Key('companyName'),
                      decoration: const InputDecoration(
                          labelText: 'Business Company name'),
                      validator: user?.userGroup == UserGroup.admin
                          ? FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                  errorText:
                                      'Please enter business name("Private" for Private person)'),
                            ])
                          : null,
                    ),
                    if (user?.userGroup == UserGroup.admin)
                      const SizedBox(height: 10),
                    if (user?.userGroup == UserGroup.admin)
                      FormBuilderDropdown<Currency>(
                        name: 'currency',
                        key: const Key('currency'),
                        decoration:
                            const InputDecoration(labelText: 'Currency'),
                        hint: const Text('Currency'),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText: 'Currency field required!'),
                        ]),
                        items: currencies.map((item) {
                          return DropdownMenuItem<Currency>(
                              value: item, child: Text(item.description!));
                        }).toList(),
                        onChanged: (Currency? newValue) {
                          setState(() {
                            _currencySelected = newValue!;
                          });
                        },
                      ),
                    const SizedBox(height: 10),
                    if (user?.userGroup == UserGroup.admin)
                      FormBuilderCheckbox(
                        name: 'demoData',
                        key: const Key('demoData'),
                        title: const Text("Generate demo data"),
                        decoration: const InputDecoration(
                          labelText: 'DemoData',
                          border: InputBorder.none,
                        ),
                        onChanged: (bool? value) {
                          setState(() {
                            _demoData = value ?? false;
                          });
                        },
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                        key: const Key('continue'),
                        child: const Text('Continue'),
                        onPressed: () {
                          if (_moreInfoFormKey.currentState!
                              .saveAndValidate()) {
                            final formData =
                                _moreInfoFormKey.currentState!.value;

                            context.read<AuthBloc>().add(AuthLogin(
                                user!.loginName!,
                                moquiSessionToken!, // returned password
                                companyName:
                                    formData['companyName']?.toString() ?? '',
                                currency:
                                    formData['currency'] ?? _currencySelected,
                                demoData: formData['demoData'] ?? _demoData));
                          }
                        })
                  ])
                ]))));
  }

  Widget loginForm() {
    String defaultUsername = authenticate.user?.loginName ??
        (kReleaseMode
            ? ''
            : _classification == 'AppSupport'
                ? 'SystemSupport'
                : 'test@example.com');
    String defaultPassword = kReleaseMode
        ? ''
        : _classification == 'AppSupport'
            ? 'moqui'
            : 'qqqqqq9!';

    return popUp(
        height: isPhone(context) ? 300 : 280,
        width: 400,
        context: context,
        title: CoreLocalizations.of(context)!.loginWithExistingUserName,
        child: FormBuilder(
            key: _loginFormKey,
            initialValue: {
              'username': defaultUsername,
              'password': defaultPassword,
            },
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              key: const Key('listView'),
              child: Column(children: <Widget>[
                FormBuilderTextField(
                  name: 'username',
                  autofocus: defaultUsername.isEmpty,
                  key: const Key('username'),
                  decoration:
                      const InputDecoration(labelText: 'Username/Email'),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'Please enter username or email?'),
                  ]),
                ),
                FormBuilderTextField(
                    name: 'password',
                    autofocus: defaultUsername.isNotEmpty,
                    key: const Key('password'),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Please enter your password?'),
                    ]),
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        child: Icon(_obscureText
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    )),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          key: const Key('login'),
                          child: const Text('Login'),
                          onPressed: () {
                            if (_loginFormKey.currentState!.saveAndValidate()) {
                              final formData =
                                  _loginFormKey.currentState!.value;

                              _authBloc.add(AuthLogin(
                                  formData['username']?.toString().trim() ?? '',
                                  formData['password']?.toString().trim() ??
                                      ''));
                            }
                          }))
                ]),
                const SizedBox(height: 20),
                Center(
                    child: GestureDetector(
                        child: const Text('forgot/change password?'),
                        onTap: () async {
                          String username = authenticate.user?.loginName ??
                              (kReleaseMode ? '' : 'test@example.com');
                          await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                    value: _authBloc,
                                    child: SendResetPasswordDialog(username));
                              });
                        })),
              ]),
            )));
  }

  Widget paymentForm() {
    return popUp(
        height: isPhone(context) ? 700 : 700,
        width: 400,
        context: context,
        title: "Subscription",
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: FormBuilder(
            autovalidateMode: AutovalidateMode.onUnfocus,
            key: builderFormKey,
            child: SingleChildScrollView(
              child: Column(children: <Widget>[
                const Center(
                  child: Text(
                    'Just testing?\ntry free system at https://admin.growerp.org',
                    style: TextStyle(fontSize: 16, color: Colors.yellow),
                  ),
                ),
                const SizedBox(height: 10),
                FormBuilderCheckboxGroup(
                  key: const Key('plan'),
                  name: 'plan',
                  options: const [
                    FormBuilderFieldOption(
                        value: 'diyPlan',
                        child: Text(
                            'DIY Plan \$50 per month\nFull functionality, unlimited users\nsupport charged extra \$75/hr')),
                    FormBuilderFieldOption(
                        value: 'smallPlan',
                        child: Text(
                            'Small Company Plan \$499 per month\nFull functionality, unlimited users\nincluding support for 20hrs/month')),
                    FormBuilderFieldOption(
                        value: 'fullPlan',
                        child: Text(
                            'Full Company Plan \$999 per month\nFull functionality, unlimited users\nincluding support for 40hrs/month')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Payment Plan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    ),
                  ),
                  onChanged: (value) {
                    // FormBuilder automatically handles form state
                  },
                  validator: FormBuilderValidators.compose([
                    (val) {
                      if (val == null || val.isEmpty || val.length > 1) {
                        return 'Please select a single plan';
                      }
                      return null;
                    }
                  ]),
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Credit card information',
                    hintText: 'Enter your credit card details',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FormBuilderTextField(
                          name: 'cardNumber',
                          decoration: const InputDecoration(
                            labelText: 'Number',
                            hintText: 'XXXX XXXX XXXX XXXX',
                          ),
                          validator: FormBuilderValidators.creditCard()),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: FormBuilderTextField(
                                name: 'expiryDate',
                                decoration: const InputDecoration(
                                  labelText: 'Expiry month/year',
                                  hintText: 'XX/XX',
                                ),
                                validator: FormBuilderValidators
                                    .creditCardExpirationDate()),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: FormBuilderTextField(
                                name: 'cvvCode',
                                decoration: const InputDecoration(
                                  labelText: 'CVC Code',
                                  hintText: 'XXX',
                                ),
                                validator:
                                    FormBuilderValidators.creditCardCVC()),
                          ),
                        ],
                      ),
                      FormBuilderTextField(
                          name: 'cardHolderName',
                          decoration: const InputDecoration(
                            labelText: 'Name on Card',
                          )),
                      const SizedBox(height: 20),
                      Center(
                        child: OutlinedButton(
                            key: const Key('pay'),
                            child: const Text('Pay'),
                            onPressed: () {
                              if (builderFormKey.currentState!
                                  .saveAndValidate()) {
                                final formData =
                                    builderFormKey.currentState!.value;

                                final selectedPlan = formData['plan'] as List?;
                                final expiryDateValue =
                                    formData['expiryDate']?.toString() ?? '';
                                final expiryParts = expiryDateValue.split('/');

                                context.read<AuthBloc>().add(AuthLogin(
                                    user!.loginName!,
                                    moquiSessionToken!, // returned password
                                    creditCardNumber: formData['cardNumber']
                                            ?.toString()
                                            .replaceAll(' ', '') ??
                                        '',
                                    nameOnCard: formData['cardHolderName']
                                            ?.toString() ??
                                        '',
                                    cVC: formData['cvvCode']?.toString() ?? '',
                                    plan: selectedPlan?.isNotEmpty == true
                                        ? selectedPlan![0]
                                        : '',
                                    expireMonth: expiryParts.isNotEmpty
                                        ? expiryParts[0]
                                        : '',
                                    expireYear: expiryParts.length > 1
                                        ? expiryParts[1]
                                        : ''));
                              }
                            }),
                      )
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ));
  }
}

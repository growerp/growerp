/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:growerp_models/growerp_models.dart';


import 'package:growerp_core/growerp_core.dart';

/// Dialog for collecting tenant setup information (company name, currency, demo data)
/// This is shown to admin users after registration to complete tenant setup.
class TenantSetupDialog extends StatefulWidget {
  final Authenticate authenticate;

  const TenantSetupDialog({super.key, required this.authenticate});

  @override
  TenantSetupDialogState createState() => TenantSetupDialogState();
}

class TenantSetupDialogState extends State<TenantSetupDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  Currency? _currencySelected;
  int _fiscalYearStartMonth = 1;
  late bool _demoData;
  bool _isSubmitting = false;
  bool _isLoadingCurrencies = true;

  @override
  void initState() {
    super.initState();
    _demoData = kReleaseMode ? false : true; // Demo data in debug mode
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final restClient = context.read<RestClient>();
      await loadCurrencies(restClient);
      if (mounted) {
        setState(() {
          _isLoadingCurrencies = false;
          if (kDebugMode && _currencySelected == null) {
            _currencySelected = currencies.firstWhere(
              (c) => c.currencyId == 'USD',
              orElse: () => Currency(
                currencyId: 'USD',
                description: 'United States Dollar',
              ),
            );
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCurrencies = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context);

    return popUp(
      context: context,
      title: 'Company Setup',
      height: 550,
      width: 400,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state.status == AuthStatus.authenticated) {
            // LoginDialog.BlocConsumer handles the trial welcome and navigation.
          } else if (state.status == AuthStatus.failure) {
            setState(() => _isSubmitting = false);
            HelperFunctions.showMessage(
              context,
              state.message ?? 'Setup failed',
              Theme.of(context).colorScheme.error,
            );
          }
        },
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Text(
                        CoreLocalizations.of(context)!.pleaseProvideYourCompanyInformationToCom,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),

                      // Company Name
                      FormBuilderTextField(
                        key: const Key('companyName'),
                        name: 'companyName',
                        autofocus: true,
                        initialValue:
                            widget.authenticate.ownerPartyId == 'GROWERP'
                            ? 'GrowERP'
                            : kDebugMode
                            ? 'Company ${widget.authenticate.user?.email?.split('@').first ?? ''}'
                            : null,
                        decoration: InputDecoration(
                                labelText: CoreLocalizations.of(context)!.enterCompanyName,
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(3),
                        ]),
                      ),
                      SizedBox(height: 20),

                      // Currency Selection
                      if (_isLoadingCurrencies)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        )
                      else
                        AutocompleteLabel<Currency>(
                          key: const Key('currency'),
                          label: localizations?.currency ?? 'Currency',
                          initialValue: _currencySelected,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return currencies;
                            }
                            return currencies.where(
                              (Currency c) =>
                                  '${c.description} [${c.currencyId}]'
                                      .toLowerCase()
                                      .contains(
                                        textEditingValue.text.toLowerCase(),
                                      ),
                            );
                          },
                          displayStringForOption: (Currency c) =>
                              '${c.description} [${c.currencyId}]',
                          onSelected: (Currency? value) {
                            if (value != null) {
                              setState(() => _currencySelected = value);
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Currency is required';
                            }
                            return null;
                          },
                        ),
                      SizedBox(height: 20),

                      // Accounting year start
                      FiscalYearStartDropdown(
                        value: _fiscalYearStartMonth,
                        label:
                            localizations?.accountingYearStarts ??
                            'Accounting year starts',
                        onChanged: (value) => setState(
                          () => _fiscalYearStartMonth = value ?? 1,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Demo Data Checkbox (only in debug mode or if explicitly shown)
                      if ((!kReleaseMode ||
                              widget.authenticate.user?.userGroup ==
                                  UserGroup.admin) &&
                          widget.authenticate.ownerPartyId != 'GROWERP')
                        FormBuilderCheckbox(
                          key: const Key('demoData'),
                          name: 'demoData',
                          initialValue: _demoData,
                          title: Text(
                            CoreLocalizations.of(context)!.loadDemoData,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            CoreLocalizations.of(context)!.populateYourSystemWithSampleDataForTesti,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onChanged: (value) {
                            setState(() => _demoData = value ?? false);
                          },
                        ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Submit Button Row (fixed at bottom)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('cancel'),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(CoreLocalizations.of(context)!.cancel),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('submit'),
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(CoreLocalizations.of(context)!.completeSetup),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isSubmitting = true);

      final formData = _formKey.currentState!.value;
      final companyName = formData['companyName'] as String;
      final currency = _currencySelected;
      final demoData = formData['demoData'] as bool? ?? false;

      // Send setup data through login endpoint
      // The backend login service will call complete#TenantSetup internally
      if (mounted) {
        context.read<AuthBloc>().add(
          AuthLogin(
            widget.authenticate.user!.email!,
            widget.authenticate.moquiSessionToken!,
            companyName: companyName,
            currency: currency,
            fiscalYearStartMonth: _fiscalYearStartMonth,
            demoData: demoData,
          ),
        );
      }
    }
  }
}

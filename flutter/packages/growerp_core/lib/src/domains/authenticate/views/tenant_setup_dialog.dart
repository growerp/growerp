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
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';

import '../../../domains/domains.dart';

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
  late Currency _currencySelected;
  late bool _demoData;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currencySelected = currencies[1]; // Default to USD
    _demoData = kReleaseMode ? false : true; // Demo data in debug mode
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context);

    return popUp(
      context: context,
      title: 'Company Setup',
      height: 450,
      width: 400,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state.status == AuthStatus.authenticated) {
            // Setup complete - show trial welcome if needed
            // NOTE: We do NOT call Navigator.pop() here because TenantSetupDialog
            // is embedded inside LoginDialog (not a separate route). The LoginDialog's
            // BlocConsumer already handles navigation when authenticated.
            await TrialWelcomeHelper.showTrialWelcomeIfNeeded(
              context: context,
              authenticate: state.authenticate,
            );
            // LoginDialog will handle closing/navigation
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
                      const SizedBox(height: 20),
                      Text(
                        'Please provide your company information to complete setup',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Company Name
                      FormBuilderTextField(
                        key: const Key('companyName'),
                        name: 'companyName',
                        autofocus: true,
                        initialValue:
                            widget.authenticate.ownerPartyId == 'GROWERP'
                            ? 'GrowERP'
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(3),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // Currency Selection
                      FormBuilderDropdown<Currency>(
                        key: const Key('currency'),
                        name: 'currency',
                        decoration: InputDecoration(
                          labelText: localizations?.currency ?? 'Currency',
                        ),
                        initialValue: _currencySelected,
                        items: currencies
                            .map(
                              (currency) => DropdownMenuItem(
                                value: currency,
                                child: Text(
                                  '${currency.description} [${currency.currencyId}]',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Currency? value) {
                          if (value != null) {
                            setState(() => _currencySelected = value);
                          }
                        },
                        validator: FormBuilderValidators.required(),
                      ),
                      const SizedBox(height: 20),

                      // Demo Data Checkbox (only in debug mode or if explicitly shown)
                      if (!kReleaseMode ||
                          widget.authenticate.user?.userGroup ==
                              UserGroup.admin)
                        FormBuilderCheckbox(
                          key: const Key('demoData'),
                          name: 'demoData',
                          initialValue: _demoData,
                          title: Text(
                            'Load Demo Data',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            'Populate your system with sample data for testing',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onChanged: (value) {
                            setState(() => _demoData = value ?? false);
                          },
                        ),
                      const SizedBox(height: 20),
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
                        child: Text(localizations?.cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('submit'),
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Complete Setup'),
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
      final currency = formData['currency'] as Currency;
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
            demoData: demoData,
          ),
        );
      }
    }
  }
}

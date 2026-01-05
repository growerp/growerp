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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';

import '../../../domains/domains.dart';

/// Dialog for handling subscription renewal and payment
class PaymentSubscriptionDialog extends StatefulWidget {
  final Authenticate authenticate;

  const PaymentSubscriptionDialog({super.key, required this.authenticate});

  @override
  PaymentSubscriptionDialogState createState() =>
      PaymentSubscriptionDialogState();
}

class PaymentSubscriptionDialogState extends State<PaymentSubscriptionDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;
  String _selectedPlan = 'smallPlan';

  // Test data for payment forms - auto-fill when in test mode
  String get _testCardNumber {
    bool test = GlobalConfiguration().get("test");
    return kReleaseMode && !test ? '' : '4242424242424242';
  }

  String get _testNameOnCard {
    bool test = GlobalConfiguration().get("test");
    return kReleaseMode && !test ? '' : 'Test Customer';
  }

  String get _testExpireMonth {
    bool test = GlobalConfiguration().get("test");
    return kReleaseMode && !test ? '' : '11';
  }

  String get _testExpireYear {
    bool test = GlobalConfiguration().get("test");
    return kReleaseMode && !test ? '' : '33';
  }

  String get _testCvc {
    bool test = GlobalConfiguration().get("test");
    return kReleaseMode && !test ? '' : '123';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context);
    final daysRemaining = widget.authenticate.evaluationDays ?? 0;

    return popUp(
      context: context,
      title: 'Subscription Required',
      height: 600,
      width: 500,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            // Don't pop here - LoginDialog will handle navigation
            // The dialog will be dismissed automatically when LoginDialog rebuilds
            // Just reset the submitting state in case of any UI updates
            if (mounted) {
              setState(() => _isSubmitting = false);
            }
          } else if (state.status == AuthStatus.failure) {
            setState(() => _isSubmitting = false);
            HelperFunctions.showMessage(
              context,
              state.message ?? 'Payment failed',
              Theme.of(context).colorScheme.error,
            );
          }
        },
        child: SingleChildScrollView(
          key: const Key('paymentForm'),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: daysRemaining > 0
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        daysRemaining > 0 ? Icons.info : Icons.warning,
                        color: daysRemaining > 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          daysRemaining > 0
                              ? 'Your trial expires in $daysRemaining days'
                              : 'Your subscription has expired',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Plan Selection
                Text(
                  'Select a Plan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildPlanOption(
                  'DIY Plan',
                  'diyPlan',
                  '\$29/month',
                  'Perfect for individuals and small teams',
                ),
                const SizedBox(height: 12),
                _buildPlanOption(
                  'Small Business',
                  'smallPlan',
                  '\$99/month',
                  'For growing businesses',
                ),
                const SizedBox(height: 12),
                _buildPlanOption(
                  'Full Plan',
                  'fullPlan',
                  '\$299/month',
                  'Complete solution for enterprises',
                ),
                const SizedBox(height: 30),

                // Payment Form
                FormBuilder(
                  key: _formKey,
                  initialValue: {
                    'nameOnCard': _testNameOnCard,
                    'cardNumber': _testCardNumber,
                    'expireMonth': _testExpireMonth,
                    'expireYear': _testExpireYear,
                    'cvc': _testCvc,
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        key: const Key('nameOnCard'),
                        name: 'nameOnCard',
                        decoration: const InputDecoration(
                          labelText: 'Name on Card',
                        ),
                        validator: FormBuilderValidators.required(),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        key: const Key('cardNumber'),
                        name: 'cardNumber',
                        decoration: const InputDecoration(
                          labelText: 'Card Number',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.creditCard(),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FormBuilderTextField(
                              key: const Key('expireMonth'),
                              name: 'expireMonth',
                              decoration: const InputDecoration(
                                labelText: 'MM',
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                                FormBuilderValidators.min(1),
                                FormBuilderValidators.max(12),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FormBuilderTextField(
                              key: const Key('expireYear'),
                              name: 'expireYear',
                              decoration: const InputDecoration(
                                labelText: 'YY',
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FormBuilderTextField(
                              key: const Key('cvc'),
                              name: 'cvc',
                              decoration: const InputDecoration(
                                labelText: 'CVC',
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                                FormBuilderValidators.minLength(3),
                                FormBuilderValidators.maxLength(4),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Submit Button
                Row(
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('pay'),
                        onPressed: _isSubmitting ? null : _handleSubscribe,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Subscribe Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanOption(
    String title,
    String planId,
    String price,
    String description,
  ) {
    final isSelected = _selectedPlan == planId;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = planId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        price,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isSubmitting = true);

      final formData = _formKey.currentState!.value;

      // Trigger login with payment information
      // The backend will handle subscription creation
      context.read<AuthBloc>().add(
        AuthLogin(
          widget.authenticate.user!.email!,
          widget.authenticate.moquiSessionToken!,
          creditCardNumber: formData['cardNumber'] as String,
          nameOnCard: formData['nameOnCard'] as String,
          expireMonth: formData['expireMonth'] as String,
          expireYear: formData['expireYear'] as String,
          cVC: formData['cvc'] as String,
          plan: _selectedPlan,
        ),
      );
    }
  }
}

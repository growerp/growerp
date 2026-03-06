/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/course_bloc.dart';

/// Payment dialog shown when a participant taps Subscribe on a course.
/// Shows the course price (or "Free") and collects credit card details
/// when a price is set. Auto-fills test data in debug/test mode.
class CoursePaymentDialog extends StatefulWidget {
  final Course course;

  const CoursePaymentDialog({super.key, required this.course});

  @override
  State<CoursePaymentDialog> createState() => _CoursePaymentDialogState();
}

class _CoursePaymentDialogState extends State<CoursePaymentDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;

  bool get _isTest {
    try {
      final test = GlobalConfiguration().get('test');
      return !kReleaseMode || (test is bool && test);
    } catch (_) {
      return !kReleaseMode;
    }
  }

  bool get _isFree {
    final price = widget.course.price;
    return price == null || price.toDouble() == 0;
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final priceLabel = _isFree
        ? 'Free'
        : '\$${course.price!.toStringAsFixed(2)}';

    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state.status == CourseBlocStatus.success &&
            state.message != null &&
            state.message!.contains('subscribed')) {
          Navigator.of(context).pop(true);
        } else if (state.status == CourseBlocStatus.failure) {
          setState(() => _isSubmitting = false);
          HelperFunctions.showMessage(
            context,
            state.message ?? 'Subscription failed',
            Theme.of(context).colorScheme.error,
          );
        }
      },
      child: popUp(
        context: context,
        title: 'Subscribe to Course',
        height: _isFree ? 280 : 560,
        width: 500,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course info
                Text(
                  course.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Price: ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      priceLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isFree
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Credit card form — only for paid courses
                if (!_isFree) ...[
                  Text(
                    'Payment Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FormBuilder(
                    key: _formKey,
                    initialValue: {
                      'nameOnCard': _isTest ? 'Test Customer' : '',
                      'cardNumber':
                          _isTest ? '4242424242424242' : '',
                      'expireMonth': _isTest ? '11' : '',
                      'expireYear': _isTest ? '33' : '',
                      'cvc': _isTest ? '123' : '',
                    },
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          key: const Key('nameOnCard'),
                          name: 'nameOnCard',
                          decoration: const InputDecoration(
                            labelText: 'Name on Card',
                          ),
                          validator: FormBuilderValidators.required(),
                        ),
                        const SizedBox(height: 12),
                        FormBuilderTextField(
                          key: const Key('cardNumber'),
                          name: 'cardNumber',
                          decoration: const InputDecoration(
                            labelText: 'Card Number',
                          ),
                          keyboardType: TextInputType.number,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.creditCard(),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FormBuilderTextField(
                                key: const Key('expireMonth'),
                                name: 'expireMonth',
                                decoration: const InputDecoration(
                                  labelText: 'MM',
                                ),
                                keyboardType: TextInputType.number,
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
                                keyboardType: TextInputType.number,
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
                                keyboardType: TextInputType.number,
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
                  const SizedBox(height: 24),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('cancel'),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('subscribe'),
                        onPressed: _isSubmitting ? null : _handleSubscribe,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Text(_isFree
                                ? 'Subscribe for Free'
                                : 'Subscribe'),
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

  void _handleSubscribe() {
    if (!_isFree && !(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }
    setState(() => _isSubmitting = true);

    final formData = _isFree ? <String, dynamic>{} : _formKey.currentState!.value;

    context.read<CourseBloc>().add(
          CourseSubscribe(
            courseId: widget.course.courseId!,
            creditCardNumber:
                _isFree ? null : formData['cardNumber'] as String?,
            nameOnCard: _isFree ? null : formData['nameOnCard'] as String?,
            expireMonth: _isFree ? null : formData['expireMonth'] as String?,
            expireYear: _isFree ? null : formData['expireYear'] as String?,
            cVC: _isFree ? null : formData['cvc'] as String?,
          ),
        );
  }
}

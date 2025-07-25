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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:decimal/decimal.dart';

class PlanSelectionForm extends StatefulWidget {
  const PlanSelectionForm({super.key});

  @override
  State<PlanSelectionForm> createState() => _PlanSelectionFormState();
}

class _PlanSelectionFormState extends State<PlanSelectionForm> {
  final builderFormKey = GlobalKey<FormBuilderState>();

  late DataFetchBloc<Products> productBloc;
  late DataFetchBloc<Subscriptions> getSubscriptionBloc;
  late SubscriptionBloc subscriptionBloc;
  late Subscription subscription;
  late String selectedPlan;

  @override
  void initState() {
    super.initState();
    productBloc = context.read<DataFetchBloc<Products>>()
      ..add(GetDataEvent(() =>
          context.read<RestClient>().getProduct(ownerPartyId: 'GROWERP')));
    getSubscriptionBloc = context.read<DataFetchBloc<Subscriptions>>()
      ..add(GetDataEvent(
          () => context.read<RestClient>().getSubscription(growerp: true)));
    subscriptionBloc = context.read<SubscriptionBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DataFetchBloc<Products>, DataFetchState<Products>>(
      listener: (context, state) {
        if (state.status == DataFetchStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        if (state.data is! Products) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DataFetchStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        } else if ((state.data as Products).products.isEmpty) {
          return const Center(child: Text('No plans available'));
        }
        Products productsList = state.data as Products;
        List<Product> products = List.from(productsList.products)
          ..sort((a, b) => ((a.price ?? Decimal.zero).toDouble())
              .compareTo((b.price ?? Decimal.zero).toDouble()));
        subscription = (context.read<DataFetchBloc<Subscriptions>>().state.data
                as Subscriptions)
            .subscriptions
            .first;
        selectedPlan = subscription.productId!;
        return Center(
          child: SizedBox(
            width: 400,
            child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: FormBuilder(
                    autovalidateMode: AutovalidateMode.always,
                    key: builderFormKey,
                    child: SingleChildScrollView(
                      key: const Key('paymentForm'),
                      child: Column(
                        children: <Widget>[
                          FormBuilderCheckboxGroup(
                            key: const Key('plan'),
                            initialValue: [selectedPlan],
                            name: 'plan',
                            orientation: OptionsOrientation.vertical,
                            options: [
                              for (Product product in products)
                                FormBuilderFieldOption(
                                    value: product.productId,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: product.description!
                                          .split('|')
                                          .asMap()
                                          .entries
                                          .map((entry) => entry.key == 0
                                              ? Text(
                                                  '\n+${entry.value}',
                                                  style: const TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              : Text(entry.value))
                                          .toList(),
                                    )),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Payment Plans',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25.0)),
                              ),
                            ),
                            onChanged: (value) async {
                              // Ensure only a single option is checked
                              if (value == null || value.isEmpty) {
                                // If nothing is selected, revert to the current plan
                                builderFormKey.currentState?.fields['plan']
                                    ?.didChange([subscription.productId!]);
                                return;
                              }
                              final lastSelected = value.last;
                              if (value.length > 1) {
                                // If more than one is selected, keep only the last selected
                                builderFormKey.currentState?.fields['plan']
                                    ?.didChange([lastSelected]);
                                selectedPlan = lastSelected;
                              } else {
                                selectedPlan = value.first;
                              }

                              if (selectedPlan != subscription.productId) {
                                var product = products.firstWhere(
                                    (p) => p.productId == selectedPlan,
                                    orElse: () => products.first);
                                bool? result = await confirmDialog(
                                    context,
                                    'Change your plan',
                                    'Are you sure you want to change your plan to:\n'
                                        ' ${product.description!.split('|').first}?');
                                if (result == true) {
                                  subscriptionBloc
                                      .add(SubscriptionUpdate(subscription));
                                } else {
                                  // Revert to the current plan if the user cancels
                                  builderFormKey.currentState?.fields['plan']
                                      ?.didChange([subscription.productId!]);
                                  selectedPlan = lastSelected;
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ))),
          ),
        );
      },
    );
  }
}

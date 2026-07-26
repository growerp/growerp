// ignore_for_file: unnecessary_string_interpolations

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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../accounting/accounting.dart';
import '../findoc.dart';

class PaymentTypeListItem extends StatelessWidget {
  const PaymentTypeListItem({
    super.key,
    required this.paymentType,
    required this.index,
  });

  final PaymentType paymentType;
  final int index;

  @override
  Widget build(BuildContext context) {
    GlAccountBloc glAccountBloc = context.read<GlAccountBloc>();
    FinDocBloc finDocBloc = context.read<FinDocBloc>();

    var accountSelect = BlocBuilder<GlAccountBloc, GlAccountState>(
      builder: (context, state) {
        switch (state.status) {
          case GlAccountStatus.failure:
            return const FatalErrorForm(message: 'server connection problem');
          case GlAccountStatus.success:
            final initialText =
                '${paymentType.accountCode} ${paymentType.accountName}'.trim();
            final ptKey =
                '${paymentType.paymentTypeId}_${paymentType.isPayable ? 1 : 0}_${paymentType.isApplied ? 1 : 0}';
            return Autocomplete<GlAccount>(
              key: Key('glAccount_$ptKey'),
              initialValue: TextEditingValue(text: initialText),
              displayStringForOption: (GlAccount u) =>
                  '${u.accountCode ?? ''} ${u.accountName ?? ''}',
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.toLowerCase();
                if (query.isEmpty) return glAccountBloc.state.glAccounts;
                return glAccountBloc.state.glAccounts.where((gl) {
                  return '${gl.accountCode ?? ''} ${gl.accountName ?? ''}'
                      .toLowerCase()
                      .contains(query);
                }).toList();
              },
              fieldViewBuilder:
                  (context, textController, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      key: Key('glAccountField_$ptKey'),
                      controller: textController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(),
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 250,
                        maxWidth: 400,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, idx) {
                          final gl = options.elementAt(idx);
                          return ListTile(
                            dense: true,
                            title: Text(
                              '${gl.accountCode ?? ''} ${gl.accountName ?? ''}',
                            ),
                            onTap: () => onSelected(gl),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (GlAccount newValue) {
                finDocBloc.add(
                  FinDocUpdatePaymentType(
                    paymentType: paymentType.copyWith(
                      accountCode: newValue.accountCode!,
                      accountName: newValue.accountName!,
                    ),
                    update: true,
                  ),
                );
              },
            );
          default:
            return const Center(child: LoadingIndicator());
        }
      },
    );

    return ListTile(
      leading: CircleAvatar(
        child: Text(paymentType.paymentTypeName.substring(3, 5)),
      ),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              "${paymentType.paymentTypeName} -- "
              "${paymentType.isPayable ? 'Outgoing' : 'Incoming'} -- "
              "${paymentType.isApplied ? 'Y' : 'N'}",
              key: Key('name$index'),
            ),
          ),
          if (!isPhone(context)) Expanded(child: accountSelect),
        ],
      ),
      subtitle: isPhone(context) ? accountSelect : null,
      trailing: IconButton(
        key: Key('delete$index'),
        icon: const Icon(Icons.delete_forever),
        onPressed: () {
          finDocBloc.add(
            FinDocUpdatePaymentType(paymentType: paymentType, delete: true),
          );
        },
      ),
    );
  }
}

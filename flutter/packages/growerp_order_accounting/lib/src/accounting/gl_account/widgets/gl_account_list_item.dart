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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_core/growerp_core.dart';

class GlAccountListItem extends StatelessWidget {
  const GlAccountListItem({
    super.key,
    required this.glAccount,
    required this.index,
  });

  final GlAccount glAccount;
  final int index;

  @override
  Widget build(BuildContext context) {
    final glAccountBloc = context.read<GlAccountBloc>();
    String postedBalance =
        glAccount.postedBalance == null ||
            glAccount.postedBalance.toString() == '0'
        ? ''
        // NumberFormat needs a num: a Decimal reaches it as an untyped argument
        // and only fails at runtime, on its isNegative call
        : Constant.numberFormat.format(glAccount.postedBalance!.toDouble());
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          glAccount.accountCode == null
              ? '?'
              : glAccount.accountCode!.substring(0, 3),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPhone(context))
            Text(
              glAccount.accountName ?? '',
              textAlign: TextAlign.left,
              key: Key('name$index'),
            ),
          Row(
            children: <Widget>[
              if ((isLargerThanPhone(context) && glAccount.isDebit != null))
                Expanded(
                  child: Text(
                    glAccount.accountCode ?? '',
                    key: Key('code$index'),
                  ),
                ),
              if ((isPhone(context) && glAccount.isDebit != null))
                Expanded(
                  child: Text(
                    glAccount.accountCode ?? '',
                    key: Key('code$index'),
                  ),
                ),
              if (isLargerThanPhone(context))
                Expanded(
                  child: Text(
                    glAccount.accountName ?? '',
                    key: Key('name$index'),
                  ),
                ),
              if (isPhone(context))
                Expanded(
                  child: glAccount.isDebit == true
                      ? Text(
                          postedBalance,
                          textAlign: TextAlign.right,
                          key: Key('isDebit$index'),
                        )
                      : const Text(''),
                ),
              if (isLargerThanPhone(context))
                Expanded(
                  child: Text(
                    "${glAccount.accountClass?.description ?? ''} "
                    "${glAccount.isDebit != null
                        ? glAccount.isDebit!
                              ? '(D)'
                              : '(C)'
                        : ' '} ",
                    key: Key('class$index'),
                  ),
                ),
              if (isLargerThanPhone(context))
                Expanded(
                  child: Text(
                    glAccount.accountType?.description ?? '',
                    key: Key('type$index'),
                  ),
                ),
              if (isPhone(context) && glAccount.isDebit == null)
                Text(
                  "debit:${glAccount.postedDebits.toString()} "
                  "credit:${glAccount.postedCredits.toString()}",
                  key: Key('postedBalance$index'),
                ),
              if (isPhone(context))
                Expanded(
                  child: glAccount.isDebit == false
                      ? Text(
                          postedBalance,
                          textAlign: TextAlign.right,
                          key: Key('isDebit$index'),
                        )
                      : const Text(''),
                ),
              if (isLargerThanPhone(context))
                Expanded(
                  child: glAccount.isDebit == null
                      ? Text(
                          glAccount.postedDebits.toString(),
                          textAlign: TextAlign.center,
                        )
                      : glAccount.isDebit == true
                      ? Text(
                          postedBalance,
                          textAlign: TextAlign.right,
                          key: Key('postedBalance$index'),
                        )
                      : const Text(''),
                ),
              if (isLargerThanPhone(context))
                Expanded(
                  child: glAccount.isDebit == null
                      ? Text(
                          glAccount.postedCredits.toString(),
                          textAlign: TextAlign.center,
                        )
                      : glAccount.isDebit == false
                      ? Text(
                          postedBalance,
                          textAlign: TextAlign.right,
                          key: Key('postedBalance$index'),
                        )
                      : const Text(''),
                ),
            ],
          ),
        ],
      ),
      onTap: () async {
        await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) => BlocProvider.value(
            value: glAccountBloc,
            child: GlAccountDialog(glAccount),
          ),
        );
      },
    );
  }
}

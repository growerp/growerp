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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class BalanceSummaryListItem extends StatelessWidget {
  const BalanceSummaryListItem({
    super.key,
    required this.glAccount,
    required this.index,
  });

  final GlAccount glAccount;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          glAccount.accountName!.isEmpty ? '?' : glAccount.accountName![0],
        ),
      ),
      title: Column(
        children: [
          if (isPhone(context)) Text("${glAccount.accountName}"),
          Row(
            children: <Widget>[
              Expanded(
                child: Text("${glAccount.accountCode}", key: Key("code$index")),
              ),
              if (!isPhone(context))
                Expanded(
                  child: Text(
                    "${glAccount.accountName}",
                    key: Key("name$index"),
                  ),
                ),
              Expanded(
                child: Text(
                  Constant.numberFormat.format(
                    Decimal.parse(
                      glAccount.beginningBalance.toString(),
                    ).toDouble(),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (!isPhone(context))
                Expanded(
                  child: Text(
                    Constant.numberFormat.format(
                      Decimal.parse(
                        glAccount.postedDebits.toString(),
                      ).toDouble(),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              if (!isPhone(context))
                Expanded(
                  child: Text(
                    Constant.numberFormat.format(
                      Decimal.parse(
                        glAccount.postedCredits.toString(),
                      ).toDouble(),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              Expanded(
                child: Text(
                  Constant.numberFormat.format(
                    Decimal.parse(
                      glAccount.postedBalance.toString(),
                    ).toDouble(),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () async {
        /*          await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) => RepositoryProvider.value(
                  value: repos,
                  child: BlocProvider.value(
                      value: balanceSummaryBloc,
                      child: BalanceSummaryDialog(balanceSummary))));
    */
      },
      /*       trailing: IconButton(
          key: Key('delete$index'),
          icon: const Icon(Icons.delete_forever),
          onPressed: () {
            balanceSummaryBloc
                .add(BalanceSummaryDelete(balanceSummary.copyWith(image: null)));
          },
        )*/
    );
  }
}

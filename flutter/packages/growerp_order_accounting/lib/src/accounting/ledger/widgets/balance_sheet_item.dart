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
import 'package:growerp_models/growerp_models.dart';

class BalanceSheetItem extends StatelessWidget {
  const BalanceSheetItem({
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
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              "${glAccount.accountCode} ${glAccount.accountName}",
              key: Key("code$index"),
            ),
          ),
          Expanded(
            child: Text(
              glAccount.beginningBalance.toString(),
              key: Key("openBalance$index"),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              glAccount.postedDebits.toString(),
              key: Key("name$index"),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              glAccount.postedCredits.toString(),
              key: Key("name$index"),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              glAccount.postedBalance.toString(),
              key: Key("name$index"),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

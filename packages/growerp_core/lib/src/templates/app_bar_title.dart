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
import '../domains/domains.dart';

Widget appBarTitle(
    BuildContext context, Authenticate authenticate, String title) {
  return Row(children: [
    InkWell(
      key: const Key('tapCompany'),
      onTap: () {
        if (authenticate.apiKey != null) {
          Navigator.pushNamed(context, '/company', arguments: FormArguments());
        }
      },
      child: CircleAvatar(
          backgroundColor: Colors.green,
          radius: 15,
          child: authenticate.company?.image != null
              ? Image.memory(authenticate.company!.image!)
              : Text(
                  authenticate.company?.name != null &&
                          authenticate.company!.name!.isNotEmpty
                      ? authenticate.company!.name!.substring(0, 1)
                      : '?',
                  style: const TextStyle(fontSize: 20, color: Colors.black))),
    ),
    const SizedBox(width: 10),
    Column(children: [
      Text(title, style: const TextStyle(fontSize: 20, color: Colors.black)),
      Text(authenticate.company?.name ?? '??',
          key: const Key('appBarCompanyName'),
          style: const TextStyle(fontSize: 10, color: Colors.black)),
    ]),
  ]);
}

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
import 'package:growerp_models/growerp_models.dart';

Widget appBarTitle(BuildContext context, Authenticate authenticate,
    String title, bool isPhone) {
  return Row(children: [
    InkWell(
      key: const Key('tapCompany'),
      onTap: () {
        if (authenticate.apiKey != null) {
          Navigator.pushNamed(context, '/company',
              arguments: authenticate.company);
        }
      },
      child: CircleAvatar(
          radius: 15,
          child: authenticate.company?.image != null
              ? Image.memory(authenticate.company!.image!)
              : Text(
                  authenticate.company?.name != null &&
                          authenticate.company!.name!.isNotEmpty
                      ? authenticate.company!.name!.substring(0, 1)
                      : '?',
                  key: const Key('appBarAvatarText'),
                )),
    ),
    const SizedBox(width: 5),
    Column(children: [
      Text(
        isPhone ? title : title.replaceAll('\n', ' '),
        style: const TextStyle(fontSize: 18),
        key: const Key('appBarTitle'),
      ),
      Text(authenticate.company?.name ?? '??',
          key: const Key('appBarCompanyName'),
          style: const TextStyle(fontSize: 10)),
    ]),
  ]);
}

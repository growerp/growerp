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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

Widget appBarTitle(BuildContext context, String title, bool isPhone) {
  AuthBloc authBloc = context.read<AuthBloc>();
  Authenticate? auth = authBloc.state.authenticate;
  return Row(
    children: [
      InkWell(
        key: const Key('tapCompany'),
        onTap: () {
          Navigator.pushNamed(context, '/company', arguments: auth?.company);
        },
        child: CircleAvatar(
          radius: 15,
          child: auth?.company?.image != null
              ? Image.memory(auth!.company!.image!)
              : Text(
                  auth?.company?.name != null && auth?.company?.name! != ''
                      ? auth!.company!.name!.substring(0, 1)
                      : '',
                  key: const Key('appBarAvatarText'),
                ),
        ),
      ),
      const SizedBox(width: 5),
      Column(
        children: [
          Text(
            isPhone ? title : title.replaceAll('\n', ' '),
            style: const TextStyle(fontSize: 15),
            key: const Key('appBarTitle'),
          ),
          Text(
            auth?.company?.name ?? '',
            key: const Key('appBarCompanyName'),
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    ],
  );
}

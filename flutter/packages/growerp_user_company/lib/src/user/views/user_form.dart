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
import '../views/views.dart';

class UserForm extends StatelessWidget {
  final User user;
  const UserForm({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserBloc>(
        create: (context) =>
            UserBloc(context.read<RestClient>(), user.company!.role!),
        child: UserDialog(user));
  }
}

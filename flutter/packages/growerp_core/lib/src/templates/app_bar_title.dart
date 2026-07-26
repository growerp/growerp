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
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

Widget appBarTitle(BuildContext context, String title, bool isPhone) {
  AuthBloc authBloc = context.read<AuthBloc>();
  Authenticate? auth = authBloc.state.authenticate;
  final colorScheme = Theme.of(context).colorScheme;
  return Row(
    children: [
      InkWell(
        key: const Key('tapCompany'),
        onTap: () {
          context.push('/company', extra: auth?.company);
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: auth?.company?.image != null
                ? Image.memory(
                    auth!.company!.image!,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  )
                : Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Text(
                        auth?.company?.name?.isNotEmpty == true
                            ? auth!.company!.name!.substring(0, 1)
                            : '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        key: const Key('appBarAvatarText'),
                      ),
                    ),
                  ),
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

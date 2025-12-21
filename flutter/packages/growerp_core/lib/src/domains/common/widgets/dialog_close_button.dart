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
import 'package:go_router/go_router.dart';

class DialogCloseButton extends StatelessWidget {
  const DialogCloseButton({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: GestureDetector(
      key: const Key('cancel'),
      onTap: () {
        // Check if we can pop, otherwise go to home
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.close,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    ),
  );
}

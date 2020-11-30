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
import '../models/@models.dart';
import '../routing_constants.dart';

Widget companyLogo(context, authenticate, title) {
  return Row(children: [
    InkWell(
      onTap: () {
        Navigator.pushNamed(context, CompanyRoute, arguments: FormArguments());
      },
      child: CircleAvatar(
          backgroundColor: Colors.green,
          radius: 15,
          child: authenticate?.company?.image != null
              ? Image.memory(authenticate?.company?.image)
              : Text(authenticate?.company?.name?.substring(0, 1) ?? '',
                  style: TextStyle(fontSize: 20, color: Colors.black))),
    ),
    SizedBox(width: 10),
    Text("$title", style: TextStyle(fontSize: 20, color: Colors.black)),
  ]);
}

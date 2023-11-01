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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';

import '../company.dart';

class CompanyListItem extends StatelessWidget {
  final Company company;
  final Role? role;
  final int index;

  const CompanyListItem({
    Key? key,
    required this.company,
    required this.index,
    this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    CompanyUserAPIRepository repos = context.read<CompanyUserAPIRepository>();
    CompanyBloc companyBloc = context.read<CompanyBloc>();
    return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: company.image != null
              ? Image.memory(company.image!)
              : Text(company.name != null ? company.name![0] : '?'),
        ),
        title: Row(
          children: <Widget>[
            Expanded(
                child: Text(
              "${company.name ?? ''} ",
              key: Key('name$index'),
            )),
            if (!isPhone && role == null)
              Expanded(
                  child: Text(
                company.role!.value,
                key: Key('role$index'),
              )),
            if (!isPhone)
              Expanded(
                  child: Text(
                company.email ?? '',
                key: Key('email$index'),
              )),
            if (!isPhone)
              Expanded(
                  child: Text(
                company.telephoneNr ?? '',
                key: Key('telephone$index'),
              )),
            if (!isPhone)
              Expanded(
                  child: Text(
                company.address?.city ?? '',
                key: Key('city$index'),
              )),
            if (!isPhone)
              Expanded(
                  child: Center(
                child: Text(
                  company.vatPerc != Decimal.parse("0")
                      ? company.vatPerc.toString()
                      : company.salesPerc.toString(),
                  key: Key('perc$index'),
                ),
              )),
            if (!isPhone)
              Expanded(
                  child: Center(
                child: Text(
                  company.employees.length.toString(),
                  key: Key('employees$index'),
                ),
              )),
          ],
        ),
        subtitle: isPhone
            ? Row(children: [
                Expanded(
                    child: Text(company.email ?? '',
                        key: const Key("companyEmail"))),
                Text(
                  company.employees.length.toString(),
                  key: Key('employees$index'),
                ),
                if (role == null)
                  Expanded(
                      child: Text(
                    company.role!.value,
                    key: Key('role$index'),
                  )),
              ])
            : null,
        onTap: () async {
          await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return RepositoryProvider.value(
                    value: repos,
                    child: BlocProvider.value(
                        value: companyBloc, child: CompanyDialog(company)));
              });
        },
        trailing: IconButton(
          key: Key("delete$index"),
          icon: const Icon(Icons.delete_forever),
          onPressed: () {
            companyBloc.add(CompanyDelete(company.copyWith(image: null)));
          },
        ));
  }
}

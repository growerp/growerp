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
import 'package:growerp_core/growerp_core.dart';
import '../../../growerp_user_company.dart';

class CompanyListHeader extends StatefulWidget {
  final Role? role;
  final bool isPhone;
  final CompanyBloc companyBloc;
  const CompanyListHeader({
    Key? key,
    this.role,
    required this.isPhone,
    required this.companyBloc,
  }) : super(key: key);

  @override
  State<CompanyListHeader> createState() => _CompanyListHeaderState();
}

class _CompanyListHeaderState extends State<CompanyListHeader> {
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    return Material(
        child: ListTile(
            leading: GestureDetector(
                key: const Key('search'),
                onTap: (() => setState(() {
                      if (search) {
                        search = false;
                        widget.companyBloc
                            .add(const CompanyFetch(refresh: true));
                      } else {
                        search = true;
                      }
                    })),
                child: const Icon(Icons.search_sharp, size: 40)),
            title: search
                ? Row(children: <Widget>[
                    Expanded(
                        child: TextField(
                      key: const Key('searchField'),
                      autofocus: true,
                      decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          hintText: 'enter company name or ID'),
                      onChanged: ((value) {
                        searchString = value;
                      }),
                    )),
                    ElevatedButton(
                        key: const Key('searchButton'),
                        child: const Text('search'),
                        onPressed: () {
                          widget.companyBloc
                              .add(CompanyFetch(searchString: searchString));
                        })
                  ])
                : Row(
                    children: <Widget>[
                      const Expanded(child: Text("Company Name")),
                      if (!widget.isPhone && widget.role == null)
                        const Expanded(child: Text("Role")),
                      if (!widget.isPhone) const Expanded(child: Text("Email")),
                      if (!widget.isPhone)
                        const Expanded(child: Text("telephoneNr")),
                      if (!widget.isPhone) const Expanded(child: Text("City")),
                      if (!widget.isPhone) const Expanded(child: Text("Curr.")),
                      if (!widget.isPhone)
                        const Expanded(child: Text("VAT/salesPerc")),
                      if (!widget.isPhone)
                        Expanded(
                            child: Text(UserCompanyLocalizations.of(context)!
                                .numberOfEmployees)),
                    ],
                  ),
            subtitle: widget.isPhone
                ? Row(children: [
                    const Expanded(child: Text('Email')),
                    const Expanded(child: Text('Employees')),
                    if (widget.role == null)
                      const Expanded(child: Text('Role')),
                  ])
                : null,
            trailing: const Text(' ')));
  }
}

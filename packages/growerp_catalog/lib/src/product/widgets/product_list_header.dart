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
import 'package:global_configuration/global_configuration.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';

import '../../l10n/generated/catalog_localizations.dart';
import '../product.dart';

class ProductListHeader extends StatefulWidget {
  const ProductListHeader({Key? key}) : super(key: key);

  @override
  State<ProductListHeader> createState() => _ProductListHeaderState();
}

class _ProductListHeaderState extends State<ProductListHeader> {
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final productBloc = context.read<ProductBloc>();
    late Authenticate authenticate;
    String classificationId = GlobalConfiguration().get("classificationId");
    String searchString = '';
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state.status == AuthStatus.authenticated) {
        authenticate = state.authenticate!;
      }
      return Material(
          child: ListTile(
              leading: GestureDetector(
                key: const Key('search'),
                onTap: (() =>
                    setState(() => search ? search = false : search = true)),
                child: const Icon(Icons.search_sharp, size: 40),
              ),
              title: search
                  ? Row(children: <Widget>[
                      Expanded(
                          child: TextField(
                        key: const Key('searchField'),
                        controller: searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          hintText: "search in ID, name and description...",
                        ),
                        onChanged: ((value) {
                          searchString = value;
                        }),
                        onSubmitted: ((value) {
                          productBloc.add(ProductFetch(
                            companyPartyId: authenticate.company!.partyId!,
                            searchString: value,
                          ));
                        }),
                      )),
                      ElevatedButton(
                          key: const Key('searchButton'),
                          child: const Text('Search'),
                          onPressed: () {
                            productBloc.add(ProductFetch(
                                companyPartyId: authenticate.company!.partyId!,
                                searchString: searchString));
                            searchString = '';
                          })
                    ])
                  : Column(children: [
                      Row(children: <Widget>[
                        const Expanded(
                            child: Text("Name", textAlign: TextAlign.center)),
                        if (ResponsiveBreakpoints.of(context)
                            .largerThan(MOBILE))
                          const Expanded(
                              child: Text("Description",
                                  textAlign: TextAlign.center)),
                        Expanded(
                            child: Text(CatalogLocalizations.of(context)!.price,
                                textAlign: TextAlign.center)),
                        if (classificationId != 'AppHotel')
                          const Expanded(
                              child: Text("Catg", textAlign: TextAlign.center)),
                        Expanded(
                            child: Text(
                                classificationId != 'AppHotel'
                                    ? "Nbr Of Assets"
                                    : "Number of Rooms",
                                textAlign: TextAlign.center)),
                      ]),
                      const Divider(color: Colors.black),
                    ]),
              trailing: const Text(' ')));
    });
  }
}

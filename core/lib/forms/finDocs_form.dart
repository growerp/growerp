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

import 'package:core/forms/@forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/widgets/@widgets.dart';
import 'package:core/helper_functions.dart';
import 'package:models/@models.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

class FinDocsForm extends StatefulWidget {
  final sales, docType, onlyRental;
  final DateTime? rentalFromDate, rentalThruDate;
  const FinDocsForm(
      {this.sales = true,
      this.docType,
      this.onlyRental,
      this.rentalFromDate,
      this.rentalThruDate});
  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<FinDocsForm> {
  final _scrollController = ScrollController();
  late FinDocBloc _finDocBloc;
  Authenticate authenticate = Authenticate();
  List<FinDoc> finDocs = <FinDoc>[];
  int? tab;
  int limit = 12;
  late bool showSearchField;
  String? searchString;
  bool isLoading = true;
  bool hasReachedMax = false;

  _OrdersState();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    showSearchField = false;
    switch (widget.docType) {
      case 'order':
        if (widget.sales) {
          tab = 4;
          _finDocBloc = BlocProvider.of<SalesOrderBloc>(context) as FinDocBloc
            ..add(FetchFinDoc(limit: limit));
        } else {
          tab = 5;
          _finDocBloc = BlocProvider.of<PurchaseOrderBloc>(context)
              as FinDocBloc
            ..add(FetchFinDoc(limit: limit));
        }
        break;
      case 'invoice':
        if (widget.sales) {
          tab = 0;
          _finDocBloc = BlocProvider.of<SalesInvoiceBloc>(context) as FinDocBloc
            ..add(FetchFinDoc(limit: limit));
        } else {
          tab = 0;
          _finDocBloc = BlocProvider.of<PurchInvoiceBloc>(context) as FinDocBloc
            ..add(FetchFinDoc(limit: limit));
        }
        break;
      case 'payment':
        if (widget.sales) {
          tab = 0;
          _finDocBloc = BlocProvider.of<SalesPaymentBloc>(context) as FinDocBloc
            ..add(FetchFinDoc(limit: limit));
        } else {
          tab = 0;
          _finDocBloc = BlocProvider.of<PurchPaymentBloc>(context) as FinDocBloc
            ..add(FetchFinDoc(limit: limit));
        }
        break;
      case 'transaction':
        tab = 1;
        _finDocBloc = BlocProvider.of<TransactionBloc>(context) as FinDocBloc
          ..add(FetchFinDoc(limit: limit));
    }
  }

  @override
  Widget build(BuildContext context) {
    limit = (MediaQuery.of(context).size.height / 60).round();

    dynamic blocConsumerListener = (context, state) {
      if (state is FinDocProblem)
        HelperFunctions.showMessage(
            context, '${state.errorMessage}', Colors.red);
      if (state is FinDocSuccess) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
      }
      if (state is FinDocLoading)
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
    };

    dynamic blocConsumerBuilder = (context, state) {
      if (state is FinDocProblem) return FatalErrorForm(state.errorMessage);
      if (state is FinDocSuccess) {
        isLoading = false;
        finDocs = state.finDocs;
        if (widget.rentalFromDate != null) {
          finDocs = finDocs
              .where((el) =>
                  el.items![0].rentalFromDate != null &&
                  el.items![0].rentalFromDate!
                          .difference(widget.rentalFromDate!)
                          .inDays ==
                      0)
              .toList();
        } else if (widget.rentalThruDate != null) {
          finDocs = finDocs
              .where((el) =>
                  el.items![0].rentalThruDate != null &&
                  el.items![0].rentalThruDate!
                          .difference(widget.rentalThruDate!)
                          .inDays ==
                      0)
              .toList();
        } else if (widget.onlyRental == true) {
          finDocs = finDocs
              .where((el) => el.items![0].rentalFromDate != null)
              .toList();
        }
        hasReachedMax = state.hasReachedMax;
        return finDocsPage();
      }
      isLoading = true;
      return LoadingIndicator();
    };

    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) {
        authenticate = state.authenticate;
        switch (widget.docType) {
          case 'order':
            if (widget.sales)
              return BlocConsumer<SalesOrderBloc, FinDocState>(
                  listener: blocConsumerListener, builder: blocConsumerBuilder);
            else
              return BlocConsumer<PurchaseOrderBloc, FinDocState>(
                  listener: blocConsumerListener, builder: blocConsumerBuilder);
          case 'invoice':
            if (widget.sales)
              return BlocConsumer<SalesInvoiceBloc, FinDocState>(
                  listener: blocConsumerListener, builder: blocConsumerBuilder);
            else
              return BlocConsumer<PurchInvoiceBloc, FinDocState>(
                  listener: blocConsumerListener, builder: blocConsumerBuilder);
          case 'payment':
            if (widget.sales)
              return BlocConsumer<SalesPaymentBloc, FinDocState>(
                  listener: blocConsumerListener, builder: blocConsumerBuilder);
            else
              return BlocConsumer<PurchPaymentBloc, FinDocState>(
                  listener: blocConsumerListener, builder: blocConsumerBuilder);
          case 'transaction':
            return BlocConsumer<TransactionBloc, FinDocState>(
                listener: blocConsumerListener, builder: blocConsumerBuilder);
          default:
            return Container(
                child: Center(
                    child: Text(
                        "Not recognized document type: ${widget.docType}")));
        }
      }
      return FatalErrorForm(
          "To list the ${widget.docType}, you needs to be logged in!");
    });
  }

  Widget finDocsPage() {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return RefreshIndicator(
        onRefresh: (() async {
          _finDocBloc.add(FetchFinDoc(refresh: true, limit: limit));
        }),
        child: ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: hasReachedMax && finDocs.isNotEmpty
                ? finDocs.length + 1
                : finDocs.length + 2,
            controller: _scrollController,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0)
                return Column(children: [
                  ListTile(
                      onTap: (() {
                        setState(() {
                          showSearchField = !showSearchField;
                        });
                      }),
                      leading:
                          Image.asset('assets/images/search.png', height: 30),
                      title: showSearchField
                          ? Row(children: <Widget>[
                              SizedBox(
                                  width: isPhone
                                      ? MediaQuery.of(context).size.width - 150
                                      : MediaQuery.of(context).size.width - 250,
                                  child: TextField(
                                    textInputAction: TextInputAction.go,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.transparent),
                                      ),
                                      hintText: "search in ID, " +
                                          (widget.sales
                                              ? "customer"
                                              : "supplier"),
                                    ),
                                    onChanged: ((value) {
                                      searchString = value;
                                    }),
                                    onSubmitted: ((value) {
                                      _finDocBloc.add(FetchFinDoc(
                                          search: value, limit: limit));
                                      setState(() {
                                        showSearchField = !showSearchField;
                                      });
                                    }),
                                  )),
                              ElevatedButton(
                                  child: Text('Search'),
                                  onPressed: () {
                                    _finDocBloc.add(FetchFinDoc(
                                        search: searchString, limit: limit));
                                  })
                            ])
                          : Row(children: <Widget>[
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                      // capitalize first char
                                      "${widget.docType[0].toUpperCase()}"
                                      "${widget.docType.substring(1)} ID")),
                              SizedBox(width: 10),
                              SizedBox(width: 120, child: Text("Date")),
                              Expanded(
                                  child: Text(widget.sales == null
                                      ? 'Other User'
                                      : (widget.sales
                                              ? "Customer"
                                              : "Supplier") +
                                          ' name & Company')),
                              if (!ResponsiveWrapper.of(context)
                                      .isSmallerThan(TABLET) &&
                                  widget.docType != 'payment')
                                SizedBox(width: 80, child: Text("#items")),
                            ]),
                      subtitle: Row(children: <Widget>[
                        SizedBox(width: 100),
                        SizedBox(width: 80, child: Text("Total")),
                        SizedBox(width: 120, child: Text("Status")),
                        SizedBox(width: 120, child: Text("Email Address")),
                      ]),
                      trailing: isPhone
                          ? Text('             ')
                          : Text('                            ')),
                  Divider(color: Colors.black),
                ]);

              if (index == 1 && finDocs.isEmpty && !isLoading)
                return Center(
                    heightFactor: 20,
                    child:
                        Text("no records found!", textAlign: TextAlign.center));
              index -= 1;
              return index >= finDocs.length
                  ? BottomLoader()
                  : Dismissible(
                      key: Key(finDocs[index].id()!),
                      direction: DismissDirection.startToEnd,
                      child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                                "${finDocs[index].otherUser!.companyName![0]}"),
                          ),
                          title: Row(
                            children: <Widget>[
                              SizedBox(
                                  width: 80,
                                  child: Text("${finDocs[index].id()}")),
                              SizedBox(width: 10),
                              SizedBox(
                                  width: 120,
                                  child: Text(
                                      "${finDocs[index].creationDate?.toString().substring(0, 11)}")),
                              Expanded(
                                  child: Text(
                                      "${finDocs[index].otherUser!.firstName ?? ''} "
                                      "${finDocs[index].otherUser!.lastName ?? ''} "
                                      "${finDocs[index].otherUser!.companyName ?? ''}")),
                              if (!ResponsiveWrapper.of(context)
                                      .isSmallerThan(TABLET) &&
                                  widget.docType != 'payment')
                                SizedBox(
                                    width: 80,
                                    child: Text(
                                        "${finDocs[index].items?.length}")),
                            ],
                          ),
                          subtitle: Row(children: <Widget>[
                            SizedBox(width: 100),
                            SizedBox(
                                width: 80,
                                child: Text("${finDocs[index].grandTotal}")),
                            SizedBox(
                                width: 120,
                                child: Text(
                                    "${finDocStatusValues[finDocs[index].statusId!]}")),
                            SizedBox(
                                width: 120,
                                child: Text(
                                  "${finDocs[index].otherUser!.email ?? ''}",
                                )),
                          ]),
                          children: List.from(finDocs[index].items!.map((e) =>
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SizedBox(width: 50),
                                    Expanded(
                                        child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.green,
                                              maxRadius: 10,
                                              child: Text(
                                                  "${e.itemSeqId.toString()}"),
                                            ),
                                            title: Text(finDocs[index]
                                                        .docType !=
                                                    "transaction"
                                                ? "ProductId: ${e.productId} "
                                                        "Description: ${e.description} "
                                                        "Quantity: ${e.quantity.toString()} "
                                                        "Price: ${e.price.toString()} "
                                                        "SubTotal: ${(e.quantity! * e.price!).toString()}" +
                                                    (e.rentalFromDate == null
                                                        ? ''
                                                        : " Rental: ${e.rentalFromDate.toString().substring(0, 10)} "
                                                            "${e.rentalThruDate.toString().substring(0, 10)}")
                                                : "ProductId: ${e.productId} "
                                                    "Description: ${e.description} ")))
                                  ]))),
                          trailing: Container(
                              width: isPhone ? 100 : 160,
                              child: Visibility(
                                  visible: finDocStatusFixed[
                                          finDocs[index].statusId!] ??
                                      true,
                                  child: Row(children: [
                                    IconButton(
                                      icon: Icon(Icons.print),
                                      tooltip:
                                          'PDF/Print ${finDocs[0].docType}',
                                      onPressed: () async {
                                        await Navigator.pushNamed(
                                            context, '/printer',
                                            arguments: FormArguments(
                                                menuIndex: tab,
                                                object: finDocs[index]));
                                      },
                                    ),
                                    Visibility(
                                        visible: !isPhone,
                                        child: Row(children: [
                                          IconButton(
                                            icon: Icon(Icons.edit),
                                            tooltip:
                                                'Edit ${finDocs[0].docType}',
                                            onPressed: () async {
                                              await showDialog(
                                                  barrierDismissible: true,
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return widget.onlyRental ==
                                                            true
                                                        ? ReservationDialog(
                                                            formArguments:
                                                                FormArguments(
                                                                    object: finDocs[
                                                                        index]))
                                                        : (FinDocDialog(
                                                            formArguments:
                                                                FormArguments(
                                                                    object: finDocs[
                                                                        index])));
                                                  });
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_forever),
                                            tooltip:
                                                'Cancel ${finDocs[0].docType}',
                                            onPressed: () {
                                              _finDocBloc.add(UpdateFinDoc(
                                                  finDocs[index].copyWith(
                                                      statusId:
                                                          'FinDocCancelled')));
                                            },
                                          ),
                                        ])),
                                    IconButton(
                                        icon: Icon(Icons.arrow_upward),
                                        tooltip: nextFinDocStatus[
                                            finDocStatusValues[
                                                finDocs[index].statusId!]!],
                                        onPressed: () {
                                          _finDocBloc.add(UpdateFinDoc(
                                              finDocs[index].copyWith(
                                                  statusId: nextFinDocStatus[
                                                      finDocs[index]
                                                          .statusId!])));
                                        })
                                  ])))));
            }));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > 0 && maxScroll - currentScroll <= 200) {
      _finDocBloc.add(FetchFinDoc(limit: limit, search: searchString));
    }
  }
}

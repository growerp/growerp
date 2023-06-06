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

import '../findoc.dart';

/// listing financial documents and orders
class FinDocListForm extends StatelessWidget {
  const FinDocListForm({
    super.key,
    required this.sales,
    required this.docType,
    this.onlyRental = false,
    this.status,
    this.additionalItemButtonName,
    this.additionalItemButtonRoute,
  });

  final bool sales;
  final FinDocType docType;
  final bool onlyRental;
  final String? status;
  final String? additionalItemButtonName;
  final String? additionalItemButtonRoute;

  @override
  Widget build(BuildContext context) {
    FinDocAPIRepository finDocAPIRepository = FinDocAPIRepository(
        context.read<AuthBloc>().state.authenticate!.apiKey!);
    Widget finDocList = RepositoryProvider.value(
        value: finDocAPIRepository,
        child: FinDocList(
          key: key,
          sales: sales,
          docType: docType,
          onlyRental: onlyRental,
          status: status,
          additionalItemButtonName: additionalItemButtonName,
          additionalItemButtonRoute: additionalItemButtonRoute,
        ));
    switch (docType) {
      case FinDocType.order:
        if (sales) {
          return BlocProvider<SalesOrderBloc>(
              create: (context) =>
                  FinDocBloc(finDocAPIRepository, sales, docType)
                    ..add(const FinDocFetch()),
              child: finDocList);
        }
        return BlocProvider<PurchaseOrderBloc>(
            create: (BuildContext context) =>
                FinDocBloc(finDocAPIRepository, sales, docType)
                  ..add(const FinDocFetch()),
            child: finDocList);
      case FinDocType.invoice:
        if (sales) {
          return BlocProvider<SalesInvoiceBloc>(
              create: (context) =>
                  FinDocBloc(finDocAPIRepository, sales, docType)
                    ..add(const FinDocFetch()),
              child: finDocList);
        }
        return BlocProvider<PurchaseInvoiceBloc>(
            create: (BuildContext context) =>
                FinDocBloc(finDocAPIRepository, sales, docType)
                  ..add(const FinDocFetch()),
            child: finDocList);
      case FinDocType.payment:
        if (sales) {
          return BlocProvider<SalesPaymentBloc>(
              create: (context) =>
                  FinDocBloc(finDocAPIRepository, sales, docType)
                    ..add(const FinDocFetch()),
              child: finDocList);
        }
        return BlocProvider<PurchasePaymentBloc>(
            create: (BuildContext context) =>
                FinDocBloc(finDocAPIRepository, sales, docType)
                  ..add(const FinDocFetch()),
            child: finDocList);
      case FinDocType.shipment:
        if (sales) {
          return BlocProvider<OutgoingShipmentBloc>(
              create: (context) =>
                  FinDocBloc(finDocAPIRepository, sales, docType)
                    ..add(const FinDocFetch()),
              child: finDocList);
        }
        return BlocProvider<IncomingShipmentBloc>(
            create: (BuildContext context) =>
                FinDocBloc(finDocAPIRepository, sales, docType)
                  ..add(const FinDocFetch()),
            child: finDocList);
      case FinDocType.transaction:
        return BlocProvider<TransactionBloc>(
            create: (context) => FinDocBloc(finDocAPIRepository, sales, docType)
              ..add(const FinDocFetch()),
            child: finDocList);
      default:
        return Center(child: Text("FinDoc type: ${docType.name} not allowed"));
    }
  }
}

class FinDocList extends StatefulWidget {
  const FinDocList({
    super.key,
    this.sales = true,
    this.docType = FinDocType.unknown,
    this.onlyRental = false,
    this.status,
    this.additionalItemButtonName,
    this.additionalItemButtonRoute,
  });

  final bool sales;
  final FinDocType docType;
  final bool onlyRental;
  final String? status;
  final String? additionalItemButtonName;
  final String? additionalItemButtonRoute;

  @override
  FinDocListState createState() => FinDocListState();
}

extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class FinDocListState extends State<FinDocList> {
  final _scrollController = ScrollController();
  List<FinDoc> finDocs = <FinDoc>[];
  int? tab;
  int limit = 12;
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;
  bool isLoading = true;
  bool hasReachedMax = false;
  late FinDocBloc _finDocBloc;
  late FinDocAPIRepository repos;

  @override
  void initState() {
    super.initState();
    entityName =
        classificationId == 'AppHotel' && widget.docType == FinDocType.order
            ? 'Reservation'
            : widget.docType.toString();
    _scrollController.addListener(_onScroll);
    repos = context.read<FinDocAPIRepository>();
    switch (widget.docType) {
      case FinDocType.order:
        widget.sales
            ? _finDocBloc = context.read<SalesOrderBloc>() as FinDocBloc
            : _finDocBloc = context.read<PurchaseOrderBloc>() as FinDocBloc;
        break;
      case FinDocType.invoice:
        widget.sales
            ? _finDocBloc = context.read<SalesInvoiceBloc>() as FinDocBloc
            : _finDocBloc = context.read<PurchaseInvoiceBloc>() as FinDocBloc;
        break;
      case FinDocType.payment:
        widget.sales
            ? _finDocBloc = context.read<SalesPaymentBloc>() as FinDocBloc
            : _finDocBloc = context.read<PurchasePaymentBloc>() as FinDocBloc;
        break;
      case FinDocType.shipment:
        widget.sales
            ? _finDocBloc = context.read<OutgoingShipmentBloc>() as FinDocBloc
            : _finDocBloc = context.read<IncomingShipmentBloc>() as FinDocBloc;
        break;
      case FinDocType.transaction:
        _finDocBloc = context.read<TransactionBloc>() as FinDocBloc;
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    limit = (MediaQuery.of(context).size.height / 60).round();
    Widget finDocsPage() {
      bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
      return RefreshIndicator(
          onRefresh: (() async =>
              _finDocBloc.add(const FinDocFetch(refresh: true))),
          child: ListView.builder(
              key: const Key('listView'),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount:
                  hasReachedMax ? finDocs.length + 1 : finDocs.length + 2,
              controller: _scrollController,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Column(children: [
                    FinDocListHeader(
                        isPhone: isPhone,
                        sales: widget.sales,
                        docType: widget.docType,
                        finDocBloc: _finDocBloc),
                    const Divider(),
                    Visibility(
                        visible: finDocs.isEmpty,
                        child: Center(
                            heightFactor: 20,
                            child: Text(
                                "no (open)${widget.docType == FinDocType.shipment ? "${widget.sales ? 'outgoing' : 'incoming'} " : "${widget.sales ? 'sales' : 'purchase'} "}${entityName}s found!",
                                textAlign: TextAlign.center)))
                  ]);
                }
                index--;
                return index >= finDocs.length
                    ? const BottomLoader()
                    : Dismissible(
                        key: const Key('finDocItem'),
                        direction: DismissDirection.startToEnd,
                        child: BlocProvider.value(
                            value: _finDocBloc,
                            child: RepositoryProvider.value(
                                value: repos,
                                child: FinDocListItem(
                                  finDoc: finDocs[index],
                                  docType: widget.docType,
                                  index: index,
                                  isPhone: isPhone,
                                  sales: widget.sales,
                                  onlyRental: widget.onlyRental,
                                  additionalItemButton: widget
                                                  .additionalItemButtonName !=
                                              null &&
                                          widget.additionalItemButtonRoute !=
                                              null
                                      ? TextButton(
                                          key: Key('addButton$index'),
                                          child: Text(
                                              widget.additionalItemButtonName!),
                                          onPressed: () async {
                                            await Navigator.pushNamed(
                                                context,
                                                widget
                                                    .additionalItemButtonRoute!,
                                                arguments: finDocs[index]);
                                          },
                                        )
                                      : null,
                                ))));
              }));
    }

    return Builder(builder: (BuildContext context) {
      // used in the blocbuilder below

      listener(context, state) {
        if (state.status == FinDocStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == FinDocStatus.success) {
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
        }
      }

      builder(context, state) {
        if (state.status == FinDocStatus.success ||
            state.status == FinDocStatus.failure) {
          finDocs = state.finDocs;
          hasReachedMax = state.hasReachedMax;
          // if rental (hotelroom) need to show checkin/out orders
          if (widget.onlyRental && widget.status != null) {
            if (widget.status == FinDocStatusVal.created.toString()) {
              finDocs = finDocs
                  .where((el) =>
                      el.items[0].rentalFromDate != null &&
                      el.status.toString() == widget.status &&
                      el.items[0].rentalFromDate!
                          .isSameDate(CustomizableDateTime.current))
                  .toList();
            }
            if (widget.status == FinDocStatusVal.approved.toString()) {
              finDocs = finDocs
                  .where((el) =>
                      el.items[0].rentalThruDate != null &&
                      el.status.toString() == widget.status &&
                      el.items[0].rentalThruDate!
                          .isSameDate(CustomizableDateTime.current))
                  .toList();
            }
          } else if (widget.onlyRental == true) {
            finDocs = finDocs
                .where((el) => el.items[0].rentalFromDate != null)
                .toList();
          }

          return Scaffold(
              floatingActionButton: [
                FinDocType.order,
                FinDocType.invoice,
                FinDocType.payment,
              ].contains(widget.docType)
                  ? FloatingActionButton(
                      key: const Key("addNew"),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return RepositoryProvider.value(
                                  value: repos,
                                  child: BlocProvider.value(
                                      value: _finDocBloc,
                                      child: widget.docType ==
                                              FinDocType.payment
                                          ? PaymentDialog(
                                              finDoc: FinDoc(
                                                  sales: widget.sales,
                                                  docType: widget.docType))
                                          : FinDocDialog(
                                              finDoc: FinDoc(
                                                  sales: widget.sales,
                                                  docType: widget.docType))));
                            });
                      },
                      tooltip: 'Add New',
                      child: const Icon(Icons.add))
                  : null,
              body: finDocsPage());
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      }

      // finally create the Blocbuilder
      if (widget.docType == FinDocType.order) {
        if (widget.sales) {
          return BlocConsumer<SalesOrderBloc, FinDocState>(
              listener: listener, builder: builder);
        }
        return BlocConsumer<PurchaseOrderBloc, FinDocState>(
            listener: listener, builder: builder);
      }
      if (widget.docType == FinDocType.invoice) {
        if (widget.sales) {
          return BlocConsumer<SalesInvoiceBloc, FinDocState>(
              listener: listener, builder: builder);
        }
        return BlocConsumer<PurchaseInvoiceBloc, FinDocState>(
            listener: listener, builder: builder);
      }
      if (widget.docType == FinDocType.payment) {
        if (widget.sales) {
          return BlocConsumer<SalesPaymentBloc, FinDocState>(
              listener: listener, builder: builder);
        }
        return BlocConsumer<PurchasePaymentBloc, FinDocState>(
            listener: listener, builder: builder);
      }
      if (widget.docType == FinDocType.shipment) {
        if (widget.sales) {
          return BlocConsumer<OutgoingShipmentBloc, FinDocState>(
              listener: listener, builder: builder);
        }
        return BlocConsumer<IncomingShipmentBloc, FinDocState>(
            listener: listener, builder: builder);
      }
      return BlocConsumer<TransactionBloc, FinDocState>(
          listener: listener, builder: builder);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) _finDocBloc.add(const FinDocFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}

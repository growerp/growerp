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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/src/findoc/widgets/search_findoc_list.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../findoc.dart';
import 'findoc_dialog/request_dialog.dart';
import 'invoice_upload_view.dart';

class FinDocList extends StatefulWidget {
  const FinDocList({
    super.key,
    this.sales = true,
    this.docType = FinDocType.unknown,
    this.onlyRental = false,
    this.status,
    this.additionalItemButtonName,
    this.additionalItemButtonRoute,
    this.journalId,
  });

  final bool sales;
  final FinDocType docType;
  final bool onlyRental;
  final FinDocStatusVal? status;
  final String? additionalItemButtonName;
  final String? additionalItemButtonRoute;
  final String? journalId;

  @override
  FinDocListState createState() => FinDocListState();
}

/*
extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
*/
class FinDocListState extends State<FinDocList> {
  final _scrollController = ScrollController();
  List<FinDoc> finDocs = <FinDoc>[];
  int? tab;
  late int limit;
  late bool isPhone;
  bool hasReachedMax = false;
  late FinDocBloc _finDocBloc;
  late final ScrollController _horizontalController = ScrollController();
  List<List<TableViewCell>> tableViewRows = [];
  late String classificationId;
  String searchString = '';
  late FocusNode myFocusNode;
  List<FinDoc> searchFinDocs = [];
  late bool my;
  late AuthBloc _authBloc;
  late double bottom;
  double? right;
  late OrderAccountingLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    my = _authBloc.state.authenticate?.user?.userGroup == UserGroup.other;
    classificationId = context.read<String>();
    myFocusNode = FocusNode();
    _scrollController.addListener(_onScroll);
    switch (widget.docType) {
      case FinDocType.order:
        widget.sales
            ? _finDocBloc = context.read<SalesOrderBloc>() as FinDocBloc
            : _finDocBloc = context.read<PurchaseOrderBloc>() as FinDocBloc;
      case FinDocType.invoice:
        widget.sales
            ? _finDocBloc = context.read<SalesInvoiceBloc>() as FinDocBloc
            : _finDocBloc = context.read<PurchaseInvoiceBloc>() as FinDocBloc;
      case FinDocType.payment:
        widget.sales
            ? _finDocBloc = context.read<SalesPaymentBloc>() as FinDocBloc
            : _finDocBloc = context.read<PurchasePaymentBloc>() as FinDocBloc;
      case FinDocType.shipment:
        widget.sales
            ? _finDocBloc = context.read<OutgoingShipmentBloc>() as FinDocBloc
            : _finDocBloc = context.read<IncomingShipmentBloc>() as FinDocBloc;
      case FinDocType.transaction:
        _finDocBloc = context.read<TransactionBloc>() as FinDocBloc;
      case FinDocType.request:
        _finDocBloc = context.read<RequestBloc>() as FinDocBloc;
      default:
    }
    _finDocBloc.add(
      FinDocFetch(refresh: true, limit: 15, my: my, status: widget.status),
    );
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = OrderAccountingLocalizations.of(context)!;
    right = right ?? (isAPhone(context) ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();
    isPhone = isAPhone(context);
    Widget finDocsPage(int length) {
      if (finDocs.isEmpty) {
        return Center(
          heightFactor: 20,
          child: Text(
            widget.journalId != null
                ? _localizations.noJournalEntries
                : widget.docType == FinDocType.transaction
                ? _localizations.noOpenTransactions
                : widget.docType == FinDocType.order
                ? (widget.sales
                      ? _localizations.noOpenOrders
                      : _localizations.noPurchaseOrders)
                : widget.docType == FinDocType.invoice
                ? (widget.sales
                      ? _localizations.noOpenInvoices
                      : _localizations.noPurchaseInvoices)
                : widget.docType == FinDocType.payment
                ? (widget.sales
                      ? _localizations.noOpenPayments
                      : _localizations.noPurchasePayments)
                : widget.docType == FinDocType.shipment
                ? (widget.sales
                      ? _localizations.noOpenShipments
                      : _localizations.noIncomingShipments)
                : _localizations.noOpenRequests,
            style: const TextStyle(fontSize: 20.0),
          ),
        );
      }
      // get table data formatted for tableView
      var (
        List<List<TableViewCell>> tableViewCells,
        List<double> fieldWidths,
        double? rowHeight,
      ) = get2dTableData<FinDoc>(
        getTableData,
        bloc: _finDocBloc,
        classificationId: classificationId,
        context: context,
        items: finDocs,
      );
      // build the table
      return TableView.builder(
        diagonalDragBehavior: DiagonalDragBehavior.free,
        verticalDetails: ScrollableDetails.vertical(
          controller: _scrollController,
        ),
        horizontalDetails: ScrollableDetails.horizontal(
          controller: _horizontalController,
        ),
        cellBuilder: (context, vicinity) =>
            tableViewCells[vicinity.row][vicinity.column],
        columnBuilder: (index) => index >= tableViewCells[0].length
            ? null
            : TableSpan(
                padding: padding,
                backgroundDecoration: getBackGround(context, index),
                extent: FixedTableSpanExtent(fieldWidths[index]),
              ),
        pinnedColumnCount: 1,
        rowBuilder: (index) => index >= tableViewCells.length
            ? null
            : TableSpan(
                padding: padding,
                backgroundDecoration: getBackGround(context, index),
                extent: FixedTableSpanExtent(rowHeight!),
                recognizerFactories: <Type, GestureRecognizerFactory>{
                  TapGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        TapGestureRecognizer
                      >(
                        () => TapGestureRecognizer(),
                        (TapGestureRecognizer t) => t.onTap = () => showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return index > finDocs.length
                                ? const BottomLoader()
                                : Dismissible(
                                    key: const Key('finDocItem'),
                                    direction: DismissDirection.startToEnd,
                                    child: BlocProvider.value(
                                      value: _finDocBloc,
                                      child: SelectFinDocDialog(
                                        onlyRental: widget.onlyRental,
                                        finDoc: finDocs[index - 1],
                                      ),
                                    ),
                                  );
                          },
                        ),
                      ),
                },
              ),
        pinnedRowCount: 1,
      );
    }

    return Builder(
      builder: (BuildContext context) {
        //
        // used in the blocConsumer below
        listener(context, state) {
          if (state.status == FinDocStatus.failure) {
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Colors.red,
            );
          }
          if (state.status == FinDocStatus.success) {
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Colors.green,
            );
          }
        }

        Widget builder(BuildContext context, FinDocState state) {
          switch (state.status) {
            case FinDocStatus.initial:
            case FinDocStatus.loading:
              return const Center(child: LoadingIndicator());
            case FinDocStatus.failure:
            case FinDocStatus.success:
              finDocs = state.finDocs;
              hasReachedMax = state.hasReachedMax;

              // if rental (hotelroom) need to show checkin/out orders
              if (widget.onlyRental && widget.status != null) {
                if (widget.status == FinDocStatusVal.created) {
                  finDocs = state.finDocs
                      .where(
                        (FinDoc el) =>
                            el.items[0].rentalFromDate != null &&
                            el.status == widget.status &&
                            el.items[0].rentalFromDate!.isSameDate(
                              CustomizableDateTime.current,
                            ),
                      )
                      .toList();
                }
                if (widget.status == FinDocStatusVal.approved) {
                  finDocs = state.finDocs
                      .where(
                        (FinDoc el) =>
                            el.items[0].rentalThruDate != null &&
                            el.status == widget.status &&
                            el.items[0].rentalThruDate!.isSameDate(
                              CustomizableDateTime.current,
                            ),
                      )
                      .toList();
                }
              } else if (widget.onlyRental == true) {
                finDocs = state.finDocs
                    .where((el) => el.items[0].rentalFromDate != null)
                    .toList();
              }

              return Stack(
                children: [
                  finDocsPage(state.finDocs.length),
                  Positioned(
                    right: right,
                    bottom: bottom,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          right = right! - details.delta.dx;
                          bottom -= details.delta.dy;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: FloatingActionButton(
                              key: const Key("search"),
                              heroTag: "btn1",
                              onPressed: () async {
                                // find findoc id to show
                                await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    // search separate from finDocBloc
                                    return BlocProvider.value(
                                      value: context
                                          .read<DataFetchBloc<FinDocs>>(),
                                      child: SearchFinDocList(
                                        docType: widget.docType,
                                        sales: widget.sales,
                                      ),
                                    );
                                  },
                                ).then(
                                  (value) async =>
                                      value != null && context.mounted
                                      ?
                                        // show detail page
                                        await showDialog(
                                          barrierDismissible: true,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return BlocProvider.value(
                                              value: _finDocBloc,
                                              child: SelectFinDocDialog(
                                                finDoc: value,
                                              ),
                                            );
                                          },
                                        )
                                      : const SizedBox.shrink(),
                                );
                              },
                              child: const Icon(Icons.search),
                            ),
                          ),
                          if (widget.docType == FinDocType.invoice &&
                              !widget.sales)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                              child: FloatingActionButton(
                                key: const Key("upload"),
                                heroTag: "btn4",
                                onPressed: () async => showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) =>
                                      const InvoiceUploadView(),
                                ),
                                tooltip: 'Upload Invoice',
                                child: const Icon(Icons.upload_file),
                              ),
                            ),
                          if (widget.docType != FinDocType.shipment)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                              child: FloatingActionButton(
                                key: const Key("addNew"),
                                heroTag: "btn2",
                                onPressed: () async => showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) =>
                                      BlocProvider.value(
                                        value: _finDocBloc,
                                        child:
                                            widget.docType == FinDocType.payment
                                            ? PaymentDialog(
                                                finDoc: FinDoc(
                                                  sales: widget.sales,
                                                  docType: widget.docType,
                                                ),
                                              )
                                            : widget.docType ==
                                                  FinDocType.request
                                            ? RequestDialog(
                                                finDoc: FinDoc(
                                                  sales: widget.sales,
                                                  docType: widget.docType,
                                                ),
                                              )
                                            : FinDocDialog(
                                                FinDoc(
                                                  sales: widget.sales,
                                                  docType: widget.docType,
                                                ),
                                              ),
                                      ),
                                ),
                                tooltip: _localizations.addNew,
                                child: const Icon(Icons.add),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: FloatingActionButton(
                              key: const Key("refresh"),
                              heroTag: "btn3",
                              onPressed: () async => _finDocBloc.add(
                                const FinDocFetch(refresh: true),
                              ),
                              tooltip: _localizations.refresh,
                              child: const Icon(Icons.refresh),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
          }
        }

        // finally create the BlocConsumer
        switch (widget.docType) {
          case FinDocType.order:
            if (widget.sales) {
              return BlocConsumer<SalesOrderBloc, FinDocState>(
                listener: listener,
                builder: builder,
              );
            }
            return BlocConsumer<PurchaseOrderBloc, FinDocState>(
              listener: listener,
              builder: builder,
            );

          case FinDocType.invoice:
            if (widget.sales) {
              return BlocConsumer<SalesInvoiceBloc, FinDocState>(
                listener: listener,
                builder: builder,
              );
            }
            return BlocConsumer<PurchaseInvoiceBloc, FinDocState>(
              listener: listener,
              builder: builder,
            );

          case FinDocType.payment:
            if (widget.sales) {
              return BlocConsumer<SalesPaymentBloc, FinDocState>(
                listener: listener,
                builder: builder,
              );
            }
            return BlocConsumer<PurchasePaymentBloc, FinDocState>(
              listener: listener,
              builder: builder,
            );

          case FinDocType.shipment:
            if (widget.sales) {
              return BlocConsumer<OutgoingShipmentBloc, FinDocState>(
                listener: listener,
                builder: builder,
              );
            }
            return BlocConsumer<IncomingShipmentBloc, FinDocState>(
              listener: listener,
              builder: builder,
            );
          case FinDocType.transaction:
            return BlocConsumer<TransactionBloc, FinDocState>(
              listener: listener,
              builder: builder,
            );
          case FinDocType.request:
            return BlocConsumer<RequestBloc, FinDocState>(
              listener: listener,
              builder: builder,
            );
          case FinDocType.unknown:
            return Container();
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) _finDocBloc.add(FinDocFetch(limit: limit));
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}

class SelectFinDocDialog extends StatelessWidget {
  const SelectFinDocDialog({
    super.key,
    required this.finDoc,
    bool onlyRental = false,
  });

  final FinDoc finDoc;
  final bool onlyRental = false;

  @override
  Widget build(BuildContext context) {
    return onlyRental == true
        ? ReservationDialog(finDoc: finDoc, original: finDoc)
        // shipment with status approved shows receive screen
        : finDoc.docType == FinDocType.request
        ? RequestDialog(finDoc: finDoc)
        : finDoc.docType == FinDocType.shipment &&
              finDoc.status == FinDocStatusVal.approved &&
              finDoc.sales == false
        ? ShipmentReceiveDialog(finDoc)
        : finDoc.docType == FinDocType.payment
        ? PaymentDialog(finDoc: finDoc)
        : FinDocDialog(finDoc);
  }
}

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
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../findoc.dart';
import 'findoc_dialog/request_dialog.dart';
import 'findoc_list_styled_data.dart';
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

class FinDocListState extends State<FinDocList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  List<FinDoc> finDocs = <FinDoc>[];
  int? tab;
  late int limit;
  late bool isPhone;
  bool hasReachedMax = false;
  late FinDocBloc _finDocBloc;
  late String classificationId;
  String searchString = '';
  late FocusNode myFocusNode;
  List<FinDoc> searchFinDocs = [];
  late bool my;
  late AuthBloc _authBloc;
  late double bottom;
  double? right;
  late OrderAccountingLocalizations _localizations;
  bool _isLoading = true;
  double currentScroll = 0;

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
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = finDocs.map((finDoc) {
        final index = finDocs.indexOf(finDoc);
        return getFinDocListRow(
          context: context,
          finDoc: finDoc,
          index: index,
          bloc: _finDocBloc,
          classificationId: classificationId,
        );
      }).toList();

      return StyledDataTable(
        columns: getFinDocListColumns(
          context,
          docType: widget.docType,
          classificationId: classificationId,
        ),
        rows: rows,
        isLoading: _isLoading && finDocs.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 80 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('finDocItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _finDocBloc,
                  child: SelectFinDocDialog(
                    onlyRental: widget.onlyRental,
                    finDoc: finDocs[index],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    String getSearchHint() {
      final docName = widget.docType.name.toLowerCase();
      return 'Search ${widget.sales ? 'sales' : 'purchase'} ${docName}s...';
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
          // Update loading state
          _isLoading = state.status == FinDocStatus.loading;

          if (state.status == FinDocStatus.failure) {
            return FatalErrorForm(
              message: state.message ?? 'An error occurred',
            );
          }

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

          if (finDocs.isNotEmpty && _scrollController.hasClients) {
            Future.delayed(const Duration(milliseconds: 100), () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(currentScroll);
                }
              });
            });
          }

          return Column(
            children: [
              // Filter bar with search
              ListFilterBar(
                searchHint: getSearchHint(),
                searchController: _searchController,
                onSearchChanged: (value) {
                  searchString = value;
                  _finDocBloc.add(
                    FinDocFetch(
                      refresh: true,
                      searchString: value,
                      my: my,
                      status: widget.status,
                    ),
                  );
                },
              ),
              // Main content area
              Expanded(
                child: Stack(
                  children: [
                    tableView(),
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
                                              widget.docType ==
                                                  FinDocType.payment
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
                ),
              ),
            ],
          );
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
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    currentScroll = _scrollController.offset;
    if (_isBottom) {
      _finDocBloc.add(FinDocFetch(limit: limit, searchString: searchString));
    }
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

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
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

/// Seasonal rental rates: date bands that override the rental product's
/// standard daily price for the days they cover (weekends, high season,
/// events). Shared by hotel (rooms) and rental (equipment); the noun and the
/// per-night surcharge label follow the hosting app's applicationId.
class RentalRateForm extends StatefulWidget {
  const RentalRateForm({super.key});

  @override
  State<RentalRateForm> createState() => _RentalRateFormState();
}

class _RentalRateFormState extends State<RentalRateForm> {
  late RestClient _restClient;
  late String _applicationId;
  late bool _isHotel;
  late String _productNoun; // 'Room Type' for hotel, 'Equipment Type' otherwise
  List<Product> _productTypes = [];
  final Map<String, List<RentalPrice>> _ratesByProduct = {};
  final _touristTaxController = TextEditingController();
  bool _loading = true;
  bool _savingTax = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restClient = context.read<RestClient>();
    _applicationId = context.read<String>();
    _isHotel = _applicationId == 'AppHotel';
    _productNoun = _isHotel ? 'Room Type' : 'Equipment Type';
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final products = await _restClient.getProduct(
        limit: 100,
        isForDropDown: true,
        applicationId: _applicationId,
      );
      final rateLists = await Future.wait(
        products.products.map(
          (product) => _restClient.getRentalPrices(productId: product.productId),
        ),
      );
      _ratesByProduct
        ..clear()
        ..addEntries(
          products.products.indexed.map(
            (e) => MapEntry(e.$2.productId, rateLists[e.$1].rentalPrices),
          ),
        );
      final settings = await _restClient.getSystemSettings();
      if (!mounted) return;
      setState(() {
        _productTypes = products.products;
        _touristTaxController.text =
            settings.touristTaxPerNight?.toString() ?? '';
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Flattened view: one row per rate band, product types without any band
  /// are not listed (their standard price applies to every day).
  List<(Product, RentalPrice)> get _rows {
    final rows = <(Product, RentalPrice)>[];
    for (final product in _productTypes) {
      for (final rate in _ratesByProduct[product.productId] ?? []) {
        rows.add((product, rate));
      }
    }
    return rows;
  }

  /// The lodging tax the hotel must charge per room per night; added to every
  /// quote and reservation as its own line. Hotel-only.
  Future<void> _saveTouristTax() async {
    setState(() => _savingTax = true);
    try {
      await _restClient.updateSystemSettings({
        'touristTaxPerNight': _touristTaxController.text.isEmpty
            ? '0'
            : _touristTaxController.text,
      });
      if (!mounted) return;
      setState(() => _savingTax = false);
      HelperFunctions.showMessage(context, 'Tourist tax saved', Colors.green);
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingTax = false);
      HelperFunctions.showMessage(context, '$e', Colors.red);
    }
  }

  @override
  void dispose() {
    _touristTaxController.dispose();
    super.dispose();
  }

  Future<void> _delete(RentalPrice rate) async {
    try {
      await _restClient.deleteRentalPrice(rentalPriceId: rate.rentalPriceId);
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      HelperFunctions.showMessage(context, '$e', Colors.red);
    }
  }

  Future<void> _showDialog({Product? product, RentalPrice? rate}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _RentalRateDialog(
        restClient: _restClient,
        productTypes: _productTypes,
        productNoun: _productNoun,
        product: product,
        rate: rate,
      ),
    );
    if (saved == true) await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator();
    if (_error != null) {
      return Center(child: Text('Error: $_error', key: const Key('rateError')));
    }
    final rows = _rows;
    final dateFormat = DateFormat('yyyy-MM-dd');
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: const Key('addNew'),
        onPressed: () => _showDialog(),
        tooltip: 'Add rate',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_isHotel)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('touristTaxPerNight'),
                      controller: _touristTaxController,
                      decoration: const InputDecoration(
                        labelText: 'Tourist tax per room per night',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    key: const Key('saveTouristTax'),
                    onPressed: _savingTax ? null : _saveTouristTax,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              'Seasonal rates: ${rows.length}',
              key: const Key('rateSummary'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: StyledDataTable(
              columns: [
                StyledColumn(header: _productNoun, flex: 3),
                const StyledColumn(header: 'From', flex: 2),
                const StyledColumn(header: 'Thru', flex: 2),
                const StyledColumn(header: 'Rate', flex: 2),
                const StyledColumn(header: '', flex: 1),
              ],
              rows: rows.indexed.map((entry) {
                final index = entry.$1;
                final (product, rate) = entry.$2;
                return <Widget>[
                  Text(
                    product.productName ?? '',
                    key: Key('rateProduct$index'),
                  ),
                  Text(
                    rate.fromDate != null
                        ? dateFormat.format(rate.fromDate!)
                        : '',
                    key: Key('rateFrom$index'),
                  ),
                  Text(
                    rate.thruDate != null
                        ? dateFormat.format(rate.thruDate!)
                        : '',
                  ),
                  Text('${rate.price ?? ''}', key: Key('ratePrice$index')),
                  IconButton(
                    key: Key('rateDelete$index'),
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _delete(rate),
                  ),
                ];
              }).toList(),
              onRowTap: (index) => _showDialog(
                product: rows[index].$1,
                rate: rows[index].$2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Create or edit one seasonal rate band.
class _RentalRateDialog extends StatefulWidget {
  final RestClient restClient;
  final List<Product> productTypes;
  final String productNoun;
  final Product? product;
  final RentalPrice? rate;

  const _RentalRateDialog({
    required this.restClient,
    required this.productTypes,
    required this.productNoun,
    this.product,
    this.rate,
  });

  @override
  State<_RentalRateDialog> createState() => _RentalRateDialogState();
}

class _RentalRateDialogState extends State<_RentalRateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  Product? _product;
  late DateTime _fromDate;
  late DateTime _thruDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product ?? widget.productTypes.firstOrNull;
    _fromDate = widget.rate?.fromDate ?? CustomizableDateTime.current;
    _thruDate =
        widget.rate?.thruDate ??
        CustomizableDateTime.current.add(const Duration(days: 1));
    if (widget.rate?.price != null) {
      _priceController.text = widget.rate!.price.toString();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _thruDate,
      firstDate: DateTime(CustomizableDateTime.current.year - 1),
      lastDate: DateTime(CustomizableDateTime.current.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (!_thruDate.isAfter(_fromDate)) {
          _thruDate = _fromDate.add(const Duration(days: 1));
        }
      } else {
        _thruDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _product == null) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'productId': _product!.productId,
        'fromDate': _dateFormat.format(_fromDate),
        'thruDate': _dateFormat.format(_thruDate),
        'price': _priceController.text,
      };
      if (widget.rate == null) {
        await widget.restClient.createRentalPrice(body);
      } else {
        await widget.restClient.updateRentalPrice({
          'rentalPriceId': widget.rate!.rentalPriceId,
          ...body,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      HelperFunctions.showMessage(context, '$e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('RentalRateDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        height: 420,
        width: 400,
        title: widget.rate == null ? 'New Seasonal Rate' : 'Seasonal Rate',
        child: Form(
          key: _formKey,
          child: ListView(
            key: const Key('listView'),
            children: [
              DropdownButtonFormField<Product>(
                key: const Key('rentalProductType'),
                initialValue: _product,
                decoration:
                    InputDecoration(labelText: widget.productNoun),
                items: widget.productTypes
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.productName ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _product = value),
                validator: (value) => value == null
                    ? 'Select a ${widget.productNoun.toLowerCase()}'
                    : null,
              ),
              const SizedBox(height: 20),
              InkWell(
                key: const Key('rateFromDate'),
                onTap: () => _pickDate(isFrom: true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'From date',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(_dateFormat.format(_fromDate)),
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                key: const Key('rateThruDate'),
                onTap: () => _pickDate(isFrom: false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Thru date (exclusive)',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(_dateFormat.format(_thruDate)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('rate'),
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Rate per day'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter a rate';
                  if (Decimal.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  OutlinedButton(
                    key: const Key('cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('update'),
                      onPressed: _saving ? null : _save,
                      child: Text(widget.rate == null ? 'Create' : 'Update'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

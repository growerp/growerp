/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import '../../../l10n/generated/support_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../website_conversion.dart';

/// New conversion: the form. Existing conversion: progress and result.
class WebsiteConversionDialog extends StatefulWidget {
  final WebsiteConversion? conversion;
  const WebsiteConversionDialog(this.conversion, {super.key});

  @override
  WebsiteConversionDialogState createState() => WebsiteConversionDialogState();
}

class WebsiteConversionDialogState extends State<WebsiteConversionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _hostNamesController = TextEditingController();
  String _currencyId = 'USD';
  int _maxPages = 12;
  late WebsiteConversionBloc _bloc;

  /// the password only exists once the import ran, so it has to be fetched again
  /// when a conversion completes while this dialog is open
  bool _passwordRequested = false;

  bool get _isNew => widget.conversion == null;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<WebsiteConversionBloc>();
    if (!_isNew) {
      // the list payload has no password, ask for the single row
      _bloc.add(WebsiteConversionGetOne(widget.conversion!.conversionId));
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _hostNamesController.dispose();
    super.dispose();
  }

  /// the freshest version of this row, updated by the polling in the bloc
  WebsiteConversion _current(WebsiteConversionState state) {
    final id = widget.conversion!.conversionId;
    if (state.selected?.conversionId == id) return state.selected!;
    return state.conversions.firstWhere(
      (c) => c.conversionId == id,
      orElse: () => widget.conversion!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WebsiteConversionBloc, WebsiteConversionState>(
      listener: (context, state) {
        // only a real user action closes this dialog, never a background poll
        if (state.status == WebsiteConversionStatus.success && _isNew) {
          Navigator.of(context).pop();
        }
        if (state.status == WebsiteConversionStatus.failure) {
          HelperFunctions.showMessage(
            context,
            'Error: ${state.message}',
            Colors.red,
          );
        }
        // it just finished while we were watching: ask for the password
        if (!_isNew && !_passwordRequested) {
          final c = _current(state);
          if (c.isCompleted && c.generatedPassword.isEmpty) {
            _passwordRequested = true;
            _bloc.add(WebsiteConversionGetOne(c.conversionId));
          }
        }
      },
      builder: (context, state) {
        return Dialog(
          key: const Key('WebsiteConversionDialog'),
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: popUp(
            context: context,
            title: _isNew ? 'Convert a website' : 'Website conversion',
            height: 620,
            width: 450,
            child: _isNew ? _newForm(state) : _detail(_current(state)),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // new conversion
  // --------------------------------------------------------------------------
  Widget _newForm(WebsiteConversionState state) {
    if (state.status == WebsiteConversionStatus.loading) {
      return const LoadingIndicator();
    }
    return SingleChildScrollView(
      key: const Key('listView'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(SupportLocalizations.of(context)!.websiteReadAI),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('sourceUrl'),
              decoration: const InputDecoration(
                labelText: 'Website address',
                hintText: 'www.example.com',
              ),
              controller: _urlController,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter a website address' : null,
            ),
            TextFormField(
              key: const Key('companyName'),
              decoration: const InputDecoration(labelText: 'Company name'),
              controller: _companyController,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter the company name' : null,
            ),
            TextFormField(
              key: const Key('adminEmail'),
              decoration: const InputDecoration(
                labelText: 'Admin email',
                helperText: 'becomes the login of the new owner',
              ),
              controller: _emailController,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter an email address';
                if (!value.contains('@')) return 'Not a valid email address';
                return null;
              },
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('adminFirstName'),
                    decoration: const InputDecoration(labelText: 'First name'),
                    controller: _firstNameController,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const Key('adminLastName'),
                    decoration: const InputDecoration(labelText: 'Last name'),
                    controller: _lastNameController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const Key('currencyId'),
                    decoration: const InputDecoration(labelText: 'Currency'),
                    initialValue: _currencyId,
                    items: const ['USD', 'EUR', 'GBP', 'THB', 'AUD', 'CAD']
                        .map(
                          (c) => DropdownMenuItem<String>(value: c, child: Text(c)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _currencyId = value ?? 'USD'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const Key('maxPages'),
                    decoration: const InputDecoration(labelText: 'Max pages'),
                    initialValue: _maxPages,
                    items: const [6, 12, 20]
                        .map(
                          (n) => DropdownMenuItem<int>(value: n, child: Text('$n')),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _maxPages = value ?? 12),
                  ),
                ),
              ],
            ),
            TextFormField(
              key: const Key('hostNames'),
              decoration: const InputDecoration(
                labelText: 'Host names',
                helperText: 'comma separated, empty = taken from the address',
              ),
              controller: _hostNamesController,
            ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton(
                key: const Key('startConversion'),
                child: Text(SupportLocalizations.of(context)!.startConversion),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _bloc.add(
                      WebsiteConversionCreate(
                        sourceUrl: _urlController.text,
                        companyName: _companyController.text,
                        adminEmail: _emailController.text,
                        adminFirstName: _firstNameController.text.isEmpty
                            ? null
                            : _firstNameController.text,
                        adminLastName: _lastNameController.text.isEmpty
                            ? null
                            : _lastNameController.text,
                        currencyId: _currencyId,
                        hostNames: _hostNamesController.text.isEmpty
                            ? null
                            : _hostNamesController.text,
                        maxPages: _maxPages,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // existing conversion
  // --------------------------------------------------------------------------
  Widget _detail(WebsiteConversion c) {
    return SingleChildScrollView(
      key: const Key('listView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _row('Website', c.sourceUrl),
          _row('Company', c.companyName),
          _row('Admin login', c.adminEmail),
          _row('Host names', c.hostNames),
          const Divider(),
          Row(
            children: [
              if (c.inProgress)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              Expanded(
                child: Text(
                  c.status,
                  key: const Key('detailStatus'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.isFailed
                        ? Theme.of(context).colorScheme.error
                        : c.isCompleted
                        ? Colors.green
                        : null,
                  ),
                ),
              ),
            ],
          ),
          if (c.statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(c.statusMessage),
            ),
          if (c.isFailed && c.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              c.errorMessage,
              key: const Key('errorMessage'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (c.isCompleted) ...[
            const Divider(),
            _row('Pages / images', '${c.pageCount ?? 0} / ${c.imageCount ?? 0}'),
            _row('Owner', c.createdOwnerPartyId),
            _row('Company id', c.createdCompanyPartyId),
            _row('Store', c.productStoreId),
            if (c.hostNameList.isNotEmpty)
              _row('Open at', 'http://${c.hostNameList.first}/'),
            if (c.generatedPassword.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      SupportLocalizations.of(context)!.passwordArg(c.generatedPassword),
                      key: const Key('generatedPassword'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    key: const Key('copyPassword'),
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy password',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: c.generatedPassword),
                      );
                      HelperFunctions.showMessage(
                        context,
                        'Password copied',
                        Colors.green,
                      );
                    },
                  ),
                ],
              ),
              Text(SupportLocalizations.of(context)!.giveThisToCustomer, style: const TextStyle(fontSize: 12)),
            ],
          ],
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              key: const Key('deleteConversion'),
              child: Text(SupportLocalizations.of(context)!.removeFromList),
              onPressed: () {
                _bloc.add(WebsiteConversionDelete(c));
                Navigator.of(context).pop();
              },
            ),
          ),
          if (c.isCompleted)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(SupportLocalizations.of(context)!.removingClearsRow, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

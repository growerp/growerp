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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../blocs/website_form_bloc.dart';

const List<String> websiteFormFieldTypes = [
  'text',
  'email',
  'phone',
  'textarea',
];

class WebsiteFormDialog extends StatefulWidget {
  final WebsiteForm webForm;
  const WebsiteFormDialog(this.webForm, {super.key});

  @override
  WebsiteFormDialogState createState() => WebsiteFormDialogState();
}

class _FieldRow {
  final TextEditingController label = TextEditingController();
  String fieldType = 'text';
  bool required = false;
  String fieldId = '';
}

class WebsiteFormDialogState extends State<WebsiteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _submitLabelController = TextEditingController();
  final _successMessageController = TextEditingController();
  final List<_FieldRow> _fieldRows = [];
  late WebsiteFormBloc _websiteFormBloc;

  @override
  void initState() {
    super.initState();
    _websiteFormBloc = context.read<WebsiteFormBloc>();
    _nameController.text = widget.webForm.formName;
    _titleController.text = widget.webForm.title;
    _submitLabelController.text = widget.webForm.submitLabel;
    _successMessageController.text = widget.webForm.successMessage;
    for (final field in widget.webForm.fields) {
      final row = _FieldRow()
        ..fieldId = field.fieldId
        ..fieldType = field.fieldType.isEmpty ? 'text' : field.fieldType
        ..required = field.isRequired == 'Y';
      row.label.text = field.label;
      _fieldRows.add(row);
    }
    if (_fieldRows.isEmpty) {
      // sensible starter fields for a lead form
      final name = _FieldRow();
      name.label.text = 'Name';
      final email = _FieldRow()
        ..fieldType = 'email'
        ..required = true;
      email.label.text = 'Email';
      _fieldRows.addAll([name, email]);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocListener<WebsiteFormBloc, WebsiteFormState>(
      listener: (context, state) {
        if (state.status == WebsiteFormStatus.success) {
          Navigator.of(context).pop();
        }
        if (state.status == WebsiteFormStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      child: Dialog(
        key: const Key('WebsiteFormDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: widget.webForm.formId.isEmpty
              ? 'New Web Form'
              : 'Web Form #${widget.webForm.pseudoId}',
          width: isPhone ? 400 : 700,
          height: 600,
          child: _formContent(),
        ),
      ),
    );
  }

  Widget _formContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        key: const Key('listView'),
        child: Column(
          children: [
            TextFormField(
              key: const Key('formName'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Form Name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Name required' : null,
            ),
            TextFormField(
              key: const Key('formTitle'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title shown above the form'),
            ),
            TextFormField(
              key: const Key('submitLabel'),
              controller: _submitLabelController,
              decoration: const InputDecoration(labelText: 'Submit button label'),
            ),
            TextFormField(
              key: const Key('successMessage'),
              controller: _successMessageController,
              decoration: const InputDecoration(labelText: 'Message after submit'),
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Fields',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ..._fieldRows.map((row) {
              final index = _fieldRows.indexOf(row);
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      key: Key('fieldLabel$index'),
                      controller: row.label,
                      decoration: const InputDecoration(labelText: 'Label'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      key: Key('fieldType$index'),
                      initialValue: row.fieldType,
                      items: websiteFormFieldTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => row.fieldType = value ?? 'text'),
                    ),
                  ),
                  Checkbox(
                    key: Key('fieldRequired$index'),
                    value: row.required,
                    onChanged: (value) =>
                        setState(() => row.required = value ?? false),
                  ),
                  IconButton(
                    key: Key('fieldDelete$index'),
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() => _fieldRows.remove(row)),
                  ),
                ],
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('addField'),
                onPressed: () => setState(() => _fieldRows.add(_FieldRow())),
                icon: const Icon(Icons.add),
                label: const Text('Add field'),
              ),
            ),
            if (widget.webForm.formId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText(
                  'Embed on a page with: '
                  '<div data-growerp-form="${widget.webForm.formId}"></div>',
                  key: const Key('embedCode'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('update'),
                    child: Text(
                      widget.webForm.formId.isEmpty ? 'Create' : 'Update',
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _websiteFormBloc.add(
                          WebsiteFormUpdate(
                            widget.webForm.copyWith(
                              formName: _nameController.text,
                              title: _titleController.text,
                              submitLabel: _submitLabelController.text,
                              successMessage: _successMessageController.text,
                              fields: _fieldRows
                                  .map(
                                    (row) => WebsiteFormField(
                                      fieldId: row.fieldId,
                                      sequenceNum: _fieldRows.indexOf(row) + 1,
                                      label: row.label.text,
                                      fieldType: row.fieldType,
                                      isRequired: row.required ? 'Y' : 'N',
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

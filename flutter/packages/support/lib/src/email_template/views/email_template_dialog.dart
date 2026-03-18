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

import '../blocs/email_template_bloc.dart';

class EmailTemplateDialog extends StatefulWidget {
  final EmailTemplate? emailTemplate;
  const EmailTemplateDialog(this.emailTemplate, {super.key});
  @override
  EmailTemplateDialogState createState() => EmailTemplateDialogState();
}

class EmailTemplateDialogState extends State<EmailTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fromAddressController = TextEditingController();
  final _fromNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyContentController = TextEditingController();
  final _replyToController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  late EmailTemplateBloc _emailTemplateBloc;

  @override
  void initState() {
    super.initState();
    final t = widget.emailTemplate;
    _idController.text = t?.emailTemplateId ?? '';
    _descriptionController.text = t?.description ?? '';
    _fromAddressController.text = t?.fromAddress ?? '';
    _fromNameController.text = t?.fromName ?? '';
    _subjectController.text = t?.subject ?? '';
    _bodyContentController.text = t?.bodyContent ?? '';
    _replyToController.text = t?.replyToAddresses ?? '';
    _ccController.text = t?.ccAddresses ?? '';
    _bccController.text = t?.bccAddresses ?? '';
    _emailTemplateBloc = context.read<EmailTemplateBloc>();
  }

  @override
  void dispose() {
    _idController.dispose();
    _descriptionController.dispose();
    _fromAddressController.dispose();
    _fromNameController.dispose();
    _subjectController.dispose();
    _bodyContentController.dispose();
    _replyToController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.emailTemplate == null ||
        widget.emailTemplate!.emailTemplateId.isEmpty;
    final phone = isPhone(context);
    return BlocConsumer<EmailTemplateBloc, EmailTemplateState>(
      listener: (context, state) {
        switch (state.status) {
          case EmailTemplateStatus.success:
            Navigator.of(context).pop();
            break;
          case EmailTemplateStatus.failure:
            HelperFunctions.showMessage(
              context,
              'Error: ${state.message}',
              Colors.red,
            );
            break;
          default:
        }
      },
      builder: (context, state) {
        if (state.status == EmailTemplateStatus.loading) {
          return const LoadingIndicator();
        }
        return Dialog(
          key: const Key('EmailTemplateDialog'),
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: popUp(
            context: context,
            title:
                'Email Template: ${isNew ? 'New' : widget.emailTemplate!.emailTemplateId}',
            height: 700,
            width: phone ? 400 : 1000,
            child: Form(
              key: _formKey,
              child: phone
                  ? _buildPhoneLayout(isNew)
                  : _buildDesktopLayout(isNew),
            ),
          ),
        );
      },
    );
  }

  /// Two-column layout for wider screens: metadata on the left, HTML editor on
  /// the right.
  Widget _buildDesktopLayout(bool isNew) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _metadataFields(isNew),
                ),
              ),
              const SizedBox(height: 8),
              _actionButtons(isNew),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Body Content (HTML)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _bodyEditor(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Single-column layout for narrow screens: metadata first, then editor,
  /// then action buttons.
  Widget _buildPhoneLayout(bool isNew) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: _metadataFields(isNew),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Body Content (HTML)',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 2,
          child: _bodyEditor(),
        ),
        const SizedBox(height: 8),
        _actionButtons(isNew),
      ],
    );
  }

  Widget _metadataFields(bool isNew) {
    return Column(
      children: [
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('emailTemplateId'),
          controller: _idController,
          enabled: isNew,
          decoration: const InputDecoration(labelText: 'Email Template ID'),
          validator: (value) =>
              value!.isEmpty ? 'Please enter an ID' : null,
        ),
        TextFormField(
          key: const Key('description'),
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        TextFormField(
          key: const Key('fromAddress'),
          controller: _fromAddressController,
          decoration: const InputDecoration(labelText: 'From Address'),
        ),
        TextFormField(
          key: const Key('fromName'),
          controller: _fromNameController,
          decoration: const InputDecoration(labelText: 'From Name'),
        ),
        TextFormField(
          key: const Key('subject'),
          controller: _subjectController,
          decoration: const InputDecoration(labelText: 'Subject'),
        ),
        TextFormField(
          key: const Key('replyToAddresses'),
          controller: _replyToController,
          decoration:
              const InputDecoration(labelText: 'Reply-To Addresses'),
        ),
        TextFormField(
          key: const Key('ccAddresses'),
          controller: _ccController,
          decoration: const InputDecoration(labelText: 'CC Addresses'),
        ),
        TextFormField(
          key: const Key('bccAddresses'),
          controller: _bccController,
          decoration: const InputDecoration(labelText: 'BCC Addresses'),
        ),
        if (widget.emailTemplate?.bodyScreenLocation != null &&
            widget.emailTemplate!.bodyScreenLocation!.isNotEmpty) ...[
          const SizedBox(height: 4),
          TextFormField(
            key: const Key('bodyScreenLocation'),
            initialValue: widget.emailTemplate!.bodyScreenLocation,
            enabled: false,
            decoration:
                const InputDecoration(labelText: 'Body Screen Location'),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _bodyEditor() {
    return TextFormField(
      key: const Key('bodyContent'),
      controller: _bodyContentController,
      expands: true,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      textInputAction: TextInputAction.newline,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(10),
      ),
    );
  }

  Widget _actionButtons(bool isNew) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (!isNew)
          OutlinedButton(
            key: const Key('delete'),
            style:
                OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: Text(
                    'Delete template '
                    '${widget.emailTemplate!.emailTemplateId}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                _emailTemplateBloc
                    .add(EmailTemplateDelete(widget.emailTemplate!));
              }
            },
            child: const Text('Delete'),
          ),
        OutlinedButton(
          key: const Key('update'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _emailTemplateBloc.add(
                EmailTemplateUpdate(
                  EmailTemplate(
                    emailTemplateId: _idController.text,
                    description: _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                    fromAddress: _fromAddressController.text.isEmpty
                        ? null
                        : _fromAddressController.text,
                    fromName: _fromNameController.text.isEmpty
                        ? null
                        : _fromNameController.text,
                    subject: _subjectController.text.isEmpty
                        ? null
                        : _subjectController.text,
                    bodyContent: _bodyContentController.text.isEmpty
                        ? null
                        : _bodyContentController.text,
                    replyToAddresses: _replyToController.text.isEmpty
                        ? null
                        : _replyToController.text,
                    ccAddresses: _ccController.text.isEmpty
                        ? null
                        : _ccController.text,
                    bccAddresses: _bccController.text.isEmpty
                        ? null
                        : _bccController.text,
                  ),
                ),
              );
            }
          },
          child: Text(isNew ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}

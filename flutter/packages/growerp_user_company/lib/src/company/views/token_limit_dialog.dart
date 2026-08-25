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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/l10n/generated/user_company_localizations.dart';

/// Override the monthly system AI token limit for a single owner(tenant).
/// An empty value clears the override so the GrowERP wide default applies again.
class TokenLimitDialog extends StatefulWidget {
  final Company company;
  const TokenLimitDialog({required this.company, super.key});

  @override
  TokenLimitDialogState createState() => TokenLimitDialogState();
}

class TokenLimitDialogState extends State<TokenLimitDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _limitController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.company.llmTokenLimit?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);
    try {
      final restClient = context.read<RestClient>();
      final text = _limitController.text.trim();
      await restClient.updateOwnerTokenLimit({
        // tokens are recorded against the owner party, not the company party
        'ownerPartyId': widget.company.ownerPartyId ?? widget.company.partyId,
        'llmMonthlyTokenLimit': text.isEmpty ? null : int.parse(text),
      });
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        HelperFunctions.showMessage(context, e.toString(), Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = UserCompanyLocalizations.of(context)!;
    return Dialog(
      key: const Key('TokenLimitDialog'),
      insetPadding: const EdgeInsets.all(20),
      child: popUp(
        context: context,
        title: localizations.aiTokenLimit,
        height: 280,
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.company.name}\n${localizations.aiTokenLimitHelp}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('tokenLimit'),
                controller: _limitController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: localizations.aiTokenLimit,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                key: const Key('tokenLimitUpdate'),
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(localizations.update),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

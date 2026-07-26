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

import 'package:growerp_order_accounting/growerp_order_accounting.dart';

/// Translate FinDoc BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param' or 'key:param1:param2'
/// Example: 'finDocAddSuccess:Order:ORD001' -> "Order ORD001 added successfully"
String translateFinDocBlocMessage(
  String? messageKey,
  OrderAccountingLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Check if message has parameters (format: key:param or key:param1:param2)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param1 = parts.length > 1 ? parts[1] : '';
    final param2 = parts.length > 2 ? parts[2] : '';

    switch (key) {
      case 'finDocAddSuccess':
        return localizations.finDocAddSuccess(param1, param2);
      case 'paymentRefundSuccess':
        return localizations.paymentRefundSuccess(param1, param2);
      default:
        break;
    }
  }

  // Handle non-parameterized finDoc keys
  switch (messageKey) {
    case 'finDocUpdateSuccess':
      return localizations.finDocUpdateSuccess;
    case 'finDocUpdateFailure':
      return localizations.finDocUpdateFailure;
    case 'finDocDeleteSuccess':
      return localizations.finDocDeleteSuccess;
    case 'finDocDeleteFailure':
      return localizations.finDocDeleteFailure;
    case 'finDocAddFailure':
      return localizations.finDocAddFailure;
    case 'finDocFetchFailure':
      return localizations.finDocFetchFailure;
    default:
      break;
  }

  // Fallback: return the key itself
  return messageKey;
}

/// Translate GlAccount BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param'
/// Example: 'glAccountUpdateSuccess:Cash' -> "GL Account Cash updated successfully"
String translateGlAccountBlocMessage(
  String? messageKey,
  OrderAccountingLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Check if message has parameters (format: key:param)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param = parts.length > 1 ? parts.sublist(1).join(':') : '';

    switch (key) {
      case 'glAccountUpdateSuccess':
        return localizations.glAccountUpdateSuccess(param);
      case 'glAccountAddSuccess':
        return localizations.glAccountAddSuccess(param);
      case 'glAccountUploadSuccess':
        return localizations.glAccountUploadSuccess;
      default:
        break;
    }
  }

  // Fallback: return the key itself
  return messageKey;
}

/// Translate Ledger BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param'
/// Example: 'timePeriodUpdateSuccess:Q1-2025' -> "Time Period Q1-2025 updated successfully"
String translateLedgerBlocMessage(
  String? messageKey,
  OrderAccountingLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Check if message has parameters (format: key:param)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param = parts.length > 1 ? parts.sublist(1).join(':') : '';

    switch (key) {
      case 'timePeriodUpdateSuccess':
        return localizations.timePeriodUpdateSuccess(param);
      case 'timePeriodCloseSuccess':
        return localizations.timePeriodCloseSuccess(param);
      default:
        break;
    }
  }

  // Fallback: return the key itself
  return messageKey;
}

/// Translate LedgerJournal BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param'
/// Example: 'ledgerJournalAddSuccess:Main Journal' -> "Ledger journal Main Journal added successfully"
String translateLedgerJournalBlocMessage(
  String? messageKey,
  OrderAccountingLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Check if message has parameters (format: key:param)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param = parts.length > 1 ? parts.sublist(1).join(':') : '';

    switch (key) {
      case 'ledgerJournalAddSuccess':
        return localizations.ledgerJournalAddSuccess(param);
      default:
        break;
    }
  }

  // Fallback: return the key itself
  return messageKey;
}

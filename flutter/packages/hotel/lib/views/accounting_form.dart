/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:universal_io/io.dart';

class AccountingForm extends StatelessWidget {
  const AccountingForm({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;
    String currencyId = context
        .read<AuthBloc>()
        .state
        .authenticate!
        .company!
        .currency!
        .currencyId!;
    String currencySymbol = NumberFormat.simpleCurrency(
      locale: Platform.localeName,
      name: currencyId,
    ).currencySymbol;
    Authenticate authenticate = context.read<AuthBloc>().state.authenticate!;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.count(
        crossAxisCount: isAPhone(context) ? 2 : 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          _AcctCard(
            title: localizations.accountingSales,
            subtitle:
                "${localizations.openInvoices}\n$currencySymbol "
                "${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'}",
            count: "(${authenticate.stats?.salesInvoicesNotPaidCount})",
            imageAsset: "packages/growerp_core/images/orderGrey.png",
            onTap: () => context.go('/accounting/sales'),
          ),
          _AcctCard(
            title: localizations.accountingPurch,
            subtitle:
                "${localizations.openInvoices}\n$currencySymbol "
                "${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'}",
            count: "(${authenticate.stats?.purchInvoicesNotPaidCount})",
            imageAsset: "packages/growerp_core/images/supplierGrey.png",
            onTap: () => context.go('/accounting/purchase'),
          ),
          _AcctCard(
            title: localizations.accountingLedger,
            imageAsset: "packages/growerp_core/images/accountingGrey.png",
            onTap: () => context.go('/accounting/ledger'),
          ),
          _AcctCard(
            title: localizations.reports,
            subtitle:
                "${localizations.revenueExpense}\n${localizations.balanceSheet}\n${localizations.balanceSummary}",
            imageAsset: "packages/growerp_core/images/reportGrey.png",
            onTap: () => context.go('/accounting/reports'),
          ),
          _AcctCard(
            title: localizations.setUp,
            subtitle:
                "${localizations.timePeriods}\n${localizations.itemTypes}\n${localizations.paymentTypes}",
            imageAsset: "packages/growerp_core/images/setupGrey.png",
            onTap: () => context.go('/accounting/setup'),
          ),
          _AcctCard(
            title: localizations.mainDashboard,
            imageAsset: "packages/growerp_core/images/dashBoardGrey.png",
            onTap: () => context.go('/'),
          ),
        ],
      ),
    );
  }
}

class _AcctCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? count;
  final String imageAsset;
  final VoidCallback onTap;

  const _AcctCard({
    required this.title,
    this.subtitle,
    this.count,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imageAsset,
                height: 60,
                // ignore: deprecated_member_use
                color: Colors
                    .grey[700], // Apply tint if needed to match Grey images
                colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              if (count != null)
                Text(
                  count!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

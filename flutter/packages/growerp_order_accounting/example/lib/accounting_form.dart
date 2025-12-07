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
import 'package:responsive_framework/responsive_framework.dart';

class AccountingForm extends StatelessWidget {
  const AccountingForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const Center(child: CircularProgressIndicator());
        }
        Authenticate authenticate = state.authenticate!;

        return Padding(
          padding: const EdgeInsets.all(10),
          child: GridView.count(
            crossAxisCount: ResponsiveBreakpoints.of(context).isMobile ? 2 : 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _AcctCard(
                title: "Sales",
                subtitle:
                    "Open Inv: ${authenticate.company!.currency!.description} ${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'}",
                count: "(${authenticate.stats?.salesInvoicesNotPaidCount})",
                icon: Icons.attach_money,
                onTap: () =>
                    context.go('/accounting/sales'), // Placeholder route
              ),
              _AcctCard(
                title: "Purchase",
                subtitle:
                    "Unpaid Inv: ${authenticate.company!.currency!.description} ${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'}",
                count: "(${authenticate.stats?.purchInvoicesNotPaidCount})",
                icon: Icons.money_off,
                onTap: () => context.go('/accounting/purchase'),
              ),
              _AcctCard(
                title: "Ledger",
                subtitle: "Accounts, Trans, Journals",
                icon: Icons.account_balance_wallet,
                onTap: () => context.go('/accounting/ledger'),
              ),
              _AcctCard(
                title: "Reports",
                subtitle: "Balance Sheet, Summary",
                icon: Icons.summarize,
                onTap: () => context.go('/accounting/reports'),
              ),
              _AcctCard(
                title: "Setup",
                subtitle: "Periods, Item types, Payment types",
                icon: Icons.settings,
                onTap: () => context.go('/accounting/setup'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AcctCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? count;
  final IconData icon;
  final VoidCallback onTap;

  const _AcctCard({
    required this.title,
    this.subtitle,
    this.count,
    required this.icon,
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
              Icon(icon, size: 40, color: Colors.grey),
              const SizedBox(height: 10),
              Text(
                title,
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

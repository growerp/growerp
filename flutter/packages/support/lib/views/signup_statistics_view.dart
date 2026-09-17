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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../l10n/generated/support_localizations.dart';

/// New tenant signups that logged in at least once: which app they registered
/// with, on how many days their users logged in and how many REST calls they
/// made. Login and call figures come from the artifact hit log, which is
/// purged after 90 days.
class SignupStatisticsView extends StatefulWidget {
  const SignupStatisticsView({super.key});

  @override
  State<SignupStatisticsView> createState() => _SignupStatisticsViewState();
}

class _SignupStatisticsViewState extends State<SignupStatisticsView> {
  late RestClient _restClient;
  SignupStatistics? _stats;
  bool _loading = true;
  String? _error;
  int _periodDays = 90;
  String _search = '';

  /// Without a bloc there is no restartable() to cancel a superseded search,
  /// and the search field fires twice per keystroke, so only the newest
  /// request may update the screen.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _restClient = context.read<RestClient>();
    _fetch();
  }

  Future<void> _fetch() async {
    final requestId = ++_requestId;
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final from = now.subtract(Duration(days: _periodDays));
      final stats = await _restClient.getSignupStatistics(
        startDateTime: '${_isoDate(from)} 00:00:00',
        endDateTime: '${_isoDate(now)} 23:59:59',
        searchString: _search.isEmpty ? null : _search,
        limit: 200,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _stats = stats;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _showDetail(Signup signup) {
    final localizations = SupportLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        key: const Key('SignupDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: signup.companyName,
          width: 400,
          height: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(localizations.signupColSignup, signup.signupDate),
                _detailRow(localizations.signupColApp, signup.applicationId),
                _detailRow(localizations.signupAdmin, signup.adminName),
                _detailRow(localizations.signupAdminEmail, signup.adminEmail),
                _detailRow(localizations.signupFirstLogin, signup.firstLoginDate),
                _detailRow(localizations.signupColLastLogin, signup.lastLoginDate),
                _detailRow(
                    localizations.signupColDays, '${signup.daysLoggedIn}'),
                _detailRow(
                    localizations.signupColLogins, '${signup.loginCount}'),
                _detailRow(
                    localizations.signupColCalls, '${signup.restCalls}'),
                _detailRow(localizations.signupUsers, '${signup.userCount}'),
                _detailRow(
                    localizations.signupAppsUsed, signup.appsUsed.join(', ')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  List<StyledColumn> _columns(bool isPhone) {
    final localizations = SupportLocalizations.of(context)!;
    return [
      StyledColumn(header: localizations.signupColSignup, flex: 2),
      StyledColumn(header: localizations.signupColCompany, flex: 3),
      if (!isPhone) StyledColumn(header: localizations.signupColApp, flex: 2),
      if (!isPhone)
        StyledColumn(header: localizations.signupColLastLogin, flex: 2),
      // the numeric columns come last: a right aligned column followed by a
      // left aligned one would have its text touch the next column
      StyledColumn(
          header: localizations.signupColDays,
          flex: 1,
          alignment: TextAlign.right),
      if (!isPhone)
        StyledColumn(
            header: localizations.signupColLogins,
            flex: 1,
            alignment: TextAlign.right),
      StyledColumn(
          header: localizations.signupColCalls,
          flex: 2,
          alignment: TextAlign.right),
    ];
  }

  List<Widget> _row(int index, Signup signup, bool isPhone) {
    Widget cell(String text, {TextAlign align = TextAlign.left, Key? key}) =>
        Text(text,
            key: key,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis);
    return [
      cell(signup.signupDate, key: Key('item$index')),
      cell(signup.companyName),
      if (!isPhone) cell(signup.applicationId),
      if (!isPhone) cell(signup.lastLoginDate),
      cell('${signup.daysLoggedIn}', align: TextAlign.right),
      if (!isPhone) cell('${signup.loginCount}', align: TextAlign.right),
      cell('${signup.restCalls}', align: TextAlign.right),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = SupportLocalizations.of(context)!;
    final isPhone = MediaQuery.of(context).size.width < 600;
    final signups = _stats?.signups ?? [];

    return Scaffold(
      key: const Key('SignupStatisticsView'),
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          ListFilterBar(
            searchHint: localizations.signupsSearchHint,
            onSearchChanged: (value) {
              _search = value;
              _fetch();
            },
            filters: [
              FilterDropdown<int>(
                key: const Key('periodDropDown'),
                label: localizations.ninetyDays,
                value: _periodDays,
                items: [
                  DropdownMenuItem(
                      value: 30, child: Text(localizations.thirtyDays)),
                  DropdownMenuItem(
                      value: 60, child: Text(localizations.sixtyDays)),
                  DropdownMenuItem(
                      value: 90, child: Text(localizations.ninetyDays)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  _periodDays = value;
                  _fetch();
                },
              ),
            ],
          ),
          if (_error != null)
            Expanded(child: Center(child: Text(_error!)))
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${localizations.signupsTitle} '
                      '${_stats?.fromDate ?? ''} — ${_stats?.thruDate ?? ''}   '
                      '${localizations.signupsCount(_stats?.signupCount ?? 0)}',
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: !_loading && signups.isEmpty
                          ? Center(child: Text(localizations.noSignupsInPeriod))
                          : StyledDataTable(
                              key: const Key('listView'),
                              isLoading: _loading,
                              columns: _columns(isPhone),
                              rows: [
                                for (var i = 0; i < signups.length; i++)
                                  _row(i, signups[i], isPhone),
                              ],
                              onRowTap: (index) => _showDetail(signups[index]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

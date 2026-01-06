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
import 'package:growerp_core/growerp_core.dart';

import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';

class RestRequestDetailDialog extends StatelessWidget {
  final RestRequest restRequest;

  const RestRequestDetailDialog({super.key, required this.restRequest});

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;

    return Dialog(
      key: const Key('RestRequestDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: localizations.restRequestDetails,
        width: isPhone ? 400 : 800,
        height: isPhone ? 700 : 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                localizations.dateTime,
                restRequest.dateTime != null
                    ? DateFormat(
                        'dd/MM/yyyy HH:mm:ss',
                      ).format(restRequest.dateTime!)
                    : localizations.unknown,
              ),
              _buildDetailRow(
                localizations.user,
                '${restRequest.user?.firstName ?? ''} ${restRequest.user?.lastName ?? ''}',
              ),
              _buildDetailRow(
                localizations.email,
                restRequest.user?.email ?? localizations.notAvailable,
              ),
              _buildDetailRow(
                localizations.loginName,
                restRequest.user?.loginName ?? localizations.notAvailable,
              ),
              _buildDetailRow(
                localizations.requestName,
                restRequest.restRequestName ?? localizations.notAvailable,
              ),
              _buildDetailRow(
                localizations.serverIp,
                restRequest.serverIp ?? localizations.notAvailable,
              ),
              _buildDetailRow(
                localizations.serverHost,
                restRequest.serverHostName ?? localizations.notAvailable,
              ),
              _buildDetailRow(
                localizations.runningTime,
                '${restRequest.runningTimeMillis ?? 0}${localizations.ms}',
              ),
              _buildDetailRow(
                localizations.status,
                restRequest.wasError == true
                    ? localizations.error
                    : localizations.success,
                valueColor: restRequest.wasError == true
                    ? Colors.red
                    : Colors.green,
              ),
              _buildDetailRow(
                localizations.slowHit,
                restRequest.isSlowHit == true
                    ? localizations.yes
                    : localizations.no,
                valueColor: restRequest.isSlowHit == true
                    ? Colors.orange
                    : Colors.green,
              ),
              if (restRequest.errorMessage?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  localizations.errorMessage,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    restRequest.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              if (restRequest.requestUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  localizations.requestUrl,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SelectableText(restRequest.requestUrl!),
                ),
              ],
              if (restRequest.referrerUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  localizations.referrerUrl,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SelectableText(restRequest.referrerUrl!),
                ),
              ],
              if (restRequest.parameterString?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  localizations.parameters,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SelectableText(restRequest.parameterString!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }
}

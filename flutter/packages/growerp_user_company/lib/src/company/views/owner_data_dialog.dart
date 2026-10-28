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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// System support on the owners list: download the data of one owner
/// ([company] given), or upload a download as a new owner (no [company]).
class OwnerDataDialog extends StatelessWidget {
  final Company? company;

  const OwnerDataDialog({this.company, super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;
    final download = company != null;
    return Dialog(
      key: const Key('OwnerDataDialog'),
      insetPadding: const EdgeInsets.all(20),
      child: popUp(
        context: context,
        title: download
            ? '${localizations.ownerDataDownload}: ${company!.name ?? ''}'
            : localizations.ownerDataUpload,
        height: download ? 420 : 340,
        width: 600,
        child: SingleChildScrollView(
          child: SystemSetupBackupView(
            ownerPartyId: company?.ownerPartyId,
            download: download,
            upload: !download,
            standalone: false,
          ),
        ),
      ),
    );
  }
}

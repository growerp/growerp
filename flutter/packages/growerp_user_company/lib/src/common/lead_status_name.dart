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

import 'package:growerp_models/growerp_models.dart';

import '../../l10n/generated/user_company_localizations.dart';

/// Localized name of a [LeadStatus], a lead without a status is new.
String leadStatusName(UserCompanyLocalizations l10n, LeadStatus? status) =>
    switch (status) {
      LeadStatus.assigned => l10n.leadStatusAssigned,
      LeadStatus.qualified => l10n.leadStatusQualified,
      LeadStatus.converted => l10n.leadStatusConverted,
      null => l10n.leadStatusNew,
    };

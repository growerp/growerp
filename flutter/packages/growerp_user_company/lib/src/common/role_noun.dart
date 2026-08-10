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

/// Localized plural noun for a [Role], used in list titles and search hints.
///
/// [fallback] is returned when the list is not restricted to a single role,
/// e.g. 'Companies' for the company list and 'Users' for the user list.
String roleNoun(UserCompanyLocalizations l10n, Role? role, String fallback) =>
    switch (role) {
      Role.company => l10n.employees,
      Role.customer => l10n.customers,
      Role.lead => l10n.leads,
      Role.supplier => l10n.suppliers,
      _ => fallback,
    };

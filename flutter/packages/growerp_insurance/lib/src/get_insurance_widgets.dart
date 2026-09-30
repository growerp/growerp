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

import 'package:growerp_core/growerp_core.dart';

import '../growerp_insurance.dart';

/// Widget mappings for the insurance package
Map<String, GrowerpWidgetBuilder> getInsuranceWidgets() {
  return {
    'PolicyList': (args) => const PolicyList(),
    'PolicyRenewalList': (args) => const PolicyRenewalList(),
    'CommissionList': (args) => const CommissionList(),
    'ClaimList': (args) => const ClaimList(),
    'MyPoliciesView': (args) => const MyPoliciesView(),
  };
}

/// Widget metadata with icons and keywords for the insurance package
List<WidgetMetadata> getInsuranceWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'PolicyList',
      description:
          'Insurance policies sold for carriers to clients: policy number, '
          'insured, carrier, line of business, term, premium, coverages',
      iconName: 'shield',
      keywords: ['policy', 'insurance', 'coverage', 'premium', 'carrier'],
      builder: (args) => const PolicyList(),
    ),
    WidgetMetadata(
      widgetName: 'PolicyRenewalList',
      description:
          'Policies expiring within  days which still '
          'have to be renewed',
      iconName: 'autorenew',
      keywords: ['renewal', 'renew', 'expiring', 'policy'],
      builder: (args) => const PolicyRenewalList(),
    ),
    WidgetMetadata(
      widgetName: 'CommissionList',
      description:
          'Expected yearly commission per policy against what the carrier '
          'paid; record a received commission',
      iconName: 'payments',
      keywords: ['commission', 'carrier', 'income', 'brokerage'],
      builder: (args) => const CommissionList(),
    ),
    WidgetMetadata(
      widgetName: 'ClaimList',
      description:
          'Claims of the clients on their policies, followed up with the '
          'carrier',
      iconName: 'report',
      keywords: ['claim', 'damage', 'loss', 'incident'],
      builder: (args) => const ClaimList(),
    ),
    WidgetMetadata(
      widgetName: 'MyPoliciesView',
      description:
          'Client portal: the policies and claims of the logged in client, '
          'report a claim',
      iconName: 'shield',
      keywords: ['my policies', 'my claims', 'client portal'],
      builder: (args) => const MyPoliciesView(),
    ),
  ];
}

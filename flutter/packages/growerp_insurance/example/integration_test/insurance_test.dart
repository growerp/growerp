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

// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_insurance/growerp_insurance.dart';
import 'package:growerp_insurance_example/router_builder.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('GrowERP insurance test', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createInsuranceExampleRouter(),
      insuranceMenuConfig,
      extraDelegates,
      restClient: restClient,
      blocProviders: getExampleBlocProviders(restClient, 'AppInsurance'),
      applicationId: 'AppInsurance',
      title: "Insurance test",
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    final random = CommonTest.getRandom();

    // the carrier is a supplier, the insured client a customer
    final carrier = await restClient.createCompany(
      company: Company(name: 'Carrier$random', role: Role.supplier),
    );
    final client = await restClient.createCompany(
      company: Company(name: 'Client$random', role: Role.customer),
    );

    final now = DateTime.now();
    final plate = '51K-$random';
    final expiringSoon = Policy(
      policyNumber: 'SOON$random',
      insuredName: client.name,
      carrierName: carrier.name,
      policyType: PolicyType.motorCompulsory,
      vehiclePlate: plate,
      effectiveDate: now.subtract(const Duration(days: 345)),
      expirationDate: now.add(const Duration(days: 20)),
      premiumAmount: Decimal.parse('500'),
      premiumFrequency: PremiumFrequency.annual,
      commissionRate: Decimal.parse('15'),
      coverages: [
        PolicyCoverage(
          coverageName: 'General liability',
          limitAmount: Decimal.parse('1000000'),
        ),
      ],
    );
    final nextYear = Policy(
      policyNumber: 'YEAR$random',
      insuredName: client.name,
      carrierName: carrier.name,
      policyType: PolicyType.property,
      effectiveDate: now,
      expirationDate: now.add(const Duration(days: 365)),
      premiumAmount: Decimal.parse('100'),
      premiumFrequency: PremiumFrequency.monthly,
      commissionRate: Decimal.parse('10'),
    );

    // --- staff: policies; a new one is added at the top of the list
    await PolicyTest.selectPolicies(tester);
    await PolicyTest.addPolicies(tester, [expiringSoon, nextYear]);
    await PolicyTest.checkPolicy(tester, 0, policyNumber: 'YEAR$random');
    await PolicyTest.checkPolicy(
      tester,
      1,
      policyNumber: 'SOON$random',
      status: PolicyStatus.active,
      insuredName: client.name,
    );

    // renewal: only the policy expiring soon is listed, and gone once renewed
    await CommonTest.selectOption(tester, '/renewals', 'PolicyRenewalList');
    await PolicyTest.checkPolicy(tester, 0, policyNumber: 'SOON$random');
    expect(find.byKey(const Key('item1')), findsNothing);
    await PolicyTest.renewPolicy(tester, 0);
    expect(find.byKey(const Key('item0')), findsNothing);

    // fetched again, ordered by expiration date: the renewal runs a year
    // after the renewed policy, which comes first
    await PolicyTest.selectPolicies(tester);
    await PolicyTest.checkPolicy(
      tester,
      0,
      policyNumber: 'SOON$random',
      status: PolicyStatus.renewed,
    );
    await PolicyTest.checkPolicy(tester, 1, policyNumber: 'YEAR$random');
    await PolicyTest.checkPolicy(
      tester,
      2,
      policyNumber: 'SOON$random',
      status: PolicyStatus.active,
    );

    // commission: 100 a month at 10% is 120 a year
    await PolicyTest.selectCommissions(tester);
    await PolicyTest.checkCommission(tester, 1, expected: '120', received: '0');
    await PolicyTest.receiveCommission(tester, 1, '50');
    await PolicyTest.checkCommission(tester, 1, received: '50');

    // claim reported by the agency and filed with the carrier
    await ClaimTest.selectClaims(tester);
    await ClaimTest.addClaims(tester, [
      Claim(
        policyNumber: 'YEAR$random',
        incidentDate: now.subtract(const Duration(days: 2)),
        description: 'Water damage in storage room',
        amountClaimed: Decimal.parse('2500'),
      ),
    ]);
    await ClaimTest.checkClaim(
      tester,
      0,
      status: ClaimStatus.submitted,
      policyNumber: 'YEAR$random',
    );
    await ClaimTest.updateClaim(
      tester,
      0,
      status: ClaimStatus.filed,
      claimNumber: 'CL$random',
    );
    await ClaimTest.checkClaim(tester, 0, status: ClaimStatus.filed);

    // --- client: logs in to the portal, sees its policies and reports a claim
    final clientEmail = 'client$random@example.com';
    await restClient.createUser(
      user: User(
        firstName: 'Carla',
        lastName: 'Client$random',
        email: clientEmail,
        loginName: clientEmail,
        role: Role.customer,
        userGroup: UserGroup.other,
        company: Company(partyId: client.partyId, name: client.name),
      ),
      password: 'qqqqqq9!',
    );
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
    await CommonTest.login(tester, username: clientEmail);

    // the renewed policy is shown until it expires, as it is still the
    // proof of cover; then the next year one and the renewal
    await MyPoliciesTest.selectMyPolicies(tester);
    await MyPoliciesTest.checkMyPolicy(tester, 0, 'SOON$random');
    await MyPoliciesTest.checkMyPolicy(tester, 1, 'YEAR$random');
    await MyPoliciesTest.checkMyPolicy(tester, 2, 'SOON$random');
    await MyPoliciesTest.checkNoOtherPolicies(tester, 3);
    // the digital card of the policy in force carries the plate and QR proof
    await MyPoliciesTest.checkPolicyCard(tester, 0, plate: plate);
    // a claim through the guided wizard, with a photo
    await MyPoliciesTest.reportClaim(
      tester,
      policyLabel: 'YEAR$random',
      incidentDate: now.subtract(const Duration(days: 1)),
      description: 'Rear-ended at a traffic light',
      location: 'Nguyen Hue, District 1',
    );
    await ClaimTest.checkClaim(tester, 0, status: ClaimStatus.submitted);
    await ClaimTest.checkClaim(tester, 1, status: ClaimStatus.filed);
    // photos are stored with the claim and triaged in the background; the
    // client only sees what extra evidence is asked (canned in test mode)
    final myPolicies = await restClient.getPolicies(search: plate);
    final withPhoto = await restClient.createClaim(
      claim: Claim(
        policyId: myPolicies.policies.first.policyId,
        incidentType: IncidentType.parked,
        incidentDate: now.subtract(const Duration(days: 1)),
        description: 'Scratched while parked',
        photos: [
          ClaimPhoto(description: 'damage', image: base64Decode(_pixel)),
        ],
      ),
    );
    Claim? assessed;
    for (var i = 0; i < 20; i++) {
      final found = await restClient.getClaims(claimId: withPhoto.claimId);
      assessed = found.claims.first;
      if (assessed.status == ClaimStatus.aiAssessed) break;
      await Future.delayed(const Duration(seconds: 1));
    }
    expect(assessed!.photos?.length, 1);
    expect(assessed.photos!.first.image, isNotNull);
    expect(assessed.status, ClaimStatus.aiAssessed);
    expect(assessed.aiAssessment, isNull); // advice is for staff only
    expect(assessed.missingEvidence, isNotEmpty);
    expect(assessed.statusHistory?.first.status, ClaimStatus.submitted);

    // the assistant answers from the client's own data (canned in test mode)
    await MyPoliciesTest.askAssistant(
      tester,
      'When does my car insurance end?',
    );

    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
  });
}

/// 1x1 transparent png, a photo for the claim upload
const _pixel =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

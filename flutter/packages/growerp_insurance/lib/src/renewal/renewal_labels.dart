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

import '../../growerp_insurance.dart';

/// Plain-language labels of the renewal engine's backend codes.
String channelLabel(InsuranceLocalizations l, String? id) => switch (id) {
  'InchZalo' => l.chZalo,
  'InchVetc' => l.chVetc,
  'InchSms' => l.chSms,
  'InchEmail' => l.chEmail,
  'InchVoiceBot' => l.chVoiceBot,
  'InchCall' => l.chCall,
  'InchWeb' => l.chWeb,
  _ => '',
};

String eventLabel(InsuranceLocalizations l, String? id) => switch (id) {
  'InevSent' => l.evSent,
  'InevOpened' => l.evOpened,
  'InevVisited' => l.evVisited,
  'InevConfirmed' => l.evConfirmed,
  'InevRenewRequested' => l.evRenewRequested,
  'InevCallback' => l.evCallback,
  'InevCalled' => l.evCalled,
  'InevOptOut' => l.evOptOut,
  'InevRenewed' => l.evRenewed,
  'InevIssued' => l.evIssued,
  _ => l.evNone,
};

const outcomeIds = [
  'InocRenewed',
  'InocInterested',
  'InocCallLater',
  'InocNotInterested',
  'InocSoldVehicle',
  'InocInsuredElsewhere',
  'InocWrongNumber',
  'InocNoAnswer',
  'InocOptOut',
];

String outcomeLabel(InsuranceLocalizations l, String? id) => switch (id) {
  'InocRenewed' => l.ocRenewed,
  'InocInterested' => l.ocInterested,
  'InocCallLater' => l.ocCallLater,
  'InocNotInterested' => l.ocNotInterested,
  'InocSoldVehicle' => l.ocSoldVehicle,
  'InocInsuredElsewhere' => l.ocInsuredElsewhere,
  'InocWrongNumber' => l.ocWrongNumber,
  'InocNoAnswer' => l.ocNoAnswer,
  'InocOptOut' => l.ocOptOut,
  _ => '',
};

String actionLabel(InsuranceLocalizations l, String? action) =>
    switch (action) {
      'Send reminder' => l.actSendReminder,
      'Telesales call' => l.actTelesales,
      'AI voice call' => l.actAiCall,
      'Issue the renewal' => l.actIssue,
      'Wait, reminded recently' => l.actWait,
      'Ask consent at next visit' => l.actConsent,
      'Do not contact' => l.actStop,
      _ => l.actNone,
    };

String bandLabel(InsuranceLocalizations l, String? band) => switch (band) {
  'High' => l.bandHigh,
  'Medium' => l.bandMedium,
  'Low' => l.bandLow,
  'Done' => l.bandDone,
  'Stop' => l.bandStop,
  _ => l.bandAll,
};

/// band colour; the band is always written next to it, colour never alone
Color bandColor(String? band) => switch (band) {
  'High' => const Color(0xFF1B7F66),
  'Medium' => const Color(0xFFB7791F),
  'Low' => const Color(0xFF8A94A3),
  'Done' => const Color(0xFF2B6CB0),
  _ => const Color(0xFFB3261E),
};

/// a score with its band, e.g. "82 · High"
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score, required this.band});
  final int? score;
  final String? band;

  @override
  Widget build(BuildContext context) {
    final l = InsuranceLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bandColor(band),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${score ?? '-'} · ${bandLabel(l, band)}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

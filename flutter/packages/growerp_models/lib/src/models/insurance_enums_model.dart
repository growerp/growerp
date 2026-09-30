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

/// Line of business of an insurance policy, backend field: policyTypeEnumId.
enum PolicyType {
  auto('InptAuto', 'Auto'),
  home('InptHome', 'Home'),
  liability('InptLiability', 'Liability'),
  property('InptProperty', 'Commercial Property'),
  life('InptLife', 'Life'),
  health('InptHealth', 'Health'),
  travel('InptTravel', 'Travel'),
  motorCompulsory('InptMotorCompulsory', 'Compulsory Motor Liability'),
  other('InptOther', 'Other');

  const PolicyType(this.value, this.name);

  final String value; // value used in backend
  final String name; // value used in frontend

  static PolicyType? getByValue(String value) {
    for (final type in PolicyType.values) {
      if (type.value == value) return type;
    }
    return null;
  }

  @override
  String toString() => value;
}

/// How often the premium is paid, backend field: premiumFrequencyEnumId.
enum PremiumFrequency {
  monthly('InpfMonthly', 'Monthly'),
  quarterly('InpfQuarterly', 'Quarterly'),
  semiAnnual('InpfSemiAnnual', 'Semi-annual'),
  annual('InpfAnnual', 'Annual'),
  single('InpfSingle', 'Single');

  const PremiumFrequency(this.value, this.name);

  final String value;
  final String name;

  static PremiumFrequency? getByValue(String value) {
    for (final frequency in PremiumFrequency.values) {
      if (frequency.value == value) return frequency;
    }
    return null;
  }

  @override
  String toString() => value;
}

/// Status of an insurance policy, backend field: statusId.
enum PolicyStatus {
  quote('InpsQuote', 'Quote'),
  active('InpsActive', 'Active'),
  renewalDue('InpsRenewalDue', 'Renewal Due'),
  renewed('InpsRenewed', 'Renewed'),
  lapsed('InpsLapsed', 'Lapsed'),
  cancelled('InpsCancelled', 'Cancelled');

  const PolicyStatus(this.value, this.name);

  final String value;
  final String name;

  static PolicyStatus? getByValue(String value) {
    for (final status in PolicyStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }

  @override
  String toString() => value;
}

/// Status of an insurance claim, backend field: statusId.
enum ClaimStatus {
  submitted('InclSubmitted', 'Submitted'),
  aiAssessed('InclAiAssessed', 'Assessed, awaiting adjuster'),
  inReview('InclInReview', 'In Review'),
  filed('InclFiled', 'Filed with Carrier'),
  approved('InclApproved', 'Approved'),
  denied('InclDenied', 'Denied'),
  paid('InclPaid', 'Paid'),
  closed('InclClosed', 'Closed');

  const ClaimStatus(this.value, this.name);

  final String value;
  final String name;

  static ClaimStatus? getByValue(String value) {
    for (final status in ClaimStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }

  @override
  String toString() => value;
}

/// What happened, chosen by the client in the guided claim wizard,
/// backend field: incidentTypeEnumId.
enum IncidentType {
  collision('InitCollision', 'Collision with another vehicle'),
  singleVehicle('InitSingleVehicle', 'Single vehicle accident'),
  parked('InitParked', 'Damaged while parked'),
  injury('InitInjury', 'Someone was injured'),
  flood('InitFlood', 'Flood or storm'),
  theft('InitTheft', 'Theft or break-in'),
  glass('InitGlass', 'Broken glass'),
  other('InitOther', 'Something else');

  const IncidentType(this.value, this.name);

  final String value;
  final String name;

  static IncidentType? getByValue(String value) {
    for (final type in IncidentType.values) {
      if (type.value == value) return type;
    }
    return null;
  }

  @override
  String toString() => value;
}

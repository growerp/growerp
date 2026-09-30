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

part of 'policy_bloc.dart';

abstract class PolicyEvent extends Equatable {
  const PolicyEvent();
  @override
  List<Object?> get props => [];
}

/// Fetch policies; with [expiringWithinDays] above 0 only those expiring
/// within that many days (renewals).
class PoliciesFetch extends PolicyEvent {
  const PoliciesFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
    this.expiringWithinDays = 0,
  });
  final String searchString;
  final bool refresh;
  final int limit;
  final int expiringWithinDays;
  @override
  List<Object?> get props => [searchString, refresh, expiringWithinDays];
}

class PolicySearchChanged extends PolicyEvent {
  const PolicySearchChanged({required this.searchString});
  final String searchString;
  @override
  List<Object?> get props => [searchString];
}

class PolicyUpdate extends PolicyEvent {
  const PolicyUpdate(this.policy);
  final Policy policy;
}

class PolicyDelete extends PolicyEvent {
  const PolicyDelete(this.policy);
  final Policy policy;
}

/// Renew [policy] for the next term; a changed premium or policy number of
/// the renewal can be passed in it.
class PolicyRenew extends PolicyEvent {
  const PolicyRenew(this.policy);
  final Policy policy;
}

class PolicyCommissionReceive extends PolicyEvent {
  const PolicyCommissionReceive({required this.policyId, required this.amount});
  final String policyId;
  final Decimal amount;
}

/// The client asks the agency to renew [policyId]; staff renew it with the
/// carrier.
class PolicyRenewalRequest extends PolicyEvent {
  const PolicyRenewalRequest({required this.policyId, this.message});
  final String policyId;
  final String? message;
}

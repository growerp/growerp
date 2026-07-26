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

part of 'opportunity_bloc.dart';

abstract class OpportunityEvent extends Equatable {
  const OpportunityEvent();
  @override
  List<Object> get props => [];
}

class OpportunityFetch extends OpportunityEvent {
  const OpportunityFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
  });
  final String searchString;
  final bool refresh;
  final int limit;
  @override
  List<Object> get props => [searchString, refresh];
}

class OpportunitySummaryFetch extends OpportunityEvent {
  const OpportunitySummaryFetch();
}

class OpportunityUpdate extends OpportunityEvent {
  const OpportunityUpdate(this.opportunity);
  final Opportunity opportunity;
}

class OpportunityDelete extends OpportunityEvent {
  const OpportunityDelete(this.opportunity);
  final Opportunity opportunity;
}

class OpportunityConvertToOrder extends OpportunityEvent {
  const OpportunityConvertToOrder(this.opportunity);
  final Opportunity opportunity;
}

class OpportunitySearchChanged extends OpportunityEvent {
  const OpportunitySearchChanged({required this.searchString, this.limit = 20});
  final String searchString;
  final int limit;
  @override
  List<Object> get props => [searchString];
}

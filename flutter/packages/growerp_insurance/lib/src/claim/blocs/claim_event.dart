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

part of 'claim_bloc.dart';

abstract class ClaimEvent extends Equatable {
  const ClaimEvent();
  @override
  List<Object?> get props => [];
}

class ClaimsFetch extends ClaimEvent {
  const ClaimsFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
  });
  final String searchString;
  final bool refresh;
  final int limit;
  @override
  List<Object?> get props => [searchString, refresh];
}

class ClaimSearchChanged extends ClaimEvent {
  const ClaimSearchChanged({required this.searchString});
  final String searchString;
  @override
  List<Object?> get props => [searchString];
}

class ClaimUpdate extends ClaimEvent {
  const ClaimUpdate(this.claim);
  final Claim claim;
}

class ClaimDelete extends ClaimEvent {
  const ClaimDelete(this.claim);
  final Claim claim;
}

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

part of 'liner_type_bloc.dart';

abstract class LinerTypeEvent extends Equatable {
  const LinerTypeEvent();
  @override
  List<Object?> get props => [];
}

class LinerTypesFetch extends LinerTypeEvent {
  const LinerTypesFetch({
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

class LinerTypeUpdate extends LinerTypeEvent {
  const LinerTypeUpdate(this.linerType);
  final LinerType linerType;
}

class LinerTypeDelete extends LinerTypeEvent {
  const LinerTypeDelete(this.linerType);
  final LinerType linerType;
}

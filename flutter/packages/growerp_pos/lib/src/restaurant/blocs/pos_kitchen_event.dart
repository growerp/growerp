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

part of 'pos_kitchen_bloc.dart';

abstract class PosKitchenEvent extends Equatable {
  const PosKitchenEvent();
  @override
  List<Object?> get props => [];
}

class PosKitchenFetch extends PosKitchenEvent {
  const PosKitchenFetch();
}

class PosKitchenBump extends PosKitchenEvent {
  const PosKitchenBump(this.line);
  final PosTabLine line;
  @override
  List<Object?> get props => [line];
}

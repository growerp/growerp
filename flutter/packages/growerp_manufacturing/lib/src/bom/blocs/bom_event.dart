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

part of 'bom_bloc.dart';

abstract class BomEvent extends Equatable {
  const BomEvent();
  @override
  List<Object?> get props => [];
}

class BomFetch extends BomEvent {
  const BomFetch({
    this.productId,
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
  });
  final String? productId;
  final String searchString;
  final bool refresh;
  final int limit;
  @override
  List<Object?> get props => [productId, searchString, refresh];
}

class BomsFetch extends BomEvent {
  const BomsFetch({
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

class BomUpdate extends BomEvent {
  const BomUpdate(this.bomItem);
  final BomItem bomItem;
}

class BomDelete extends BomEvent {
  const BomDelete(this.bomItem);
  final BomItem bomItem;
}

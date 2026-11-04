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

part of 'pos_catalog_bloc.dart';

abstract class PosCatalogEvent extends Equatable {
  const PosCatalogEvent();
  @override
  List<Object?> get props => [];
}

class PosCatalogFetch extends PosCatalogEvent {
  const PosCatalogFetch({this.refresh = false});
  final bool refresh;
  @override
  List<Object?> get props => [refresh];
}

class PosBarcodeScan extends PosCatalogEvent {
  const PosBarcodeScan(this.barcode);
  final String barcode;
  @override
  List<Object?> get props => [barcode];
}

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

part of 'pos_sale_bloc.dart';

enum PosSaleStatus { initial, loading, success, failure }

class PosSaleState extends Equatable {
  const PosSaleState({
    this.status = PosSaleStatus.initial,
    this.clientSaleId,
    this.sale,
    this.message,
  });

  final PosSaleStatus status;
  final String? clientSaleId;
  final PosSale? sale;
  final String? message;

  PosSaleState copyWith({
    PosSaleStatus? status,
    String? clientSaleId,
    PosSale? sale,
    String? message,
  }) {
    return PosSaleState(
      status: status ?? this.status,
      clientSaleId: clientSaleId ?? this.clientSaleId,
      sale: sale ?? this.sale,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, clientSaleId, sale, message];

  @override
  String toString() => '$status { id: $clientSaleId, message: $message }';
}

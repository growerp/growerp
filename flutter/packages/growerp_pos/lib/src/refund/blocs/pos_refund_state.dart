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

part of 'pos_refund_bloc.dart';

enum PosRefundStatus { initial, loading, found, success, failure }

class PosRefundState extends Equatable {
  const PosRefundState({
    this.status = PosRefundStatus.initial,
    this.sale,
    this.refund,
    this.clientRefundId,
    this.message,
  });

  final PosRefundStatus status;
  final PosSale? sale;
  final PosRefund? refund;
  final String? clientRefundId;
  final String? message;

  PosRefundState copyWith({
    PosRefundStatus? status,
    PosSale? sale,
    PosRefund? refund,
    String? clientRefundId,
    String? message,
  }) {
    return PosRefundState(
      status: status ?? this.status,
      sale: sale ?? this.sale,
      refund: refund ?? this.refund,
      clientRefundId: clientRefundId ?? this.clientRefundId,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, sale, refund, clientRefundId, message];

  @override
  String toString() => '$status { sale: ${sale?.orderId}, message: $message }';
}

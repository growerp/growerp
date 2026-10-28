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

import 'package:json_annotation/json_annotation.dart';
import 'assessment_model.dart' show NullableTimestampConverter;

part 'owner_data_transfer_model.g.dart';

/// A background download (EXPORT) of all data of the owner, or an upload
/// (IMPORT) of such a download as a new owner, and its progress.
@JsonSerializable(explicitToJson: true)
class OwnerDataTransfer {
  final String? ownerDataTransferId;

  /// EXPORT | IMPORT
  final String? direction;

  /// QUEUED | RUNNING | DONE | FAILED
  final String? status;
  final String? progress;
  final String? errorMessage;
  final String? fileName;

  /// Records per entity.
  final Map<String, int> counts;

  /// IMPORT: the owner created.
  final String? newOwnerPartyId;
  @NullableTimestampConverter()
  final DateTime? createdDate;
  @NullableTimestampConverter()
  final DateTime? completedDate;

  const OwnerDataTransfer({
    this.ownerDataTransferId,
    this.direction,
    this.status,
    this.progress,
    this.errorMessage,
    this.fileName,
    this.counts = const {},
    this.newOwnerPartyId,
    this.createdDate,
    this.completedDate,
  });

  bool get isRunning => status == 'QUEUED' || status == 'RUNNING';

  /// Accepts the REST wrapper `{ownerDataTransfer: {...}}` or the bare object.
  factory OwnerDataTransfer.fromJson(Map<String, dynamic> json) =>
      _$OwnerDataTransferFromJson(
        json['ownerDataTransfer'] is Map<String, dynamic>
            ? json['ownerDataTransfer'] as Map<String, dynamic>
            : json,
      );
  Map<String, dynamic> toJson() => _$OwnerDataTransferToJson(this);
}

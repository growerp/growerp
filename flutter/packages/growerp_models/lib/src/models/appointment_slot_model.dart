/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:growerp_models/growerp_models.dart';

part 'appointment_slot_model.freezed.dart';
part 'appointment_slot_model.g.dart';

@freezed
abstract class AppointmentSlot with _$AppointmentSlot {
  AppointmentSlot._();
  factory AppointmentSlot({
    @Default("") String slotId,
    @DateTimeConverter() DateTime? startDateTime,
    @DateTimeConverter() DateTime? endDateTime,
    @Default("") String status, // AVAILABLE, BOOKED
    @Default("") String workEffortId,
  }) = _AppointmentSlot;

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) =>
      _$AppointmentSlotFromJson(json['appointmentSlot'] ?? json);
}

@freezed
abstract class AppointmentSlots with _$AppointmentSlots {
  AppointmentSlots._();
  factory AppointmentSlots({
    @Default([]) List<AppointmentSlot> appointmentSlots,
  }) = _AppointmentSlots;

  factory AppointmentSlots.fromJson(Map<String, dynamic> json) =>
      _$AppointmentSlotsFromJson(json);
}

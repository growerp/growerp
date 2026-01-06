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

part of 'application_bloc.dart';

enum ApplicationStatus { initial, loading, success, failure }

class ApplicationState extends Equatable {
  const ApplicationState({
    this.status = ApplicationStatus.initial,
    this.applications = const <Application>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final ApplicationStatus status;
  final String? message;
  final List<Application> applications;
  final bool hasReachedMax;
  final String searchString;

  ApplicationState copyWith({
    ApplicationStatus? status,
    String? message,
    List<Application>? applications,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return ApplicationState(
      status: status ?? this.status,
      applications: applications ?? this.applications,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [status, message, applications, hasReachedMax];

  @override
  String toString() =>
      '$status { #applications: ${applications.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}

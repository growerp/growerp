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

part of 'routing_bloc.dart';

abstract class RoutingEvent extends Equatable {
  const RoutingEvent();
  @override
  List<Object?> get props => [];
}

class RoutingsFetch extends RoutingEvent {
  const RoutingsFetch({
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

class RoutingUpdate extends RoutingEvent {
  const RoutingUpdate(this.routing);
  final Routing routing;
}

class RoutingDelete extends RoutingEvent {
  const RoutingDelete(this.routing);
  final Routing routing;
}

class RoutingTaskUpdate extends RoutingEvent {
  const RoutingTaskUpdate(this.routingTask);
  final RoutingTask routingTask;
}

class RoutingTaskDelete extends RoutingEvent {
  const RoutingTaskDelete(this.routingTask);
  final RoutingTask routingTask;
}

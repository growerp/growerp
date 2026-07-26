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

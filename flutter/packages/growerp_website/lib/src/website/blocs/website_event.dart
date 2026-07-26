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

part of 'website_bloc.dart';

abstract class WebsiteEvent extends Equatable {
  const WebsiteEvent();
  @override
  List<Object> get props => [];
}

class WebsiteFetch extends WebsiteEvent {}

class WebsiteObsUpload extends WebsiteEvent {
  final Obsidian obsidian;
  final String? path;
  const WebsiteObsUpload(this.obsidian, this.path);
}

class WebsiteUpdate extends WebsiteEvent {
  final Website website;
  const WebsiteUpdate(this.website);
}

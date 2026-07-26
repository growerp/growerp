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

part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object> get props => [];
}

class CategoryFetch extends CategoryEvent {
  const CategoryFetch({
    this.companyPartyId = '',
    this.searchString = '',
    this.refresh = false,
    this.isForDropDown = false,
    this.limit = 20,
  });

  /// companyPartyId required for ecommerce
  final String companyPartyId;
  final String searchString;
  final bool refresh;
  final bool isForDropDown;
  final int limit;
  @override
  List<Object> get props => [companyPartyId, searchString, refresh];
}

class CategoryDelete extends CategoryEvent {
  const CategoryDelete(this.category);
  final Category category;
}

class CategoryUpdate extends CategoryEvent {
  const CategoryUpdate(this.category);
  final Category category;
}

class CategoryDownload extends CategoryEvent {}

class CategoryUpload extends CategoryEvent {
  const CategoryUpload(this.file);
  final String file;
}

class CategorySearchChanged extends CategoryEvent {
  const CategorySearchChanged({
    required this.searchString,
    this.companyPartyId = '',
    this.limit = 20,
  });
  final String searchString;
  final String companyPartyId;
  final int limit;
  @override
  List<Object> get props => [searchString, companyPartyId];
}

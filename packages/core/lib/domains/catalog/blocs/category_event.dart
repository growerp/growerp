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

part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object> get props => [];
}

class CategoryFetch extends CategoryEvent {
  const CategoryFetch(
      {this.companyPartyId = '', this.searchString = '', this.refresh = false});

  /// companyPartyId required for ecommerce
  final String companyPartyId;
  final String searchString;
  final bool refresh;
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

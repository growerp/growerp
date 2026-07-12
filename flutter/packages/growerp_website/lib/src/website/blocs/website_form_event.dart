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

part of 'website_form_bloc.dart';

abstract class WebsiteFormEvent extends Equatable {
  const WebsiteFormEvent();
  @override
  List<Object> get props => [];
}

class WebsiteFormFetch extends WebsiteFormEvent {
  const WebsiteFormFetch({this.searchString = '', this.limit = 20});
  final String searchString;
  final int limit;
  @override
  List<Object> get props => [searchString];
}

class WebsiteFormUpdate extends WebsiteFormEvent {
  const WebsiteFormUpdate(this.webForm);
  final WebsiteForm webForm;
}

class WebsiteFormDelete extends WebsiteFormEvent {
  const WebsiteFormDelete(this.webForm);
  final WebsiteForm webForm;
}

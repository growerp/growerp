/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the websiteor(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

part of 'website_bloc.dart';

abstract class WebsiteEvent extends Equatable {
  const WebsiteEvent();
  @override
  List<Object> get props => [];
}

class WebsiteFetch extends WebsiteEvent {}

class WebsiteUpdate extends WebsiteEvent {
  final Website website;
  WebsiteUpdate(this.website);
}

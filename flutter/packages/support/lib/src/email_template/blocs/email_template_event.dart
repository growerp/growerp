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

part of 'email_template_bloc.dart';

abstract class EmailTemplateEvent extends Equatable {
  const EmailTemplateEvent();
  @override
  List<Object> get props => [];
}

class EmailTemplateFetch extends EmailTemplateEvent {
  const EmailTemplateFetch({
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

class EmailTemplateUpdate extends EmailTemplateEvent {
  const EmailTemplateUpdate(this.emailTemplate);
  final EmailTemplate emailTemplate;
}

class EmailTemplateDelete extends EmailTemplateEvent {
  const EmailTemplateDelete(this.emailTemplate);
  final EmailTemplate emailTemplate;
}

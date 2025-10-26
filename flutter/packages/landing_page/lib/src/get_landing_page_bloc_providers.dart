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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_assessment/growerp_assessment.dart';

/// Provides BLoC providers for landing page functionality
List<BlocProvider> getLandingPageBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [
    BlocProvider<LandingPageBloc>(
      create: (context) => LandingPageBloc(
        restClient: restClient,
        classificationId: classificationId,
      ),
    ),
  ];
}

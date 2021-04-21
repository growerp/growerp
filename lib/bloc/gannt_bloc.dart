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

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:models/@models.dart';

class GanntBloc extends Bloc<GanntEvent, GanntState> {
  final repos;

  GanntBloc(this.repos)
      : assert(repos != null),
        super(GanntInitial());

  @override
  Stream<GanntState> mapEventToState(GanntEvent event) async* {
    if (event is LoadGannt) {
      yield GanntLoading();
      final result = await repos.getAssetGannt();
      if (result is String)
        yield GanntFailure(message: result);
      else
        yield GanntSuccess(result);
    }
  }
}

//--------------------------events ---------------------------------
abstract class GanntEvent extends Equatable {
  const GanntEvent();
  @override
  List<Object> get props => [];
}

class LoadGannt extends GanntEvent {}

// -------------------------------state ------------------------------
abstract class GanntState extends Equatable {
  const GanntState();

  @override
  List<Object> get props => [];
}

class GanntInitial extends GanntState {}

class GanntLoading extends GanntState {}

class GanntSuccess extends GanntState {
  final List<GanntLine> ganntLines;

  GanntSuccess(this.ganntLines);
}

class GanntFailure extends GanntState {
  final String message;

  const GanntFailure({required this.message});

  @override
  List<Object> get props => [message];

  @override
  String toString() => 'GanntFailed { error: $message }';
}

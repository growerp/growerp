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
import 'package:models/models.dart';

class AccntgBloc extends Bloc<AccntgEvent, AccntgState> {
  final repos;
  BalanceSheet balanceSheet;

  AccntgBloc(this.repos) : super(AccntgInitial());

  @override
  Stream<AccntgState> mapEventToState(AccntgEvent event) async* {
    if (event is LoadAccntg) {
      yield AccntgInProgress();
      dynamic result = await repos.getBalanceSheet();
      if (result is BalanceSheet) {
        balanceSheet = result;
        yield AccntgLoaded(result, "balancesheet loaded");
      } else
        yield AccntgProblem(result);
    }
  }
}

//--------------------------events ---------------------------------
abstract class AccntgEvent extends Equatable {
  const AccntgEvent();
  @override
  List<Object> get props => [];
}

class LoadAccntg extends AccntgEvent {}

// -------------------------------state ------------------------------
abstract class AccntgState extends Equatable {
  const AccntgState();

  @override
  List<Object> get props => [];
}

class AccntgInitial extends AccntgState {}

class AccntgInProgress extends AccntgState {}

class AccntgLoaded extends AccntgState {
  final BalanceSheet balanceSheet;
  final String message;

  AccntgLoaded(this.balanceSheet, this.message);
  @override
  List<Object> get props => [message];

  @override
  String toString() => 'AccntgLoad { $message }';
}

class AccntgProblem extends AccntgState {
  final String message;

  const AccntgProblem(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => 'AccntgFailed { error: $message }';
}

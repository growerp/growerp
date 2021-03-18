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

class AccntBloc extends Bloc<AccntEvent, AccntState> {
  final repos;

  AccntBloc(this.repos) : super(AccntInitial());

  @override
  Stream<AccntState> mapEventToState(AccntEvent event) async* {
    if (event is FetchBalanceSheet) {
      yield AccntInProgress();
      dynamic result = await repos.getBalanceSheet();
      if (result is BalanceSheet) {
        yield AccntSuccess(
            balanceSheet: result, message: "balancesheet loaded");
      } else
        yield AccntProblem(result);
    }
    if (event is FetchLedger) {
      yield AccntInProgress();
      dynamic result = await repos.getLedger();
      if (result is List<GlAccount>) {
        yield AccntSuccess(
            ledgerTree: result, message: "Ledger summary loaded");
      } else
        yield AccntProblem(result);
    }
    if (event is FetchLedger) {
      yield AccntInProgress();
      dynamic result = await repos.getLedger();
      if (result is List<GlAccount>) {
        yield AccntSuccess(
            ledgerTree: result, message: "Ledger summary loaded");
      } else
        yield AccntProblem(result);
    }
  }
}

//--------------------------events ---------------------------------
abstract class AccntEvent extends Equatable {
  const AccntEvent();
  @override
  List<Object> get props => [];
}

class FetchBalanceSheet extends AccntEvent {}

class FetchLedger extends AccntEvent {}

// -------------------------------state ------------------------------
abstract class AccntState extends Equatable {
  const AccntState();

  @override
  List<Object> get props => [];
}

class AccntInitial extends AccntState {}

class AccntInProgress extends AccntState {}

class AccntSuccess extends AccntState {
  final BalanceSheet balanceSheet;
  final List<GlAccount> ledgerTree;
  final String message;

  AccntSuccess({this.balanceSheet, this.message, this.ledgerTree});
  @override
  List<Object> get props => [message];

  @override
  String toString() => 'AccntLoad { $message }';
}

class AccntProblem extends AccntState {
  final String errorMessage;

  const AccntProblem(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];

  @override
  String toString() => 'AccntFailed { error: $errorMessage }';
}

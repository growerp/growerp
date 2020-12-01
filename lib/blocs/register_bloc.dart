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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import '../models/@models.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final repos;

  RegisterBloc({
    @required this.repos,
  })  : assert(repos != null),
        super(RegisterInitial());

  @override
  Stream<RegisterState> mapEventToState(RegisterEvent event) async* {
    if (event is LoadRegister) {
      yield RegisterLoading();
      if (event.companyPartyId == null) {
        // create new company and admin user
        yield RegisterLoaded();
      } else {
        // create new customer existing company
        yield RegisterLoaded();
      }
    } else if (event is RegisterButtonPressed) {
      yield RegisterSending();
      final authenticate = await repos.register(
          companyPartyId: event.companyPartyId,
          firstName: event.firstName,
          lastName: event.lastName,
          email: event.email);
      if (authenticate is Authenticate) {
        await repos.persistAuthenticate(authenticate);
        yield RegisterSuccess(authenticate);
      } else {
        yield RegisterError(authenticate);
      }
    } else if (event is RegisterCompanyAdmin) {
      yield RegisterSending();
      final authenticate = await repos.register(
          companyName: event.companyName,
          currencyId: event.currencyId,
          classificationId: event.classificationId,
          firstName: event.firstName,
          lastName: event.lastName,
          email: event.email);
      if (authenticate is Authenticate) {
        await repos.persistAuthenticate(authenticate);
        yield RegisterSuccess(authenticate);
      } else {
        yield RegisterError(authenticate);
      }
    }
  }
}

//--------------------------events ---------------------------------
@immutable
abstract class RegisterEvent extends Equatable {
  const RegisterEvent();
  @override
  List<Object> get props => [];
}

class LoadRegister extends RegisterEvent {
  final String companyPartyId;
  final String companyName;

  LoadRegister({this.companyPartyId, this.companyName});
  @override
  List<Object> get props => [companyPartyId];

  @override
  String toString() => 'Register Load event: companyPartyId: $companyPartyId';
}

class RegisterButtonPressed extends RegisterEvent {
  final String companyPartyId;
  final String firstName;
  final String lastName;
  final String email;

  const RegisterButtonPressed({
    @required this.companyPartyId,
    @required this.firstName,
    @required this.lastName,
    @required this.email,
  });

  @override
  List<Object> get props => [companyPartyId, firstName, lastName, email];

  @override
  String toString() =>
      'RegisterButtonPressed { companyPartyId: $companyPartyId '
          'first Last name: $firstName $lastName,' +
      ' email: $email }';
}

class RegisterCompanyAdmin extends RegisterEvent {
  final String companyName;
  final String currencyId;
  final String classificationId;
  final String firstName;
  final String lastName;
  final String email;

  const RegisterCompanyAdmin({
    @required this.companyName,
    @required this.currencyId,
    @required this.classificationId,
    @required this.firstName,
    @required this.lastName,
    @required this.email,
  });

  @override
  String toString() => 'Register CompanyAdmin  { company name: $companyName, '
      'email: $email class: $classificationId}';
}

// -------------------------------state ------------------------------
@immutable
abstract class RegisterState extends Equatable {
  const RegisterState();
  @override
  List<Object> get props => [];
}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterLoaded extends RegisterState {}

class RegisterSending extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final Authenticate authenticate;
  RegisterSuccess(this.authenticate);
  List<Object> get props => [authenticate];
  String toString() =>
      "Register success new company: " +
      "${authenticate.company.name}[${authenticate.company.partyId}]";
}

class RegisterError extends RegisterState {
  final String errorMessage;

  const RegisterError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];

  @override
  String toString() => 'RegisterError { error: $errorMessage }';
}

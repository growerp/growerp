import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_user_company.dart';

List<BlocProvider> getUserCompanyBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  List<BlocProvider> blocProviders = [
    BlocProvider<CompanyUserBloc>(
      create: (context) => CompanyUserBloc(restClient, Role.unknown),
    ),
    BlocProvider<CompanyUserCustomerBloc>(
      create: (context) => CompanyUserBloc(restClient, Role.customer),
    ),
    BlocProvider<CompanyUserSupplierBloc>(
      create: (context) => CompanyUserBloc(restClient, Role.supplier),
    ),
    BlocProvider<CompanyUserLeadBloc>(
      create: (context) => CompanyUserBloc(restClient, Role.lead),
    ),
    BlocProvider<CompanyBloc>(
      create: (context) => CompanyBloc(restClient, Role.unknown),
    ),
    BlocProvider<CompanyCustomerBloc>(
      create: (context) => CompanyBloc(restClient, Role.customer),
    ),
    BlocProvider<CompanySupplierBloc>(
      create: (context) => CompanyBloc(restClient, Role.supplier),
    ),
    BlocProvider<CompanyLeadBloc>(
      create: (context) => CompanyBloc(restClient, Role.lead),
    ),
    BlocProvider<EmployeeBloc>(
      create: (context) => UserBloc(restClient, Role.company),
    ),
    BlocProvider<LeadBloc>(
      create: (context) => UserBloc(restClient, Role.lead),
    ),
    BlocProvider<CustomerBloc>(
      create: (context) => UserBloc(restClient, Role.customer),
    ),
    BlocProvider<SupplierBloc>(
      create: (context) => UserBloc(restClient, Role.supplier),
    ),
    BlocProvider<UserBloc>(
      create: (context) => UserBloc(restClient, Role.unknown),
    ),
  ];
  return blocProviders;
}

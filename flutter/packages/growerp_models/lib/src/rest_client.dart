import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';
import 'models/platform_configurations_model.dart';
import 'models/campaign_progress_model.dart';

import 'rest_client/auth_api.dart';
import 'rest_client/system_api.dart';
import 'rest_client/company_user_api.dart';
import 'rest_client/website_api.dart';
import 'rest_client/catalog_api.dart';
import 'rest_client/rental_api.dart';
import 'rest_client/fin_doc_api.dart';
import 'rest_client/inventory_api.dart';
import 'rest_client/manufacturing_api.dart';
import 'rest_client/hr_api.dart';
import 'rest_client/insurance_api.dart';
import 'rest_client/accounting_api.dart';
import 'rest_client/chat_activity_api.dart';
import 'rest_client/crm_api.dart';
import 'rest_client/marketing_api.dart';
import 'rest_client/assessment_api.dart';
import 'rest_client/landing_page_api.dart';
import 'rest_client/outreach_api.dart';
import 'rest_client/menu_api.dart';
import 'rest_client/adk_api.dart';
import 'rest_client/courses_api.dart';
import 'rest_client/wiki_api.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: null)
abstract class RestClient
    with
        AuthApi,
        SystemApi,
        CompanyUserApi,
        WebsiteApi,
        CatalogApi,
        RentalApi,
        FinDocApi,
        InventoryApi,
        ManufacturingApi,
        HrApi,
        InsuranceApi,
        AccountingApi,
        ChatActivityApi,
        CrmApi,
        MarketingApi,
        AssessmentApi,
        LandingPageApi,
        OutreachApi,
        MenuApi,
        AdkApi,
        CoursesApi,
        WikiApi {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET("{path}")
  Future<dynamic> get(
    @Path("path") String path, {
    @Queries() Map<String, dynamic>? queryParameters,
  });

  @POST("{path}")
  Future<dynamic> post(
    @Path("path") String path, {
    @Body() Map<String, dynamic> data = const {},
  });

  @PATCH("{path}")
  Future<dynamic> patch(
    @Path("path") String path, {
    @Body() Map<String, dynamic> data = const {},
  });

  @DELETE("{path}")
  Future<dynamic> delete(
    @Path("path") String path, {
    @Queries() Map<String, dynamic>? queryParameters,
  });
}

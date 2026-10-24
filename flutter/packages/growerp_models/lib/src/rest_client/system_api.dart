import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin SystemApi {
  // website generator: convert an existing website into a new owner
  @GET("rest/s1/growerp/100/WebsiteConversion")
  Future<WebsiteConversions> getWebsiteConversion({
    @Query('conversionId') String? conversionId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? search,
  });

  @POST("rest/s1/growerp/100/WebsiteConversion")
  Future<WebsiteConversion> createWebsiteConversion({
    @Field() required String sourceUrl,
    @Field() required String companyName,
    @Field() required String adminEmail,
    @Field() String? adminFirstName,
    @Field() String? adminLastName,
    @Field() required String currencyId,
    @Field() int? fiscalYearStartMonth,
    @Field() String? applicationId,
    @Field() String? hostNames,
    @Field() int? maxPages,
  });

  @DELETE("rest/s1/growerp/100/WebsiteConversion")
  Future<void> deleteWebsiteConversion({@Field() required String conversionId});

  /// rebuild the owner-import XML of a live website so it can be installed elsewhere
  @GET("rest/s1/growerp/100/WebsiteConversion/export")
  Future<WebsiteExport> exportWebsiteOwner({
    @Query('conversionId') String? conversionId,
    @Query('productStoreId') String? productStoreId,
    @Query('siteId') String? siteId,
    @Query('adminEmail') String? adminEmail,
  });

  /// install an owner-import XML file produced by an export or by /convert-website.
  /// Sent as a JSON body, not form fields: a site with images is megabytes and
  /// Jetty rejects form posts over 200kB.
  @POST("rest/s1/growerp/100/WebsiteConversion/file")
  Future<WebsiteConversion> importWebsiteFile({
    @Body() required Map<String, dynamic> data,
  });

  // website translation: translate a website into the languages the apps support
  @GET("rest/s1/growerp/100/WebsiteTranslation")
  Future<WebsiteTranslations> getWebsiteTranslation({
    @Query('translationId') String? translationId,
    @Query('ownerPartyId') String? ownerPartyId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? search,
  });

  @POST("rest/s1/growerp/100/WebsiteTranslation")
  Future<WebsiteTranslation> createWebsiteTranslation({
    @Field() required String ownerPartyId,
    @Field() String? sourceLocale,
    @Field() required String targetLocales,
    @Field() String? translateEntityNames,
    @Field() String? overwriteExisting,
  });

  @DELETE("rest/s1/growerp/100/WebsiteTranslation")
  Future<void> deleteWebsiteTranslation({
    @Field() required String translationId,
  });

  // GL account name translation: system support only, the translations are
  // shared by every tenant
  @GET("rest/s1/growerp/100/GlAccountTranslation")
  Future<GlAccountTranslations> getGlAccountTranslation({
    @Query('locale') String? locale,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? search,
  });

  @POST("rest/s1/growerp/100/GlAccountTranslation")
  Future<GlAccountTranslations> createGlAccountTranslation({
    @Field() String? sourceLocale,
    @Field() required String targetLocale,
  });

  @DELETE("rest/s1/growerp/100/GlAccountTranslation")
  Future<void> deleteGlAccountTranslation({@Field() required String locale});

  // email templates
  @GET("rest/s1/growerp/100/EmailTemplate")
  Future<EmailTemplates> getEmailTemplates({
    @Query('searchString') String? searchString,
  });

  @POST("rest/s1/growerp/100/EmailTemplate")
  Future<EmailTemplate> updateEmailTemplate(
    @Field() EmailTemplate emailTemplate,
  );

  @DELETE("rest/s1/growerp/100/EmailTemplate")
  Future<EmailTemplate> deleteEmailTemplate(
    @Field() EmailTemplate emailTemplate,
  );

  @GET("rest/s1/growerp/100/SystemSettings")
  Future<SystemSettings> getSystemSettings();

  @POST("rest/s1/growerp/100/SystemSettings")
  Future<SystemSettings> updateSystemSettings(
    @Body() Map<String, dynamic> systemSettings,
  );

  /// Derive a house writing voice from samples of the tenant's own writing.
  /// Returns writingStyle + sampleCount; nothing is saved by this call.
  @POST("rest/s1/growerp/100/SystemSettings/generateWritingStyle")
  Future<dynamic> generateWritingStyle({
    @Field() required List<String> samples,
  });

  /// Google consent URL ({authUrl}) for the services: drive, gmail, calendar.
  @POST("rest/s1/growerp/100/SystemSettings/googleSignIn")
  Future<dynamic> startGoogleSignIn({
    @Field() required List<String> services,
  });

  /// Disconnect one Google service: drive, gmail or calendar.
  @POST("rest/s1/growerp/100/SystemSettings/googleDisconnect")
  Future<SystemSettings> disconnectGoogleService({
    @Field() required String service,
  });

  /// Rebuild the per-user calendars of the tenant in the background.
  @POST("rest/s1/growerp/100/SystemSettings/calendarResync")
  Future<void> resyncCalendars();

  /// The in-app calendar of the user for a period (epoch millis, thru
  /// exclusive): connected calendar events or else activities, plus social
  /// posts with includeContent.
  @GET("rest/s1/growerp/100/CalendarItems")
  Future<CalendarItems> getCalendarItems({
    @Query('fromDate') required int fromDate,
    @Query('thruDate') required int thruDate,
    @Query('includeContent') bool? includeContent,
  });

  @GET("rest/s1/growerp/100/SystemDefault")
  Future<SystemDefault> getSystemDefault();

  @POST("rest/s1/growerp/100/SystemDefault")
  Future<SystemDefault> updateSystemDefault(
    @Body() Map<String, dynamic> systemDefault,
  );

  /// override one tenant's monthly LLM token limit, null limit clears the override
  @POST("rest/s1/growerp/100/OwnerTokenLimit")
  Future<void> updateOwnerTokenLimit(
    @Body() Map<String, dynamic> ownerTokenLimit,
  );

  // countries not used
  @GET("rest/s1/growerp/100/Countries")
  @Extra({'noApiKey': true})
  Future<Countries> getCountries(
    @Query('id') String? id,
    @Query('name') String? name,
  );

  // unit of measure
  @GET("rest/s1/growerp/100/Uoms")
  @Extra({'noApiKey': true})
  Future<Uoms> getUom(@Query('uomTypes') List<String>? uomTypes);

  // central currency exchange rates (read only)
  @GET("rest/s1/growerp/100/ExchangeRates")
  Future<ExchangeRates> getExchangeRates();

  // import / export ========
  @POST("rest/s1/growerp/100/ImportExport")
  Future<void> uploadEntities({
    @Field() required dynamic entities,
    @Field() required String applicationId,
  });

  @POST("rest/s1/growerp/100/ImportExport/itemTypes")
  Future<String> importItemTypes(@Field() List<ItemType> itemTypes);

  @POST("rest/s1/growerp/100/ImportExport/paymentTypes")
  Future<String> importPaymentTypes(@Field() List<PaymentType> paymentTypes);

  @POST("rest/s1/growerp/100/ImportExport/glAccounts")
  Future<String> importGlAccounts(
    @Field() List<GlAccount> glAccounts, {
    @Field() String? periodYear,
  });

  /// the GlAccount CSV itself, to be saved as a file by the caller
  @GET("rest/s1/growerp/100/ImportExport/glAccounts")
  Future<String> downloadGlAccounts();

  @POST("rest/s1/growerp/100/ImportExport/companies")
  Future<void> importCompanies(@Field() List<Company> companies);

  @POST("rest/s1/growerp/100/ImportExport/users")
  Future<void> importUsers(@Field() List<User> users);

  @POST("rest/s1/growerp/100/ImportExport/products")
  Future<void> importProducts(
    @Field() List<Product> products,
    @Field() String applicationId,
  );

  @POST("rest/s1/growerp/100/ImportExport/categories")
  Future<void> importCategories(@Field() List<Category> categories);

  @POST("rest/s1/growerp/100/ImportExport/assets")
  Future<void> importAssets(
    @Field() List<Asset> assets,
    @Field() String applicationId,
  );

  @GET("rest/s1/growerp/100/Categories")
  Future<Categories> getCategories({@Query('limit') int? limit});

  @GET("rest/s1/growerp/100/Products")
  Future<Products> getProducts({
    @Query('limit') int? limit,
    @Query('applicationId') String? applicationId,
  });

  @GET("rest/s1/growerp/100/User")
  Future<Users> getUsers(@Query('limit') String limit);
}

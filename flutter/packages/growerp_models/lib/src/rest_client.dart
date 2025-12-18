import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';
import 'models/platform_configurations_model.dart';
import 'models/campaign_progress_model.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: null)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET("rest/s1/growerp/100/CheckEmail")
  @Extra({'noApiKey': true})
  Future<Map<String, bool>> checkEmail({@Query('email') required String email});

  @POST("rest/s1/growerp/100/Register")
  @Extra({'noApiKey': true})
  @FormUrlEncoded()
  Future<Authenticate> register({
    @Field() required String classificationId,
    @Field() required String firstName,
    @Field() required String lastName,
    @Field() required String email,
    @Field() String? companyPartyId, // required for other than admin
    @Field() String? newPassword,
    @Field('userGroupId') UserGroup? userGroup, // if admin also company
    @Field() String? timeZoneOffset,
    @Field() String? locale,
  });

  @POST("rest/s1/growerp/100/Login")
  @Extra({'noApiKey': true})
  @FormUrlEncoded()
  Future<Authenticate> login({
    @Field() required String username,
    @Field() required String password,
    @Field() String? creditCardNumber,
    @Field() String? creditCardType,
    @Field() String? nameOnCard,
    @Field() String? expireMonth,
    @Field() String? expireYear,
    @Field() String? cVC,
    @Field() String? plan,
    @Field() String? companyName,
    @Field() String? currencyId,
    @Field() bool? demoData,
    @Field() required String classificationId,
    @Field() String? timeZoneOffset,
    @Field() int? testDaysOffset,
  });

  @POST("rest/s1/growerp/100/Logout")
  Future<String> logout();

  @POST("rest/s1/growerp/100/ResetPassword")
  @Extra({'noApiKey': true})
  Future<String> resetPassword({@Field() required String username});

  @POST("rest/s1/growerp/100/Password")
  @Extra({'noApiKey': true})
  Future<Authenticate> updatePassword({
    @Field() required String username,
    @Field() required String oldPassword,
    @Field() required String newPassword,
    @Field() required String classificationId,
  });

  @GET("rest/s1/growerp/100/Companies")
  @Extra({'noApiKey': true})
  Future<Companies> getCompanies({
    @Query('mainCompanies') bool? mainCompanies,
    @Query('searchString') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/RestRequest")
  Future<RestRequests> getRestRequest({
    @Query('hitId') String? hitId,
    @Query('userId') String? userId,
    @Query('ownerPartyId') String? ownerPartyId,
    @Query('startDateTime') String? startDateTime,
    @Query('endDateTime') String? endDateTime,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/Authenticate")
  Future<Authenticate> getAuthenticate({
    @Query('classificationId') required String classificationId,
  });

  // backend application url override
  @GET("rest/s1/growerp/100/Application")
  Future<Applications> getApplication();

  // applications
  @POST("rest/s1/growerp/100/Application")
  Future<Application> createApplication(@Field() Application application);

  @DELETE("rest/s1/growerp/100/Application")
  Future<Application> deleteApplication(@Field() Application application);

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

  // company
  @GET("rest/s1/growerp/100/CompanyFromHost")
  @Extra({'noApiKey': true})
  Future<Company> getCompanyFromHost(@Query('hostName') String? hostName);

  // company
  @GET("rest/s1/growerp/100/Company")
  Future<Companies> getCompany({
    @Query('companyPartyId') String? companyPartyId,
    @Query('companyName') String? companyName,
    @Query('userPartyId') String? userPartyId,
    @Query('ownerPartyId') String? ownerPartyId,
    @Query('role') Role? role,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('firstName') String? firstName,
    @Query('lastName') String? lastName,
    @Query('searchString') String? searchString,
    @Query('isForDropDown') bool? isForDropDown,
  });

  @POST("rest/s1/growerp/100/Company")
  Future<Company> createCompany({@Field() required Company company});

  @PATCH("rest/s1/growerp/100/Company")
  Future<Company> updateCompany({@Field() required Company company});

  // party to replace company and user
  @GET("rest/s1/growerp/100/CompanyUser")
  Future<CompaniesUsers> getCompanyUser({
    @Query('role') Role? role,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
    @Query('partyId') String? partyId,
  });

  @POST("rest/s1/growerp/100/ImportExport/companyUsers")
  Future<String> importCompanyUsers(@Field() List<CompanyUser> companyUsers);

  @GET("rest/s1/growerp/100/ImportExport")
  Future<String> exportScreenCompanyUsers({
    @Query('entityName') String entityName = 'CompanyUser',
  });

  // user
  @GET("rest/s1/growerp/100/User")
  Future<Users> getUser({
    @Query('userPartyId') String? partyId,
    @Query('role') Role? role,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('firstName') String? firstName,
    @Query('lastName') String? lastName,
    @Query('search') String? searchString,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('loginOnly') bool? loginOnly,
  });

  @POST("rest/s1/growerp/100/User")
  Future<User> createUser({@Field() required User user});

  @PATCH("rest/s1/growerp/100/User")
  Future<User> updateUser({@Field() required User user});

  @DELETE("rest/s1/growerp/100/User")
  Future<User> deleteUser({
    @Field() required String partyId,
    @Field() required bool deleteCompanyToo,
  });

  // payment gateway actions
  @POST("rest/s1/growerp/100/GatewayPayment")
  Future<FinDoc> authorizeGatewayPayment({@Field() required String paymentId});
  @PATCH("rest/s1/growerp/100/GatewayPayment")
  Future<FinDoc> captureGatewayPayment({@Field() required String paymentId});
  @DELETE("rest/s1/growerp/100/GatewayPayment")
  Future<FinDoc> releaseGatewayPayment({@Field() required String paymentId});

  // Website ======
  @GET("rest/s1/growerp/100/Website")
  Future<Website> getWebsite();

  @GET("rest/s1/growerp/100/WebsiteContent")
  Future<Content> getWebsiteContent({
    @Query('path') required String path,
    @Query('text') required String text,
  });

  @PATCH("rest/s1/growerp/100/Website")
  Future<Website> updateWebsite({@Field() required Website website});

  @POST("rest/s1/growerp/100/WebsiteContent")
  Future<Content> uploadWebsiteContent({@Field() required Content content});

  @POST("rest/s1/growerp/100/Obsidian")
  Future<Website> obsUpload({@Field() required Obsidian obsidian});

  @POST("rest/s1/growerp/100/ImportExport/website")
  Future<void> importWebsite(@Field() Website website);

  @GET("rest/s1/growerp/100/ImportExport/website")
  Future<Website> exportWebsite();

  // catalog
  // asset
  @GET("rest/s1/growerp/100/Asset")
  Future<Assets> getAsset({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('companyPartyId') String? companyPartyId,
    @Query('assetClassId') String? assetClassId,
    @Query('assetId') String? assetId,
    @Query('productId') String? productId,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/Asset")
  Future<Asset> createAsset({
    @Field() required Asset asset,
    @Field() required String classificationId,
  });

  @PATCH("rest/s1/growerp/100/Asset")
  Future<Asset> updateAsset({
    @Field() required Asset asset,
    @Field() required String classificationId,
  });

  // categories
  @GET("rest/s1/growerp/100/Categories")
  Future<Categories> getCategory({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('companyPartyId') String? companyPartyId,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
    @Query('classificationId') String? classificationId,
  });

  @POST("rest/s1/growerp/100/Category")
  Future<Category> createCategory({
    @Field() required Category category,
    @Field() required String classificationId,
  });

  @PATCH("rest/s1/growerp/100/Category")
  Future<Category> updateCategory({
    @Field() required Category category,
    @Field() required String classificationId,
  });

  @DELETE("rest/s1/growerp/100/Category")
  Future<Category> deleteCategory({@Field() required Category category});

  @POST("rest/s1/growerp/100/ImportExport")
  Future<String> importScreenCategories({
    @Field() required List categories,
    @Field() required String classificationId,
  });

  @GET("rest/s1/growerp/100/ImportExport")
  Future<String> exportScreenCategories({
    @Query('entityName') String entityName = 'Category',
    @Query('classificationId') String? classificationId,
  });

  // products
  @GET("rest/s1/growerp/100/Products")
  Future<Products> getProduct({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('companyPartyId') String? companyPartyId,
    @Query('ownerPartyId') String? ownerPartyId,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
    @Query('classificationId') String? classificationId,
    @Query('categoryId') String? categoryId,
    @Query('productId') String? productId,
    @Query('productTypeId') String? productTypeId,
    @Query('assetClassId') String? assetClassId,
  });

  @POST("rest/s1/growerp/100/Product")
  Future<Product> createProduct({
    @Field() required Product product,
    @Field() required String classificationId,
  });

  @PATCH("rest/s1/growerp/100/Product")
  Future<Product> updateProduct({
    @Field() required Product product,
    @Field() required String classificationId,
  });

  @DELETE("rest/s1/growerp/100/Product")
  Future<Product> deleteProduct({@Field() required Product product});

  @POST("rest/s1/growerp/100/ImportExport")
  Future<String> importScreenProducts({
    @Field() required List<Product> products,
    @Field() required String classificationId,
  });

  @GET("rest/s1/growerp/100/ImportExport")
  Future<String> exportScreenProducts({
    @Query('entityName') String entityName = 'Product',
    @Query('classificationId') required String classificationId,
  });

  // dayly rental
  @GET("rest/s1/growerp/100/DailyRentalOccupancy")
  Future<ProductRentalDates> getDailyRentalOccupancy({
    @Query('productId') String? productId,
  });

  // FINDOC
  @GET("rest/s1/growerp/100/FinDoc")
  Future<FinDocs> getFinDoc({
    @Query('finDocId') String? finDocId,
    @Query('pseudoId') String? pseudoId,
    @Query('sales') bool? sales,
    @Query('docType') FinDocType? docType,
    @Query('companyPartyId') String? companyPartyId,
    @Query('search') String? searchString,
    @Query('journalId') String? journalId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('my') bool? my,
    @Query('status') FinDocStatusVal? status,
  });

  @POST("rest/s1/growerp/100/FinDoc")
  Future<FinDoc> createFinDoc({@Field() required FinDoc finDoc});

  @PATCH("rest/s1/growerp/100/FinDoc")
  Future<FinDoc> updateFinDoc({@Field() required FinDoc finDoc});

  @PATCH("rest/s1/growerp/100/FinDocShipment")
  Future<FinDoc> receiveShipment({@Field() required FinDoc finDoc});

  @GET("rest/s1/growerp/100/ItemType")
  Future<ItemTypes> getItemTypes({@Query('sales') bool? sales});

  @PATCH("rest/s1/growerp/100/ItemType")
  Future<ItemType> updateItemType({
    @Field() required ItemType itemType,
    @Field() bool? update,
    @Field() bool? delete,
  });

  @GET("rest/s1/growerp/100/PaymentType")
  Future<PaymentTypes> getPaymentTypes({@Query('sales') bool? sales});

  @PATCH("rest/s1/growerp/100/PaymentType")
  Future<PaymentType> updatePaymentType({
    @Field() required PaymentType paymentType,
    @Field() bool? update,
    @Field() bool? delete,
  });

  @POST("rest/s1/growerp/100/ImportExport/finDocs")
  Future<void> importFinDoc(@Field() List<FinDoc> finDocs);

  @POST("rest/s1/growerp/100/ImportExport/finDocItems")
  Future<void> importFinDocItem(
    @Field() List<FinDocItem> finDocItems,
    @Field() String classificationId,
  );

  // finalize import
  @POST("rest/s1/growerp/100/ImportExport/finalizeImport")
  Future<Map<String, String>> finalizeImport({
    @Field() required int start,
    @Field() required int limit,
    @Field() required String part, //
    // closePeriod, approveInvoices, completePayments,
    // completeInvoicesOrders, receiveShipments, sendShipments
  });

  // Inventory locations
  @GET("rest/s1/growerp/100/Location")
  Future<Locations> getLocation({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('filter') String? filter,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/Location")
  Future<Location> createLocation({@Field() required Location location});

  @PATCH("rest/s1/growerp/100/Location")
  Future<Location> updateLocation({@Field() required Location location});

  @DELETE("rest/s1/growerp/100/Location")
  Future<Location> deleteLocation({@Field() required Location location});

  // accounting
  @GET("rest/s1/growerp/100/Ledger")
  Future<LedgerReport> getLedger();

  @POST("rest/s1/growerp/100/Ledger")
  Future<void> calculateLedger();

  @GET("rest/s1/growerp/100/GlAccount")
  Future<GlAccounts> getGlAccount({
    @Query('start') int? start = 0,
    @Query('limit') int? limit = 10,
    @Query('search') String? searchString,
    @Query('trialBalance') bool? trialBalance,
  });

  @GET("rest/s1/growerp/100/TimePeriod")
  Future<TimePeriods> getTimePeriod({
    @Query('periodType') String? periodType = 'Y',
    @Query('year') String? year,
  });

  @PATCH("rest/s1/growerp/100/TimePeriod")
  Future<TimePeriods> updateTimePeriod({
    @Field() required String timePeriodId,
    @Field() bool? createNext,
    @Field() bool? createPrevious,
    @Field() bool? delete,
  });

  @POST("rest/s1/growerp/100/TimePeriod")
  Future<TimePeriods> closeTimePeriod({@Field() required String timePeriodId});

  @GET("rest/s1/growerp/100/LedgerJournal")
  Future<LedgerJournals> getLedgerJournal({
    @Query('ledgerJournalId') String? ledgerJournalId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/GlAccount")
  Future<GlAccount> createGlAccount({@Field() required GlAccount glAccount});

  @PATCH("rest/s1/growerp/100/GlAccount")
  Future<GlAccount> updateGlAccount({@Field() required GlAccount glAccount});

  @POST("rest/s1/growerp/100/LedgerJournal")
  Future<LedgerJournal> createLedgerJournal({
    @Field() required LedgerJournal ledgerJournal,
  });

  @PATCH("rest/s1/growerp/100/LedgerJournal")
  Future<LedgerJournal> updateLedgerJournal({
    @Field() required LedgerJournal ledgerJournal,
  });

  @GET("rest/s1/growerp/100/BalanceSheet")
  Future<LedgerReport> getBalanceSheet({
    @Query('periodName') String? periodName,
  });

  @GET("rest/s1/growerp/100/BalanceSummary")
  Future<LedgerReport> getBalanceSummary({
    @Query('periodName') String? periodName,
  });

  @GET("rest/s1/growerp/100/OperatingRevenueExpenseChart")
  Future<LedgerReport> getOperatingRevenueExpenseChart({
    @Query('periodName') String? periodName,
  });

  @GET("rest/s1/growerp/100/AccountClass")
  Future<AccountClasses> getAccountClass({
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  @GET("rest/s1/growerp/100/AccountType")
  Future<AccountTypes> getAccountType({
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  // chat
  @GET("rest/s1/growerp/100/ChatRoom")
  Future<ChatRooms> getChatRooms({
    @Query('hasRead') bool? hasRead, // return rooms with unread messages
    @Query('userId') String? userId,
    @Query('chatRoomName') String? chatRoomName,
    @Query('chatRoomId') String? chatRoomId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('isPrivate') bool? isPrivate,
    @Query('search') String? searchString,
    @Query('filter') String? filter,
  });

  @POST("rest/s1/growerp/100/ChatRoom")
  Future<ChatRoom> createChatRoom({@Field() required ChatRoom chatRoom});

  @PATCH("rest/s1/growerp/100/ChatRoom")
  Future<ChatRoom> updateChatRoom({@Field() required ChatRoom chatRoom});

  @DELETE("rest/s1/growerp/100/ChatRoom")
  Future<ChatRoom> deleteChatRoom({@Field() required String chatRoomId});

  @GET("rest/s1/growerp/100/ChatMessage")
  Future<ChatMessages> getChatMessages({
    @Query('chatRoomId') String? chatRoomId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/ChatMessage")
  Future<ChatMessage> createChatMessage({
    @Field() required ChatMessage chatMessage,
  });

  // notification
  @GET("rest/s1/growerp/100/Notification")
  Future<Notifications> getNotifications({@Query('limit') int? limit});

  // activities
  @GET("rest/s1/growerp/100/Activity")
  Future<Activities> getActivity({
    @Query('activityId') String? activityId,
    @Query('activityType') ActivityType? activityType,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('open') bool? open,
    @Query('my') bool? my,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
    @Query('companyPseudoId') String? companyPseudoId,
    @Query('userPseudoId') String? userPseudoId,
  });

  @POST("rest/s1/growerp/100/Activity")
  Future<Activity> createActivity({@Field() required Activity activity});

  @PATCH("rest/s1/growerp/100/Activity")
  Future<Activity> updateActivity({@Field() required Activity activity});

  // time entry
  @POST("rest/s1/growerp/100/TimeEntry")
  Future<TimeEntry> createTimeEntry({@Field() required TimeEntry timeEntry});

  @PATCH("rest/s1/growerp/100/TimeEntry")
  Future<TimeEntry> updateTimeEntry({@Field() required TimeEntry timeEntry});

  @DELETE("rest/s1/growerp/100/TimeEntry")
  Future<TimeEntry> deleteTimeEntry({@Field() required TimeEntry timeEntry});

  // import / export ========
  @POST("rest/s1/growerp/100/ImportExport")
  Future<void> uploadEntities({
    @Field() required dynamic entities,
    @Field() required String classificationId,
  });

  @POST("rest/s1/growerp/100/ImportExport/itemTypes")
  Future<String> importItemTypes(@Field() List<ItemType> itemTypes);

  @POST("rest/s1/growerp/100/ImportExport/paymentTypes")
  Future<String> importPaymentTypes(@Field() List<PaymentType> paymentTypes);

  @POST("rest/s1/growerp/100/ImportExport/glAccounts")
  Future<String> importGlAccounts(@Field() List<GlAccount> glAccounts);

  @GET("rest/s1/growerp/100/ImportExport")
  Future<String> exportGlAccounts({
    @Query('entityName') String entityName = 'GlAccount',
  });

  @POST("rest/s1/growerp/100/ImportExport/companies")
  Future<void> importCompanies(@Field() List<Company> companies);

  @POST("rest/s1/growerp/100/ImportExport/users")
  Future<void> importUsers(@Field() List<User> users);

  @POST("rest/s1/growerp/100/ImportExport/products")
  Future<void> importProducts(
    @Field() List<Product> products,
    @Field() String classificationId,
  );

  @POST("rest/s1/growerp/100/ImportExport/categories")
  Future<void> importCategories(@Field() List<Category> categories);

  @POST("rest/s1/growerp/100/ImportExport/assets")
  Future<void> importAssets(
    @Field() List<Asset> assets,
    @Field() String classificationId,
  );

  @GET("rest/s1/growerp/100/Categories")
  Future<Categories> getCategories({@Query('limit') int? limit});

  @GET("rest/s1/growerp/100/Products")
  Future<Products> getProducts({
    @Query('limit') int? limit,
    @Query('classificationId') String? classificationId,
  });

  @GET("rest/s1/growerp/100/User")
  Future<Users> getUsers(@Query('limit') String limit);

  // opportunities
  @GET("rest/s1/growerp/100/Opportunity")
  Future<Opportunities> getOpportunity({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('opportunityId') String? opportunityId,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/Opportunity")
  Future<Opportunity> createOpportunity({
    @Field() required Opportunity opportunity,
  });

  @PATCH("rest/s1/growerp/100/Opportunity")
  Future<Opportunity> updateOpportunity({
    @Field() required Opportunity opportunity,
  });

  @DELETE("rest/s1/growerp/100/Opportunity")
  Future<Opportunity> deleteOpportunity({
    @Field() required Opportunity opportunity,
  });

  // subscriptions
  @GET("rest/s1/growerp/100/Subscription")
  Future<Subscriptions> getSubscription({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('subscriptionId') String? subscriptionId,
    @Query('growerp')
    bool? growerp, // if true, only owner GROWERP subscriptions
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/Subscription")
  Future<Subscription> createSubscription({
    @Field() required Subscription subscription,
  });

  @PATCH("rest/s1/growerp/100/Subscription")
  Future<Subscription> updateSubscription({
    @Field() required Subscription subscription,
  });

  @DELETE("rest/s1/growerp/100/Subscription")
  Future<Subscription> deleteSubscription({
    @Field() required Subscription subscription,
  });

  @POST("rest/s1/mcp/ProcessInvoiceImage")
  @FormUrlEncoded()
  Future<String> processInvoiceImage({
    @Field() required String imageData,
    @Field() required String prompt,
    @Field() required String mimeType,
  });

  @POST("rest/s1/mcp/CreateInvoiceFromData")
  Future<String> createInvoiceFromData({
    @Field() required Map<String, dynamic> invoiceData,
  });

  // Assessment endpoints
  @GET("rest/s1/growerp/100/AssessmentComplete")
  Future<Assessment> getAssessmentComplete({
    @Query('assessmentId') String? assessmentId,
    @Query('pseudoId') String? pseudoId,
    @Query('ownerPartyId') String? ownerPartyId,
  });

  @GET("rest/s1/growerp/100/Assessment")
  Future<Assessments> getAssessment({
    @Query('assessmentId') String? assessmentId,
    @Query('pseudoId') String? pseudoId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
    @Query('statusId') String? statusId,
  });

  @GET("rest/s1/growerp/100/Assessment")
  Future<Assessments> searchAssessments({
    @Query('search') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('statusId') String? statusId,
  });

  @POST("rest/s1/growerp/100/Assessment")
  Future<Assessment> createAssessment({
    @Field() String? pseudoId,
    @Field() required String assessmentName,
    @Field() String? description,
    @Field() String status = 'ACTIVE',
  });

  @PATCH("rest/s1/growerp/100/Assessment")
  Future<Assessment> updateAssessment({
    @Field() required String assessmentId,
    @Field() String? pseudoId,
    @Field() String? assessmentName,
    @Field() String? description,
    @Field() String? status,
  });

  @DELETE("rest/s1/growerp/100/Assessment")
  Future<void> deleteAssessment({@Field() required String assessmentId});

  @POST("rest/s1/growerp/100/Assessment/submit")
  Future<AssessmentResult> submitAssessment({
    @Field() required String assessmentId,
    @Field('answersData') required String answers,
    @Field() required String respondentName,
    @Field() required String respondentEmail,
    @Field() String? respondentPhone,
    @Field() String? respondentCompany,
    @Field() String? ownerPartyId,
    @Field() String? campaignId,
  });

  // Assessment Question endpoints
  // question and options
  @GET("rest/s1/growerp/100/Assessment/Questions")
  Future<AssessmentQuestions> getAssessmentQuestions({
    @Query('assessmentId') required String assessmentId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/Assessment/Question")
  Future<AssessmentQuestions> getAssessmentQuestion({
    @Query('assessmentId') required String assessmentId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/Assessment/Question")
  @POST("rest/s1/growerp/100/Assessment/Question")
  Future<AssessmentQuestion> createAssessmentQuestion({
    @Field() required String assessmentId,
    @Field() required String questionText,
    @Field() String? questionDescription,
    @Field() String? questionType,
    @Field() int? questionSequence,
    @Field() String? isRequired,
    @Field() List<Map<String, dynamic>>? options,
  });

  @PATCH("rest/s1/growerp/100/Assessment/Question")
  Future<AssessmentQuestion> updateAssessmentQuestion({
    @Field() required String assessmentId,
    @Field() required String questionId,
    @Field() String? questionText,
    @Field() String? questionDescription,
    @Field() String? questionType,
    @Field() int? questionSequence,
    @Field() String? isRequired,
    @Field() List<Map<String, dynamic>>? options,
  });

  @DELETE("rest/s1/growerp/100/Assessment/Question")
  Future<void> deleteAssessmentQuestion({
    @Field() required String assessmentId,
    @Field() required String questionId,
  });
  // Assessment Question Option endpoints
  // Assessment Scoring Threshold endpoints
  @GET("rest/s1/growerp/100/Assessment/Threshold")
  Future<ScoringThresholds> getAssessmentThresholds({
    @Query('assessmentId') required String assessmentId,
  });

  @PATCH("rest/s1/growerp/100/Assessment/Threshold")
  Future<ScoringThresholds> updateAssessmentThresholds({
    @Field() required String assessmentId,
    @Field() required List<ScoringThreshold> thresholds,
  });

  // Marketing Persona endpoints
  @GET("rest/s1/growerp/100/MarketingPersonas")
  Future<Personas> getMarketingPersonas({
    @Query('searchString') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/MarketingPersona")
  Future<Persona> createMarketingPersona({
    @Field() required String name,
    @Field() String? pseudoId,
    @Field() String? demographics,
    @Field() String? painPoints,
    @Field() String? goals,
    @Field() String? toneOfVoice,
  });

  @PATCH("rest/s1/growerp/100/MarketingPersona")
  Future<Persona> updateMarketingPersona({
    @Field() required String personaId,
    @Field() String? pseudoId,
    @Field() String? name,
    @Field() String? demographics,
    @Field() String? painPoints,
    @Field() String? goals,
    @Field() String? toneOfVoice,
  });

  @DELETE("rest/s1/growerp/100/MarketingPersona")
  Future<void> deleteMarketingPersona({@Field() required String personaId});

  @POST("rest/s1/growerp/100/MarketingPersona/generate")
  Future<Persona> generateMarketingPersonaWithAI({
    @Field() required String businessDescription,
    @Field() String? targetMarket,
  });

  // Content Plan endpoints
  @GET("rest/s1/growerp/100/ContentPlans")
  Future<ContentPlans> getContentPlans({
    @Query('searchString') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/ContentPlan")
  Future<ContentPlan> createContentPlan({
    @Field() String? pseudoId,
    @Field() String? personaId,
    @Field() int? weekStartDate,
    @Field() String? theme,
  });

  @PATCH("rest/s1/growerp/100/ContentPlan")
  Future<ContentPlan> updateContentPlan({
    @Field() required String planId,
    @Field() String? pseudoId,
    @Field() String? personaId,
    @Field() int? weekStartDate,
    @Field() String? theme,
  });

  @DELETE("rest/s1/growerp/100/ContentPlan")
  Future<void> deleteContentPlan({@Field() required String planId});

  @POST("rest/s1/growerp/100/ContentPlan/generateWithAI")
  Future<ContentPlan> generateContentPlanWithAI({
    @Field() required String personaId,
    @Field() int? weekStartDate,
  });

  // Social Post endpoints
  @GET("rest/s1/growerp/100/SocialPosts")
  Future<SocialPosts> getSocialPosts({
    @Query('searchString') String? searchString,
    @Query('planId') String? planId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/SocialPost")
  Future<SocialPost> createSocialPost({
    @Field() String? pseudoId,
    @Field() String? planId,
    @Field() String? type,
    @Field() String? platform,
    @Field() String? headline,
    @Field() String? draftContent,
    @Field() String? finalContent,
    @Field() String? status,
    @Field() int? scheduledDate,
  });

  @PATCH("rest/s1/growerp/100/SocialPost")
  Future<SocialPost> updateSocialPost({
    @Field() required String postId,
    @Field() String? pseudoId,
    @Field() String? planId,
    @Field() String? type,
    @Field() String? platform,
    @Field() String? headline,
    @Field() String? draftContent,
    @Field() String? finalContent,
    @Field() String? status,
    @Field() int? scheduledDate,
  });

  @DELETE("rest/s1/growerp/100/SocialPost")
  Future<void> deleteSocialPost({@Field() required String postId});

  @POST("rest/s1/growerp/100/SocialPost/draftWithAI")
  Future<SocialPost> draftSocialPostWithAI({@Field() required String postId});

  // Assessment Result endpoints
  @GET("rest/s1/growerp/100/Assessment/Results")
  Future<AssessmentResults> getAssessmentResults({
    @Query('assessmentId') String? assessmentId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/AllAssessment/Results")
  Future<AssessmentResults> getAllAssessmentResults({
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  // Landing Page endpoints
  @GET("rest/s1/growerp/100/LandingPage")
  Future<LandingPages> getLandingPages({
    @Query('landingPageId') String? landingPageId,
    @Query('pseudoId') String? pseudoId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
    @Query('statusId') String? statusId,
  });

  // Public landing page endpoint (anonymous access)
  @GET("rest/s1/growerp/100/LandingPagePublic")
  Future<LandingPage> getLandingPage({
    @Query('landingPageId') String? landingPageId,
    @Query('pseudoId') String? pseudoId,
    @Query('ownerPartyId') String? ownerPartyId,
  });

  @POST("rest/s1/growerp/100/LandingPage")
  Future<LandingPage> createLandingPage({
    @Field() required String title,
    @Field() String? pseudoId,
    @Field() String? hookType,
    @Field() String? headline,
    @Field() String? subheading,
    @Field() String? privacyPolicyUrl,
    @Field() String? ctaActionType,
    @Field() String? ctaAssessmentId,
    @Field() String? ctaButtonLink,
    @Field() String status = 'DRAFT',
  });

  @PATCH("rest/s1/growerp/100/LandingPage")
  Future<LandingPage> updateLandingPage({
    @Query('landingPageId') required String landingPageId,
    @Field() String? pseudoId,
    @Field() String? title,
    @Field() String? hookType,
    @Field() String? headline,
    @Field() String? subheading,
    @Field() String? ctaActionType,
    @Field() String? ctaAssessmentId,
    @Field() String? ctaButtonLink,
    @Field() String? privacyPolicyUrl,
    @Field() String? status,
  });

  @DELETE("rest/s1/growerp/100/LandingPage")
  Future<void> deleteLandingPage({
    @Query('landingPageId') required String landingPageId,
  });

  @POST("rest/s1/growerp/100/LandingPage/publish")
  Future<LandingPage> publishLandingPage({
    @Query('landingPageId') required String landingPageId,
  });

  // ============================================
  // AI LANDING PAGE GENERATION ENDPOINTS
  // ============================================

  @POST("rest/s1/growerp/100/LandingPage/generateWithAI")
  @FormUrlEncoded()
  Future<LandingPageGenerationResponse> generateLandingPageWithAI({
    @Field() required String businessDescription,
    @Field() String? targetAudience,
    @Field() String? industry,
    @Field() String tone = 'professional',
    @Field() int numSections = 5,
  });

  // ============================================
  // PAGE SECTION ENDPOINTS
  // ============================================

  @GET("rest/s1/growerp/100/LandingPage/Section")
  Future<LandingPageSections> getPageSections({
    @Query('landingPageId') required String landingPageId,
  });

  @POST("rest/s1/growerp/100/LandingPage/Section")
  Future<LandingPageSection> createPageSection({
    @Field() required String landingPageId,
    @Field() required String sectionTitle,
    @Field() String? sectionDescription,
    @Field() String? sectionImageUrl,
    @Field() int? sectionSequence,
  });

  @PATCH("rest/s1/growerp/100/LandingPage/Section")
  Future<LandingPageSection> updatePageSection({
    @Query('landingPageId') required String landingPageId,
    @Query('pageSectionId') required String pageSectionId,
    @Field() String? sectionTitle,
    @Field() String? sectionDescription,
    @Field() String? sectionImageUrl,
    @Field() int? sectionSequence,
  });

  @DELETE("rest/s1/growerp/100/LandingPage/Section")
  Future<void> deletePageSection({
    @Query('landingPageId') required String landingPageId,
    @Query('pageSectionId') required String pageSectionId,
  });

  // ============================================
  // CREDIBILITY INFO ENDPOINTS (Nested under LandingPage)
  // ============================================

  @GET("rest/s1/growerp/100/LandingPage/Credibility")
  Future<CredibilityInfoList> getCredibilityInfo({
    @Query('landingPageId') required String landingPageId,
  });

  @POST("rest/s1/growerp/100/LandingPage/Credibility")
  Future<CredibilityInfo> createCredibilityInfo({
    @Field() required String landingPageId,
    @Field() String? creatorBio,
    @Field() String? backgroundText,
    @Field() String? creatorImageUrl,
    @Field() String? statisticsJson,
  });

  @PATCH("rest/s1/growerp/100/LandingPage/Credibility")
  Future<CredibilityInfo> updateCredibilityInfo({
    @Field() required String landingPageId,
    @Field() required String credibilityInfoId,
    @Field() String? pseudoId,
    @Field() String? creatorBio,
    @Field() String? backgroundText,
    @Field() String? creatorImageUrl,
    @Field() String? statisticsJson,
  });

  @DELETE("rest/s1/growerp/100/LandingPage/Credibility")
  Future<void> deleteCredibilityInfo({
    @Field() required String landingPageId,
    @Field() required String credibilityInfoId,
  });

  @DELETE("rest/s1/growerp/100/LandingPage/Credibility/Statistic")
  Future<void> deleteCredibilityStatistic({
    @Field() required String credibilityInfoId,
    @Field() required String credibilityStatisticId,
  });

  // ========================================================
  // OUTREACH CAMPAIGN ENDPOINTS
  // ========================================================

  // Outreach Campaign endpoints
  @GET("rest/s1/growerp/100/OutreachCampaigns")
  Future<OutreachCampaigns> listOutreachCampaigns({
    @Query('status') String? status,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  @GET("rest/s1/growerp/100/OutreachCampaign")
  Future<OutreachCampaigns> getOutreachCampaigns({
    @Query('marketingCampaignId') String? marketingCampaignId,
    @Query('pseudoId') String? pseudoId,
    @Query('statusId') String? statusId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/OutreachCampaign")
  Future<CampaignDetail> getOutreachCampaignDetail({
    @Query('marketingCampaignId') String? marketingCampaignId,
    @Query('pseudoId') String? pseudoId,
  });

  @POST("rest/s1/growerp/100/OutreachCampaign")
  Future<OutreachCampaign> createOutreachCampaign({
    @Field() required Map<String, dynamic> campaign,
  });

  @PATCH("rest/s1/growerp/100/OutreachCampaign")
  Future<OutreachCampaign> updateOutreachCampaign({
    @Field() required Map<String, dynamic> campaign,
  });

  @DELETE("rest/s1/growerp/100/OutreachCampaign")
  Future<void> deleteOutreachCampaign({
    @Field() required String marketingCampaignId,
  });

  // Campaign Automation endpoints
  @POST("rest/s1/growerp/100/OutreachCampaign/start")
  Future<dynamic> startCampaignAutomation({
    @Field() required String marketingCampaignId,
  });

  @POST("rest/s1/growerp/100/OutreachCampaign/pause")
  Future<dynamic> pauseCampaignAutomation({
    @Field() required String marketingCampaignId,
  });

  @GET("rest/s1/growerp/100/OutreachMessage")
  Future<OutreachMessages> listOutreachMessages({
    @Query("marketingCampaignId") String? marketingCampaignId,
    @Query("status") String? status,
    @Query("start") int? start,
    @Query("limit") int? limit,
    @Query("search") String? search,
  });

  @DELETE("rest/s1/growerp/100/OutreachMessage")
  Future<void> deleteOutreachMessage({@Field() required String messageId});

  @GET("rest/s1/growerp/100/OutreachCampaign/progress")
  Future<CampaignProgress> getCampaignProgress({
    @Query('marketingCampaignId') required String marketingCampaignId,
  });

  // Outreach Message endpoints
  @POST("rest/s1/growerp/100/OutreachMessage")
  Future<OutreachMessage> createOutreachMessage({
    @Field() String? marketingCampaignId,
    @Field() required String platform,
    @Field() String? recipientName,
    @Field() String? recipientProfileUrl,
    @Field() String? recipientHandle,
    @Field() String? recipientEmail,
    @Field() required String messageContent,
    @Field() String? status,
  });

  @PATCH("rest/s1/growerp/100/OutreachMessage")
  Future<OutreachMessage> updateOutreachMessageStatus({
    @Field() required String messageId,
    @Field() required String status,
    @Field() int? responseDate,
    @Field() String? errorMessage,
  });

  // Campaign Metrics endpoints
  @GET("rest/s1/growerp/100/CampaignMetrics")
  Future<CampaignMetrics> getCampaignMetrics({
    @Query('marketingCampaignId') required String marketingCampaignId,
  });

  // Platform Configuration endpoints
  @GET("rest/s1/growerp/100/PlatformConfigurations")
  Future<PlatformConfigurations> listPlatformConfigurations();

  @GET("rest/s1/growerp/100/PlatformConfiguration")
  Future<PlatformConfiguration> getPlatformConfiguration({
    @Query('platform') required String platform,
  });

  @POST("rest/s1/growerp/100/PlatformConfiguration")
  Future<PlatformConfiguration> createPlatformConfiguration({
    @Field() required String platform,
    @Field() String? isEnabled,
    @Field() int? dailyLimit,
    @Field() String? apiKey,
    @Field() String? apiSecret,
    @Field() String? username,
    @Field() String? password,
  });

  @PATCH("rest/s1/growerp/100/PlatformConfiguration")
  Future<PlatformConfiguration> updatePlatformConfiguration({
    @Field() required String configId,
    @Field() String? isEnabled,
    @Field() int? dailyLimit,
    @Field() String? apiKey,
    @Field() String? apiSecret,
    @Field() String? username,
    @Field() String? password,
  });

  @DELETE("rest/s1/growerp/100/PlatformConfiguration")
  Future<void> deletePlatformConfiguration({
    @Query('configId') required String configId,
  });

  // Send outreach email
  @POST("rest/s1/growerp/100/OutreachEmail")
  Future<OutreachMessage> sendOutreachEmail({
    @Field() required String marketingCampaignId,
    @Field() required String toEmail,
    @Field() String? toName,
    @Field() required String subject,
    @Field() required String body,
    @Field() String? bodyContentType,
  });

  // Generate platform-specific message with AI
  @POST("rest/s1/growerp/100/GeneratePlatformMessage")
  Future<Map<String, dynamic>> generatePlatformMessage({
    @Field() required String campaignTemplate,
    @Field() required String platform,
    @Field() required String actionType,
  });

  // ============================================
  // MENU CONFIGURATION ENDPOINTS
  // ============================================

  /// Get menu configuration by ID or appId+userLoginId
  /// Returns configuration with hierarchical menu items
  @GET("rest/s1/growerp/100/MenuConfiguration")
  Future<MenuConfiguration> getMenuConfiguration({
    @Query('menuConfigurationId') String? menuConfigurationId,
    @Query('appId') String? appId,
    @Query('userId') String? userId,
  });

  /// List all menu configurations with pagination
  @GET("rest/s1/growerp/100/MenuConfigurations")
  Future<MenuConfigurations> listMenuConfigurations({
    @Query('menuConfigurationId') String? menuConfigurationId,
    @Query('appId') String? appId,
    @Query('userId') String? userId,
    @Query('isActive') String? isActive,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? search,
  });

  /// Create new menu configuration
  @POST("rest/s1/growerp/100/MenuConfiguration")
  Future<MenuConfiguration> createMenuConfiguration({
    @Field() required String appId,
    @Field() String? userId,
    @Field() required String name,
    @Field() String? description,
    @Field() String? isActive,
  });

  /// Update menu configuration
  @PATCH("rest/s1/growerp/100/MenuConfiguration")
  Future<MenuConfiguration> updateMenuConfiguration({
    @Field() required String menuConfigurationId,
    @Field() String? name,
    @Field() String? description,
    @Field() String? isActive,
  });

  /// Delete menu configuration and all its items
  @DELETE("rest/s1/growerp/100/MenuConfiguration")
  Future<Map<String, int>> deleteMenuConfiguration({
    @Field() required String menuConfigurationId,
  });

  /// Clone menu configuration for user customization
  @POST("rest/s1/growerp/100/MenuConfiguration/clone")
  Future<MenuConfiguration> cloneMenuConfiguration({
    @Field() required String sourceMenuConfigurationId,
    @Field() String? name,
  });

  /// Reset menu configuration to default (copies items from default app config)
  @POST("rest/s1/growerp/100/MenuConfiguration/reset")
  Future<void> resetMenuConfiguration({
    @Field() required String menuConfigurationId,
  });

  // ============================================
  // MENU OPTION ENDPOINTS
  // ============================================

  /// Create new menu option (main menu entry)
  @POST("rest/s1/growerp/100/MenuOption")
  Future<MenuOption> createMenuOption({
    @Field() required String menuConfigurationId,
    @Field() String? itemKey,
    @Field() required String title,
    @Field() String? route,
    @Field() String? iconName,
    @Field() String? widgetName,
    @Field() String? image,
    @Field() String? selectedImage,
    @Field() String? userGroupsJson,
    @Field() int? sequenceNum,
    @Field() String? isActive,
  });

  /// Update menu option
  @PATCH("rest/s1/growerp/100/MenuOption")
  Future<MenuOption> updateMenuOption({
    @Field() required String menuOptionId,
    @Field() String? itemKey,
    @Field() String? title,
    @Field() String? route,
    @Field() String? iconName,
    @Field() String? widgetName,
    @Field() String? image,
    @Field() String? selectedImage,
    @Field() String? userGroupsJson,
    @Field() int? sequenceNum,
    @Field() String? isActive,
  });

  /// Delete menu option and its child links
  @DELETE("rest/s1/growerp/100/MenuOption")
  Future<Map<String, int>> deleteMenuOption({
    @Query('menuOptionId') required String menuOptionId,
  });

  /// Reorder multiple menu options (batch sequence update)
  @PATCH("rest/s1/growerp/100/MenuOptions/reorder")
  Future<Map<String, int>> reorderMenuOptions({
    @Field() required String menuConfigurationId,
    @Field() required List<Map<String, dynamic>> optionSequences,
  });

  /// Toggle menu option active status
  @PATCH("rest/s1/growerp/100/MenuOption/toggle")
  Future<MenuOption> toggleMenuOptionActive({
    @Field() required String menuOptionId,
  });

  /// Link a MenuItem (tab) to a MenuOption
  @POST("rest/s1/growerp/100/MenuOption/link")
  Future<MenuOption> linkMenuItem({
    @Field() required String menuOptionId,
    @Field() required String menuItemId,
    @Field() int? sequenceNum,
  });

  /// Unlink a MenuItem (tab) from a MenuOption
  @POST("rest/s1/growerp/100/MenuOption/unlink")
  Future<Map<String, int>> unlinkMenuItem({
    @Field() required String menuOptionId,
    @Field() required String menuItemId,
  });

  // ========== Agent Manager ==========

  /// Get agent dashboard data
  @GET("rest/s1/growerp-agent/Dashboard")
  Future<AgentDashboard> getAgentDashboard();

  /// List agent instances
  @GET("rest/s1/growerp-agent/Agents")
  Future<AgentInstances> getAgentInstances({
    @Query('status') String? status,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  /// Get single agent instance
  @GET("rest/s1/growerp-agent/Agent/{instanceId}")
  Future<AgentInstance> getAgentInstance({
    @Path('instanceId') required String instanceId,
  });

  /// Create agent instance
  @POST("rest/s1/growerp-agent/Agents")
  Future<AgentInstance> createAgentInstance({
    @Field() required AgentInstance agent,
  });

  /// Update agent instance
  @PATCH("rest/s1/growerp-agent/Agent/{instanceId}")
  Future<AgentInstance> updateAgentInstance({
    @Field() required AgentInstance agent,
  });

  /// Delete agent instance
  @DELETE("rest/s1/growerp-agent/Agent/{instanceId}")
  Future<void> deleteAgentInstance({
    @Path('instanceId') required String instanceId,
  });

  /// Start agent instance
  @POST("rest/s1/growerp-agent/Agent/{instanceId}/start")
  Future<void> startAgentInstance({
    @Path('instanceId') required String instanceId,
  });

  /// Pause agent instance
  @POST("rest/s1/growerp-agent/Agent/{instanceId}/pause")
  Future<void> pauseAgentInstance({
    @Path('instanceId') required String instanceId,
  });

  /// Stop agent instance
  @POST("rest/s1/growerp-agent/Agent/{instanceId}/stop")
  Future<void> stopAgentInstance({
    @Path('instanceId') required String instanceId,
  });

  /// List approval requests
  @GET("rest/s1/growerp-agent/Approvals")
  Future<List<ApprovalRequest>> getAgentApprovalRequests({
    @Query('status') String? status,
  });

  /// Resolve (approve/reject) approval request
  @POST("rest/s1/growerp-agent/Approval/{requestId}/resolve")
  Future<void> resolveAgentApprovalRequest({
    @Path('requestId') required String requestId,
    @Field() required bool approved,
    @Field() String? comment,
  });

  /// Check rate limit
  @GET("rest/s1/growerp-agent/RateLimit/check")
  Future<RateLimitCheck> checkAgentRateLimit({
    @Query('instanceId') required String instanceId,
    @Query('platform') required String platform,
  });
}

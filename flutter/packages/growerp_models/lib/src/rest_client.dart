import 'dart:ui';

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';

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
    @Field() Locale? locale,
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
  @GET("rest/s1/growerp/100/Assessment")
  Future<Assessments> getAssessment({
    @Query('assessmentId') String? assessmentId,
    @Query('pseudoId') String? pseudoId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
    @Query('statusId') String? statusId,
  });

  @POST("rest/s1/growerp/100/Assessment")
  Future<Assessment> createAssessment({
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
    @Field() required Map<String, dynamic> answers,
    @Field() required String respondentName,
    @Field() required String respondentEmail,
    @Field() String? respondentPhone,
    @Field() String? respondentCompany,
  });

  // Assessment Question endpoints
  @GET("rest/s1/growerp/100/AssessmentQuestion")
  Future<AssessmentQuestions> getAssessmentQuestions({
    @Query('assessmentId') required String assessmentId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/AssessmentQuestion")
  Future<AssessmentQuestion> createAssessmentQuestion({
    @Field() required String assessmentId,
    @Field() required String questionText,
    @Field() String? questionType,
    @Field() int? questionSequence,
    @Field() String? isRequired,
  });

  @PATCH("rest/s1/growerp/100/AssessmentQuestion")
  Future<AssessmentQuestion> updateAssessmentQuestion({
    @Field() required String assessmentId,
    @Field() required String questionId,
    @Field() String? questionText,
    @Field() String? questionType,
    @Field() int? questionSequence,
    @Field() String? isRequired,
  });

  @DELETE("rest/s1/growerp/100/AssessmentQuestion")
  Future<void> deleteAssessmentQuestion({
    @Field() required String assessmentId,
    @Field() required String questionId,
  });

  // Assessment Question Option endpoints
  @GET("rest/s1/growerp/100/AssessmentQuestionOption")
  Future<AssessmentQuestionOptions> getAssessmentQuestionOptions({
    @Query('assessmentId') required String assessmentId,
    @Query('questionId') required String questionId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/AssessmentQuestionOption")
  Future<AssessmentQuestionOption> createAssessmentQuestionOption({
    @Field() required String assessmentId,
    @Field() required String questionId,
    @Field() required String optionText,
    @Field() required double optionScore,
    @Field() int? optionSequence,
  });

  @PATCH("rest/s1/growerp/100/AssessmentQuestionOption")
  Future<AssessmentQuestionOption> updateAssessmentQuestionOption({
    @Field() required String assessmentId,
    @Field() required String questionId,
    @Field() required String optionId,
    @Field() String? optionText,
    @Field() double? optionScore,
    @Field() int? optionSequence,
  });

  @DELETE("rest/s1/growerp/100/AssessmentQuestionOption")
  Future<void> deleteAssessmentQuestionOption({
    @Field() required String assessmentId,
    @Field() required String questionId,
    @Field() required String optionId,
  });

  // Assessment Scoring Threshold endpoints
  @GET("rest/s1/growerp/100/AssessmentThreshold")
  Future<ScoringThresholds> getAssessmentThresholds({
    @Query('assessmentId') required String assessmentId,
  });

  @PATCH("rest/s1/growerp/100/AssessmentThreshold")
  Future<ScoringThresholds> updateAssessmentThresholds({
    @Field() required String assessmentId,
    @Field() required List<ScoringThreshold> thresholds,
  });

  @POST("rest/s1/growerp/100/Assessment/calculateScore")
  Future<AssessmentScoreResponse> calculateAssessmentScore({
    @Field() required String assessmentId,
    @Field() required Map<String, dynamic> answers,
  });

  // Assessment Result endpoints
  @GET("rest/s1/growerp/100/AssessmentResult")
  Future<AssessmentResults> getAssessmentResults({
    @Query('assessmentId') String? assessmentId,
    @Query('resultId') String? resultId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('statusId') String? statusId,
  });

  @GET("rest/s1/growerp/100/AllAssessmentResults")
  Future<AssessmentResults> getAllAssessmentResults({
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @DELETE("rest/s1/growerp/100/AssessmentResult")
  Future<void> deleteAssessmentResult({
    @Field() required String assessmentId,
    @Field() required String resultId,
  });

  // Landing Page endpoints
  @GET("rest/s1/growerp/100/LandingPage")
  Future<LandingPages> getLandingPages({
    @Query('pageId') String? pageId,
    @Query('pseudoId') String? pseudoId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
    @Query('statusId') String? statusId,
  });

  @GET("rest/s1/growerp/100/LandingPage/{pageId}")
  Future<LandingPageResponse> getLandingPage({
    @Path() required String pageId,
    @Query('ownerPartyId') String? ownerPartyId,
  });

  @POST("rest/s1/growerp/100/LandingPage")
  Future<LandingPage> createLandingPage({
    @Field() required String title,
    @Field() String? hookType,
    @Field() String? headline,
    @Field() String? subheading,
    @Field() String? assessmentId,
    @Field() String? privacyPolicyUrl,
    @Field() String status = 'DRAFT',
  });

  @PATCH("rest/s1/growerp/100/LandingPage/{pageId}")
  Future<LandingPage> updateLandingPage({
    @Path() required String pageId,
    @Field() String? title,
    @Field() String? hookType,
    @Field() String? headline,
    @Field() String? subheading,
    @Field() String? assessmentId,
    @Field() String? privacyPolicyUrl,
    @Field() String? status,
  });

  @DELETE("rest/s1/growerp/100/LandingPage/{pageId}")
  Future<void> deleteLandingPage({@Path() required String pageId});

  @POST("rest/s1/growerp/100/LandingPage/{pageId}/publish")
  Future<LandingPage> publishLandingPage({@Path() required String pageId});

  // Public Landing Page access (no authentication)
  @GET("rest/s1/growerp/100/Public/LandingPage/{pageId}")
  @Extra({'noApiKey': true})
  Future<LandingPageResponse> getPublicLandingPage({
    @Path() required String pageId,
    @Query('ownerPartyId') String? ownerPartyId,
  });

  // ============================================
  // PAGE SECTION ENDPOINTS
  // ============================================

  @GET("rest/s1/growerp/100/LandingPage/{pageId}/Section")
  Future<List<LandingPageSection>> getPageSections({
    @Path() required String pageId,
  });

  @POST("rest/s1/growerp/100/LandingPage/{pageId}/Section")
  Future<LandingPageSection> createPageSection({
    @Path() required String pageId,
    @Field() required String sectionTitle,
    @Field() String? sectionDescription,
    @Field() String? sectionImageUrl,
    @Field() int? sectionSequence,
  });

  @PATCH("rest/s1/growerp/100/LandingPage/{pageId}/Section/{sectionId}")
  Future<LandingPageSection> updatePageSection({
    @Path() required String pageId,
    @Path() required String sectionId,
    @Field() String? sectionTitle,
    @Field() String? sectionDescription,
    @Field() String? sectionImageUrl,
    @Field() int? sectionSequence,
  });

  @DELETE("rest/s1/growerp/100/LandingPage/{pageId}/Section/{sectionId}")
  Future<void> deletePageSection({
    @Path() required String pageId,
    @Path() required String sectionId,
  });

  // ============================================
  // CREDIBILITY INFO ENDPOINTS (Nested under LandingPage)
  // ============================================

  @POST("rest/s1/growerp/100/LandingPage/{pageId}/Credibility")
  Future<CredibilityElement> createCredibilityInfo({
    @Path() required String pageId,
    @Field() required String creatorBio,
    @Field() String? backgroundText,
    @Field() String? creatorImageUrl,
  });

  @PATCH("rest/s1/growerp/100/LandingPage/{pageId}/Credibility/{credibilityId}")
  Future<CredibilityElement> updateCredibilityInfo({
    @Path() required String pageId,
    @Path() required String credibilityId,
    @Field() String? creatorBio,
    @Field() String? backgroundText,
    @Field() String? creatorImageUrl,
  });

  @DELETE(
    "rest/s1/growerp/100/LandingPage/{pageId}/Credibility/{credibilityId}",
  )
  Future<void> deleteCredibilityInfo({
    @Path() required String pageId,
    @Path() required String credibilityId,
  });

  // ============================================
  // CREDIBILITY STATISTICS ENDPOINTS
  // ============================================

  @GET("rest/s1/growerp/100/CredibilityStatistic")
  Future<dynamic> getCredibilityStatistics({
    @Query('credibilityId') required String credibilityId,
  });

  @POST("rest/s1/growerp/100/CredibilityStatistic")
  Future<dynamic> addCredibilityStatistic({
    @Field() required String credibilityId,
    @Field() required String statistic,
  });

  @DELETE("rest/s1/growerp/100/CredibilityStatistic/{statisticId}")
  Future<void> removeCredibilityStatistic({
    @Path() required String statisticId,
  });

  // ============================================
  // PRIMARY CTA ENDPOINTS (Nested under LandingPage)
  // ============================================

  @POST("rest/s1/growerp/100/LandingPage/{pageId}/CallToAction")
  Future<CallToAction> createPrimaryCTA({
    @Path() required String pageId,
    @Field() required String buttonText,
    @Field() String? estimatedTime,
    @Field() String? cost,
    @Field() String? valuePromise,
  });

  @PATCH("rest/s1/growerp/100/LandingPage/{pageId}/CallToAction/{ctaId}")
  Future<CallToAction> updatePrimaryCTA({
    @Path() required String pageId,
    @Path() required String ctaId,
    @Field() String? buttonText,
    @Field() String? estimatedTime,
    @Field() String? cost,
    @Field() String? valuePromise,
  });
}

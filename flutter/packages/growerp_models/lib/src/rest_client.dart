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

  @POST("rest/s1/growerp/100/UserAndCompany")
  @Extra({'noApiKey': true})
  @FormUrlEncoded()
  Future<String> registerCompanyAdmin({
    @Field() required String emailAddress,
    @Field() required String companyEmailAddress,
    @Field() required String firstName,
    @Field() required String lastName,
    @Field() required String companyName,
    @Field() required String currencyId,
    @Field() required bool demoData,
    @Field() required String classificationId,
    @Field() String? newPassword,
  });

  @POST("rest/s1/growerp/100/Login")
  @Extra({'noApiKey': true})
  @FormUrlEncoded()
  Future<Authenticate> login({
    @Field() required String username,
    @Field() required String password,
    @Field() required String classificationId,
  });

  @POST("rest/s1/growerp/100/Logout")
  @Extra({'noApiKey': true})
  Future<String> logout();

  @POST("rest/s1/growerp/100/ResetPassword")
  @Extra({'noApiKey': true})
  Future<String> resetPassword({@Field() required String username});

  @POST("rest/s1/growerp/100/Password")
  Future<Authenticate> updatePassword({
    @Field() required String username,
    @Field() required String oldPassword,
    @Field() required String newPassword,
    @Field() required String classificationId,
  });

  @GET("rest/s1/growerp/100/Companies")
  Future<Companies> getCompanies({
    @Query('mainCompanies') bool? mainCompanies,
    @Query('searchString') String? searchString,
    @Query('filter') String? filter,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/Authenticate")
  Future<Authenticate> getAuthenticate(
      {@Query('classificationId') required String classificationId});

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
    @Query('filter') String? filter,
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
  @GET("rest/s1/growerp/100/Party")
  Future<Parties> getParty({
    @Query('partyId') String? partyId,
    @Query('pseudoId') String? pseudoId,
    @Query('role') Role? role,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('firstName') String? firstName,
    @Query('lastName') String? lastName,
    @Query('company') Party? company,
    @Query('search') String? searchString,
    @Query('isForDropDown') bool? isForDropDown,
  });

  @POST("rest/s1/growerp/100/Party")
  Future<Party> createParty({@Field() required Party party});

  @PATCH("rest/s1/growerp/100/Party")
  Future<Party> updateParty({@Field() required Party party});

  @DELETE("rest/s1/growerp/100/Party")
  Future<Party> deleteParty(
      {@Field() required String partyId,
      @Field() required bool deleteCompanyToo});

  // user
  @GET("rest/s1/growerp/100/User")
  Future<Users> getUser({
    @Query('userpartyId') String? userpartyId,
    @Query('role') Role? role,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('firstName') String? firstName,
    @Query('lastName') String? lastName,
    @Query('search') String? searchString,
    @Query('isForDropDown') bool? isForDropDown,
  });

  @POST("rest/s1/growerp/100/User")
  Future<User> createUser({@Field() required User user});

  @PATCH("rest/s1/growerp/100/User")
  Future<User> updateUser({@Field() required User user});

  @DELETE("rest/s1/growerp/100/User")
  Future<User> deleteUser(
      {@Field() required String partyId,
      @Field() required bool deleteCompanyToo});

  // ecommerce
  @POST("rest/s1/growerp/100/RegisterUser")
  @FormUrlEncoded()
  Future<Authenticate> registerUser({
    @Field() required User user,
    @Field() required String ownerPartyId,
    @Field() required String classificationId,
    @Field() required String newPassword,
  });
  // Website ======
  @GET("rest/s1/growerp/100/Website")
  Future<Website> getWebsite();

  @GET("rest/s1/growerp/100/WebsiteContent")
  Future<Content> getWebsiteContent(
      {@Query('path') required String path,
      @Query('text') required String text});

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
  Future<Assets> getAsset(
      {@Query('start') int? start,
      @Query('limit') int? limit,
      @Query('companyPartyId') String? companyPartyId,
      @Query('assetClassId') String? assetClassId,
      @Query('assetId') String? assetId,
      @Query('productId') String? productId,
      @Query('isForDropDown') bool? isForDropDown,
      @Query('search') String? searchString});

  @POST("rest/s1/growerp/100/Asset")
  Future<Asset> createAsset(
      {@Field() required Asset asset,
      @Field() required String classificationId});

  @PATCH("rest/s1/growerp/100/Asset")
  Future<Asset> updateAsset(
      {@Field() required Asset asset,
      @Field() required String classificationId});

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
  Future<Category> createCategory(
      {@Field() required Category category,
      @Field() required String classificationId});

  @PATCH("rest/s1/growerp/100/Category")
  Future<Category> updateCategory(
      {@Field() required Category category,
      @Field() required String classificationId});

  @DELETE("rest/s1/growerp/100/Category")
  Future<Category> deleteCategory({@Field() required Category category});

  @POST("rest/s1/growerp/100/ImportExport")
  Future<String> importScreenCategories(
      {@Field() required List categories,
      @Field() required String classificationId});

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
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
    @Query('classificationId') String? classificationId,
    @Query('categoryId') String? categoryId,
    @Query('productId') String? productId,
    @Query('productTypeId') String? productTypeId,
    @Query('assetClassId') String? assetClassId,
  });

  @POST("rest/s1/growerp/100/Product")
  Future<Product> createProduct(
      {@Field() required Product product,
      @Field() required String classificationId});

  @PATCH("rest/s1/growerp/100/Product")
  Future<Product> updateProduct(
      {@Field() required Product product,
      @Field() required String classificationId});

  @DELETE("rest/s1/growerp/100/Product")
  Future<Product> deleteProduct({@Field() required Product product});

  @POST("rest/s1/growerp/100/ImportExport")
  Future<String> importScreenProducts(
      {@Field() required List<Product> products,
      @Field() required String classificationId});

  @GET("rest/s1/growerp/100/ImportExport")
  Future<String> exportScreenProducts({
    @Query('entityName') String entityName = 'Product',
    @Query('classificationId') required String classificationId,
  });

  // dayly rental
  @GET("rest/s1/growerp/100/DailyRentalOccupancy")
  Future<Products> getDailyRentalOccupancy({
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
  });

  @POST("rest/s1/growerp/100/FinDoc")
  Future<FinDoc> createFinDoc({
    @Field() required FinDoc finDoc,
  });

  @PATCH("rest/s1/growerp/100/FinDoc")
  Future<FinDoc> updateFinDoc({@Field() required FinDoc finDoc});

  @PATCH("rest/s1/growerp/100/FinDocShipment")
  Future<FinDoc> receiveShipment({@Field() required FinDoc finDoc});

  @GET("rest/s1/growerp/100/ItemType")
  Future<ItemTypes> getItemTypes({
    @Query('sales') bool? sales,
  });

  @PATCH("rest/s1/growerp/100/ItemType")
  Future<ItemType> updateItemType({
    @Field() required ItemType itemType,
    @Field() bool? update,
    @Field() bool? delete,
  });

  @GET("rest/s1/growerp/100/PaymentType")
  Future<PaymentTypes> getPaymentTypes({
    @Query('sales') bool? sales,
  });

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
      @Field() List<FinDocItem> finDocItems, @Field() String classificationId);

  // finalize import
  @POST("rest/s1/growerp/100/ImportExport/finalizeImport")
  Future<void> finalizeImport();

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

  @GET("rest/s1/growerp/100/LedgerJournal")
  Future<LedgerJournals> getLedgerJournal({
    @Query('ledgerJournalId') String? ledgerJournalId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/GlAccount")
  Future<GlAccount> createGlAccount({
    @Field() required GlAccount glAccount,
  });

  @PATCH("rest/s1/growerp/100/GlAccount")
  Future<GlAccount> updateGlAccount({
    @Field() required GlAccount glAccount,
  });

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
  Future<LedgerReport> getOperatingRevenueExpenseChart();

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
  Future<ChatRoom> createChatRoom({
    @Field() required ChatRoom chatRoom,
  });

  @PATCH("rest/s1/growerp/100/ChatRoom")
  Future<ChatRoom> updateChatRoom({
    @Field() required ChatRoom chatRoom,
  });

  @DELETE("rest/s1/growerp/100/ChatRoom")
  Future<ChatRoom> deleteChatRoom({@Field() required ChatRoom chatRoom});

  @GET("rest/s1/growerp/100/ChatMessage")
  Future<ChatMessages> getChatMessages({
    @Query('chatRoomId') String? chatRoomId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  // tasks
  @GET("rest/s1/growerp/100/Task")
  Future<Tasks> getTask({
    @Query('taskId') String? taskId,
    @Query('taskType') TaskType? taskType,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('open') bool? open,
    @Query('my') bool? my,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/Task")
  Future<Task> createTask({
    @Field() required Task task,
  });

  @PATCH("rest/s1/growerp/100/Task")
  Future<Task> updateTask({
    @Field() required Task task,
  });

  // user workflow
  @GET("rest/s1/growerp/100/UserWorkflow")
  Future<Tasks> getUserWorkflow({
    @Query('taskType') TaskType? taskType,
  });

  @POST("rest/s1/growerp/100/UserWorkflow")
  Future<Tasks> createUserWorkflow({
    @Field() required String workflowId,
  });

  @DELETE("rest/s1/growerp/100/UserWorkflow")
  Future<Task> deleteUserWorkflow({
    @Field() required String workflowId,
  });

  // time entry
  @POST("rest/s1/growerp/100/TimeEntry")
  Future<TimeEntry> createTimeEntry({
    @Field() required TimeEntry timeEntry,
  });

  @PATCH("rest/s1/growerp/100/TimeEntry")
  Future<TimeEntry> updateTimeEntry({
    @Field() required TimeEntry timeEntry,
  });

  @DELETE("rest/s1/growerp/100/TimeEntry")
  Future<TimeEntry> deleteTimeEntry({@Field() required TimeEntry timeEntry});

  // import / export ========
  @POST("rest/s1/growerp/100/ImportExport")
  Future<void> uploadEntities(
      {@Field() required dynamic entities,
      @Field() required String classificationId});

  @POST("rest/s1/growerp/100/ImportExport/itemTypes")
  Future<String> importItemTypes(@Field() List<ItemType> itemTypes);

  @POST("rest/s1/growerp/100/ImportExport/paymentTypes")
  Future<String> importPaymentTypes(@Field() List<PaymentType> paymentTypes);

  @POST("rest/s1/growerp/100/ImportExport/glAccounts")
  Future<String> importGlAccounts(@Field() List<GlAccount> glAccounts);

  @GET("rest/s1/growerp/100/exportGlAccounts")
  Future<String> exportGlAccounts(
      {@Query('entityName') String entityName = 'glAccount'});

  @POST("rest/s1/growerp/100/ImportExport/companies")
  Future<void> importCompanies(@Field() List<Company> companies);

  @POST("rest/s1/growerp/100/ImportExport/users")
  Future<void> importUsers(@Field() List<User> users);

  @POST("rest/s1/growerp/100/ImportExport/products")
  Future<void> importProducts(
      @Field() List<Product> products, @Field() String classificationId);

  @POST("rest/s1/growerp/100/ImportExport/categories")
  Future<void> importCategories(@Field() List<Category> categories);

  @POST("rest/s1/growerp/100/ImportExport/assets")
  Future<void> importAssets(
      @Field() List<Asset> assets, @Field() String classificationId);

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
    @Query('my') bool? my,
  });

  @POST("rest/s1/growerp/100/Opportunity")
  Future<Opportunity> createOpportunity(
      {@Field() required Opportunity opportunity});

  @PATCH("rest/s1/growerp/100/Opportunity")
  Future<Opportunity> updateOpportunity(
      {@Field() required Opportunity opportunity});

  @DELETE("rest/s1/growerp/100/Opportunity")
  Future<Opportunity> deleteOpportunity(
      {@Field() required Opportunity opportunity});
}

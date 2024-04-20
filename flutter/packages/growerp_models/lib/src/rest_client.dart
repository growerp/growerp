import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: null)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET("rest/s1/growerp/100/CheckEmail")
  Future<Map<String, bool>> checkEmail({@Query('email') required String email});

  @POST("rest/s1/growerp/100/UserAndCompany")
  @FormUrlEncoded()
  Future<Authenticate> registerCompanyAdmin({
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
  @FormUrlEncoded()
  Future<Authenticate> login({
    @Field() required String username,
    @Field() required String password,
    @Field() required String classificationId,
  });

  @POST("rest/s1/growerp/100/Logout")
  @Extra({'requireApiKey': true})
  Future<String> logout();

  @POST("rest/s1/growerp/100/ResetPassword")
  Future<String> resetPassword({@Field() required String username});

  @POST("rest/s1/growerp/100/Password")
  @Extra({'requireApiKey': true})
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
  @Extra({'requireApiKey': true})
  Future<Authenticate> getAuthenticate(
      {@Query('classificationId') required String classificationId});

  // company
  @GET("rest/s1/growerp/100/Company")
  @Extra({'requireApiKey': true})
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
  @Extra({'requireApiKey': true})
  Future<Company> createCompany({@Field() required Company company});

  @PATCH("rest/s1/growerp/100/Company")
  @Extra({'requireApiKey': true})
  Future<Company> updateCompany({@Field() required Company company});

  // user
  @GET("rest/s1/growerp/100/User")
  @Extra({'requireApiKey': true})
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
  @Extra({'requireApiKey': true})
  Future<User> createUser({@Field() required User user});

  @PATCH("rest/s1/growerp/100/User")
  @Extra({'requireApiKey': true})
  Future<User> updateUser({@Field() required User user});

  @DELETE("rest/s1/growerp/100/User")
  @Extra({'requireApiKey': true})
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
  @Extra({'requireApiKey': true})
  Future<Website> getWebsite();

  @GET("rest/s1/growerp/100/WebsiteContent")
  @Extra({'requireApiKey': true})
  Future<Content> getWebsiteContent(
      {@Query('path') required String path,
      @Query('text') required String text});

  @PATCH("rest/s1/growerp/100/Website")
  @Extra({'requireApiKey': true})
  Future<Website> updateWebsite({@Field() required Website website});

  @POST("rest/s1/growerp/100/WebsiteContent")
  @Extra({'requireApiKey': true})
  Future<Content> uploadWebsiteContent({@Field() required Content content});

  @POST("rest/s1/growerp/100/Obsidian")
  @Extra({'requireApiKey': true})
  Future<Website> obsUpload({@Field() required Obsidian obsidian});

  @POST("rest/s1/growerp/100/ImportExport/website")
  @Extra({'requireApiKey': true})
  Future<void> importWebsite(@Field() Website website);

  @GET("rest/s1/growerp/100/ImportExport/website")
  @Extra({'requireApiKey': true})
  Future<Website> exportWebsite();

  // catalog
  // asset
  @GET("rest/s1/growerp/100/Asset")
  @Extra({'requireApiKey': true})
  Future<Assets> getAsset(
      {@Query('start') int? start,
      @Query('limit') int? limit,
      @Query('companyPartyId') String? companyPartyId,
      @Query('assetClassId') String? assetClassId,
      @Query('assetId') String? assetId,
      @Query('productId') String? productId,
      @Query('isForDropDown') bool? isForDropDown,
      @Query('search') String? search});

  @POST("rest/s1/growerp/100/Asset")
  @Extra({'requireApiKey': true})
  Future<Asset> createAsset(
      {@Field() required Asset asset,
      @Field() required String classificationId});

  @PATCH("rest/s1/growerp/100/Asset")
  @Extra({'requireApiKey': true})
  Future<Asset> updateAsset(
      {@Field() required Asset asset,
      @Field() required String classificationId});

  // categories
  @GET("rest/s1/growerp/100/Categories")
  @Extra({'requireApiKey': true})
  Future<Categories> getCategory({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('companyPartyId') String? companyPartyId,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
    @Query('classificationId') String? classificationId,
  });

  @POST("rest/s1/growerp/100/Category")
  @Extra({'requireApiKey': true})
  Future<Category> createCategory(
      {@Field() required Category category,
      @Field() required String classificationId});

  @PATCH("rest/s1/growerp/100/Category")
  @Extra({'requireApiKey': true})
  Future<Category> updateCategory(
      {@Field() required Category category,
      @Field() required String classificationId});

  @DELETE("rest/s1/growerp/100/Category")
  @Extra({'requireApiKey': true})
  Future<Category> deleteCategory({@Field() required Category category});

  @POST("rest/s1/growerp/100/ImportExport")
  @Extra({'requireApiKey': true})
  Future<String> importScreenCategories(
      {@Field() required List categories,
      @Field() required String classificationId});

  @GET("rest/s1/growerp/100/ImportExport")
  @Extra({'requireApiKey': true})
  Future<String> exportScreenCategories({
    @Query('entityName') String entityName = 'Category',
    @Query('classificationId') String? classificationId,
  });

  // products
  @GET("rest/s1/growerp/100/Products")
  @Extra({'requireApiKey': true})
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
  @Extra({'requireApiKey': true})
  Future<Product> createProduct(
      {@Field() required Product product,
      @Field() required String classificationId});

  @PATCH("rest/s1/growerp/100/Product")
  @Extra({'requireApiKey': true})
  Future<Product> updateProduct(
      {@Field() required Product product,
      @Field() required String classificationId});

  @DELETE("rest/s1/growerp/100/Product")
  @Extra({'requireApiKey': true})
  Future<Product> deleteProduct({@Field() required Product product});

  @POST("rest/s1/growerp/100/ImportExport")
  @Extra({'requireApiKey': true})
  Future<String> importScreenProducts(
      {@Field() required List<Product> products,
      @Field() required String classificationId});

  @GET("rest/s1/growerp/100/ImportExport")
  @Extra({'requireApiKey': true})
  Future<String> exportScreenProducts({
    @Query('entityName') String entityName = 'Product',
    @Query('classificationId') required String classificationId,
  });

  // dayly rental
  @GET("rest/s1/growerp/100/DailyRentalOccupancy")
  @Extra({'requireApiKey': true})
  Future<Products> getDailyRentalOccupancy({
    @Query('productId') String? productId,
  });

  // FINDOC
  @GET("rest/s1/growerp/100/FinDoc")
  @Extra({'requireApiKey': true})
  Future<FinDocs> getFinDoc({
    @Query('sales') bool? sales,
    @Query('docType') FinDocType? docType,
    @Query('companyPartyId') String? companyPartyId,
    @Query('search') String? searchString,
    @Query('journalId') String? journalId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/FinDoc")
  @Extra({'requireApiKey': true})
  Future<FinDoc> createFinDoc({
    @Field() required FinDoc finDoc,
  });

  @PATCH("rest/s1/growerp/100/FinDoc")
  @Extra({'requireApiKey': true})
  Future<FinDoc> updateFinDoc({@Field() required FinDoc finDoc});

  @PATCH("rest/s1/growerp/100/FinDocShipment")
  @Extra({'requireApiKey': true})
  Future<FinDoc> receiveShipment({@Field() required FinDoc finDoc});

  @GET("rest/s1/growerp/100/ItemType")
  @Extra({'requireApiKey': true})
  Future<ItemTypes> getItemTypes({
    @Query('sales') bool? sales,
  });

  @PATCH("rest/s1/growerp/100/ItemType")
  @Extra({'requireApiKey': true})
  Future<ItemType> updateItemType({
    @Field() required ItemType itemType,
    @Field() bool? update,
    @Field() bool? delete,
  });

  @GET("rest/s1/growerp/100/PaymentType")
  @Extra({'requireApiKey': true})
  Future<PaymentTypes> getPaymentTypes({
    @Query('sales') bool? sales,
  });

  @PATCH("rest/s1/growerp/100/PaymentType")
  @Extra({'requireApiKey': true})
  Future<PaymentType> updatePaymentType({
    @Field() required PaymentType paymentType,
    @Field() bool? update,
    @Field() bool? delete,
  });

  @POST("rest/s1/growerp/100/ImportExport/finDocs")
  @Extra({'requireApiKey': true})
  Future<void> importFinDoc(@Field() List<FinDoc> finDocs);

  @POST("rest/s1/growerp/100/ImportExport/finDocItems")
  @Extra({'requireApiKey': true})
  Future<void> importFinDocItem(
      @Field() List<FinDocItem> finDocItems, @Field() String classificationId);

  // Inventory locations
  @GET("rest/s1/growerp/100/Location")
  @Extra({'requireApiKey': true})
  Future<Locations> getLocation({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('filter') String? filter,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/Location")
  @Extra({'requireApiKey': true})
  Future<Location> createLocation({@Field() required Location location});

  @PATCH("rest/s1/growerp/100/Location")
  @Extra({'requireApiKey': true})
  Future<Location> updateLocation({@Field() required Location location});

  @DELETE("rest/s1/growerp/100/Location")
  @Extra({'requireApiKey': true})
  Future<Location> deleteLocation({@Field() required Location location});

  // accounting
  @GET("rest/s1/growerp/100/Ledger")
  @Extra({'requireApiKey': true})
  Future<LedgerReport> getLedger();

  @POST("rest/s1/growerp/100/Ledger")
  @Extra({'requireApiKey': true})
  Future<void> calculateLedger();

  @GET("rest/s1/growerp/100/GlAccount")
  @Extra({'requireApiKey': true})
  Future<GlAccounts> getGlAccount({
    @Query('start') int? start = 0,
    @Query('limit') int? limit = 10,
    @Query('search') String? searchString,
    @Query('trialBalance') bool? trialBalance,
  });

  @GET("rest/s1/growerp/100/TimePeriod")
  @Extra({'requireApiKey': true})
  Future<TimePeriods> getTimePeriod({
    @Query('periodType') String? periodType = 'Y',
    @Query('year') String? year,
  });

  @PATCH("rest/s1/growerp/100/TimePeriod")
  @Extra({'requireApiKey': true})
  Future<TimePeriods> updateTimePeriod({
    @Field() required String timePeriodId,
    @Field() bool? createNext,
    @Field() bool? createPrevious,
    @Field() bool? delete,
  });

  @GET("rest/s1/growerp/100/LedgerJournal")
  @Extra({'requireApiKey': true})
  Future<LedgerJournals> getLedgerJournal({
    @Query('ledgerJournalId') String? ledgerJournalId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/GlAccount")
  @Extra({'requireApiKey': true})
  Future<GlAccount> createGlAccount({
    @Field() required GlAccount glAccount,
  });

  @PATCH("rest/s1/growerp/100/GlAccount")
  @Extra({'requireApiKey': true})
  Future<GlAccount> updateGlAccount({
    @Field() required GlAccount glAccount,
  });

  @POST("rest/s1/growerp/100/LedgerJournal")
  @Extra({'requireApiKey': true})
  Future<LedgerJournal> createLedgerJournal({
    @Field() required LedgerJournal ledgerJournal,
  });

  @PATCH("rest/s1/growerp/100/LedgerJournal")
  @Extra({'requireApiKey': true})
  Future<LedgerJournal> updateLedgerJournal({
    @Field() required LedgerJournal ledgerJournal,
  });

  @GET("rest/s1/growerp/100/BalanceSheet")
  @Extra({'requireApiKey': true})
  Future<LedgerReport> getBalanceSheet({
    @Query('periodName') String? periodName,
  });

  @GET("rest/s1/growerp/100/BalanceSummary")
  @Extra({'requireApiKey': true})
  Future<LedgerReport> getBalanceSummary({
    @Query('periodName') String? periodName,
  });

  @GET("rest/s1/growerp/100/AccountClass")
  @Extra({'requireApiKey': true})
  Future<AccountClasses> getAccountClass({
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  @GET("rest/s1/growerp/100/AccountType")
  @Extra({'requireApiKey': true})
  Future<AccountTypes> getAccountType({
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  // chat
  @GET("rest/s1/growerp/100/ChatRoom")
  @Extra({'requireApiKey': true})
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
  @Extra({'requireApiKey': true})
  Future<ChatRoom> createChatRoom({
    @Field() required ChatRoom chatRoom,
  });

  @PATCH("rest/s1/growerp/100/ChatRoom")
  @Extra({'requireApiKey': true})
  Future<ChatRoom> updateChatRoom({
    @Field() required ChatRoom chatRoom,
  });

  @DELETE("rest/s1/growerp/100/ChatRoom")
  @Extra({'requireApiKey': true})
  Future<ChatRoom> deleteChatRoom({@Field() required ChatRoom chatRoom});

  @GET("rest/s1/growerp/100/ChatMessage")
  @Extra({'requireApiKey': true})
  Future<ChatMessages> getChatMessages({
    @Query('chatRoomId') String? chatRoomId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  // tasks
  @GET("rest/s1/growerp/100/Task")
  @Extra({'requireApiKey': true})
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
  @Extra({'requireApiKey': true})
  Future<Task> createTask({
    @Field() required Task task,
  });

  @PATCH("rest/s1/growerp/100/Task")
  @Extra({'requireApiKey': true})
  Future<Task> updateTask({
    @Field() required Task task,
  });

  // user workflow
  @GET("rest/s1/growerp/100/UserWorkflow")
  @Extra({'requireApiKey': true})
  Future<Tasks> getUserWorkflow({
    @Query('taskType') TaskType? taskType,
  });

  @POST("rest/s1/growerp/100/UserWorkflow")
  @Extra({'requireApiKey': true})
  Future<Tasks> createUserWorkflow({
    @Field() required String workflowId,
  });

  @DELETE("rest/s1/growerp/100/UserWorkflow")
  @Extra({'requireApiKey': true})
  Future<Task> deleteUserWorkflow({
    @Field() required String workflowId,
  });

  // time entry
  @POST("rest/s1/growerp/100/TimeEntry")
  @Extra({'requireApiKey': true})
  Future<TimeEntry> createTimeEntry({
    @Field() required TimeEntry timeEntry,
  });

  @PATCH("rest/s1/growerp/100/TimeEntry")
  @Extra({'requireApiKey': true})
  Future<TimeEntry> updateTimeEntry({
    @Field() required TimeEntry timeEntry,
  });

  @DELETE("rest/s1/growerp/100/TimeEntry")
  @Extra({'requireApiKey': true})
  Future<TimeEntry> deleteTimeEntry({@Field() required TimeEntry timeEntry});

  // import / export ========
  @POST("rest/s1/growerp/100/ImportExport")
  @Extra({'requireApiKey': true})
  Future<void> uploadEntities(
      {@Field() required dynamic entities,
      @Field() required String classificationId});

  @POST("rest/s1/growerp/100/ImportExport/itemTypes")
  @Extra({'requireApiKey': true})
  Future<String> importItemTypes(@Field() List<ItemType> itemTypes);

  @POST("rest/s1/growerp/100/ImportExport/paymentTypes")
  @Extra({'requireApiKey': true})
  Future<String> importPaymentTypes(@Field() List<PaymentType> paymentTypes);

  @POST("rest/s1/growerp/100/ImportExport/glAccounts")
  @Extra({'requireApiKey': true})
  Future<String> importGlAccounts(@Field() List<GlAccount> glAccounts);

  @GET("rest/s1/growerp/100/exportGlAccounts")
  @Extra({'requireApiKey': true})
  Future<String> exportGlAccounts(
      {@Query('entityName') String entityName = 'glAccount'});

  @POST("rest/s1/growerp/100/ImportExport/companies")
  @Extra({'requireApiKey': true})
  Future<void> importCompanies(@Field() List<Company> companies);

  @POST("rest/s1/growerp/100/ImportExport/users")
  @Extra({'requireApiKey': true})
  Future<void> importUsers(@Field() List<User> users);

  @POST("rest/s1/growerp/100/ImportExport/products")
  @Extra({'requireApiKey': true})
  Future<void> importProducts(
      @Field() List<Product> products, @Field() String classificationId);

  @POST("rest/s1/growerp/100/ImportExport/categories")
  @Extra({'requireApiKey': true})
  Future<void> importCategories(@Field() List<Category> categories);

  @GET("rest/s1/growerp/100/Categories")
  @Extra({'requireApiKey': true})
  Future<Categories> getCategories({@Query('limit') int? limit});

  @GET("rest/s1/growerp/100/Products")
  @Extra({'requireApiKey': true})
  Future<Products> getProducts({
    @Query('limit') int? limit,
    @Query('classificationId') String? classificationId,
  });

  @GET("rest/s1/growerp/100/User")
  @Extra({'requireApiKey': true})
  Future<Users> getUsers(@Query('limit') String limit);

  // opportunities
  @GET("rest/s1/growerp/100/Opportunity")
  @Extra({'requireApiKey': true})
  Future<Opportunities> getOpportunity({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('opportunityId') String? opportunityId,
    @Query('search') String? searchString,
    @Query('my') bool? my,
  });

  @POST("rest/s1/growerp/100/Opportunity")
  @Extra({'requireApiKey': true})
  Future<Opportunity> createOpportunity(
      {@Field() required Opportunity opportunity});

  @PATCH("rest/s1/growerp/100/Opportunity")
  @Extra({'requireApiKey': true})
  Future<Opportunity> updateOpportunity(
      {@Field() required Opportunity opportunity});

  @DELETE("rest/s1/growerp/100/Opportunity")
  @Extra({'requireApiKey': true})
  Future<Opportunity> deleteOpportunity(
      {@Field() required Opportunity opportunity});
}

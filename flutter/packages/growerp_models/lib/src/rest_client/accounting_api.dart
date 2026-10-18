import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin AccountingApi {
  // accounting
  @GET("rest/s1/growerp/100/Ledger")
  Future<LedgerReport> getLedger();

  @POST("rest/s1/growerp/100/Ledger")
  Future<void> calculateLedger();

  @POST("rest/s1/growerp/100/Statistics")
  Future<void> recalculateStatistics({@Field() String? ownerPartyId});

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

  // simplified cash in / cash out bookkeeping
  @GET("rest/s1/growerp/100/CashBookEntry")
  Future<CashBookEntries> getCashBookEntry({
    @Query('transactionId') String? transactionId,
    @Query('isIncome') bool? isIncome,
    @Query('fromDate') String? fromDate,
    @Query('thruDate') String? thruDate,
    @Query('search') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/CashBookEntry")
  Future<CashBookEntry> createCashBookEntry({
    @Field() required CashBookEntry cashBookEntry,
  });

  @PATCH("rest/s1/growerp/100/CashBookEntry")
  Future<CashBookEntry> updateCashBookEntry({
    @Field() required CashBookEntry cashBookEntry,
  });

  @DELETE("rest/s1/growerp/100/CashBookEntry")
  Future<void> deleteCashBookEntry({@Field() required String transactionId});

  /// income (isIncome=true) or expense ledger accounts used as categories
  @GET("rest/s1/growerp/100/CashBookCategory")
  Future<GlAccounts> getCashBookCategory({
    @Query('isIncome') required bool isIncome,
    // only the categories the company uses: what the cash book offers
    @Query('usedOnly') bool? usedOnly,
  });

  @POST("rest/s1/growerp/100/CashBookCategory")
  Future<GlAccount> createCashBookCategory({
    @Field() required String accountName,
    @Field() required bool isIncome,
  });

  @PATCH("rest/s1/growerp/100/CashBookCategory")
  Future<GlAccount> updateCashBookCategory({
    @Field() required String glAccountId,
    @Field() bool? isUsed,
    @Field() String? accountName,
  });

  @GET("rest/s1/growerp/100/ProfitLoss")
  Future<ProfitLoss> getProfitLoss({@Query('periodName') String? periodName});

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

  // time entry
  @POST("rest/s1/growerp/100/TimeEntry")
  Future<TimeEntry> createTimeEntry({@Field() required TimeEntry timeEntry});

  @PATCH("rest/s1/growerp/100/TimeEntry")
  Future<TimeEntry> updateTimeEntry({@Field() required TimeEntry timeEntry});

  @DELETE("rest/s1/growerp/100/TimeEntry")
  Future<TimeEntry> deleteTimeEntry({@Field() required TimeEntry timeEntry});

  /// Create an invoice from approved time entries. sales=true: sales invoice
  /// to a client; sales=false: purchase (self-billing) invoice for an
  /// assistant, [hourlyRate] required.
  @POST("rest/s1/growerp/100/TimeEntryInvoice")
  Future<FinDoc> createInvoiceFromTimeEntries({
    @Field() required bool sales,
    @Field() required String partyId,
    @Field() String? hourlyRate,
  });

  /// Hours per assistant: in process, approved and invoiced.
  @GET("rest/s1/growerp/100/TimeEntryReport")
  Future<TimeEntryReport> getTimeEntryReport();
}

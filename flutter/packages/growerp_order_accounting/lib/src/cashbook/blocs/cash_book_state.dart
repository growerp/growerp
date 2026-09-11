part of 'cash_book_bloc.dart';

// categoriesSuccess is separate so the entry dialog does not pop when the
// category lists arrive while it is open
enum CashBookStatus { initial, success, categoriesSuccess, failure }

class CashBookState extends Equatable {
  const CashBookState({
    this.status = CashBookStatus.initial,
    this.entries = const <CashBookEntry>[],
    this.incomeCategories = const <GlAccount>[],
    this.expenseCategories = const <GlAccount>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
    this.isIncome,
  });

  final CashBookStatus status;
  final List<CashBookEntry> entries;
  final List<GlAccount> incomeCategories;
  final List<GlAccount> expenseCategories;
  final String? message;
  final bool hasReachedMax;
  final String searchString;
  final bool? isIncome; // active direction filter, null = all

  CashBookState copyWith({
    CashBookStatus? status,
    List<CashBookEntry>? entries,
    List<GlAccount>? incomeCategories,
    List<GlAccount>? expenseCategories,
    String? message,
    bool? hasReachedMax,
    String? searchString,
    bool? isIncome,
    bool clearIsIncome = false,
  }) {
    return CashBookState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      isIncome: clearIsIncome ? null : (isIncome ?? this.isIncome),
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    entries,
    incomeCategories,
    expenseCategories,
    hasReachedMax,
    isIncome,
  ];

  @override
  String toString() =>
      '$status { #entries: ${entries.length}, hasReachedMax: $hasReachedMax '
      'message $message}';
}

part of 'cash_book_bloc.dart';

abstract class CashBookEvent extends Equatable {
  const CashBookEvent();
  @override
  List<Object?> get props => [];
}

class CashBookFetch extends CashBookEvent {
  const CashBookFetch({
    this.searchString = '',
    this.refresh = false,
    this.isIncome, // null: both directions
  });
  final String searchString;
  final bool refresh;
  final bool? isIncome;
  @override
  List<Object?> get props => [searchString, refresh, isIncome];
}

class CashBookSearchChanged extends CashBookEvent {
  const CashBookSearchChanged({required this.searchString, this.isIncome});
  final String searchString;
  final bool? isIncome;
  @override
  List<Object?> get props => [searchString, isIncome];
}

/// create when [entry] has no transactionId, else update
class CashBookUpdate extends CashBookEvent {
  const CashBookUpdate(this.entry);
  final CashBookEntry entry;
}

class CashBookDelete extends CashBookEvent {
  const CashBookDelete(this.entry);
  final CashBookEntry entry;
}

class CashBookCategoriesFetch extends CashBookEvent {
  const CashBookCategoriesFetch({this.refresh = false});
  final bool refresh;
}

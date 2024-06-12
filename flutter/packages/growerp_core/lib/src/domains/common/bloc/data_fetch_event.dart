part of 'data_fetch_bloc.dart';

abstract class DataFetchBlocEvent extends Equatable {
  const DataFetchBlocEvent();
  @override
  List<Object> get props => [];
}

class GetDataEvent<T> extends DataFetchBlocEvent {
  const GetDataEvent(this.futureFunction);
  final Future<T> Function() futureFunction;
  @override
  List<Object> get props => [futureFunction];
}

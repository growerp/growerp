part of 'data_fetch_bloc.dart';

enum DataFetchStatus { initial, loading, success, failure }

class DataFetchState<T> extends Equatable {
  const DataFetchState({
    this.status = DataFetchStatus.initial,
    this.data = const Object(),
    this.message,
  });

  final DataFetchStatus status;
  final Object data;
  final String? message;

  DataFetchState copyWith({
    DataFetchStatus? status,
    Object? data,
    String? message,
  }) {
    return DataFetchState(
      status: status ?? this.status,
      data: data ?? this.data,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, data, message];

  @override
  String toString() => '$status { $data }';
}

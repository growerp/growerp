import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

part 'data_fetch_state.dart';
part 'data_fetch_event.dart';

mixin DataFetchBlocOther<T> on Bloc<DataFetchBlocEvent, DataFetchState> {}

class DataFetchBloc<T> extends Bloc<DataFetchBlocEvent, DataFetchState>
    with DataFetchBlocOther<T> {
  DataFetchBloc() : super(const DataFetchState()) {
    on<GetDataEvent<T>>(
        (GetDataEvent event, Emitter<DataFetchState> emit) async {
      try {
        emit(state.copyWith(status: DataFetchStatus.loading));
        final data = await event.futureFunction();
        return emit(
            state.copyWith(status: DataFetchStatus.success, data: data));
      } on DioException catch (e) {
        emit(state.copyWith(
            status: DataFetchStatus.failure,
            data: [],
            message: await getDioError(e)));
      }
    });
  }
}

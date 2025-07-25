import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

part 'data_fetch_state.dart';
part 'data_fetch_event.dart';

mixin DataFetchBlocOther<T> on Bloc<DataFetchBlocEvent, DataFetchState<T>> {}

EventTransformer<E> dataEventDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class DataFetchBloc<T> extends Bloc<DataFetchBlocEvent, DataFetchState<T>>
    with DataFetchBlocOther<T> {
  DataFetchBloc() : super(DataFetchState<T>()) {
    Future<void> onGetDataEvent<X>(
      GetDataEvent event,
      Emitter<DataFetchState<T>> emit,
    ) async {
      try {
        emit(state.copyWith(status: DataFetchStatus.loading));
        final data = await event.futureFunction();
        return emit(
            state.copyWith(status: DataFetchStatus.success, data: data));
      } on DioException catch (e) {
        emit(state.copyWith(
            status: DataFetchStatus.failure, message: await getDioError(e)));
      }
    }

    on<GetDataEvent<T>>(onGetDataEvent<T>,
        transformer: dataEventDroppable(const Duration(milliseconds: 100)));
  }
}

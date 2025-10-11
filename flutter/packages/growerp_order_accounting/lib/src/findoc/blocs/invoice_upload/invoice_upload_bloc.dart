import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:image_picker/image_picker.dart';

part 'invoice_upload_event.dart';
part 'invoice_upload_state.dart';

class InvoiceUploadBloc extends Bloc<InvoiceUploadEvent, InvoiceUploadState> {
  InvoiceUploadBloc(this.restClient) : super(const InvoiceUploadState()) {
    on<InvoiceUploadImage>(_onInvoiceUploadImage);
    on<InvoiceCreate>(_onInvoiceCreate);
  }

  final RestClient restClient;

  Future<void> _onInvoiceUploadImage(
    InvoiceUploadImage event,
    Emitter<InvoiceUploadState> emit,
  ) async {
    emit(state.copyWith(status: InvoiceUploadStatus.loading));
    try {
      final imageData = await event.image.readAsBytes();
      final base64Image = base64Encode(imageData);

      final result = await restClient.processInvoiceImage(
        imageData: base64Image,
        prompt: event.prompt,
        mimeType: event.mimeType,
      );

      final decodedResult = jsonDecode(result);
      emit(
        state.copyWith(
          status: InvoiceUploadStatus.success,
          extractedData: decodedResult as Map<String, dynamic>?,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: InvoiceUploadStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceUploadStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onInvoiceCreate(
    InvoiceCreate event,
    Emitter<InvoiceUploadState> emit,
  ) async {
    emit(state.copyWith(status: InvoiceUploadStatus.loading));
    try {
      final result = await restClient.createInvoiceFromData(
        invoiceData: event.invoiceData['extractedData'],
      );
      final decodedResult = jsonDecode(result);
      emit(
        state.copyWith(
          status: InvoiceUploadStatus.success,
          invoice: FinDoc.fromJson(decodedResult),
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: InvoiceUploadStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceUploadStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }
}

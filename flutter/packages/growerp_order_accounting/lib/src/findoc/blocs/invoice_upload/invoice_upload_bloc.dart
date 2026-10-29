import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:image_picker/image_picker.dart';

part 'invoice_upload_event.dart';
part 'invoice_upload_state.dart';

class InvoiceUploadBloc extends Bloc<InvoiceUploadEvent, InvoiceUploadState> {
  InvoiceUploadBloc(this.restClient) : super(const InvoiceUploadState()) {
    on<InvoiceUploadImage>(_onInvoiceUploadImage);
  }

  final RestClient restClient;

  Future<void> _onInvoiceUploadImage(
    InvoiceUploadImage event,
    Emitter<InvoiceUploadState> emit,
  ) async {
    emit(state.copyWith(status: InvoiceUploadStatus.loading));
    try {
      final imageData = await event.image.readAsBytes();
      final finDoc = await restClient.getFinDocFromImage(
        imageData: base64Encode(imageData),
        mimeType: _mimeType(event.image),
      );
      emit(state.copyWith(status: InvoiceUploadStatus.success, finDoc: finDoc));
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

  /// the picked file's own type, else from its name, else jpeg (camera)
  String _mimeType(XFile image) {
    if (image.mimeType != null) return image.mimeType!;
    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

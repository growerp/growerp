part of 'invoice_upload_bloc.dart';

enum InvoiceUploadStatus { initial, loading, success, failure }

class InvoiceUploadState extends Equatable {
  const InvoiceUploadState({
    this.status = InvoiceUploadStatus.initial,
    this.finDoc,
    this.message,
  });

  final InvoiceUploadStatus status;

  /// the purchase invoice read from the image, not saved yet
  final FinDoc? finDoc;
  final String? message;

  InvoiceUploadState copyWith({
    InvoiceUploadStatus? status,
    FinDoc? finDoc,
    String? message,
  }) {
    return InvoiceUploadState(
      status: status ?? this.status,
      finDoc: finDoc ?? this.finDoc,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, finDoc, message];
}

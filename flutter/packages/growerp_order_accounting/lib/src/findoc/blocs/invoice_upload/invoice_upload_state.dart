part of 'invoice_upload_bloc.dart';

enum InvoiceUploadStatus { initial, loading, success, failure }

class InvoiceUploadState extends Equatable {
  const InvoiceUploadState({
    this.status = InvoiceUploadStatus.initial,
    this.extractedData,
    this.invoice,
    this.message,
  });

  final InvoiceUploadStatus status;
  final Map<String, dynamic>? extractedData;
  final FinDoc? invoice;
  final String? message;

  InvoiceUploadState copyWith({
    InvoiceUploadStatus? status,
    Map<String, dynamic>? extractedData,
    FinDoc? invoice,
    String? message,
  }) {
    return InvoiceUploadState(
      status: status ?? this.status,
      extractedData: extractedData ?? this.extractedData,
      invoice: invoice ?? this.invoice,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, extractedData, invoice, message];
}
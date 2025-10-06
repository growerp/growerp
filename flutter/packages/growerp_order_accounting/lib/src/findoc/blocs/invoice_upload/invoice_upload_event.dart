part of 'invoice_upload_bloc.dart';

abstract class InvoiceUploadEvent extends Equatable {
  const InvoiceUploadEvent();

  @override
  List<Object> get props => [];
}

class InvoiceUploadImage extends InvoiceUploadEvent {
  const InvoiceUploadImage({
    required this.image,
    required this.prompt,
    required this.mimeType,
  });

  final XFile image;
  final String prompt;
  final String mimeType;

  @override
  List<Object> get props => [image, prompt, mimeType];
}

class InvoiceCreate extends InvoiceUploadEvent {
  const InvoiceCreate(this.invoiceData);

  final Map<String, dynamic> invoiceData;

  @override
  List<Object> get props => [invoiceData];
}
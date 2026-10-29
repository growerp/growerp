part of 'invoice_upload_bloc.dart';

abstract class InvoiceUploadEvent extends Equatable {
  const InvoiceUploadEvent();

  @override
  List<Object> get props => [];
}

/// read a supplier invoice image into a purchase invoice to review
class InvoiceUploadImage extends InvoiceUploadEvent {
  const InvoiceUploadImage(this.image);

  final XFile image;

  @override
  List<Object> get props => [image];
}

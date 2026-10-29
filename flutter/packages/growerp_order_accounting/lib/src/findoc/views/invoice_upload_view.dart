import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';
import 'package:growerp_order_accounting/src/findoc/blocs/invoice_upload/invoice_upload_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Pick a supplier invoice image and read it with AI. Pops with the purchase
/// invoice read (a FinDoc, not saved yet) so the caller opens it for review.
class InvoiceUploadView extends StatefulWidget {
  const InvoiceUploadView({super.key});

  @override
  State<InvoiceUploadView> createState() => _InvoiceUploadViewState();
}

class _InvoiceUploadViewState extends State<InvoiceUploadView> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  Uint8List? _imageBytes;
  OrderAccountingLocalizations? _localizations;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = imageBytes;
      });
    }
  }

  void _uploadImage() {
    if (_imageFile == null) {
      return;
    }
    context.read<InvoiceUploadBloc>().add(InvoiceUploadImage(_imageFile!));
  }

  @override
  Widget build(BuildContext context) {
    _localizations = OrderAccountingLocalizations.of(context)!;
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocListener<InvoiceUploadBloc, InvoiceUploadState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == InvoiceUploadStatus.failure) {
              HelperFunctions.showMessage(
                context,
                '${state.message}',
                Colors.red,
              );
            }
            if (state.status == InvoiceUploadStatus.success &&
                state.finDoc != null) {
              Navigator.of(context).pop(state.finDoc);
            }
          },
          child: Dialog(
            key: const Key('InvoiceUploadDialog'),
            insetPadding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: popUp(
              context: context,
              title: _localizations!.uploadInvoice,
              height: 450,
              width: 500,
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return BlocBuilder<InvoiceUploadBloc, InvoiceUploadState>(
      builder: (context, state) {
        if (state.status == InvoiceUploadStatus.loading) {
          return const Center(child: LoadingIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_imageFile != null && _imageBytes != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('pickImage'),
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(
                  _imageFile == null
                      ? _localizations!.pickImage
                      : _localizations!.changeImage,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('processImage'),
                onPressed: _imageFile != null ? _uploadImage : null,
                icon: const Icon(Icons.cloud_upload),
                label: Text(_localizations!.uploadAndProcess),
              ),
            ],
          ),
        );
      },
    );
  }
}
